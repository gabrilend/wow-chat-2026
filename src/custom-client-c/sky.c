/*
 * sky.c (issue 173n) - the sky dome; see sky.h
 *
 * For a general audience: builds the bowl once (rings of points round
 * the camera), recolours its points from the light each frame, and draws
 * it behind everything.
 */
#include "sky.h"

#include "raymath.h"
#include "rlgl.h"

#include <math.h>
#include <string.h>

/* {{{ the rings */
#define SEGMENTS 48
static const float RING_DEG[] = { -30, 0, 6, 15, 35, 90 };
static const int   RING_SKY[] = { 4, 4, 3, 2, 1, 0 };           /* which sky colour each ring takes */
#define RINGS ((int)(sizeof RING_DEG / sizeof RING_DEG[0]))
#define RADIUS 900.0f                                            /* inside the far plane (1600) */
static Mesh     dome;
static Material plain;
/* }}} */

/* {{{ sky_init */
void sky_init(void)
{
    Mesh m = { 0 };
    m.vertexCount = RINGS * (SEGMENTS + 1);
    m.vertices = MemAlloc(sizeof(float) * 3 * m.vertexCount);
    m.colors = MemAlloc(4 * m.vertexCount);
    for (int r = 0; r < RINGS; ++r)
        for (int s = 0; s <= SEGMENTS; ++s) {
            float el = RING_DEG[r] * DEG2RAD, az = (float)s / SEGMENTS * 2 * PI;
            int i = r * (SEGMENTS + 1) + s;
            m.vertices[i * 3]     = cosf(el) * cosf(az) * RADIUS;
            m.vertices[i * 3 + 1] = cosf(el) * sinf(az) * RADIUS;
            m.vertices[i * 3 + 2] = sinf(el) * RADIUS;
            m.colors[i * 4 + 3] = 255;
        }
    m.triangleCount = (RINGS - 1) * SEGMENTS * 2;
    m.indices = MemAlloc(sizeof(unsigned short) * m.triangleCount * 3);
    int n = 0;
    for (int r = 0; r + 1 < RINGS; ++r)
        for (int s = 0; s < SEGMENTS; ++s) {
            unsigned short a = (unsigned short)(r * (SEGMENTS + 1) + s), b = (unsigned short)(a + 1);
            unsigned short c = (unsigned short)(a + SEGMENTS + 1), d = (unsigned short)(c + 1);
            unsigned short tri[6] = { a, b, c, b, d, c };
            memcpy(m.indices + n, tri, sizeof tri);
            n += 6;
        }
    UploadMesh(&m, true);                                    /* colours change through the day */
    dome = m;
    plain = LoadMaterialDefault();                           /* Raylib's own shader: vertex colours, no light */
}
/* }}} */

/* {{{ sky_light_shader */
void sky_light_shader(Shader sh, const LightNow *l)
{
    float range[2] = { l->fog_start, l->fog_end };
    SetShaderValue(sh, GetShaderLocation(sh, "sun_dir"), l->sun_dir, SHADER_UNIFORM_VEC3);
    SetShaderValue(sh, GetShaderLocation(sh, "sun_col"), l->sun, SHADER_UNIFORM_VEC3);
    SetShaderValue(sh, GetShaderLocation(sh, "shade_col"), l->shade, SHADER_UNIFORM_VEC3);
    SetShaderValue(sh, GetShaderLocation(sh, "fog_col"), l->fog, SHADER_UNIFORM_VEC3);
    SetShaderValue(sh, GetShaderLocation(sh, "fog_range"), range, SHADER_UNIFORM_VEC2);
}
/* }}} */

/* {{{ sky_draw */
void sky_draw(Vector3 eye, const LightNow *light)
{
    for (int r = 0; r < RINGS; ++r)
        for (int s = 0; s <= SEGMENTS; ++s) {
            int i = r * (SEGMENTS + 1) + s;
            for (int c = 0; c < 3; ++c) dome.colors[i * 4 + c] = (unsigned char)(fminf(light->sky[RING_SKY[r]][c], 1.0f) * 255);
        }
    UpdateMeshBuffer(dome, 3, dome.colors, 4 * dome.vertexCount, 0);   /* buffer 3: colours */
    rlDisableDepthTest();
    rlDisableDepthMask();
    DrawMesh(dome, plain, MatrixTranslate(eye.x, eye.y, eye.z));
    rlDrawRenderBatchActive();
    rlEnableDepthMask();
    rlEnableDepthTest();
}
/* }}} */
