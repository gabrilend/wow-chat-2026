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
 *   --clock MS        (pictures) start the world's animations MS milliseconds in
 *   --hour H          the time of day, 0 to 24 (default: this machine's clock)
 *   --face DEG        her start facing turned DEG degrees (left)
 *   --walk S          (pictures) hold forward for S world-seconds
 *   --pose ID MS      (pictures) hold her in animation ID (AnimationData.dbc:
 *                     0 stand, 5 run, 13 walk backwards, 38 jump ...) at MS
 */
#include "anim.h"
#include "camera.h"
#include "character.h"
#include "collide.h"
#include "doodads.h"
#include "figure.h"
#include "ground.h"
#include "light.h"
#include "maps.h"
#include "mover.h"
#include "moves.h"
#include "mpq.h"
#include "navmesh_slope.h"
#include "settings.h"
#include "sky.h"

#include "raylib.h"
#include "raymath.h"
#include "rlgl.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

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
    "in vec3 n; in vec4 col; in vec2 uv; in float dist; out vec4 frag; uniform sampler2D texture0;\n"
    "uniform vec3 sun_dir, sun_col, shade_col, fog_col; uniform vec2 fog_range;\n"
    "void main() {\n"
    "  vec4 t = texture(texture0, uv);\n"
    "  if (t.a < 0.5) discard;\n"
    "  vec3 light = shade_col + sun_col * max(dot(normalize(n), sun_dir), 0.0);\n"
    "  float fog = clamp((dist - fog_range.x) / max(fog_range.y - fog_range.x, 1.0), 0.0, 1.0);\n"
    "  frag = vec4(mix(t.rgb * light, fog_col, fog), 1.0);\n"
    "}\n";
/* }}} */

/* {{{ the figures: her, and the models standing around her (173j)
 * Each bystander: who (a character's look, or a creature display from
 * CreatureDisplayInfo), where (yards ahead of her start and to her left,
 * facing back toward her), and the animations it cycles through, by the
 * game's numbers (AnimationData.dbc), each held for HOLD_MS. A number
 * its model lacks is skipped. The owner's first pick (2026-10-05): a
 * tauren, a furbolg, an Ashenvale treant (the ancient protector: no
 * treant model is named so) and a nightsaber (the tiger model, the
 * nightsaber's body). */
#define HOLD_MS 4000
static const int CYCLE[] = { 0, 60, 74, 16, 25, 69, 67, 66, 68, 53 };   /* stand, talk, roar, attack, ready, dance, wave, bow, cheer, cast */
static const struct {
    int race, sex;                    /* a character (race 0: a creature) */
    int display;                      /* a creature's display */
    float ahead, left;                /* yards from her start */
} BYSTANDERS[] = {
    { 6, 0, 0,   9.0f,  -4.0f },      /* a tauren man */
    { 0, 0, 145, 10.0f,  1.0f },      /* a furbolg */
    { 0, 0, 860, 14.0f,  7.0f },      /* the ancient protector */
    { 0, 0, 321, 7.0f,   5.0f },      /* a nightsaber */
};
#define NBYSTANDERS ((int)(sizeof BYSTANDERS / sizeof BYSTANDERS[0]))
static Figure her;
static Figure others[NBYSTANDERS];
static int    nothers;
static struct { double x, y, z; float facing; MovesState moves; int cycle; float held; } other_at[NBYSTANDERS];
/* }}} */

/* {{{ the world and the camera */
static MapWorld world;
static MpqChain chain;                                   /* the original client's archives, open for the whole run */
static char   tile_state[64 * 64];                      /* 0 not tried, 1 painted, 2 no ground file (open sea) */
static double ox, oy;                                    /* the drawing origin, near the start */
static Mover  elf;
static FollowCam view = { .yaw = (float)START_O, .pitch = 0.35f, .dist = 12.0f, .rest_pitch = 0.35f };   /* camera.h */
static int    cam_held;                                  /* --front: the camera keeps its own heading */

/* {{{ the ground and walls the mover asks about (173q)
 * The floor: the map's ground or a model's floor (bridge, stair, a
 * building's floor), whichever is higher at or below z_top; the map's
 * ground above z_top (she is under it, in a cave or a building's
 * cellar) doesn't count. Walls: the models' steep triangles. Her body for
 * walls: 0.4 yards round, 2.3 tall, stepping over 1 yard (173q's open
 * question: the original's own numbers). */
static CollideWorld *solids;
static float ground_at(void *ctx, float x, float y, float z_top, float *gx, float *gy)
{
    float tx, ty, mx, my;
    float t = maps_world_height((MapWorld *)ctx, x, y, &tx, &ty);
    float m = collide_floor(solids, x, y, z_top, &mx, &my);
    /* the model's floor wins when it is higher than a usable map ground,
     * or when the map's ground is above her (she is beneath it) */
    int map_below = t > -10000 && t <= z_top + 0.01f;
    if (m > -10000 && (!map_below || m > t)) { *gx = mx; *gy = my; return m; }
    /* otherwise the map's ground, as before models: also when it lies
     * above her and no model floor does (she lands on it, or the slope
     * rule decides) */
    *gx = tx; *gy = ty;
    return t;
}
static int wall_at(void *ctx, double x0, double y0, double x1, double y1, double z, float *nx, float *ny)
{
    (void)ctx;
    return collide_wall(solids, x0, y0, x1, y1, z, 0.4f, (float)MOVER_STEP_UP, ELF_HEIGHT, (float)elf.max_grad, nx, ny);
}
/* }}} */

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
    double start_ms = 0;                                 /* --clock: the world's animations start this far in */
    double face_deg = 0;                                 /* --face: her start facing turned this far (left) */
    float  walk_s = 0;                                   /* --walk: hold forward this many world-seconds (pictures) */
    /* the time of day: the original follows the realm's clock, which is
     * real time; until the client talks to a server, this machine's own
     * (--hour H for pictures) */
    time_t now = time(NULL);
    struct tm *lt = localtime(&now);
    float hours = (float)lt->tm_hour + (float)lt->tm_min / 60.0f;
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
        else if (!strcmp(argv[i], "--clock") && i + 1 < argc) start_ms = atof(argv[++i]);
        else if (!strcmp(argv[i], "--hour") && i + 1 < argc) hours = (float)atof(argv[++i]);
        else if (!strcmp(argv[i], "--face") && i + 1 < argc) face_deg = atof(argv[++i]);
        else if (!strcmp(argv[i], "--walk") && i + 1 < argc) walk_s = (float)atof(argv[++i]);
    }
    if (!maps || !client) { fprintf(stderr, "usage: custom-client --maps DIR --client DIR [--settings FILE] [--shot FILE] [--zoom N] [--front] [--turn DEG] [--pitch DEG] [--pose ID MS] [--clock MS] [--hour H] [--face DEG] [--walk S]\n"); return 2; }

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
    mover_init(&elf, START_X, START_Y, z, START_O + face_deg * PI / 180, SPEED, max_slope);
    view.yaw = (float)elf.o + (view.yaw - (float)START_O);   /* the camera keeps its place behind her */
    ox = floor(START_X); oy = floor(START_Y);

    SetConfigFlags(FLAG_WINDOW_RESIZABLE | FLAG_VSYNC_HINT);
    InitWindow(win_w, win_h, "Everland Ghostsong");
    SetExitKey(KEY_NULL);                                /* Escape is read in the loop, so it can open the game menu later */
    Shader model_sh  = LoadShaderFromMemory(GROUND_VS, MODEL_FS);
    if (mpq_chain_open(&chain, client, "enUS", why, sizeof why)) { fprintf(stderr, "%s\n", why); CloseWindow(); return 1; }
    if (figure_from_character(&her, &chain, &LOOK, why, sizeof why)) { fprintf(stderr, "%s\n", why); CloseWindow(); return 1; }
    static const int NEEDED[] = { MOVE_STAND, MOVE_RUN, MOVE_WALK_BACK, MOVE_SHUFFLE_LEFT, MOVE_SHUFFLE_RIGHT, MOVE_JUMP_START, MOVE_JUMP, MOVE_JUMP_END, MOVE_FALL };
    for (unsigned i = 0; i < sizeof NEEDED / sizeof NEEDED[0]; ++i)
        if (anim_find(&her.anim, NEEDED[i], 0) < 0) fprintf(stderr, "her animations: her model has no animation %d; she stands instead\n", NEEDED[i]);
    /* the bystanders: each stands round her start, facing her; one that
     * can't be built is named and left out */
    for (int i = 0; i < NBYSTANDERS; ++i) {
        Figure *f = &others[nothers];
        CharacterLook look = { BYSTANDERS[i].race, BYSTANDERS[i].sex, 0, 0, 0, 0 };
        int bad = BYSTANDERS[i].race ? figure_from_character(f, &chain, &look, why, sizeof why)
                                     : figure_from_display(f, &chain, BYSTANDERS[i].display, why, sizeof why);
        if (bad) { fprintf(stderr, "bystander %d left out: %s\n", i, why); continue; }
        double fx = cos(START_O), fy = sin(START_O);
        other_at[nothers].x = START_X + fx * BYSTANDERS[i].ahead - fy * BYSTANDERS[i].left;
        other_at[nothers].y = START_Y + fy * BYSTANDERS[i].ahead + fx * BYSTANDERS[i].left;
        other_at[nothers].z = maps_world_height(&world, (float)other_at[nothers].x, (float)other_at[nothers].y, &gx, &gy);
        other_at[nothers].facing = (float)atan2(START_Y - other_at[nothers].y, START_X - other_at[nothers].x);
        moves_init(&other_at[nothers].moves, &f->anim);
        other_at[nothers].cycle = 0;
        other_at[nothers].held = (float)(i * 900);        /* staggered, so they don't change together */
        printf("bystander: %s\n", f->name);
        ++nothers;
    }
    if (ground_init(&chain, MAP_NAME, why, sizeof why)) { fprintf(stderr, "%s\n", why); CloseWindow(); return 1; }
    solids = collide_new(ox, oy);
    if (doodads_init(&chain, solids, why, sizeof why)) { fprintf(stderr, "%s\n", why); CloseWindow(); return 1; }
    LightTables lights;
    if (light_open(&lights, &chain, why, sizeof why)) { fprintf(stderr, "%s\n", why); CloseWindow(); return 1; }
    sky_init();
    LightNow light;
    int light_id = light_at(&lights, MAP_ID, (float)elf.x, (float)elf.y, (float)elf.z, hours, &light);
    if (light_id < 0) printf("light: map %d has no lights in Light.dbc; a plain grey day is used\n", MAP_ID);
    else printf("light: %02d:%02d, light %d, fog from %.0f to %.0f yards\n", (int)hours, (int)(fmodf(hours, 1.0f) * 60), light_id, light.fog_start, light.fog_end);
    int eye_m = GetShaderLocation(model_sh, "eye");
    refresh_tiles();
    int dm, dc, ds, dmov, demit;
    doodads_counts(&dm, &dc, &ds, &dmov, &demit);
    printf("doodads: %d models (%d of them moving, %d with particles), %d placed; %d solid triangles\n", dm, dmov, demit, dc, collide_count(solids));
    if (ds) printf("doodads: %d pieces left out: their picture is chosen by the game at run time (not built yet)\n", ds);

    MovesState moves;
    moves_init(&moves, &her.anim);
    double clock_ms = start_ms;

    int frames = 0, drag_l = 0, drag_r = 0;
    while (!WindowShouldClose()) {
        /* {{{ input and movement */
        float dt = shot ? 0.05f : GetFrameTime();          /* pictures: steady 20 frames a world-second */
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
            .forward = IsKeyDown(KEY_W) || IsKeyDown(KEY_UP) || (drag_l && drag_r) || (walk_s > 0 && frames * 0.05f < walk_s),
            .back = IsKeyDown(KEY_S) || IsKeyDown(KEY_DOWN),
            .left = IsKeyDown(KEY_A) || IsKeyDown(KEY_LEFT),
            .right = IsKeyDown(KEY_D) || IsKeyDown(KEY_RIGHT),
            .strafe_left = IsKeyDown(KEY_Q),
            .strafe_right = IsKeyDown(KEY_E),
            .strafe_turns = drag_r,
            .jump = IsKeyDown(KEY_SPACE),
        };
        double before_o = elf.o, before_x = elf.x, before_y = elf.y;
        mover_step(&elf, &in, dt, ground_at, wall_at, &world);
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
        moves_step(&moves, &her.anim, &mi);
        if (pose_id >= 0) {
            int seq = anim_find(&her.anim, pose_id, 0);
            if (seq < 0) { fprintf(stderr, "--pose %d: her model has no such animation\n", pose_id); break; }
            moves.seq = seq; moves.ms = pose_ms; moves.from = -1; moves.once = 0;
        }
        clock_ms += dt * 1000.0;
        figure_bend(&her, &moves, (uint32_t)clock_ms);
        /* the bystanders: each holds an animation for HOLD_MS, then the
         * next of CYCLE its model has */
        for (int i = 0; i < nothers; ++i) {
            other_at[i].held += dt * 1000.0f;
            if (other_at[i].held >= HOLD_MS) {
                other_at[i].held = 0;
                for (int tries = 0; tries < (int)(sizeof CYCLE / sizeof CYCLE[0]); ++tries) {
                    other_at[i].cycle = (other_at[i].cycle + 1) % (int)(sizeof CYCLE / sizeof CYCLE[0]);
                    if (anim_find(&others[i].anim, CYCLE[other_at[i].cycle], 0) >= 0) break;
                }
                moves_play(&other_at[i].moves, &others[i].anim, CYCLE[other_at[i].cycle]);
            }
            moves_advance(&other_at[i].moves, &others[i].anim, dt);
            figure_bend(&others[i], &other_at[i].moves, (uint32_t)clock_ms);
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
        doodads_animate((uint32_t)clock_ms, dt, eye, at);   /* moving doodads, and particles near the camera */
        SetShaderValue(model_sh, eye_m, &eye, SHADER_UNIFORM_VEC3);
        /* }}} */

        BeginDrawing();
        /* the light here, now: time runs on in real time */
        hours = fmodf(hours + dt / 3600.0f, 24.0f);
        int lit = light_at(&lights, MAP_ID, (float)elf.x, (float)elf.y, (float)elf.z, hours, &light);
        if (lit != light_id) { light_id = lit; printf("light: now light %d\n", lit); }
        sky_light_shader(model_sh, &light);
        ClearBackground((Color){ (unsigned char)(fminf(light.fog[0], 1) * 255), (unsigned char)(fminf(light.fog[1], 1) * 255), (unsigned char)(fminf(light.fog[2], 1) * 255), 255 });
        BeginMode3D(cam);
        /* the Lua client's projection: 60 degrees, near 0.3, far 1600 yards
         * (Raylib's own far plane is 1000; this Raylib has no setter, so the
         * projection is loaded directly) */
        rlMatrixMode(RL_PROJECTION);
        rlLoadIdentity();
        rlMultMatrixf(MatrixToFloat(MatrixPerspective(60 * DEG2RAD, (double)GetScreenWidth() / GetScreenHeight(), 0.3, 1600)));
        rlMatrixMode(RL_MODELVIEW);
        rlDisableBackfaceCulling();
        sky_draw(eye, &light);                           /* first, behind everything */
        ground_blob(at.x, at.y, (float)elf.z, 1.3f);     /* her shadow, a little wider than her shoulders */
        for (int i = 0; i < nothers; ++i)                /* theirs, sized by their display's scale */
            ground_blob((float)(other_at[i].x - ox), (float)(other_at[i].y - oy), (float)other_at[i].z, 1.3f * others[i].scale);
        ground_draw(eye, &light);
        doodads_draw(eye, &light);
        Matrix place = MatrixMultiply(MatrixRotateZ((float)elf.o + moves.body_turn), MatrixTranslate(at.x, at.y, (float)elf.z));
        figure_draw(&her, model_sh, place);
        for (int i = 0; i < nothers; ++i)
            figure_draw(&others[i], model_sh, MatrixMultiply(MatrixRotateZ(other_at[i].facing),
                        MatrixTranslate((float)(other_at[i].x - ox), (float)(other_at[i].y - oy), (float)other_at[i].z)));
        EndMode3D();
        EndDrawing();

        /* --shot: after 3 world-seconds, the picture, then quit */
        if (shot && ++frames == 60 + (int)(walk_s * 20)) {   /* 3 world-seconds after any walk: particles have filled out */
            Image im = LoadImageFromScreen();
            int ok = ExportImage(im, shot);
            UnloadImage(im);
            printf(ok ? "picture saved: %s\n" : "could not save the picture to %s\n", shot);
            printf("she ended at x %.2f y %.2f z %.2f, %s\n", elf.x, elf.y, elf.z, elf.grounded ? "on the ground" : "in the air");
            break;
        }
    }
    CloseWindow();
    light_close(&lights);
    collide_free(solids);
    figure_free(&her);
    for (int i = 0; i < nothers; ++i) figure_free(&others[i]);
    mpq_chain_close(&chain);
    maps_world_free(&world);
    return 0;
}
/* }}} */
