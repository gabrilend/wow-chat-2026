/*
 * water.c (issue 173r) - drawing the water; see water.h
 *
 * For a general audience: one mesh per water layer, one run of ripple
 * pictures per kind of water, and a shader that tints and fogs them.
 */
#include "water.h"
#include "blp.h"
#include "dbc.h"
#include "sky.h"

#include "raymath.h"
#include "rlgl.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* {{{ the shader
 * The ripple picture, tinted toward the zone's near-water colour (water
 * and sea), lit a little by the sun, fogged; see-through (alpha 0.75).
 * Lava and slime (`raw`): the picture alone, solid. */
static const char *VS =
    "#version 330\n"
    "in vec3 vertexPosition; in vec2 vertexTexCoord;\n"
    "uniform mat4 mvp; uniform vec3 eye;\n"
    "out vec2 uv; out float dist;\n"
    "void main() { uv = vertexTexCoord; dist = length(vertexPosition - eye); gl_Position = mvp * vec4(vertexPosition, 1.0); }\n";
static const char *FS =
    "#version 330\n"
    "in vec2 uv; in float dist; out vec4 frag;\n"
    "uniform sampler2D texture0; uniform vec3 tint; uniform float raw;\n"
    "uniform vec3 sun_dir, sun_col, shade_col, fog_col; uniform vec2 fog_range;\n"
    "void main() {\n"
    "  vec3 t = texture(texture0, uv).rgb;\n"
    "  vec3 c = mix(t * 0.6 + tint * 0.6, t, raw);\n"
    "  c *= mix(shade_col + sun_col * max(sun_dir.z, 0.0), vec3(1.0), raw);\n"
    "  float fog = clamp((dist - fog_range.x) / max(fog_range.y - fog_range.x, 1.0), 0.0, 1.0);\n"
    "  frag = vec4(mix(c, fog_col, fog), mix(0.75, 1.0, raw));\n"
    "}\n";
/* }}} */

/* {{{ state
 * kinds: per LiquidType id met so far, its run of pictures and its type
 * (0 water, 1 ocean, 2 magma, 3 slime). layers: one mesh per water layer
 * with the kind it uses. */
#define MAX_FRAMES 32
typedef struct { int id, type; Texture2D frames[MAX_FRAMES]; int nframes; } Kind;
static Kind  kinds[64];   static int nkinds;
static struct { Mesh mesh; int kind, tile; } *layers;
static int   nlayers, layers_cap;
static MpqChain *chain;
static Dbc   table;  static unsigned char *table_bytes;
static Shader shader;
static Material material;
static int   loc_eye, loc_tint, loc_raw;
/* }}} */

/* {{{ water_init */
int water_init(MpqChain *c, char *why, int why_len)
{
    chain = c;
    size_t len;
    const char *from;
    table_bytes = mpq_chain_read(chain, "DBFilesClient\\LiquidType.dbc", &len, &from);
    if (!table_bytes) { snprintf(why, why_len, "LiquidType.dbc is in none of the client's archives"); return 1; }
    char inner[200];
    if (dbc_open(&table, table_bytes, len, inner, sizeof inner)) { snprintf(why, why_len, "LiquidType.dbc: %s", inner); return 1; }
    shader = LoadShaderFromMemory(VS, FS);
    if (!IsShaderReady(shader)) { snprintf(why, why_len, "the water shader didn't compile (see Raylib's messages above)"); return 1; }
    loc_eye = GetShaderLocation(shader, "eye");
    loc_tint = GetShaderLocation(shader, "tint");
    loc_raw = GetShaderLocation(shader, "raw");
    material = LoadMaterialDefault();
    material.shader = shader;
    return 0;
}
/* }}} */

/* {{{ static kind_of: a liquid kind's pictures, loaded once
 * LiquidType (3.3.5a): 1 id, 4 type, 16 the picture name with %d for the
 * frame number (1 upward). Frames are loaded until one is missing. A kind
 * with no pictures is drawn plain (and said once). */
static int kind_of(int id)
{
    for (int i = 0; i < nkinds; ++i) if (kinds[i].id == id) return i;
    if (nkinds == 64) return -1;
    Kind *k = &kinds[nkinds];
    memset(k, 0, sizeof *k);
    k->id = id;
    const char *pattern = NULL;
    for (uint32_t r = 0; r < table.rows; ++r)
        if ((int)dbc_u32(&table, r, 1) == id) { k->type = (int)dbc_u32(&table, r, 4); pattern = dbc_text(&table, r, 16); break; }
    if (!pattern || !pattern[0]) fprintf(stderr, "water: liquid kind %d has no pictures in LiquidType.dbc; drawn plain\n", id);
    for (int f = 1; pattern && pattern[0] && f <= MAX_FRAMES; ++f) {
        char name[300];
        snprintf(name, sizeof name, pattern, f);
        size_t len;
        const char *from;
        unsigned char *s = mpq_chain_read(chain, name, &len, &from);
        if (!s) break;
        BlpImage img;
        char why[200];
        int bad = blp_decode(s, len, &img, why, sizeof why);
        free(s);
        if (bad) { fprintf(stderr, "water: %s: %s\n", name, why); break; }
        Image im = { .data = img.rgba, .width = img.width, .height = img.height, .mipmaps = 1, .format = PIXELFORMAT_UNCOMPRESSED_R8G8B8A8 };
        k->frames[k->nframes] = LoadTextureFromImage(im);
        blp_free(&img);
        GenTextureMipmaps(&k->frames[k->nframes]);
        SetTextureFilter(k->frames[k->nframes], TEXTURE_FILTER_TRILINEAR);
        SetTextureWrap(k->frames[k->nframes], TEXTURE_WRAP_REPEAT);
        ++k->nframes;
    }
    return nkinds++;
}
/* }}} */

/* {{{ water_add_tile
 * Each wet cell: two triangles over its four corners; the picture
 * repeats once a cell (4.2 yards), placed by world position so
 * neighbouring layers meet seamlessly. */
void water_add_tile(const AdtTile *t, int tile, double ox, double oy)
{
    const float step = ADT_CHUNK_SIZE / 8;
    for (int i = 0; i < t->nliquids; ++i) {
        const AdtLiquid *q = &t->liquids[i];
        const AdtChunk *c = &t->chunks[q->chunk];
        int cells = 0;
        for (int r = 0; r < 8; ++r) for (int col = 0; col < 8; ++col) cells += q->wet[r][col];
        if (!cells) continue;
        Mesh m = { 0 };
        m.vertexCount = cells * 6;
        m.triangleCount = cells * 2;
        m.vertices = MemAlloc(sizeof(float) * 3 * m.vertexCount);
        m.texcoords = MemAlloc(sizeof(float) * 2 * m.vertexCount);
        int v = 0;
        for (int r = 0; r < 8; ++r)
            for (int col = 0; col < 8; ++col) {
                if (!q->wet[r][col]) continue;
                static const int CORNER[6][2] = { { 0, 0 }, { 0, 1 }, { 1, 1 }, { 0, 0 }, { 1, 1 }, { 1, 0 } };
                for (int k = 0; k < 6; ++k) {
                    int rr = r + CORNER[k][0], cc = col + CORNER[k][1];
                    double wx = c->x - rr * step, wy = c->y - cc * step;
                    m.vertices[v * 3] = (float)(wx - ox);
                    m.vertices[v * 3 + 1] = (float)(wy - oy);
                    m.vertices[v * 3 + 2] = q->height[rr][cc];
                    m.texcoords[v * 2] = (float)(wy / step);
                    m.texcoords[v * 2 + 1] = (float)(wx / step);
                    ++v;
                }
            }
        UploadMesh(&m, false);
        if (nlayers == layers_cap) { layers_cap = layers_cap ? layers_cap * 2 : 128; layers = realloc(layers, sizeof *layers * layers_cap); }
        layers[nlayers].mesh = m;
        layers[nlayers].kind = kind_of(q->kind);
        layers[nlayers].tile = tile;
        ++nlayers;
    }
}
/* }}} */

/* {{{ water_drop_tile */
void water_drop_tile(int tile)
{
    int kept = 0;
    for (int i = 0; i < nlayers; ++i) {
        if (layers[i].tile == tile) { UnloadMesh(layers[i].mesh); continue; }
        layers[kept++] = layers[i];
    }
    nlayers = kept;
}
/* }}} */

/* {{{ water_draw
 * Ripples at 15 pictures a second. Drawn with depth testing but without
 * depth writing, see-through, after everything solid. */
void water_draw(Vector3 eye, const LightNow *light, double seconds)
{
    SetShaderValue(shader, loc_eye, &eye, SHADER_UNIFORM_VEC3);
    sky_light_shader(shader, light);
    rlDisableDepthMask();
    BeginBlendMode(BLEND_ALPHA);
    for (int i = 0; i < nlayers; ++i) {
        if (layers[i].kind < 0) continue;
        Kind *k = &kinds[layers[i].kind];
        float raw = k->type >= 2 ? 1.0f : 0.0f;
        const float *tint = k->type == 1 ? light->water[0] : light->water[2];   /* the sea's near colour, or a river's */
        SetShaderValue(shader, loc_tint, tint, SHADER_UNIFORM_VEC3);
        SetShaderValue(shader, loc_raw, &raw, SHADER_UNIFORM_FLOAT);
        if (k->nframes) material.maps[MATERIAL_MAP_DIFFUSE].texture = k->frames[(int)(seconds * 15.0) % k->nframes];
        DrawMesh(layers[i].mesh, material, MatrixIdentity());
    }
    EndBlendMode();
    rlDrawRenderBatchActive();
    rlEnableDepthMask();
}
/* }}} */
