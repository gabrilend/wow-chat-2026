/*
 * main.c (issue 173k; the C twin of src/custom-client/main.lua) - the window
 *
 * For a general audience: opens a window on the ground of Ashenvale near
 * Astranaar, read from the server's own map files, with the night elf of
 * the original game's archives standing on it; moves her with the game's
 * own controls at 120% speed (W/S forward and back, A/D turn or, with the
 * right mouse button held, strafe, Q and E strafe, space jump, left drag
 * turns the camera, right drag turns her with it, the wheel zooms; Escape
 * quits until the game menu exists). Written in C on Raylib (owner,
 * 2026-10-05: "let's port now. We should build something like an engine
 * in C anyway, for performance reasons").
 *
 * Usage: custom-client --maps DIR --client DIR [--settings FILE] [--shot FILE] [--zoom N] [--front]
 *   --settings FILE   the player's settings (SET name "value" lines; 173b1);
 *                     without it, every setting is at its default
 *   --shot FILE       draw a few frames, save a picture there, quit
 */
#include "character.h"
#include "maps.h"
#include "mover.h"
#include "mpq.h"
#include "navmesh_slope.h"
#include "settings.h"

#include "raylib.h"
#include "raymath.h"
#include "rlgl.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* {{{ settings */
#define MAP_ID       1                                 /* Kalimdor */
#define START_X      2717.0                            /* Astranaar, Ashenvale */
#define START_Y      (-400.0)
#define START_O      3.6                               /* facing the town's west side */
#define SPEED        1.2                               /* 120% of the base speeds (owner, 2026-10-04) */
#define TILE_REACH   1                                 /* tiles drawn round her own: 3 x 3 */
#define ELF_HEIGHT   2.3f                              /* yards: the camera looks at her shoulders */
#define ZOOM_MIN     2.0f
#define ZOOM_BASE    20.0f                             /* yards; times cameraDistanceMaxFactor (1 to 2) is the zoom-out limit (173b4) */
#define DRAG_RATE    0.006f                            /* radians a pixel at a cameraYawMoveSpeed of 180 */
static const float SKY[3] = { 0.52f, 0.66f, 0.78f };
/* her look: ChrRaces id, sex, and the character-creation choices (from 0);
 * a stand-in for the ids the server will send (173d, 617r5) */
static const CharacterLook LOOK = { 4, 1, 0, 0, 0, 0 };
/* }}} */

/* {{{ shaders
 * Both light by the sun from one direction and fade into the sky with
 * distance. The model's cuts out see-through pixels (hair strands). GLSL
 * 330, with Raylib's own attribute and uniform names. */
static const char *GROUND_VS =
    "#version 330\n"
    "in vec3 vertexPosition; in vec3 vertexNormal; in vec4 vertexColor; in vec2 vertexTexCoord;\n"
    "uniform mat4 mvp; uniform mat4 matModel; uniform vec3 eye;\n"
    "out vec3 n; out vec4 col; out vec2 uv; out float dist;\n"
    "void main() {\n"
    "  vec4 w = matModel * vec4(vertexPosition, 1.0);\n"
    "  n = mat3(matModel) * vertexNormal; col = vertexColor; uv = vertexTexCoord;\n"
    "  dist = length(w.xyz - eye);\n"
    "  gl_Position = mvp * vec4(vertexPosition, 1.0);\n"
    "}\n";
static const char *GROUND_FS =
    "#version 330\n"
    "in vec3 n; in vec4 col; in vec2 uv; in float dist; out vec4 frag; uniform vec3 sky;\n"
    "void main() {\n"
    "  vec3 sun = normalize(vec3(0.45, 0.30, 0.84));\n"
    "  float light = max(dot(normalize(n), sun), 0.0) * 0.75 + 0.30;\n"
    "  float fog = clamp((dist - 120.0) / 520.0, 0.0, 1.0);\n"
    "  frag = vec4(mix(col.rgb * light, sky, fog), 1.0);\n"
    "}\n";
static const char *MODEL_FS =
    "#version 330\n"
    "in vec3 n; in vec4 col; in vec2 uv; in float dist; out vec4 frag; uniform vec3 sky; uniform sampler2D texture0;\n"
    "void main() {\n"
    "  vec4 t = texture(texture0, uv);\n"
    "  if (t.a < 0.5) discard;\n"
    "  vec3 sun = normalize(vec3(0.45, 0.30, 0.84));\n"
    "  float light = max(dot(normalize(n), sun), 0.0) * 0.6 + 0.45;\n"
    "  float fog = clamp((dist - 120.0) / 520.0, 0.0, 1.0);\n"
    "  frag = vec4(mix(t.rgb * light, sky, fog), 1.0);\n"
    "}\n";
/* }}} */

/* {{{ static ground_colour
 * nz: how upward the surface faces (1 level, 0 a wall): forest floor to rock. */
static void ground_colour(float nz, unsigned char *c)
{
    static const float FLOOR[3] = { 0.20f, 0.33f, 0.24f }, ROCK[3] = { 0.38f, 0.36f, 0.33f };
    float t = (0.92f - nz) / 0.25f;
    t = t < 0 ? 0 : (t > 1 ? 1 : t);
    for (int i = 0; i < 3; ++i) c[i] = (unsigned char)((FLOOR[i] + (ROCK[i] - FLOOR[i]) * t) * 255);
    c[3] = 255;
}
/* }}} */

/* {{{ static build_ground
 * One tile as a mesh: 129 x 129 corners and 128 x 128 centres as points,
 * the server's four triangles per cell, none over holes; positions
 * relative to the origin so single-precision floats stay exact. */
static int build_ground(const MapTile *t, double ox, double oy, Mesh *out)
{
    if (t->is_flat) return 0;
    const int corners = 129 * 129, count = corners + 128 * 128;
    const float step = MAPS_GRID_SIZE / MAPS_RESOLUTION;
    Mesh m = { 0 };
    m.vertexCount = count;
    m.vertices = MemAlloc(sizeof(float) * 3 * count);
    m.normals  = MemAlloc(sizeof(float) * 3 * count);
    m.colors   = MemAlloc(4 * count);
    #define H9(ix, iy) t->v9[((ix) < 0 ? 0 : (ix) > 128 ? 128 : (ix)) * 129 + ((iy) < 0 ? 0 : (iy) > 128 ? 128 : (iy))]
    for (int ix = 0; ix <= 128; ++ix)
        for (int iy = 0; iy <= 128; ++iy) {
            int i = ix * 129 + iy;
            float wx, wy;
            maps_corner_position(t->tx, t->ty, (float)ix, (float)iy, &wx, &wy);
            m.vertices[i * 3] = (float)(wx - ox); m.vertices[i * 3 + 1] = (float)(wy - oy); m.vertices[i * 3 + 2] = t->v9[i];
            /* world x falls as ix rises, so the x slope is (back - ahead) */
            float sx = (H9(ix - 1, iy) - H9(ix + 1, iy)) / (2 * step);
            float sy = (H9(ix, iy - 1) - H9(ix, iy + 1)) / (2 * step);
            Vector3 nv = Vector3Normalize((Vector3){ -sx, -sy, 1 });
            m.normals[i * 3] = nv.x; m.normals[i * 3 + 1] = nv.y; m.normals[i * 3 + 2] = nv.z;
            ground_colour(nv.z, m.colors + i * 4);
        }
    #undef H9
    for (int ix = 0; ix < 128; ++ix)
        for (int iy = 0; iy < 128; ++iy) {
            int i = corners + ix * 128 + iy;
            float wx, wy;
            maps_corner_position(t->tx, t->ty, ix + 0.5f, iy + 0.5f, &wx, &wy);
            m.vertices[i * 3] = (float)(wx - ox); m.vertices[i * 3 + 1] = (float)(wy - oy); m.vertices[i * 3 + 2] = t->v8[ix * 128 + iy];
            int c[4] = { ix * 129 + iy, (ix + 1) * 129 + iy, ix * 129 + iy + 1, (ix + 1) * 129 + iy + 1 };
            Vector3 nv = { 0 };
            for (int k = 0; k < 4; ++k) nv = Vector3Add(nv, (Vector3){ m.normals[c[k] * 3], m.normals[c[k] * 3 + 1], m.normals[c[k] * 3 + 2] });
            nv = Vector3Normalize(nv);
            m.normals[i * 3] = nv.x; m.normals[i * 3 + 1] = nv.y; m.normals[i * 3 + 2] = nv.z;
            ground_colour(nv.z, m.colors + i * 4);
        }
    /* triangles: per cell the server's four (h1 h2 h5, h1 h5 h3, h2 h4 h5, h3 h5 h4) */
    m.indices = MemAlloc(sizeof(unsigned short) * 128 * 128 * 12);
    int n = 0;
    for (int ix = 0; ix < 128; ++ix)
        for (int iy = 0; iy < 128; ++iy) {
            if (maps_is_hole(t, ix, iy)) continue;
            unsigned short h1 = ix * 129 + iy, h2 = (ix + 1) * 129 + iy, h3 = ix * 129 + iy + 1, h4 = (ix + 1) * 129 + iy + 1;
            unsigned short h5 = corners + ix * 128 + iy;
            unsigned short tri[12] = { h1, h2, h5, h1, h5, h3, h2, h4, h5, h3, h5, h4 };
            memcpy(m.indices + n, tri, sizeof tri);
            n += 12;
        }
    m.triangleCount = n / 3;
    UploadMesh(&m, false);
    *out = m;
    return 1;
}
/* }}} */

/* {{{ her model: one mesh per shown piece, each with its picture */
typedef struct { Mesh mesh; int texture; } Piece;
static Piece pieces[64];
static int npieces;
static Texture2D tex_skin, tex_hair;

static Texture2D texture_of(const BlpImage *img)
{
    Image im = { .data = img->rgba, .width = img->width, .height = img->height, .mipmaps = 1,
                 .format = PIXELFORMAT_UNCOMPRESSED_R8G8B8A8 };
    Texture2D t = LoadTextureFromImage(im);
    GenTextureMipmaps(&t);
    SetTextureFilter(t, TEXTURE_FILTER_TRILINEAR);
    SetTextureWrap(t, TEXTURE_WRAP_REPEAT);
    return t;
}
static int build_elf(const char *client, char *why, int why_len)
{
    MpqChain chain;
    if (mpq_chain_open(&chain, client, "enUS", why, why_len)) return -1;
    Character ch;
    if (character_build(&chain, &LOOK, &ch, why, why_len)) { mpq_chain_close(&chain); return -1; }
    mpq_chain_close(&chain);
    tex_skin = texture_of(&ch.skin);
    if (ch.hair.width) tex_hair = texture_of(&ch.hair);
    for (uint32_t u = 0; u < ch.model.nunits && npieces < 64; ++u) {
        M2Unit un = ch.model.units[u];
        if (un.piece >= ch.model.npieces || !ch.shown[un.piece] || un.texture >= ch.model.ntextures) continue;
        uint32_t kind = ch.model.textures[un.texture].kind;
        if (kind != 1 && !(kind == 6 && ch.hair.width)) continue;
        M2Piece p = ch.model.pieces[un.piece];
        Mesh m = { 0 };
        m.vertexCount = (int)p.count;
        m.triangleCount = (int)p.count / 3;
        m.vertices  = MemAlloc(sizeof(float) * 3 * p.count);
        m.normals   = MemAlloc(sizeof(float) * 3 * p.count);
        m.texcoords = MemAlloc(sizeof(float) * 2 * p.count);
        for (uint32_t i = 0; i < p.count; ++i) {
            M2Vertex v = ch.model.vertices[ch.model.indices[p.first + i]];
            m.vertices[i * 3] = v.x; m.vertices[i * 3 + 1] = v.y; m.vertices[i * 3 + 2] = v.z;
            m.normals[i * 3] = v.nx; m.normals[i * 3 + 1] = v.ny; m.normals[i * 3 + 2] = v.nz;
            m.texcoords[i * 2] = v.u; m.texcoords[i * 2 + 1] = v.v;
        }
        UploadMesh(&m, false);
        pieces[npieces].mesh = m;
        pieces[npieces].texture = (int)kind;
        ++npieces;
    }
    character_free(&ch);
    if (npieces == 0) { snprintf(why, why_len, "her model has nothing to draw: no shown piece has a picture"); return -1; }
    return 0;
}
/* }}} */

/* {{{ the world and the camera */
static MapWorld world;
static Mesh   tile_mesh[64 * 64];
static char   tile_state[64 * 64];                      /* 0 not tried, 1 mesh, 2 none */
static double ox, oy;                                    /* the drawing origin, near the start */
static Mover  elf;
static float  cam_yaw = (float)START_O, cam_pitch = 0.35f, cam_dist = 12.0f;
static int    cam_held;                                  /* --front: the camera keeps its own heading */

static float ground_at(void *ctx, float x, float y, float *gx, float *gy) { return maps_world_height((MapWorld *)ctx, x, y, gx, gy); }

static void refresh_tiles(void)
{
    int tx, ty;
    maps_tile_of((float)elf.x, (float)elf.y, &tx, &ty);
    for (int dx = -TILE_REACH; dx <= TILE_REACH; ++dx)
        for (int dy = -TILE_REACH; dy <= TILE_REACH; ++dy) {
            int x = tx + dx, y = ty + dy;
            if (x < 0 || x >= 64 || y < 0 || y >= 64 || tile_state[x * 64 + y]) continue;
            MapTile *t = maps_world_tile(&world, x, y);
            tile_state[x * 64 + y] = (t && build_ground(t, ox, oy, &tile_mesh[x * 64 + y])) ? 1 : 2;
        }
}
/* }}} */

/* {{{ main */
int main(int argc, char **argv)
{
    const char *maps = NULL, *client = NULL, *shot = NULL, *settings_file = NULL;
    for (int i = 1; i < argc; ++i) {
        if (!strcmp(argv[i], "--maps") && i + 1 < argc) maps = argv[++i];
        else if (!strcmp(argv[i], "--settings") && i + 1 < argc) settings_file = argv[++i];
        else if (!strcmp(argv[i], "--client") && i + 1 < argc) client = argv[++i];
        else if (!strcmp(argv[i], "--shot") && i + 1 < argc) shot = argv[++i];
        else if (!strcmp(argv[i], "--zoom") && i + 1 < argc) cam_dist = (float)atof(argv[++i]);
        else if (!strcmp(argv[i], "--front")) { cam_yaw = (float)(START_O + PI); cam_pitch = 0.1f; cam_held = 1; }
    }
    if (!maps || !client) { fprintf(stderr, "usage: custom-client --maps DIR --client DIR [--settings FILE] [--shot FILE] [--zoom N] [--front]\n"); return 2; }

    /* the settings: defaults, then the player's file; a line it refuses is
     * named on the terminal and skipped (173b1) */
    settings_init();
    if (settings_file) settings_load(settings_file, stderr);
    else fprintf(stderr, "settings: no --settings file given; every setting is at its default\n");
    int win_w, win_h;
    settings_resolution(settings_text("gxResolution"), &win_w, &win_h);   /* accepted when set, so always a resolution */

    char why[900];
    maps_world_init(&world, maps, MAP_ID);
    float gx, gy;
    float z = maps_world_height(&world, (float)START_X, (float)START_Y, &gx, &gy);
    if (z < -10000) { fprintf(stderr, "no ground at the start (%.1f, %.1f) in map %d from %s: is the maps folder right?\n", START_X, START_Y, MAP_ID, maps); return 1; }
    /* the steepest walkable ground, from the server's navigation tiles
     * (data-files/mmaps beside data-files/maps) */
    char mmaps[600];
    snprintf(mmaps, sizeof mmaps, "%s", maps);
    char *cut = strstr(mmaps, "/maps");
    if (!cut) { fprintf(stderr, "the maps folder %s doesn't end in /maps; can't find mmaps beside it\n", maps); return 1; }
    strcpy(cut, "/mmaps");
    float max_slope = navmesh_slope_read(mmaps, MAP_ID, why, sizeof why);
    if (max_slope < 0) { fprintf(stderr, "%s\n", why); return 1; }
    mover_init(&elf, START_X, START_Y, z, START_O, SPEED, max_slope);
    ox = floor(START_X); oy = floor(START_Y);

    SetConfigFlags(FLAG_WINDOW_RESIZABLE | FLAG_VSYNC_HINT);
    InitWindow(win_w, win_h, "Everland Ghostsong");
    SetExitKey(KEY_NULL);                                /* Escape is read in the loop, so it can open the game menu later */
    Shader ground_sh = LoadShaderFromMemory(GROUND_VS, GROUND_FS);
    Shader model_sh  = LoadShaderFromMemory(GROUND_VS, MODEL_FS);
    if (build_elf(client, why, sizeof why)) { fprintf(stderr, "%s\n", why); CloseWindow(); return 1; }
    Material ground_mat = LoadMaterialDefault(); ground_mat.shader = ground_sh;
    Material skin_mat = LoadMaterialDefault(); skin_mat.shader = model_sh; skin_mat.maps[MATERIAL_MAP_DIFFUSE].texture = tex_skin;
    Material hair_mat = LoadMaterialDefault(); hair_mat.shader = model_sh; hair_mat.maps[MATERIAL_MAP_DIFFUSE].texture = tex_hair;
    int eye_g = GetShaderLocation(ground_sh, "eye"), sky_g = GetShaderLocation(ground_sh, "sky");
    int eye_m = GetShaderLocation(model_sh, "eye"),  sky_m = GetShaderLocation(model_sh, "sky");
    SetShaderValue(ground_sh, sky_g, SKY, SHADER_UNIFORM_VEC3);
    SetShaderValue(model_sh, sky_m, SKY, SHADER_UNIFORM_VEC3);
    refresh_tiles();

    int frames = 0, drag_l = 0, drag_r = 0;
    while (!WindowShouldClose()) {
        /* {{{ input and movement */
        float dt = GetFrameTime();
        if (dt > 0.1f) dt = 0.1f;                        /* a stalled frame doesn't fling her */
        if (IsKeyPressed(KEY_ESCAPE)) break;            /* the owner, 2026-10-06: Escape quits until there are menus (173b2) */
        drag_l = IsMouseButtonDown(MOUSE_BUTTON_LEFT);
        int was_r = drag_r;
        drag_r = IsMouseButtonDown(MOUSE_BUTTON_RIGHT);
        if (drag_r && !was_r) cam_yaw = (float)elf.o;
        if (drag_l || drag_r) {
            Vector2 d = GetMouseDelta();
            float rate = DRAG_RATE * (float)settings_num("cameraYawMoveSpeed") / 180.0f;
            cam_yaw -= d.x * rate;
            cam_pitch += d.y * rate;
            if (cam_pitch < -0.4f) cam_pitch = -0.4f;
            if (cam_pitch > 1.45f) cam_pitch = 1.45f;
            if (drag_r) elf.o = fmod(fmod(cam_yaw, 2 * PI) + 2 * PI, 2 * PI);   /* the right button turns her with the camera */
        }
        float wheel = GetMouseWheelMove();
        float zoom_max = ZOOM_BASE * (float)settings_num("cameraDistanceMaxFactor");
        if (wheel != 0) cam_dist *= wheel > 0 ? 0.85f : 1.18f;
        cam_dist = Clamp(cam_dist, ZOOM_MIN, zoom_max);   /* every frame, so a lowered limit pulls the camera in at once */
        MoverInput in = {
            .forward = IsKeyDown(KEY_W) || IsKeyDown(KEY_UP) || (drag_l && drag_r),
            .back = IsKeyDown(KEY_S) || IsKeyDown(KEY_DOWN),
            .left = IsKeyDown(KEY_A) || IsKeyDown(KEY_LEFT),
            .right = IsKeyDown(KEY_D) || IsKeyDown(KEY_RIGHT),
            .strafe_left = IsKeyDown(KEY_Q),
            .strafe_right = IsKeyDown(KEY_E),
            .strafe_turns = drag_r,
            .jump = IsKeyDown(KEY_SPACE),
        };
        double before = elf.o;
        mover_step(&elf, &in, dt, ground_at, &world);
        if (!drag_l && !cam_held) cam_yaw += (float)(elf.o - before);   /* the camera follows her turns */
        refresh_tiles();
        SetWindowTitle(TextFormat("Everland Ghostsong  -  Ashenvale  x %.1f  y %.1f  z %.1f", elf.x, elf.y, elf.z));
        /* }}} */

        /* {{{ the camera: behind her by its own heading, raised by its pitch */
        Vector3 at = { (float)(elf.x - ox), (float)(elf.y - oy), (float)elf.z + ELF_HEIGHT * 0.85f };
        Vector3 eye = { at.x - cosf(cam_yaw) * cosf(cam_pitch) * cam_dist,
                        at.y - sinf(cam_yaw) * cosf(cam_pitch) * cam_dist,
                        at.z + sinf(cam_pitch) * cam_dist };
        float floor_z = maps_world_height(&world, eye.x + (float)ox, eye.y + (float)oy, &gx, &gy);
        if (floor_z > -10000 && eye.z < floor_z + 0.6f) eye.z = floor_z + 0.6f;   /* never under the ground */
        Camera3D cam = { .position = eye, .target = at, .up = { 0, 0, 1 }, .fovy = 60, .projection = CAMERA_PERSPECTIVE };
        SetShaderValue(ground_sh, eye_g, &eye, SHADER_UNIFORM_VEC3);
        SetShaderValue(model_sh, eye_m, &eye, SHADER_UNIFORM_VEC3);
        /* }}} */

        BeginDrawing();
        ClearBackground((Color){ (unsigned char)(SKY[0] * 255), (unsigned char)(SKY[1] * 255), (unsigned char)(SKY[2] * 255), 255 });
        BeginMode3D(cam);
        /* the Lua client's projection: 60 degrees, near 0.3, far 1600 yards
         * (Raylib's own far plane is 1000; this Raylib has no setter, so the
         * projection is loaded directly) */
        rlMatrixMode(RL_PROJECTION);
        rlLoadIdentity();
        rlMultMatrixf(MatrixToFloat(MatrixPerspective(60 * DEG2RAD, (double)GetScreenWidth() / GetScreenHeight(), 0.3, 1600)));
        rlMatrixMode(RL_MODELVIEW);
        rlDisableBackfaceCulling();
        for (int i = 0; i < 64 * 64; ++i) if (tile_state[i] == 1) DrawMesh(tile_mesh[i], ground_mat, MatrixIdentity());
        Matrix place = MatrixMultiply(MatrixRotateZ((float)elf.o), MatrixTranslate(at.x, at.y, (float)elf.z));
        for (int i = 0; i < npieces; ++i) DrawMesh(pieces[i].mesh, pieces[i].texture == 6 ? hair_mat : skin_mat, place);
        EndMode3D();
        EndDrawing();

        /* --shot: after a few frames, the picture, then quit */
        if (shot && ++frames == 5) {
            Image im = LoadImageFromScreen();
            int ok = ExportImage(im, shot);
            UnloadImage(im);
            printf(ok ? "picture saved: %s\n" : "could not save the picture to %s\n", shot);
            break;
        }
    }
    CloseWindow();
    maps_world_free(&world);
    return 0;
}
/* }}} */
