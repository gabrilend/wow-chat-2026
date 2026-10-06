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
#include <stdio.h>
#include <string.h>

/* {{{ the rings */
#define SEGMENTS 48
static const float RING_DEG[] = { -30, 0, 6, 15, 35, 90 };
static const int   RING_SKY[] = { 4, 4, 3, 2, 1, 0 };           /* which sky colour each ring takes */
#define RINGS ((int)(sizeof RING_DEG / sizeof RING_DEG[0]))
#define RADIUS 900.0f                                            /* inside the far plane (1600) */
static Mesh     dome;
static Material plain;
static MpqChain *archives;
static Figure   box;                  /* the skybox now drawn (box.name empty: none) */
static char     box_path[128];        /* which skybox `box` is ("" none) */
static MovesState box_moves;
static float    box_scale;
static double   box_ms;
/* }}} */

/* {{{ sky_init */
void sky_init(MpqChain *chain)
{
    archives = chain;
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
/* the skybox the light names, loaded when it changes; one that can't be
 * read is said once and not drawn */
static void skybox_for(const LightNow *light)
{
    if (!strcmp(light->skybox, box_path)) return;
    if (box_path[0]) figure_free(&box);
    snprintf(box_path, sizeof box_path, "%s", light->skybox);
    if (!box_path[0]) return;
    char why[400];
    if (figure_from_model(&box, archives, box_path, why, sizeof why)) {
        fprintf(stderr, "sky: the skybox %s: %s; none drawn\n", box_path, why);
        memset(&box, 0, sizeof box);
        return;
    }
    /* its size: the model's bounding radius (header 184) to 800 yards */
    float radius = 0;
    for (uint32_t i = 0; i < box.nrest; ++i) {
        float r = sqrtf(box.rest[i].x * box.rest[i].x + box.rest[i].y * box.rest[i].y + box.rest[i].z * box.rest[i].z);
        if (r > radius) radius = r;
    }
    box_scale = radius > 0 ? 800.0f / radius : 1;
    /* a skybox built from pieces that lay two pictures over each other or
     * move their pictures (an aurora: light under a scrolling mask) can't
     * be drawn right yet; drawn with its first picture alone it fills the
     * sky as a solid wall, so it isn't drawn at all (said once) */
    for (int k = 0; k < box.npieces; ++k)
        if (box.pieces[k].layers > 1 || box.pieces[k].moving_uv) {
            fprintf(stderr, "sky: the skybox %s lays pictures over each other or moves them, which isn't drawn yet (173n); it is left out\n", box_path);
            figure_free(&box);
            memset(&box, 0, sizeof box);
            return;
        }
    moves_init(&box_moves, &box.anim);
    printf("sky: the skybox %s\n", box_path);
}

void sky_draw(Vector3 eye, const LightNow *light, float dt)
{
    skybox_for(light);
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
    if (box.npieces) {
        box_ms += dt * 1000.0;
        moves_advance(&box_moves, &box.anim, dt);
        figure_bend(&box, &box_moves, (uint32_t)box_ms);
        Matrix at = MatrixMultiply(MatrixScale(box_scale, box_scale, box_scale), MatrixTranslate(eye.x, eye.y, eye.z));
        for (int k = 0; k < box.npieces; ++k) {
            BeginBlendMode(box.pieces[k].blend >= 3 ? BLEND_ADDITIVE : BLEND_ALPHA);
            float tint[4];
            figure_tint(&box, k, &box_moves, (uint32_t)box_ms, tint);
            plain.maps[MATERIAL_MAP_DIFFUSE].color = (Color){ (unsigned char)(fminf(tint[0], 1) * 255), (unsigned char)(fminf(tint[1], 1) * 255),
                                                             (unsigned char)(fminf(tint[2], 1) * 255), (unsigned char)(fminf(tint[3], 1) * 255) };
            plain.maps[MATERIAL_MAP_DIFFUSE].texture = box.pieces[k].tex;
            DrawMesh(box.pieces[k].mesh, plain, at);
            rlDrawRenderBatchActive();
            EndBlendMode();
        }
        plain.maps[MATERIAL_MAP_DIFFUSE].texture = (Texture2D){ rlGetTextureIdDefault(), 1, 1, 1, 7 };
        plain.maps[MATERIAL_MAP_DIFFUSE].color = WHITE;
    }
    rlEnableDepthMask();
    rlEnableDepthTest();
}
/* }}} */
