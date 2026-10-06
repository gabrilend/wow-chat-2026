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
 * Usage: custom-client --maps DIR --client DIR [--settings FILE] [--shot FILE] [--zoom N] [--front] [--turn DEG] [--pitch DEG]
 *   --settings FILE   the player's settings (SET name "value" lines; 173b1);
 *                     without it, every setting is at its default
 *   --shot FILE       draw a few frames, save a picture there, quit
 *   --zoom N          (pictures) the camera N yards back
 *   --turn DEG        (pictures) the camera turned DEG degrees round her, held there
 *   --pitch DEG       (pictures) the camera raised DEG degrees (up to 83)
 *   --pose ID MS      (pictures) hold her in animation ID (AnimationData.dbc:
 *                     0 stand, 5 run, 13 walk backwards, 38 jump ...) at MS
 */
#include "anim.h"
#include "camera.h"
#include "character.h"
#include "doodads.h"
#include "ground.h"
#include "maps.h"
#include "mover.h"
#include "moves.h"
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
#define MAP_NAME     "Kalimdor"                        /* its folder in the archives (World\\Maps\\Kalimdor) */
#define START_X      2717.0                            /* Astranaar, Ashenvale */
#define START_Y      (-400.0)
#define START_O      3.6                               /* facing the town's west side */
#define SPEED        1.2                               /* 120% of the base speeds (owner, 2026-10-04) */
#define TILE_REACH   1                                 /* tiles drawn round her own: 3 x 3 */
#define ELF_HEIGHT   2.3f                              /* yards: the camera looks at her shoulders */
#define ZOOM_MIN     2.0f
#define ZOOM_BASE    20.0f                             /* yards; times cameraDistanceMaxFactor (1 to 2) is the zoom-out limit (173b4) */
static const float SKY[3] = { 0.52f, 0.66f, 0.78f };
/* her look: ChrRaces id, sex, and the character-creation choices (from 0);
 * a stand-in for the ids the server will send (173d, 617r5) */
static const CharacterLook LOOK = { 4, 1, 0, 0, 0, 0 };
/* }}} */

/* {{{ shaders
 * Her model's: lit by the sun from one direction, faded into the sky with
 * distance, see-through pixels (hair strands) cut out. GLSL 330, with
 * Raylib's own attribute and uniform names. The ground has its own, in
 * ground.c. */
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

/* {{{ her model: one mesh per shown piece, each with its picture
 * Each piece's mesh lists its own copy of every corner (three a triangle);
 * point_of says which model point each copy is, so the bent model
 * (anim.c) can be copied in each frame. rest[] keeps the model's points
 * and facings as made, the bending's starting place. */
typedef struct { Mesh mesh; int texture; uint32_t *point_of; } Piece;
static Piece pieces[64];
static int npieces;
static Texture2D tex_skin, tex_hair;
static M2Vertex *rest;  static uint32_t nrest;
static char      elf_base[200];                          /* her model's archive path, for its animations */

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
static int build_elf(MpqChain *chain, char *why, int why_len)
{
    Character ch;
    if (character_build(chain, &LOOK, &ch, why, why_len)) return -1;
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
        pieces[npieces].point_of = malloc(sizeof(uint32_t) * p.count);
        for (uint32_t i = 0; i < p.count; ++i) pieces[npieces].point_of[i] = ch.model.indices[p.first + i];
        UploadMesh(&m, true);                            /* dynamic: bent every frame */
        pieces[npieces].mesh = m;
        pieces[npieces].texture = (int)kind;
        ++npieces;
    }
    nrest = ch.model.nvertices;
    rest = malloc(sizeof *rest * nrest);
    memcpy(rest, ch.model.vertices, sizeof *rest * nrest);
    snprintf(elf_base, sizeof elf_base, "%s", ch.base);
    character_free(&ch);
    if (npieces == 0) { snprintf(why, why_len, "her model has nothing to draw: no shown piece has a picture"); return -1; }
    return 0;
}
/* }}} */

/* {{{ the world and the camera */
static MapWorld world;
static MpqChain chain;                                   /* the original client's archives, open for the whole run */
static char   tile_state[64 * 64];                      /* 0 not tried, 1 painted, 2 no ground file (open sea) */
static double ox, oy;                                    /* the drawing origin, near the start */
static Mover  elf;
static FollowCam view = { .yaw = (float)START_O, .pitch = 0.35f, .dist = 12.0f, .rest_pitch = 0.35f };   /* camera.h */
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
            char why[600];
            AdtTile *adt;
            int got = ground_load_tile(x, y, ox, oy, &world, &adt, why, sizeof why);
            if (got < 0) { fprintf(stderr, "painting tile (%d, %d): %s\n", x, y, why); exit(1); }
            if (got == 0) {
                if (doodads_add_tile(adt, ox, oy, why, sizeof why)) { fprintf(stderr, "doodads on tile (%d, %d): %s\n", x, y, why); exit(1); }
                adt_free(adt);
                free(adt);
            }
            tile_state[x * 64 + y] = got == 0 ? 1 : 2;
        }
}
/* }}} */

/* {{{ main */
int main(int argc, char **argv)
{
    const char *maps = NULL, *client = NULL, *shot = NULL, *settings_file = NULL;
    int pose_id = -1;                                    /* --pose: hold her in this animation */
    float pose_ms = 0;
    for (int i = 1; i < argc; ++i) {
        if (!strcmp(argv[i], "--maps") && i + 1 < argc) maps = argv[++i];
        else if (!strcmp(argv[i], "--settings") && i + 1 < argc) settings_file = argv[++i];
        else if (!strcmp(argv[i], "--client") && i + 1 < argc) client = argv[++i];
        else if (!strcmp(argv[i], "--shot") && i + 1 < argc) shot = argv[++i];
        else if (!strcmp(argv[i], "--zoom") && i + 1 < argc) view.dist = (float)atof(argv[++i]);
        else if (!strcmp(argv[i], "--front")) { view.yaw = (float)(START_O + PI); view.pitch = 0.1f; cam_held = 1; }
        else if (!strcmp(argv[i], "--turn") && i + 1 < argc) { view.yaw = (float)(START_O + atof(argv[++i]) * DEG2RAD); cam_held = 1; }
        else if (!strcmp(argv[i], "--pitch") && i + 1 < argc) view.pitch = (float)(atof(argv[++i]) * DEG2RAD);
        else if (!strcmp(argv[i], "--pose") && i + 2 < argc) { pose_id = atoi(argv[++i]); pose_ms = (float)atof(argv[++i]); }
    }
    if (!maps || !client) { fprintf(stderr, "usage: custom-client --maps DIR --client DIR [--settings FILE] [--shot FILE] [--zoom N] [--front] [--turn DEG] [--pitch DEG] [--pose ID MS]\n"); return 2; }

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
    Shader model_sh  = LoadShaderFromMemory(GROUND_VS, MODEL_FS);
    if (mpq_chain_open(&chain, client, "enUS", why, sizeof why)) { fprintf(stderr, "%s\n", why); CloseWindow(); return 1; }
    if (build_elf(&chain, why, sizeof why)) { fprintf(stderr, "%s\n", why); CloseWindow(); return 1; }
    if (ground_init(&chain, MAP_NAME, why, sizeof why)) { fprintf(stderr, "%s\n", why); CloseWindow(); return 1; }
    if (doodads_init(&chain, why, sizeof why)) { fprintf(stderr, "%s\n", why); CloseWindow(); return 1; }
    Material skin_mat = LoadMaterialDefault(); skin_mat.shader = model_sh; skin_mat.maps[MATERIAL_MAP_DIFFUSE].texture = tex_skin;
    Material hair_mat = LoadMaterialDefault(); hair_mat.shader = model_sh; hair_mat.maps[MATERIAL_MAP_DIFFUSE].texture = tex_hair;
    int eye_m = GetShaderLocation(model_sh, "eye"),  sky_m = GetShaderLocation(model_sh, "sky");
    SetShaderValue(model_sh, sky_m, SKY, SHADER_UNIFORM_VEC3);
    refresh_tiles();
    int dm, dc, ds;
    doodads_counts(&dm, &dc, &ds);
    printf("doodads: %d models, %d placed\n", dm, dc);
    if (ds) printf("doodads: %d pieces left out: their picture is chosen by the game at run time (not built yet)\n", ds);

    /* her animations (173i): the skeleton from her model file, and any
     * animation kept in a .anim file beside it */
    Anim anim;
    {
        char path[300];
        size_t len;
        const char *from;
        snprintf(path, sizeof path, "%s.m2", elf_base);
        unsigned char *m2 = mpq_chain_read(&chain, path, &len, &from);
        if (!m2 || anim_read(m2, len, &anim, why, sizeof why)) { fprintf(stderr, "her animations (%s): %s\n", path, m2 ? why : "not in the archives"); CloseWindow(); return 1; }
        free(m2);
        for (int i = 0; i < anim.nseqs; ++i) {
            if (!anim_needs_file(&anim, i)) continue;
            snprintf(path, sizeof path, "%s%04d-%02d.anim", elf_base, anim.seqs[i].id, anim.seqs[i].variation);
            unsigned char *f = mpq_chain_read(&chain, path, &len, &from);
            if (!f) { fprintf(stderr, "her animations: %s is in none of the archives; that animation leaves her at rest\n", path); continue; }
            anim_attach_file(&anim, i, f, len);
        }
        if (anim.npoints != nrest) { fprintf(stderr, "her animations: the skeleton's model has %u points, her mesh %u\n", anim.npoints, nrest); CloseWindow(); return 1; }
        static const int NEEDED[] = { MOVE_STAND, MOVE_RUN, MOVE_WALK_BACK, MOVE_SHUFFLE_LEFT, MOVE_SHUFFLE_RIGHT, MOVE_JUMP_START, MOVE_JUMP, MOVE_JUMP_END, MOVE_FALL };
        for (unsigned i = 0; i < sizeof NEEDED / sizeof NEEDED[0]; ++i)
            if (anim_find(&anim, NEEDED[i], 0) < 0) fprintf(stderr, "her animations: her model has no animation %d; she stands instead\n", NEEDED[i]);
    }
    MovesState moves;
    moves_init(&moves, &anim);
    float (*poses)[16] = malloc(sizeof *poses * anim.nbones), (*scratch)[16] = malloc(sizeof *scratch * anim.nbones);
    float *bent = malloc(sizeof(float) * 6 * nrest);       /* each point's bent position, then facing */
    double clock_ms = 0;

    int frames = 0, drag_l = 0, drag_r = 0;
    while (!WindowShouldClose()) {
        /* {{{ input and movement */
        float dt = GetFrameTime();
        if (dt > 0.1f) dt = 0.1f;                        /* a stalled frame doesn't fling her */
        if (IsKeyPressed(KEY_ESCAPE)) break;            /* the owner, 2026-10-06: Escape quits until there are menus (173b2) */
        /* the mouse: left drag looks around her, right drag turns her too (camera.c) */
        int was_r = drag_r;
        drag_l = IsMouseButtonDown(MOUSE_BUTTON_LEFT);
        drag_r = IsMouseButtonDown(MOUSE_BUTTON_RIGHT);
        Vector2 d = GetMouseDelta();
        FollowCamInput mouse = { .left = drag_l, .right = drag_r, .dx = d.x, .dy = d.y, .dt = dt };
        camera_drag(&view, &mouse, was_r, &elf.o);
        float wheel = GetMouseWheelMove();
        float zoom_max = ZOOM_BASE * (float)settings_num("cameraDistanceMaxFactor");
        if (wheel != 0) view.dist *= wheel > 0 ? 0.85f : 1.18f;
        view.dist = Clamp(view.dist, ZOOM_MIN, zoom_max);   /* every frame, so a lowered limit pulls the camera in at once */
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
        double before_o = elf.o, before_x = elf.x, before_y = elf.y;
        mover_step(&elf, &in, dt, ground_at, &world);
        /* moving = she moved along the ground this frame, by any cause
         * (keys, both buttons, sliding); turning in place isn't moving */
        int moving = hypot(elf.x - before_x, elf.y - before_y) > 1e-4;
        if (!cam_held) camera_follow(&view, &mouse, camera_turn_between((float)before_o, (float)elf.o), moving, elf.o);

        /* her animation: chosen from what she did this frame, then her
         * points bent by the bones and copied into each piece's mesh */
        int turning = !drag_r && (in.left || in.right);
        MovesInput mi = {
            .forward = in.forward, .back = in.back,
            .strafe_left = in.strafe_left || (drag_r && in.left), .strafe_right = in.strafe_right || (drag_r && in.right),
            .turn_left = turning && in.left, .turn_right = turning && in.right,
            .grounded = elf.grounded, .rising = elf.vz > 0,
            .speed = dt > 0 ? (float)(hypot(elf.x - before_x, elf.y - before_y) / dt) : 0, .dt = dt,
        };
        moves_step(&moves, &anim, &mi);
        if (pose_id >= 0) {
            int seq = anim_find(&anim, pose_id, 0);
            if (seq < 0) { fprintf(stderr, "--pose %d: her model has no such animation\n", pose_id); break; }
            moves.seq = seq; moves.ms = pose_ms; moves.from = -1; moves.once = 0;
        }
        clock_ms += dt * 1000.0;
        moves_pose(&moves, &anim, (uint32_t)clock_ms, poses, scratch);
        for (uint32_t i = 0; i < nrest; ++i) {
            float p[3] = { rest[i].x, rest[i].y, rest[i].z }, n[3] = { rest[i].nx, rest[i].ny, rest[i].nz };
            anim_skin_point(&anim, (const float (*)[16])poses, i, p, bent + i * 6, n, bent + i * 6 + 3);
        }
        for (int k = 0; k < npieces; ++k) {
            Mesh *m = &pieces[k].mesh;
            for (int v = 0; v < m->vertexCount; ++v) {
                const float *b = bent + pieces[k].point_of[v] * 6;
                memcpy(m->vertices + v * 3, b, sizeof(float) * 3);
                memcpy(m->normals + v * 3, b + 3, sizeof(float) * 3);
            }
            UpdateMeshBuffer(*m, 0, m->vertices, (int)(sizeof(float) * 3 * m->vertexCount), 0);   /* buffer 0: positions */
            UpdateMeshBuffer(*m, 2, m->normals, (int)(sizeof(float) * 3 * m->vertexCount), 0);    /* buffer 2: facings */
        }
        refresh_tiles();
        SetWindowTitle(TextFormat("Everland Ghostsong  -  Ashenvale  x %.1f  y %.1f  z %.1f", elf.x, elf.y, elf.z));
        /* }}} */

        /* {{{ the camera: behind her by its own heading, raised by its pitch */
        Vector3 at = { (float)(elf.x - ox), (float)(elf.y - oy), (float)elf.z + ELF_HEIGHT * 0.85f };
        Vector3 eye = { at.x - cosf(view.yaw) * cosf(view.pitch) * view.dist,
                        at.y - sinf(view.yaw) * cosf(view.pitch) * view.dist,
                        at.z + sinf(view.pitch) * view.dist };
        float floor_z = maps_world_height(&world, eye.x + (float)ox, eye.y + (float)oy, &gx, &gy);
        if (floor_z > -10000 && eye.z < floor_z + 0.6f) eye.z = floor_z + 0.6f;   /* never under the ground */
        Camera3D cam = { .position = eye, .target = at, .up = { 0, 0, 1 }, .fovy = 60, .projection = CAMERA_PERSPECTIVE };
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
        ground_blob(at.x, at.y, (float)elf.z, 1.3f);     /* her shadow, a little wider than her shoulders */
        ground_draw(eye, SKY);
        doodads_draw(eye, SKY);
        Matrix place = MatrixMultiply(MatrixRotateZ((float)elf.o + moves.body_turn), MatrixTranslate(at.x, at.y, (float)elf.z));
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
    anim_free(&anim);
    free(poses); free(scratch); free(bent);
    mpq_chain_close(&chain);
    maps_world_free(&world);
    return 0;
}
/* }}} */
