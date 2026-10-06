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
 *   --zoom N          (pictures) the camera N yards back; 0 is first person
 *   --turn DEG        (pictures) the camera turned DEG degrees round her, held there
 *   --pitch DEG       (pictures) the camera raised DEG degrees (up to 83)
 *   --clock MS        (pictures) start the world's animations MS milliseconds in
 *   --hour H          the time of day, 0 to 24 (default: this machine's clock)
 *   --face DEG        her start facing turned DEG degrees (left)
 *   --walk S          (pictures) hold forward for S world-seconds
 *   --dive S          (pictures) then hold X (swim down) for S world-seconds
 *   --wait S          (pictures) then wait S world-seconds more
 *   --wear SLOT:LOOK,...  dress her: each slot's item look (ItemDisplayInfo id),
 *                     e.g. chest:41143,hands:41138,legs:41140,waist:41476,feet:41480
 *   --goto X Y        (pictures) one world-second in, move her to world (X, Y)
 *   --map ID X Y      start on map ID (Map.dbc: 0 Eastern Kingdoms, 1 Kalimdor,
 *                     530 Outland, 571 Northrend) at world (X, Y)
 *   --pose ID MS      (pictures) hold her in animation ID (AnimationData.dbc:
 *                     0 stand, 5 run, 13 walk backwards, 38 jump ...) at MS
 */
#include "anim.h"
#include "camera.h"
#include "character.h"
#include "collide.h"
#include "dbc.h"
#include "doodads.h"
#include "figure.h"
#include "ground.h"
#include "horizon.h"
#include "light.h"
#include "liquid.h"
#include "maps.h"
#include "mover.h"
#include "moves.h"
#include "mpq.h"
#include "navmesh_slope.h"
#include "settings.h"
#include "sky.h"
#include "water.h"

#include "raylib.h"
#include "raymath.h"
#include "rlgl.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* {{{ the map and the start (--map ID X Y chooses another; the folder
 * name comes from the client's Map.dbc: 1 id, 2 its folder in the
 * archives, World\\Maps\\<folder>) */
static int    map_id = 1;                               /* Kalimdor */
static char   map_name[64] = "Kalimdor";
static double start_x = 2717.0, start_y = -400.0;       /* Astranaar, Ashenvale */
/* }}} */

/* {{{ settings */
#define START_O      3.6                               /* facing the town's west side */
#define SPEED        1.2                               /* 120% of the base speeds (owner, 2026-10-04) */
#define ELF_HEIGHT   2.3f                              /* yards: the camera looks at her shoulders */
#define EYE_SHARE    0.92f                             /* first person: her eyes, as a share of her height (this client's guess) */
#define ZOOM_BASE    20.0f                             /* yards; times cameraDistanceMaxFactor (1 to 2) is the zoom-out limit (173b4) */
/* her look: ChrRaces id, sex, and the character-creation choices (from 0);
 * a stand-in for the ids the server will send (173d, 617r5) */
static CharacterLook LOOK = { 4, 1, 0, 0, 0, 0, { 0 }, 0 };   /* --wear dresses her (173p) */

/* {{{ static wear_option: "--wear chest:41143,hands:41138": slot names to
 * item looks (ItemDisplayInfo ids); 0 on success, else the bad part */
static const char *const SLOT_NAMES[SLOT_COUNT] = {
    "shirt", "legs", "feet", "wrists", "chest", "hands", "tabard", "waist", "head", "shoulders", "back", "mainhand", "offhand",
};
static int wear_option(const char *text, char *bad, int bad_len)
{
    char copy[600];
    snprintf(copy, sizeof copy, "%s", text);
    for (char *part = strtok(copy, ","); part; part = strtok(NULL, ",")) {
        char *colon = strchr(part, ':');
        int slot = -1;
        if (colon) { *colon = '\0'; for (int k = 0; k < SLOT_COUNT; ++k) if (!strcmp(part, SLOT_NAMES[k])) slot = k; }
        if (slot < 0 || atoi(colon + 1) <= 0) { snprintf(bad, bad_len, "%s", part); return 1; }
        LOOK.items[slot] = atoi(colon + 1);
    }
    return 0;
}
/* }}} */
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
/* `mode` (figure.c): 0 solid, pixels under half opacity cut out; 1
 * see-through, the picture's opacity times the tint's; 2 added light,
 * which the fog dims to nothing rather than tinting (as particles,
 * 173o). `tint` is the piece's animated colour and opacity, `unlit` skips
 * the sun (glows). */
static const char *MODEL_FS =
    "#version 330\n"
    "in vec3 n; in vec4 col; in vec2 uv; in float dist; out vec4 frag; uniform sampler2D texture0;\n"
    "uniform vec3 sun_dir, sun_col, shade_col, fog_col; uniform vec2 fog_range;\n"
    "uniform vec4 tint; uniform int mode, unlit;\n"
    "void main() {\n"
    "  vec4 t = texture(texture0, uv) * tint;\n"
    "  if (mode == 0 && t.a < 0.5 * tint.a) discard;\n"
    "  vec3 light = unlit != 0 ? vec3(1.0) : shade_col + sun_col * max(dot(normalize(n), sun_dir), 0.0);\n"
    "  float fog = clamp((dist - fog_range.x) / max(fog_range.y - fog_range.x, 1.0), 0.0, 1.0);\n"
    "  if (mode == 2) frag = vec4(t.rgb * light * (1.0 - fog), t.a);\n"
    "  else frag = vec4(mix(t.rgb * light, fog_col, fog), mode == 1 ? t.a : 1.0);\n"
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
    int facial_hair;                  /* a character's facial-hair choice (173d) */
} BYSTANDERS[] = {
    { 6, 0, 0,   9.0f,  -4.0f, 1 },   /* a tauren man, bearded */
    { 0, 0, 145, 10.0f,  1.0f, 0 },   /* a furbolg */
    { 0, 0, 860, 14.0f,  7.0f, 0 },   /* the ancient protector */
    { 0, 0, 321, 7.0f,   5.0f, 0 },   /* a nightsaber */
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
static char   tile_state[64 * 64];                      /* 0 not loaded, 1 painted, 2 no ground file (open sea) */
static int    tiles_loaded, tiles_dropped;               /* for the picture report */
static double ox, oy;                                    /* the drawing origin, near the start */
static Mover  elf;
static FollowCam view = { .yaw = (float)START_O, .pitch = 0.35f, .dist = 12.0f, .rest_pitch = 0.35f };   /* camera.h */
static int    cam_held;                                  /* --front: the camera keeps its own heading */
static float  bob_phase;                                 /* Head Bob's place in her step, yards (camera_bob) */

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
static LiquidWorld *waters;          /* every loaded tile's water (173r) */
static float water_at(void *ctx, double x, double y)
{
    (void)ctx;
    int kind;
    return liquid_surface(waters, x, y, &kind);
}
static int wall_at(void *ctx, double x0, double y0, double x1, double y1, double z, float *nx, float *ny)
{
    (void)ctx;
    return collide_wall(solids, x0, y0, x1, y1, z, 0.4f, (float)MOVER_STEP_UP, ELF_HEIGHT, (float)elf.max_grad, nx, ny);
}
/* }}} */

/* tiles loaded round hers: enough to cover the view distance (farclip,
 * 173b6), 1 to 3 (3 x 3 up to 7 x 7) */
static int tile_reach(void)
{
    int r = (int)ceil(settings_num("farclip") / 533.33333);
    return r < 1 ? 1 : r > 3 ? 3 : r;
}
static int tile_loaded(int x, int y) { return tile_state[x * 64 + y] == 1; }   /* for the horizon (173s) */
static void refresh_tiles(void)
{
    const int TILE_REACH = tile_reach();
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
                liquid_add_tile(waters, x, y, adt);
                water_add_tile(adt, x * 64 + y, ox, oy);
                if (doodads_add_tile(adt, x * 64 + y, ox, oy, why, sizeof why)) { fprintf(stderr, "doodads on tile (%d, %d): %s\n", x, y, why); exit(1); }
                adt_free(adt);
                free(adt);
            }
            tile_state[x * 64 + y] = got == 0 ? 1 : 2;
            ++tiles_loaded;
        }
    /* dropping (173s): tiles more than a tile beyond the loaded square go,
     * with all they brought; the margin keeps a walk back and forth over
     * an edge from loading and dropping the same tile again and again */
    for (int x = 0; x < 64; ++x)
        for (int y = 0; y < 64; ++y) {
            if (!tile_state[x * 64 + y] || (abs(x - tx) <= TILE_REACH + 1 && abs(y - ty) <= TILE_REACH + 1)) continue;
            if (tile_state[x * 64 + y] == 1) {
                ground_drop_tile(x, y);
                water_drop_tile(x * 64 + y);
                liquid_drop_tile(waters, x, y);
                doodads_drop_tile(x * 64 + y);
            }
            tile_state[x * 64 + y] = 0;
            ++tiles_dropped;
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
    float  dive_s = 0;                                   /* --dive: then hold X (swim down) this many world-seconds */
    float  wait_s = 0;                                   /* --wait: then this many world-seconds more before the picture */
    int    go_to = 0;                                    /* --goto: one world-second in, she is moved to (goto_x, goto_y) */
    double goto_x = 0, goto_y = 0;
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
        else if (!strcmp(argv[i], "--dive") && i + 1 < argc) dive_s = (float)atof(argv[++i]);
        else if (!strcmp(argv[i], "--wait") && i + 1 < argc) wait_s = (float)atof(argv[++i]);
        else if (!strcmp(argv[i], "--wear") && i + 1 < argc) {
            char bad[200];
            if (wear_option(argv[++i], bad, sizeof bad)) {
                fprintf(stderr, "--wear: \"%s\" isn't slot:look (slots: shirt legs feet wrists chest hands tabard waist head shoulders back mainhand offhand)\n", bad);
                return 2;
            }
        }
        else if (!strcmp(argv[i], "--map") && i + 3 < argc) { map_id = atoi(argv[++i]); start_x = atof(argv[++i]); start_y = atof(argv[++i]); }
        else if (!strcmp(argv[i], "--goto") && i + 2 < argc) { goto_x = atof(argv[++i]); goto_y = atof(argv[++i]); go_to = 1; }
    }
    if (!maps || !client) { fprintf(stderr, "usage: custom-client --maps DIR --client DIR [--settings FILE] [--shot FILE] [--zoom N] [--front] [--turn DEG] [--pitch DEG] [--pose ID MS] [--clock MS] [--hour H] [--face DEG] [--walk S] [--dive S] [--wait S] [--wear SLOT:LOOK,...] [--goto X Y] [--map ID X Y]\n"); return 2; }

    /* the settings: defaults, then the player's file; a line it refuses is
     * named on the terminal and skipped (173b1) */
    settings_init();
    if (settings_file) settings_load(settings_file, stderr);
    else fprintf(stderr, "settings: no --settings file given; every setting is at its default\n");
    int win_w, win_h;
    settings_resolution(settings_text("gxResolution"), &win_w, &win_h);   /* accepted when set, so always a resolution */

    char why[900];
    maps_world_init(&world, maps, map_id);
    float gx, gy;
    float z = maps_world_height(&world, (float)start_x, (float)start_y, &gx, &gy);
    if (z < -10000) { fprintf(stderr, "no ground at the start (%.1f, %.1f) in map %d from %s: is the maps folder right?\n", start_x, start_y, map_id, maps); return 1; }
    /* the steepest walkable ground, from the server's navigation tiles
     * (data-files/mmaps beside data-files/maps) */
    char mmaps[600];
    snprintf(mmaps, sizeof mmaps, "%s", maps);
    char *cut = strstr(mmaps, "/maps");
    if (!cut) { fprintf(stderr, "the maps folder %s doesn't end in /maps; can't find mmaps beside it\n", maps); return 1; }
    strcpy(cut, "/mmaps");
    float max_slope = navmesh_slope_read(mmaps, map_id, why, sizeof why);
    if (max_slope < 0) { fprintf(stderr, "%s\n", why); return 1; }
    mover_init(&elf, start_x, start_y, z, START_O + face_deg * PI / 180, SPEED, max_slope);
    view.yaw = (float)elf.o + (view.yaw - (float)START_O);   /* the camera keeps its place behind her */
    ox = floor(start_x); oy = floor(start_y);

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
        CharacterLook look = { BYSTANDERS[i].race, BYSTANDERS[i].sex, 0, 0, 0, 0, { 0 }, BYSTANDERS[i].facial_hair };
        int bad = BYSTANDERS[i].race ? figure_from_character(f, &chain, &look, why, sizeof why)
                                     : figure_from_display(f, &chain, BYSTANDERS[i].display, why, sizeof why);
        if (bad) { fprintf(stderr, "bystander %d left out: %s\n", i, why); continue; }
        double fx = cos(START_O), fy = sin(START_O);
        other_at[nothers].x = start_x + fx * BYSTANDERS[i].ahead - fy * BYSTANDERS[i].left;
        other_at[nothers].y = start_y + fy * BYSTANDERS[i].ahead + fx * BYSTANDERS[i].left;
        other_at[nothers].z = maps_world_height(&world, (float)other_at[nothers].x, (float)other_at[nothers].y, &gx, &gy);
        other_at[nothers].facing = (float)atan2(start_y - other_at[nothers].y, start_x - other_at[nothers].x);
        moves_init(&other_at[nothers].moves, &f->anim);
        other_at[nothers].cycle = 0;
        other_at[nothers].held = (float)(i * 900);        /* staggered, so they don't change together */
        printf("bystander: %s\n", f->name);
        ++nothers;
    }
    {
        size_t len;
        const char *from;
        unsigned char *mt = mpq_chain_read(&chain, "DBFilesClient\\Map.dbc", &len, &from);
        Dbc maps_table;
        if (!mt || dbc_open(&maps_table, mt, len, why, sizeof why)) { fprintf(stderr, "Map.dbc: %s\n", mt ? why : "not in the archives"); CloseWindow(); return 1; }
        int found = 0;
        for (uint32_t r = 0; r < maps_table.rows && !found; ++r)
            if ((int)dbc_u32(&maps_table, r, 1) == map_id) { snprintf(map_name, sizeof map_name, "%s", dbc_text(&maps_table, r, 2)); found = 1; }
        free(mt);
        if (!found) { fprintf(stderr, "no map %d in Map.dbc\n", map_id); CloseWindow(); return 1; }
    }
    if (ground_init(&chain, map_name, why, sizeof why)) { fprintf(stderr, "%s\n", why); CloseWindow(); return 1; }
    solids = collide_new(ox, oy);
    waters = liquid_new();
    if (doodads_init(&chain, solids, waters, why, sizeof why)) { fprintf(stderr, "%s\n", why); CloseWindow(); return 1; }
    if (horizon_init(&chain, map_name, ox, oy, why, sizeof why)) printf("horizon: %s\n", why);
    if (water_init(&chain, why, sizeof why)) { fprintf(stderr, "%s\n", why); CloseWindow(); return 1; }
    LightTables lights;
    if (light_open(&lights, &chain, why, sizeof why)) { fprintf(stderr, "%s\n", why); CloseWindow(); return 1; }
    sky_init();
    LightNow light;
    int light_id = light_at(&lights, map_id, (float)elf.x, (float)elf.y, (float)elf.z, hours, &light);
    if (light_id < 0) printf("light: map %d has no lights in Light.dbc; a plain grey day is used\n", map_id);
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
        if (go_to && frames == 20) {                     /* --goto: there, standing on the ground */
            go_to = 0;
            float gx2, gy2;
            float gz = maps_world_height(&world, (float)goto_x, (float)goto_y, &gx2, &gy2);
            if (gz < -10000) { fprintf(stderr, "--goto %.1f %.1f: no ground there in the server's maps\n", goto_x, goto_y); break; }
            elf.x = goto_x; elf.y = goto_y; elf.z = gz; elf.grounded = 1; elf.swimming = 0;
        }
        /* the mouse: left drag looks around her, right drag turns her too (camera.c) */
        int was_r = drag_r;
        drag_l = IsMouseButtonDown(MOUSE_BUTTON_LEFT);
        drag_r = IsMouseButtonDown(MOUSE_BUTTON_RIGHT);
        Vector2 d = GetMouseDelta();
        FollowCamInput mouse = { .left = drag_l, .right = drag_r, .dx = d.x, .dy = d.y, .dt = dt };
        camera_drag(&view, &mouse, was_r, &elf.o);
        float wheel = GetMouseWheelMove();
        float zoom_max = ZOOM_BASE * (float)settings_num("cameraDistanceMaxFactor");
        camera_zoom(&view, wheel, zoom_max);            /* in past the nearest is first person (173m) */
        MoverInput in = {
            .forward = IsKeyDown(KEY_W) || IsKeyDown(KEY_UP) || (drag_l && drag_r) || (walk_s > 0 && frames * 0.05f < walk_s),
            .back = IsKeyDown(KEY_S) || IsKeyDown(KEY_DOWN),
            .left = IsKeyDown(KEY_A) || IsKeyDown(KEY_LEFT),
            .right = IsKeyDown(KEY_D) || IsKeyDown(KEY_RIGHT),
            .strafe_left = IsKeyDown(KEY_Q),
            .strafe_right = IsKeyDown(KEY_E),
            .strafe_turns = drag_r,
            .jump = IsKeyDown(KEY_SPACE),
            .swim_down = IsKeyDown(KEY_X) || (dive_s > 0 && frames * 0.05f >= walk_s && frames * 0.05f < walk_s + dive_s),   /* swimming down; up is the jump key (173r) */
            .pitch = -view.pitch,                        /* where the camera looks, up positive */
        };
        double before_o = elf.o, before_x = elf.x, before_y = elf.y;
        MoverWorld mw = { ground_at, wall_at, water_at, &world };
        mover_step(&elf, &in, dt, &mw);
        /* moving = she moved along the ground this frame, by any cause
         * (keys, both buttons, sliding); turning in place isn't moving */
        int moving = hypot(elf.x - before_x, elf.y - before_y) > 1e-4;
        if (!cam_held) {
            camera_follow(&view, &mouse, camera_turn_between((float)before_o, (float)elf.o), moving, elf.o);
            float sgx, sgy;
            ground_at(&world, (float)elf.x, (float)elf.y, (float)elf.z + 1.0f, &sgx, &sgy);
            camera_tilt(&view, &mouse, moving && elf.grounded, (float)(sgx * cos(elf.o) + sgy * sin(elf.o)));   /* Follow Terrain (173m) */
        }

        /* her animation: chosen from what she did this frame, then her
         * points bent by the bones and copied into each piece's mesh */
        int turning = !drag_r && (in.left || in.right);
        MovesInput mi = {
            .forward = in.forward, .back = in.back,
            .strafe_left = in.strafe_left || (drag_r && in.left), .strafe_right = in.strafe_right || (drag_r && in.right),
            .turn_left = turning && in.left, .turn_right = turning && in.right,
            .grounded = elf.grounded || elf.swimming, .rising = elf.vz > 0, .swimming = elf.swimming,
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

        /* {{{ the camera: behind her by its own heading, raised by its pitch;
         * or, zoomed all the way in, first person: the view from her eyes
         * along the camera's heading, looking down by its pitch, she not
         * drawn (as the original hides you), Head Bob lifting it with her
         * steps (173m). First person skips the third-person keeping-out
         * below: her eyes are where she is, which the mover already keeps
         * out of walls, ground and (unless swimming) water */
        int first_person = view.dist == 0;
        Vector3 at = { (float)(elf.x - ox), (float)(elf.y - oy), (float)elf.z + ELF_HEIGHT * 0.85f };
        Vector3 eye = { at.x - cosf(view.yaw) * cosf(view.pitch) * view.dist,
                        at.y - sinf(view.yaw) * cosf(view.pitch) * view.dist,
                        at.z + sinf(view.pitch) * view.dist };
        Vector3 look = at;                               /* where the camera points */
        {
            float stepped = elf.grounded && !elf.swimming ? (float)hypot(elf.x - before_x, elf.y - before_y) : 0;
            float lift = camera_bob(&bob_phase, stepped, dt);   /* runs in third person too, so the phase carries over */
            if (first_person) {
                eye = (Vector3){ at.x, at.y, (float)elf.z + ELF_HEIGHT * EYE_SHARE + lift };
                look = (Vector3){ eye.x + cosf(view.yaw) * cosf(view.pitch), eye.y + sinf(view.yaw) * cosf(view.pitch), eye.z - sinf(view.pitch) };
            }
        }
        if (!first_person) {
            /* something solid between her head and the camera (a wall, a
             * tree, a roof): the camera comes in to just before it (173m) */
            float in_way = collide_ray(solids, at.x + ox, at.y + oy, at.z, eye.x + ox, eye.y + oy, eye.z);
            if (in_way < 1) {
                float keep = fmaxf(in_way - 0.3f / fmaxf(view.dist, 0.3f), 0.05f);   /* 0.3 yards short of it */
                eye = (Vector3){ at.x + (eye.x - at.x) * keep, at.y + (eye.y - at.y) * keep, at.z + (eye.z - at.z) * keep };
            }
            float floor_z = maps_world_height(&world, eye.x + (float)ox, eye.y + (float)oy, &gx, &gy);
            if (floor_z > -10000 && eye.z < floor_z + 0.6f) {
                /* never under the ground. Smart Pivot on: the camera slides along
                 * the ground and looks up at her; off: it stops lowering, the
                 * pitch held where the camera meets the ground (173m) */
                eye.z = floor_z + 0.6f;
                if (settings_num("cameraPivot") == 0 && view.dist > 0.1f) {
                    float s = (eye.z - at.z) / view.dist;
                    float hold = asinf(s < -1 ? -1 : s > 1 ? 1 : s);
                    if (view.pitch < hold) view.pitch = hold;
                }
            }
            /* Water Collision (173m): the camera stays on her side of the
             * water's surface: above it while her head is above, below while
             * under */
            if (settings_num("cameraWaterCollision") != 0) {
                int wk = 0;
                float surface = liquid_surface(waters, eye.x + ox, eye.y + oy, &wk);
                float head = at.z;
                if (surface > -10000) {
                    if (head >= surface && eye.z < surface + 0.25f) eye.z = surface + 0.25f;
                    else if (head < surface && eye.z > surface - 0.25f) eye.z = surface - 0.25f;
                }
            }
        }
        Camera3D cam = { .position = eye, .target = look, .up = { 0, 0, 1 }, .fovy = 60, .projection = CAMERA_PERSPECTIVE };
        doodads_animate((uint32_t)clock_ms, dt, eye, look);   /* moving doodads, and particles near the camera */
        SetShaderValue(model_sh, eye_m, &eye, SHADER_UNIFORM_VEC3);
        /* }}} */

        BeginDrawing();
        /* the light here, now: time runs on in real time */
        hours = fmodf(hours + dt / 3600.0f, 24.0f);
        int lit = light_at(&lights, map_id, (float)elf.x, (float)elf.y, (float)elf.z, hours, &light);
        /* underwater (173r): with the camera below the water's surface the
         * world closes in to the water's deep colour (the zone's river or sea
         * band, 173n) within 40 yards, as the original's underwater view does;
         * this client's distances, to compare */
        {
            int kind = 0;
            float surface = liquid_surface(waters, eye.x + ox, eye.y + oy, &kind);
            if (surface > -10000 && eye.z < surface) {
                const float *deep = kind == 2 || kind == 6 ? light.water[1] : light.water[3];
                for (int c = 0; c < 3; ++c) light.fog[c] = deep[c];
                light.fog_start = 0;
                light.fog_end = 40;
            }
        }
        /* the fog ends by the view distance at the latest (173b6) */
        float farclip = (float)settings_num("farclip");
        if (light.fog_end > farclip) { light.fog_start *= farclip / light.fog_end; light.fog_end = farclip; }
        if (lit != light_id) { light_id = lit; printf("light: now light %d\n", lit); }
        sky_light_shader(model_sh, &light);
        ClearBackground((Color){ (unsigned char)(fminf(light.fog[0], 1) * 255), (unsigned char)(fminf(light.fog[1], 1) * 255), (unsigned char)(fminf(light.fog[2], 1) * 255), 255 });
        BeginMode3D(cam);
        /* the projection: 60 degrees, near 0.3, far a little past the view
         * distance (farclip, 173b6) so the fog, which ends by it, hides the edge
         * (Raylib's own far plane is 1000; this Raylib has no setter, so the
         * projection is loaded directly) */
        rlMatrixMode(RL_PROJECTION);
        rlLoadIdentity();
        rlMultMatrixf(MatrixToFloat(MatrixPerspective(60 * DEG2RAD, (double)GetScreenWidth() / GetScreenHeight(), 0.3, fmax(settings_num("farclip") * 1.25 + 100, (HORIZON_REACH + 1) * 533.33))));   /* out to the far horizon (173s) */
        rlMatrixMode(RL_MODELVIEW);
        rlDisableBackfaceCulling();
        sky_draw(eye, &light);                           /* first, behind everything */
        {
            int htx, hty;
            maps_tile_of((float)elf.x, (float)elf.y, &htx, &hty);
            horizon_draw(htx, hty, tile_loaded, eye, &light);   /* low-detail tiles beyond the loaded ones (173s) */
        }
        ground_blob(at.x, at.y, (float)elf.z, 1.3f);     /* her shadow, a little wider than her shoulders */
        for (int i = 0; i < nothers; ++i)                /* theirs, sized by their display's scale */
            ground_blob((float)(other_at[i].x - ox), (float)(other_at[i].y - oy), (float)other_at[i].z, 1.3f * others[i].scale);
        ground_draw(eye, &light);
        doodads_draw(eye, &light);
        water_draw(eye, &light, clock_ms / 1000.0);       /* see-through, after the solid world */
        Matrix place = MatrixMultiply(MatrixRotateZ((float)elf.o + moves.body_turn), MatrixTranslate(at.x, at.y, (float)elf.z));
        if (!first_person) figure_draw(&her, model_sh, place);   /* first person: she isn't drawn (173m) */
        for (int i = 0; i < nothers; ++i)
            figure_draw(&others[i], model_sh, MatrixMultiply(MatrixRotateZ(other_at[i].facing),
                        MatrixTranslate((float)(other_at[i].x - ox), (float)(other_at[i].y - oy), (float)other_at[i].z)));
        EndMode3D();
        EndDrawing();

        /* --shot: after 3 world-seconds, the picture, then quit */
        if (shot && ++frames == 60 + (int)((walk_s + dive_s + wait_s) * 20)) {   /* 3 world-seconds after any walk: particles have filled out */
            Image im = LoadImageFromScreen();
            int ok = ExportImage(im, shot);
            UnloadImage(im);
            printf(ok ? "picture saved: %s\n" : "could not save the picture to %s\n", shot);
            int dm2, dc2, ds2, dmov2, demit2;
            doodads_counts(&dm2, &dc2, &ds2, &dmov2, &demit2);
            printf("tiles: %d loaded, %d dropped over the run; now %d placed, %d solid triangles\n", tiles_loaded, tiles_dropped, dc2, collide_count(solids));
            printf("she ended at x %.2f y %.2f z %.2f, %s\n", elf.x, elf.y, elf.z, elf.swimming ? "swimming" : elf.grounded ? "on the ground" : "in the air");
            break;
        }
    }
    CloseWindow();
    light_close(&lights);
    collide_free(solids);
    liquid_free(waters);
    figure_free(&her);
    for (int i = 0; i < nothers; ++i) figure_free(&others[i]);
    mpq_chain_close(&chain);
    maps_world_free(&world);
    return 0;
}
/* }}} */
