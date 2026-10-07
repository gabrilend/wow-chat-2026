/*
 * ground.c (issue 173f) - the painted ground; see ground.h
 *
 * For a general audience: turns each ground file's chunks into meshes and
 * pictures on the graphics card, and blends them as the original does.
 */
#include "ground.h"
#include "adt.h"
#include "blp.h"
#include "sight.h"
#include "sky.h"

#include "raymath.h"
#include "rlgl.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* {{{ the shader
 * A tile is drawn in four orders (one a quarter: 64 chunks each), not 256
 * (173u). Every ground picture lives in one texture array (`layers`, one
 * 256 x 256 layer a picture, shared by all tiles); each chunk's four
 * layer numbers ride on its points (Raylib's tangent slot, `lay`, not
 * blended across a triangle). The tile's 256 blend pictures sit in one
 * 1024 x 1024 picture (`blend`), 64 x 64 a chunk; `uv2` reaches only the
 * chunk's own square (from its first point's centre to its last's), so
 * smoothing never borrows a neighbour's. `uv` repeats each picture 8
 * times across a chunk (once every 4.2 yards, as the original tiles them).
 * Blending is the original's: each layer laid over the ones below by its
 * strength, then tinted by the chunk's colours (MCCV; 127 = unchanged, so
 * 0 to 2 times), then darkened where the chunk's baked shadow says (173h:
 * to 60%, the blend picture's alpha), and under each character by a soft
 * round patch (a "blob": its centre, its radius; fading out over 3 yards
 * of height, so a character high above the ground casts none). */
static const char *VS =
    "#version 330\n"
    "in vec3 vertexPosition; in vec3 vertexNormal; in vec2 vertexTexCoord; in vec2 vertexTexCoord2; in vec4 vertexColor; in vec4 vertexTangent;\n"
    "uniform mat4 mvp; uniform vec3 eye;\n"
    "out vec3 n; out vec2 uv; out vec2 uv2; out vec3 tint; out float dist; out vec3 pos; flat out vec4 lay;\n"
    "void main() {\n"
    "  pos = vertexPosition; lay = vertexTangent;\n"
    "  n = vertexNormal; uv = vertexTexCoord; uv2 = vertexTexCoord2; tint = vertexColor.rgb * (255.0 / 127.0);\n"
    "  dist = length(vertexPosition - eye);\n"
    "  gl_Position = mvp * vec4(vertexPosition, 1.0);\n"
    "}\n";
static const char *FS =
    "#version 330\n"
    "in vec3 n; in vec2 uv; in vec2 uv2; in vec3 tint; in float dist; in vec3 pos; flat in vec4 lay; out vec4 frag;\n"
    "uniform sampler2D blend; uniform sampler2DArray layers; uniform vec3 sun_dir, sun_col, shade_col, fog_col; uniform vec2 fog_range;\n"
    "uniform vec4 blobs[8]; uniform int nblobs;\n"
    "void main() {\n"
    "  vec4 a = texture(blend, uv2);\n"
    "  vec3 c = texture(layers, vec3(uv, lay.x)).rgb;\n"
    "  c = mix(c, texture(layers, vec3(uv, lay.y)).rgb, a.r);\n"
    "  c = mix(c, texture(layers, vec3(uv, lay.z)).rgb, a.g);\n"
    "  c = mix(c, texture(layers, vec3(uv, lay.w)).rgb, a.b) * tint;\n"
    "  c *= mix(0.6, 1.0, a.a);\n"
    "  for (int i = 0; i < nblobs; ++i) {\n"
    "    float d = length(pos.xy - blobs[i].xy) / blobs[i].w;\n"
    "    float above = clamp(1.0 - abs(pos.z - blobs[i].z) / 3.0, 0.0, 1.0);\n"
    "    c *= 1.0 - 0.6 * (1.0 - smoothstep(0.3, 1.0, d)) * above;\n"
    "  }\n"
    "  vec3 light = shade_col + sun_col * max(dot(normalize(n), sun_dir), 0.0);\n"
    "  float fog = clamp((dist - fog_range.x) / max(fog_range.y - fog_range.x, 1.0), 0.0, 1.0);\n"
    "  frag = vec4(mix(c * light, fog_col, fog), 1.0);\n"
    "}\n";
/* }}} */

/* {{{ the texture array, through OpenGL directly
 * Raylib 5.1 has no texture arrays, but the OpenGL loader it is built with
 * (glad) keeps every OpenGL function in a global pointer, linked into
 * libraylib.a; these are those pointers (under their own names) and the
 * OpenGL numbers they take. Only the main thread may call them, as with
 * all drawing. */
typedef unsigned int GLenum_;
extern void (*glad_glGenTextures)(int n, unsigned int *textures);
extern void (*glad_glBindTexture)(GLenum_ target, unsigned int texture);
extern void (*glad_glTexImage3D)(GLenum_ target, int level, int internalformat, int width, int height, int depth, int border, GLenum_ format, GLenum_ type, const void *pixels);
extern void (*glad_glTexSubImage3D)(GLenum_ target, int level, int x, int y, int z, int width, int height, int depth, GLenum_ format, GLenum_ type, const void *pixels);
extern void (*glad_glTexParameteri)(GLenum_ target, GLenum_ pname, int param);
extern void (*glad_glGenerateMipmap)(GLenum_ target);
#define GL_TEXTURE_2D_ARRAY_       0x8C1A
#define GL_RGBA_                   0x1908
#define GL_RGBA8_                  0x8058
#define GL_UNSIGNED_BYTE_          0x1401
#define GL_TEXTURE_MAG_FILTER_     0x2800
#define GL_TEXTURE_MIN_FILTER_     0x2801
#define GL_TEXTURE_WRAP_S_         0x2802
#define GL_TEXTURE_WRAP_T_         0x2803
#define GL_LINEAR_                 0x2601
#define GL_LINEAR_MIPMAP_LINEAR_   0x2703
#define GL_REPEAT_                 0x2901
#define LAYER_SIZE   256              /* nearly every ground picture is 256 x 256 (measured: 139 of 141 round
                                       * Astranaar, Elwynn and Northrend; two tiny ones); others are resized */
#define LAYER_LEVELS 9                /* 256 down to 1 */
#define LAYERS       256              /* layers in the array (about 87 MB with their smaller copies); a tile
                                       * uses 4 to 23; a layer no loaded tile uses is freed for reuse */
#define ARRAY_UNIT   5                /* the texture unit the array is bound to (Raylib's maps use the first ones) */
/* }}} */

/* {{{ state
 * pictures: every ground picture loaded so far, by archive name, shared by
 * all chunks and tiles that use it (a tile uses 5 to 20; Ashenvale's
 * neighbours share most). tiles: what each loaded tile holds. */
static struct { char name[128]; int refs; } layer_of[LAYERS];   /* refs: loaded tiles using it; name "" free */
static unsigned int array_id;

typedef struct {
    Mesh      mesh[4];                /* a quarter each: chunks with rows (or columns) 0-7 or 8-15 */
    int       has[4];                 /* 0 for a quarter that is all holes */
    Vector3   centre[4];  float radius[4];   /* each quarter's bounding ball, for the sight test */
    Texture2D blend;                  /* the 256 chunks' blend pictures, 16 x 16 of 64 x 64 */
    int       used[256];  int nused;  /* the layers this tile holds a reference to */
} GroundTile;
static GroundTile *tiles[64 * 64];

static MpqChain *chain;
static char      map_name[64];
static int       big_alpha;
static Shader    shader;
static Material  material;
static int       loc_eye, loc_blobs, loc_nblobs;
static float     blobs[8][4];
static int       ground_orders;                        /* draw orders sent since last asked (for the picture report) */
static int       nblobs;
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
    shader.locs[SHADER_LOC_MAP_ALBEDO] = GetShaderLocation(shader, "blend");   /* Raylib binds the material's first map to it */
    int unit = ARRAY_UNIT;
    SetShaderValue(shader, GetShaderLocation(shader, "layers"), &unit, SHADER_UNIFORM_INT);
    /* the array: LAYERS layers of LAYER_SIZE square, every smaller copy
     * made room for, smoothed between copies, repeating */
    glad_glGenTextures(1, &array_id);
    glad_glBindTexture(GL_TEXTURE_2D_ARRAY_, array_id);
    for (int lv = 0; lv < LAYER_LEVELS; ++lv)
        glad_glTexImage3D(GL_TEXTURE_2D_ARRAY_, lv, GL_RGBA8_, LAYER_SIZE >> lv, LAYER_SIZE >> lv, LAYERS, 0, GL_RGBA_, GL_UNSIGNED_BYTE_, NULL);
    glad_glTexParameteri(GL_TEXTURE_2D_ARRAY_, GL_TEXTURE_MIN_FILTER_, GL_LINEAR_MIPMAP_LINEAR_);
    glad_glTexParameteri(GL_TEXTURE_2D_ARRAY_, GL_TEXTURE_MAG_FILTER_, GL_LINEAR_);
    glad_glTexParameteri(GL_TEXTURE_2D_ARRAY_, GL_TEXTURE_WRAP_S_, GL_REPEAT_);
    glad_glTexParameteri(GL_TEXTURE_2D_ARRAY_, GL_TEXTURE_WRAP_T_, GL_REPEAT_);
    glad_glBindTexture(GL_TEXTURE_2D_ARRAY_, 0);
    loc_eye = GetShaderLocation(shader, "eye");
    loc_blobs = GetShaderLocation(shader, "blobs");
    loc_nblobs = GetShaderLocation(shader, "nblobs");
    material = LoadMaterialDefault();
    material.shader = shader;
    return 0;
}
/* }}} */

/* {{{ static picture: a ground picture's layer in the array, by archive
 * name, loaded once and shared; the caller holds one reference per tile.
 * A picture not 256 x 256 is resized to it (the two tiny ones seen are
 * plain colours; a larger one would lose detail, and is said). -1 with
 * `why` when it can't be read or the array is full. */
static int picture(const char *name, char *why, int why_len)
{
    int free_slot = -1;
    for (int i = 0; i < LAYERS; ++i) {
        if (layer_of[i].name[0] && !strcmp(layer_of[i].name, name)) return i;
        if (!layer_of[i].name[0] && free_slot < 0) free_slot = i;
    }
    if (free_slot < 0) { snprintf(why, why_len, "the ground's %d picture layers are all in use by loaded tiles", LAYERS); return -1; }
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
    Image sized = ImageCopy(im);
    blp_free(&img);
    if (sized.width != LAYER_SIZE || sized.height != LAYER_SIZE) {
        if (sized.width > LAYER_SIZE || sized.height > LAYER_SIZE)
            fprintf(stderr, "ground: %s is %d x %d; shrunk to the array's %d x %d, losing detail\n", name, sized.width, sized.height, LAYER_SIZE, LAYER_SIZE);
        ImageResize(&sized, LAYER_SIZE, LAYER_SIZE);
    }
    glad_glBindTexture(GL_TEXTURE_2D_ARRAY_, array_id);
    glad_glTexSubImage3D(GL_TEXTURE_2D_ARRAY_, 0, 0, 0, free_slot, LAYER_SIZE, LAYER_SIZE, 1, GL_RGBA_, GL_UNSIGNED_BYTE_, sized.data);
    glad_glBindTexture(GL_TEXTURE_2D_ARRAY_, 0);
    UnloadImage(sized);
    snprintf(layer_of[free_slot].name, sizeof layer_of[free_slot].name, "%s", name);
    layer_of[free_slot].refs = 0;
    return free_slot;
}
/* }}} */

/* {{{ static chunk_points: one chunk's 145 points and its triangles,
 * written into a quarter's mesh arrays at point `base` and index `*n`
 * The original's four triangles a cell (each corner pair with the
 * centre), none in a hole: hole bit (row / 2) * 4 + col / 2 hides a 2 x 2
 * block of cells. `bx`, `by` are the chunk's place in the tile's blend
 * picture (0-15 each), `lay` its four layers. */
static void chunk_points(const AdtChunk *c, double ox, double oy, MapWorld *world, Mesh *m, int base, int *n, int bx, int by, const int lay[4])
{
    const float step = ADT_CHUNK_SIZE / 8;
    for (int i = 0; i < 145; ++i) {
        int   r17 = i % 17, v = base + i;
        float row = (float)(i / 17) + (r17 >= 9 ? 0.5f : 0.0f);      /* centres sit half a cell in */
        float col = r17 >= 9 ? (float)(r17 - 9) + 0.5f : (float)r17;
        float wx = c->x - row * step, wy = c->y - col * step;
        m->vertices[v * 3]     = (float)(wx - ox);
        m->vertices[v * 3 + 1] = (float)(wy - oy);
        m->vertices[v * 3 + 2] = c->z + c->heights[i];
        /* light: the server's ground's slope a yard either side, so it runs on
         * smoothly over chunk and tile edges */
        float gx, gy;
        float hn = maps_world_height(world, wx + 1, wy, &gx, &gy), hs = maps_world_height(world, wx - 1, wy, &gx, &gy);
        float hw = maps_world_height(world, wx, wy + 1, &gx, &gy), he = maps_world_height(world, wx, wy - 1, &gx, &gy);
        /* where the server has no ground a yard away (the map's edge), the
         * point is lit as level ground */
        int edge = hn < -10000 || hs < -10000 || hw < -10000 || he < -10000;
        Vector3 nv = edge ? (Vector3){ 0, 0, 1 } : Vector3Normalize((Vector3){ -(hn - hs) / 2, -(hw - he) / 2, 1 });
        m->normals[v * 3] = nv.x; m->normals[v * 3 + 1] = nv.y; m->normals[v * 3 + 2] = nv.z;
        m->colors[v * 4] = c->tint[i][0]; m->colors[v * 4 + 1] = c->tint[i][1]; m->colors[v * 4 + 2] = c->tint[i][2]; m->colors[v * 4 + 3] = 255;
        m->texcoords[v * 2] = col;          /* 8 repeats across the chunk */
        m->texcoords[v * 2 + 1] = row;
        /* corners land on the chunk's blend square's first and last points' centres */
        m->texcoords2[v * 2]     = ((float)bx * 64 + 0.5f + col / 8.0f * 63.0f) / 1024.0f;
        m->texcoords2[v * 2 + 1] = ((float)by * 64 + 0.5f + row / 8.0f * 63.0f) / 1024.0f;
        for (int l = 0; l < 4; ++l) m->tangents[v * 4 + l] = (float)lay[l];
    }
    for (int r = 0; r < 8; ++r)
        for (int col = 0; col < 8; ++col) {
            if (c->holes & (1 << ((r / 2) * 4 + col / 2))) continue;
            unsigned short a = (unsigned short)(base + adt_corner(r, col)), b = (unsigned short)(base + adt_corner(r, col + 1));
            unsigned short d = (unsigned short)(base + adt_corner(r + 1, col)), e = (unsigned short)(base + adt_corner(r + 1, col + 1));
            unsigned short mid = (unsigned short)(base + adt_centre(r, col));
            unsigned short tri[12] = { a, b, mid, b, e, mid, e, d, mid, d, a, mid };
            memcpy(m->indices + *n, tri, sizeof tri);
            *n += 12;
        }
}
/* }}} */

/* {{{ ground_load_tile */
int ground_load_tile(int tx, int ty, double ox, double oy, MapWorld *world, AdtTile **kept, char *why, int why_len)
{
    *kept = NULL;
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
    int pic[256];                                     /* the tile's picture numbers: layers in the array */
    for (int i = 0; i < adt->ntextures && i < 256; ++i) pic[i] = -2;   /* -2: not needed yet */
    GroundTile *g = calloc(1, sizeof *g);
    unsigned char *blend = calloc(1024 * 1024, 4);
    /* each quarter: 64 chunks of 145 points (9,280, within the 16-bit
     * point numbers), 768 triangle corners a chunk at most */
    for (int q = 0; q < 4; ++q) {
        Mesh m = { 0 };
        m.vertexCount = 64 * 145;
        m.vertices   = MemAlloc(sizeof(float) * 3 * m.vertexCount);
        m.normals    = MemAlloc(sizeof(float) * 3 * m.vertexCount);
        m.texcoords  = MemAlloc(sizeof(float) * 2 * m.vertexCount);
        m.texcoords2 = MemAlloc(sizeof(float) * 2 * m.vertexCount);
        m.tangents   = MemAlloc(sizeof(float) * 4 * m.vertexCount);
        m.colors     = MemAlloc(4 * m.vertexCount);
        m.indices    = MemAlloc(sizeof(unsigned short) * 64 * 768);
        int n = 0, made = 0;
        float lo[3] = { 1e30f, 1e30f, 1e30f }, hi[3] = { -1e30f, -1e30f, -1e30f };
        for (int qk = 0; qk < 64; ++qk) {
            /* quarter q holds chunk rows 8 * (q / 2) .. +7 and columns 8 * (q % 2) .. +7 */
            int crow = (q / 2) * 8 + qk / 8, ccol = (q % 2) * 8 + qk % 8, k = crow * 16 + ccol;
            const AdtChunk *c = &adt->chunks[k];
            int lay[4];
            for (int l = 0; l < 4; ++l) {
                int t = c->tex[l < c->nlayers ? l : 0];  /* layers past nlayers repeat layer 0 (their strength is 0) */
                if (t < 0 || t >= adt->ntextures) { snprintf(why, why_len, "%s: chunk %d names picture %d of %d", path, k, t, adt->ntextures); goto fail; }
                if (pic[t] == -2) {
                    pic[t] = picture(adt->textures[t], why, why_len);
                    if (pic[t] < 0) goto fail;            /* `why` says which picture */
                    ++layer_of[pic[t]].refs;
                    g->used[g->nused++] = pic[t];
                }
                lay[l] = pic[t];
            }
            int before = n;
            chunk_points(c, ox, oy, world, &m, qk * 145, &n, ccol, crow, lay);
            if (n > before) made = 1;
            for (int i = 0; i < 145; ++i) for (int d = 0; d < 3; ++d) {
                float v = m.vertices[(qk * 145 + i) * 3 + d];
                if (v < lo[d]) lo[d] = v;
                if (v > hi[d]) hi[d] = v;
            }
            for (int i = 0; i < 4096; ++i) {
                size_t o = ((size_t)(crow * 64 + i / 64) * 1024 + (size_t)(ccol * 64 + i % 64)) * 4;
                blend[o]     = c->nlayers > 1 ? c->alpha[1][i] : 0;
                blend[o + 1] = c->nlayers > 2 ? c->alpha[2][i] : 0;
                blend[o + 2] = c->nlayers > 3 ? c->alpha[3][i] : 0;
                blend[o + 3] = c->shadow[i] ? 0 : 255;    /* 173h: 255 lit, 0 shadowed */
            }
        }
        if (!made) { UnloadMesh(m); continue; }
        m.triangleCount = n / 3;
        UploadMesh(&m, false);
        g->mesh[q] = m;
        g->has[q] = 1;
        g->centre[q] = (Vector3){ (lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2, (lo[2] + hi[2]) / 2 };
        g->radius[q] = Vector3Distance(g->centre[q], (Vector3){ hi[0], hi[1], hi[2] });
        continue;
    fail:
        /* a picture that can't be had: everything this tile took is given back */
        UnloadMesh(m);
        for (int i = 0; i < g->nused; ++i) if (--layer_of[g->used[i]].refs == 0) layer_of[g->used[i]].name[0] = '\0';
        for (int qq = 0; qq < q; ++qq) if (g->has[qq]) UnloadMesh(g->mesh[qq]);
        free(blend); free(g);
        adt_free(adt); free(adt);
        return -1;
    }
    Image im = { .data = blend, .width = 1024, .height = 1024, .mipmaps = 1, .format = PIXELFORMAT_UNCOMPRESSED_R8G8B8A8 };
    g->blend = LoadTextureFromImage(im);
    free(blend);
    SetTextureFilter(g->blend, TEXTURE_FILTER_BILINEAR);
    SetTextureWrap(g->blend, TEXTURE_WRAP_CLAMP);
    /* the array's smaller copies, remade for every layer (the new ones among them) */
    glad_glBindTexture(GL_TEXTURE_2D_ARRAY_, array_id);
    glad_glGenerateMipmap(GL_TEXTURE_2D_ARRAY_);
    glad_glBindTexture(GL_TEXTURE_2D_ARRAY_, 0);
    *kept = adt;
    tiles[tx * 64 + ty] = g;
    return 0;
}
/* }}} */

/* {{{ ground_drop_tile */
void ground_drop_tile(int tx, int ty)
{
    if (tx < 0 || tx > 63 || ty < 0 || ty > 63) return;
    GroundTile *g = tiles[tx * 64 + ty];
    if (!g) return;
    for (int q = 0; q < 4; ++q) if (g->has[q]) UnloadMesh(g->mesh[q]);
    UnloadTexture(g->blend);
    for (int i = 0; i < g->nused; ++i)                  /* a layer no loaded tile uses any more is freed for reuse */
        if (--layer_of[g->used[i]].refs == 0) layer_of[g->used[i]].name[0] = '\0';
    free(g);
    tiles[tx * 64 + ty] = NULL;
}
/* }}} */

/* {{{ ground_blob, ground_draw */
void ground_blob(float x, float y, float z, float radius)
{
    if (nblobs == 8) return;                            /* the eight nearest are enough (the caller adds nearest first) */
    blobs[nblobs][0] = x; blobs[nblobs][1] = y; blobs[nblobs][2] = z; blobs[nblobs][3] = radius;
    ++nblobs;
}
void ground_draw(Vector3 eye, const LightNow *light)
{
    SetShaderValue(shader, loc_eye, &eye, SHADER_UNIFORM_VEC3);
    sky_light_shader(shader, light);
    SetShaderValueV(shader, loc_blobs, blobs, SHADER_UNIFORM_VEC4, 8);
    SetShaderValue(shader, loc_nblobs, &nblobs, SHADER_UNIFORM_INT);
    nblobs = 0;                                         /* blobs are given afresh each frame */
    /* what the camera sees now (we are inside BeginMode3D, the projection set) */
    Sight sight;
    sight_from(&sight, MatrixMultiply(rlGetMatrixModelview(), rlGetMatrixProjection()));
    rlActiveTextureSlot(ARRAY_UNIT);
    glad_glBindTexture(GL_TEXTURE_2D_ARRAY_, array_id);
    for (int t = 0; t < 64 * 64; ++t) {
        GroundTile *g = tiles[t];
        if (!g) continue;
        material.maps[MATERIAL_MAP_ALBEDO].texture = g->blend;
        for (int q = 0; q < 4; ++q) {
            if (!g->has[q] || !sight_ball(&sight, g->centre[q], g->radius[q])) continue;   /* out of sight: not sent */
            DrawMesh(g->mesh[q], material, MatrixIdentity());
            ++ground_orders;
        }
    }
    rlActiveTextureSlot(ARRAY_UNIT);
    glad_glBindTexture(GL_TEXTURE_2D_ARRAY_, 0);
    rlActiveTextureSlot(0);
}
int ground_orders_last(void) { int n = ground_orders; ground_orders = 0; return n; }
/* }}} */
