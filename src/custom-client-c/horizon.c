/*
 * horizon.c (issue 173s) - the far horizon; see horizon.h
 *
 * For a general audience: one coarse mesh per tile, made when first
 * wanted, drawn with a simple shader in the fog's colour.
 */
#include "horizon.h"

#include "raymath.h"
#include "rlgl.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* {{{ the shader: the fog's colour, a little darker on slopes facing away
 * from the sun, so the mountains' shapes read */
static const char *VS =
    "#version 330\n"
    "in vec3 vertexPosition; in vec3 vertexNormal;\n"
    "uniform mat4 mvp;\n"
    "out vec3 n;\n"
    "void main() { n = vertexNormal; gl_Position = mvp * vec4(vertexPosition, 1.0); }\n";
static const char *FS =
    "#version 330\n"
    "in vec3 n; out vec4 frag;\n"
    "uniform vec3 sun_dir, fog_col;\n"
    "void main() { frag = vec4(fog_col * (0.82 + 0.18 * max(dot(normalize(n), sun_dir), 0.0)), 1.0); }\n";
/* }}} */

/* {{{ state */
static int16_t (*heights)[17 * 17];   /* per tile (x * 64 + y): its corner heights, or none */
static uint16_t (*holes)[16];
static unsigned char *have;           /* per tile: 1 when it has heights */
static Mesh   meshes[64 * 64];
static char   made[64 * 64];          /* 0 not yet, 1 made, 2 nothing to draw */
static double ox_, oy_;
static Shader shader;
static Material material;
static int    ready, loc_sun, loc_fog;
/* }}} */

/* {{{ horizon_init */
static uint32_t u32(const unsigned char *s, size_t at) { return s[at] | s[at + 1] << 8 | s[at + 2] << 16 | (uint32_t)s[at + 3] << 24; }
int horizon_init(MpqChain *chain, const char *map_name, double ox, double oy, char *why, int why_len)
{
    ox_ = ox; oy_ = oy;
    char path[200];
    snprintf(path, sizeof path, "World\\Maps\\%s\\%s.wdl", map_name, map_name);
    size_t len;
    const char *from;
    unsigned char *s = mpq_chain_read(chain, path, &len, &from);
    if (!s) { snprintf(why, why_len, "%s is in none of the archives: no far horizon", path); return 1; }
    size_t maof = 0;
    for (size_t at = 0; at + 8 <= len && at + 8 + u32(s, at + 4) <= len; at += 8 + u32(s, at + 4))
        if (!memcmp(s + at, "FOAM", 4)) { maof = at + 8; break; }
    if (!maof || maof + 4096 * 4 > len) { free(s); snprintf(why, why_len, "%s has no tile list (MAOF)", path); return 1; }
    heights = calloc(4096, sizeof *heights);
    holes = calloc(4096, sizeof *holes);
    have = calloc(4096, 1);
    for (int i = 0; i < 4096; ++i) {
        uint32_t o = u32(s, maof + (size_t)i * 4);
        if (!o || (size_t)o + 8 + 1090 > len || memcmp(s + o, "ERAM", 4)) continue;
        for (int k = 0; k < 17 * 17; ++k) heights[i][k] = (int16_t)(s[o + 8 + k * 2] | s[o + 9 + k * 2] << 8);
        size_t h = o + 8 + 1090;
        if (h + 8 + 32 <= len && !memcmp(s + h, "OHAM", 4))
            for (int r = 0; r < 16; ++r) holes[i][r] = (uint16_t)(s[h + 8 + r * 2] | s[h + 9 + r * 2] << 8);
        have[i] = 1;
    }
    free(s);
    shader = LoadShaderFromMemory(VS, FS);
    loc_sun = GetShaderLocation(shader, "sun_dir");
    loc_fog = GetShaderLocation(shader, "fog_col");
    material = LoadMaterialDefault();
    material.shader = shader;
    ready = 1;
    return 0;
}
float horizon_corner(int tx, int ty)
{
    if (!ready || tx < 0 || tx > 63 || ty < 0 || ty > 63 || !have[tx * 64 + ty]) return -100000.0f;
    return heights[tx * 64 + ty][0];
}
/* }}} */

/* {{{ static make: one tile's coarse mesh, its 16 x 16 cells as two
 * triangles each over the corner heights, none over holes */
static void make(int tx, int ty)
{
    int i = tx * 64 + ty;
    if (!have[i]) { made[i] = 2; return; }
    const float step = 533.33333f / 16;
    Mesh m = { 0 };
    m.vertexCount = 17 * 17;
    m.vertices = MemAlloc(sizeof(float) * 3 * m.vertexCount);
    m.normals = MemAlloc(sizeof(float) * 3 * m.vertexCount);
    for (int r = 0; r <= 16; ++r)
        for (int c = 0; c <= 16; ++c) {
            int k = r * 17 + c;
            m.vertices[k * 3] = (float)((32 - tx) * 533.33333 - r * step - ox_);
            m.vertices[k * 3 + 1] = (float)((32 - ty) * 533.33333 - c * step - oy_);
            m.vertices[k * 3 + 2] = heights[i][k];
            float hn = heights[i][(r > 0 ? r - 1 : r) * 17 + c], hs = heights[i][(r < 16 ? r + 1 : r) * 17 + c];
            float hw = heights[i][r * 17 + (c > 0 ? c - 1 : c)], he = heights[i][r * 17 + (c < 16 ? c + 1 : c)];
            Vector3 nv = Vector3Normalize((Vector3){ (hs - hn) / (2 * step), (he - hw) / (2 * step), 1 });
            m.normals[k * 3] = nv.x; m.normals[k * 3 + 1] = nv.y; m.normals[k * 3 + 2] = nv.z;
        }
    m.indices = MemAlloc(sizeof(unsigned short) * 16 * 16 * 6);
    int n = 0;
    for (int r = 0; r < 16; ++r)
        for (int c = 0; c < 16; ++c) {
            if (holes[i][r] & (1 << c)) continue;
            unsigned short a = (unsigned short)(r * 17 + c), b = (unsigned short)(a + 1), d = (unsigned short)(a + 17), e = (unsigned short)(d + 1);
            unsigned short tri[6] = { a, b, e, a, e, d };
            memcpy(m.indices + n, tri, sizeof tri);
            n += 6;
        }
    if (!n) { UnloadMesh(m); made[i] = 2; return; }
    m.triangleCount = n / 3;
    UploadMesh(&m, false);
    meshes[i] = m;
    made[i] = 1;
}
/* }}} */

/* {{{ horizon_draw */
void horizon_draw(int tx, int ty, int (*loaded)(int x, int y), Vector3 eye, const LightNow *light)
{
    (void)eye;
    if (!ready) return;
    SetShaderValue(shader, loc_sun, light->sun_dir, SHADER_UNIFORM_VEC3);
    SetShaderValue(shader, loc_fog, light->fog, SHADER_UNIFORM_VEC3);
    for (int x = tx - HORIZON_REACH; x <= tx + HORIZON_REACH; ++x)
        for (int y = ty - HORIZON_REACH; y <= ty + HORIZON_REACH; ++y) {
            if (x < 0 || x > 63 || y < 0 || y > 63 || loaded(x, y)) continue;
            int i = x * 64 + y;
            if (!made[i]) make(x, y);
            if (made[i] == 1) DrawMesh(meshes[i], material, MatrixIdentity());
        }
}
/* }}} */
