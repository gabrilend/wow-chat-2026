/*
 * ground.c (issue 173f) - the painted ground; see ground.h
 *
 * For a general audience: turns each ground file's chunks into meshes and
 * pictures on the graphics card, and blends them as the original does.
 */
#include "ground.h"
#include "adt.h"
#include "blp.h"

#include "raymath.h"
#include "rlgl.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* {{{ the shader
 * Each chunk's four layers are bound to Raylib's first five material
 * slots (layers 0-3, then the blend picture); `uv` repeats each picture 8
 * times across a chunk (once every 4.2 yards, as the original tiles them),
 * `uv2` spans the blend picture once. Blending is the original's: each
 * layer laid over the ones below by its strength, then tinted by the
 * chunk's colours (MCCV; 127 = unchanged, so 0 to 2 times). */
static const char *VS =
    "#version 330\n"
    "in vec3 vertexPosition; in vec3 vertexNormal; in vec2 vertexTexCoord; in vec2 vertexTexCoord2; in vec4 vertexColor;\n"
    "uniform mat4 mvp; uniform vec3 eye;\n"
    "out vec3 n; out vec2 uv; out vec2 uv2; out vec3 tint; out float dist;\n"
    "void main() {\n"
    "  n = vertexNormal; uv = vertexTexCoord; uv2 = vertexTexCoord2; tint = vertexColor.rgb * (255.0 / 127.0);\n"
    "  dist = length(vertexPosition - eye);\n"
    "  gl_Position = mvp * vec4(vertexPosition, 1.0);\n"
    "}\n";
static const char *FS =
    "#version 330\n"
    "in vec3 n; in vec2 uv; in vec2 uv2; in vec3 tint; in float dist; out vec4 frag;\n"
    "uniform sampler2D layer0, layer1, layer2, layer3, blend; uniform vec3 sky;\n"
    "void main() {\n"
    "  vec4 a = texture(blend, uv2);\n"
    "  vec3 c = texture(layer0, uv).rgb;\n"
    "  c = mix(c, texture(layer1, uv).rgb, a.r);\n"
    "  c = mix(c, texture(layer2, uv).rgb, a.g);\n"
    "  c = mix(c, texture(layer3, uv).rgb, a.b) * tint;\n"
    "  vec3 sun = normalize(vec3(0.45, 0.30, 0.84));\n"
    "  float light = max(dot(normalize(n), sun), 0.0) * 0.75 + 0.30;\n"
    "  float fog = clamp((dist - 120.0) / 520.0, 0.0, 1.0);\n"
    "  frag = vec4(mix(c * light, sky, fog), 1.0);\n"
    "}\n";
/* }}} */

/* {{{ state
 * pictures: every ground picture loaded so far, by archive name, shared by
 * all chunks and tiles that use it (a tile uses 5 to 20; Ashenvale's
 * neighbours share most). tiles: what each loaded tile holds. */
#define MAX_PICTURES 512
static struct { char name[128]; Texture2D tex; } pictures[MAX_PICTURES];
static int npictures;

typedef struct {
    Mesh      mesh[256];
    Texture2D blend[256];
    int       picture[256][4];        /* into pictures[]; layers past nlayers repeat layer 0 */
    int       drawn[256];             /* 0 for a chunk that is all holes */
} GroundTile;
static GroundTile *tiles[64 * 64];

static MpqChain *chain;
static char      map_name[64];
static int       big_alpha;
static Shader    shader;
static Material  material;
static int       loc_eye, loc_sky;
/* }}} */

/* {{{ ground_init */
int ground_init(MpqChain *c, const char *name, char *why, int why_len)
{
    chain = c;
    snprintf(map_name, sizeof map_name, "%s", name);
    char path[200];
    snprintf(path, sizeof path, "World\\Maps\\%s\\%s.wdt", name, name);
    size_t len;
    const char *from;
    unsigned char *wdt = mpq_chain_read(chain, path, &len, &from);
    if (!wdt) { snprintf(why, why_len, "%s is in none of the client's archives", path); return 1; }
    big_alpha = adt_wdt_big_alpha(wdt, len, why, why_len);
    free(wdt);
    if (big_alpha < 0) return 1;

    shader = LoadShaderFromMemory(VS, FS);
    if (!IsShaderReady(shader)) { snprintf(why, why_len, "the ground shader didn't compile (see Raylib's messages above)"); return 1; }
    /* the five pictures go in Raylib's first five material slots, which
     * DrawMesh binds to whatever sampler each slot's location names */
    shader.locs[SHADER_LOC_MAP_ALBEDO]    = GetShaderLocation(shader, "layer0");
    shader.locs[SHADER_LOC_MAP_METALNESS] = GetShaderLocation(shader, "layer1");
    shader.locs[SHADER_LOC_MAP_NORMAL]    = GetShaderLocation(shader, "layer2");
    shader.locs[SHADER_LOC_MAP_ROUGHNESS] = GetShaderLocation(shader, "layer3");
    shader.locs[SHADER_LOC_MAP_OCCLUSION] = GetShaderLocation(shader, "blend");
    loc_eye = GetShaderLocation(shader, "eye");
    loc_sky = GetShaderLocation(shader, "sky");
    material = LoadMaterialDefault();
    material.shader = shader;
    return 0;
}
/* }}} */

/* {{{ static picture: a ground picture by archive name, loaded once */
static int picture(const char *name, char *why, int why_len)
{
    for (int i = 0; i < npictures; ++i) if (!strcmp(pictures[i].name, name)) return i;
    if (npictures == MAX_PICTURES) { snprintf(why, why_len, "more than %d ground pictures loaded", MAX_PICTURES); return -1; }
    size_t len;
    const char *from;
    unsigned char *s = mpq_chain_read(chain, name, &len, &from);
    if (!s) { snprintf(why, why_len, "the ground picture %s is in none of the client's archives", name); return -1; }
    BlpImage img;
    char inner[300];
    int bad = blp_decode(s, len, &img, inner, sizeof inner);
    free(s);
    if (bad) { snprintf(why, why_len, "the ground picture %s: %s", name, inner); return -1; }
    Image im = { .data = img.rgba, .width = img.width, .height = img.height, .mipmaps = 1, .format = PIXELFORMAT_UNCOMPRESSED_R8G8B8A8 };
    Texture2D t = LoadTextureFromImage(im);
    blp_free(&img);
    GenTextureMipmaps(&t);
    SetTextureFilter(t, TEXTURE_FILTER_TRILINEAR);
    SetTextureWrap(t, TEXTURE_WRAP_REPEAT);
    snprintf(pictures[npictures].name, sizeof pictures[npictures].name, "%s", name);
    pictures[npictures].tex = t;
    return npictures++;
}
/* }}} */

/* {{{ static chunk_mesh: one chunk's 145 points and its triangles
 * The original's four triangles a cell (each corner pair with the centre),
 * none in a hole: hole bit (row / 2) * 4 + col / 2 hides a 2 x 2 block of
 * cells. Returns 0 when every cell is a hole. */
static int chunk_mesh(const AdtChunk *c, double ox, double oy, MapWorld *world, Mesh *out)
{
    const float step = ADT_CHUNK_SIZE / 8;
    Mesh m = { 0 };
    m.vertexCount = 145;
    m.vertices   = MemAlloc(sizeof(float) * 3 * 145);
    m.normals    = MemAlloc(sizeof(float) * 3 * 145);
    m.texcoords  = MemAlloc(sizeof(float) * 2 * 145);
    m.texcoords2 = MemAlloc(sizeof(float) * 2 * 145);
    m.colors     = MemAlloc(4 * 145);
    for (int i = 0; i < 145; ++i) {
        int   r17 = i % 17;
        float row = (float)(i / 17) + (r17 >= 9 ? 0.5f : 0.0f);      /* centres sit half a cell in */
        float col = r17 >= 9 ? (float)(r17 - 9) + 0.5f : (float)r17;
        float wx = c->x - row * step, wy = c->y - col * step;
        m.vertices[i * 3]     = (float)(wx - ox);
        m.vertices[i * 3 + 1] = (float)(wy - oy);
        m.vertices[i * 3 + 2] = c->z + c->heights[i];
        /* light: the server's ground's slope a yard either side, so it runs on
         * smoothly over chunk and tile edges */
        float gx, gy;
        float hn = maps_world_height(world, wx + 1, wy, &gx, &gy), hs = maps_world_height(world, wx - 1, wy, &gx, &gy);
        float hw = maps_world_height(world, wx, wy + 1, &gx, &gy), he = maps_world_height(world, wx, wy - 1, &gx, &gy);
        /* where the server has no ground a yard away (the map's edge), the
         * point is lit as level ground */
        int edge = hn < -10000 || hs < -10000 || hw < -10000 || he < -10000;
        Vector3 nv = edge ? (Vector3){ 0, 0, 1 } : Vector3Normalize((Vector3){ -(hn - hs) / 2, -(hw - he) / 2, 1 });
        m.normals[i * 3] = nv.x; m.normals[i * 3 + 1] = nv.y; m.normals[i * 3 + 2] = nv.z;
        m.colors[i * 4] = c->tint[i][0]; m.colors[i * 4 + 1] = c->tint[i][1]; m.colors[i * 4 + 2] = c->tint[i][2]; m.colors[i * 4 + 3] = 255;
        m.texcoords[i * 2] = col;          /* 8 repeats across the chunk */
        m.texcoords[i * 2 + 1] = row;
        /* corners land on the blend picture's first and last points' centres */
        m.texcoords2[i * 2]     = (col / 8.0f) * (63.0f / 64.0f) + 0.5f / 64.0f;
        m.texcoords2[i * 2 + 1] = (row / 8.0f) * (63.0f / 64.0f) + 0.5f / 64.0f;
    }
    m.indices = MemAlloc(sizeof(unsigned short) * 64 * 12);
    int n = 0;
    for (int r = 0; r < 8; ++r)
        for (int col = 0; col < 8; ++col) {
            if (c->holes & (1 << ((r / 2) * 4 + col / 2))) continue;
            unsigned short a = (unsigned short)adt_corner(r, col), b = (unsigned short)adt_corner(r, col + 1);
            unsigned short d = (unsigned short)adt_corner(r + 1, col), e = (unsigned short)adt_corner(r + 1, col + 1);
            unsigned short mid = (unsigned short)adt_centre(r, col);
            unsigned short tri[12] = { a, b, mid, b, e, mid, e, d, mid, d, a, mid };
            memcpy(m.indices + n, tri, sizeof tri);
            n += 12;
        }
    if (n == 0) { UnloadMesh(m); return 0; }
    m.triangleCount = n / 3;
    UploadMesh(&m, false);
    *out = m;
    return 1;
}
/* }}} */

/* {{{ ground_load_tile */
int ground_load_tile(int tx, int ty, double ox, double oy, MapWorld *world, char *why, int why_len)
{
    if (tx < 0 || tx > 63 || ty < 0 || ty > 63) return 1;
    char path[200];
    snprintf(path, sizeof path, "World\\Maps\\%s\\%s_%d_%d.adt", map_name, map_name, ty, tx);   /* west-east number first */
    size_t len;
    const char *from;
    unsigned char *s = mpq_chain_read(chain, path, &len, &from);
    if (!s) return 1;
    AdtTile *adt = malloc(sizeof *adt);
    char inner[400];
    if (adt_read(s, len, big_alpha, adt, inner, sizeof inner)) {
        snprintf(why, why_len, "%s (from %s): %s", path, from, inner);
        free(s); free(adt);
        return -1;
    }
    free(s);
    if (adt->ntextures > 256) {
        snprintf(why, why_len, "%s lists %d ground pictures; at most 256 are expected", path, adt->ntextures);
        adt_free(adt); free(adt);
        return -1;
    }
    int pic[256];                                     /* the tile's picture numbers, in pictures[] */
    for (int i = 0; i < adt->ntextures && i < 256; ++i) pic[i] = -2;   /* -2: not needed yet */
    GroundTile *g = calloc(1, sizeof *g);
    unsigned char blend[64 * 64 * 4];
    for (int k = 0; k < 256; ++k) {
        const AdtChunk *c = &adt->chunks[k];
        if (!chunk_mesh(c, ox, oy, world, &g->mesh[k])) continue;
        g->drawn[k] = 1;
        for (int l = 0; l < 4; ++l) {
            int t = c->tex[l < c->nlayers ? l : 0];
            if (pic[t] == -2) pic[t] = picture(adt->textures[t], why, why_len);
            if (pic[t] < 0) { adt_free(adt); free(adt); return -1; }   /* `why` says which picture */
            g->picture[k][l] = pic[t];
        }
        for (int i = 0; i < 4096; ++i) {
            blend[i * 4]     = c->nlayers > 1 ? c->alpha[1][i] : 0;
            blend[i * 4 + 1] = c->nlayers > 2 ? c->alpha[2][i] : 0;
            blend[i * 4 + 2] = c->nlayers > 3 ? c->alpha[3][i] : 0;
            blend[i * 4 + 3] = c->shadow[i] ? 0 : 255;          /* 173h: 255 lit, 0 shadowed */
        }
        Image im = { .data = blend, .width = 64, .height = 64, .mipmaps = 1, .format = PIXELFORMAT_UNCOMPRESSED_R8G8B8A8 };
        g->blend[k] = LoadTextureFromImage(im);
        SetTextureFilter(g->blend[k], TEXTURE_FILTER_BILINEAR);
        SetTextureWrap(g->blend[k], TEXTURE_WRAP_CLAMP);
    }
    adt_free(adt);
    free(adt);
    tiles[tx * 64 + ty] = g;
    return 0;
}
/* }}} */

/* {{{ ground_draw */
void ground_draw(Vector3 eye, const float sky[3])
{
    SetShaderValue(shader, loc_eye, &eye, SHADER_UNIFORM_VEC3);
    SetShaderValue(shader, loc_sky, sky, SHADER_UNIFORM_VEC3);
    for (int t = 0; t < 64 * 64; ++t) {
        GroundTile *g = tiles[t];
        if (!g) continue;
        for (int k = 0; k < 256; ++k) {
            if (!g->drawn[k]) continue;
            material.maps[MATERIAL_MAP_ALBEDO].texture    = pictures[g->picture[k][0]].tex;
            material.maps[MATERIAL_MAP_METALNESS].texture = pictures[g->picture[k][1]].tex;
            material.maps[MATERIAL_MAP_NORMAL].texture    = pictures[g->picture[k][2]].tex;
            material.maps[MATERIAL_MAP_ROUGHNESS].texture = pictures[g->picture[k][3]].tex;
            material.maps[MATERIAL_MAP_OCCLUSION].texture = g->blend[k];
            DrawMesh(g->mesh[k], material, MatrixIdentity());
        }
    }
}
/* }}} */
