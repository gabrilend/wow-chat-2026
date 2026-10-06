/*
 * test_client.c (issue 173k) - the C client's readers held to the same
 * facts as the Lua client's tests (scripts/test-custom-client and
 * scripts/test-client-models), on the same files, without a window.
 *
 * For a general audience: the C port must agree with the Lua original on
 * everything that can be measured: the ground's height at Astranaar, no
 * steps where map tiles meet, every movement speed, jump height, slopes
 * climbed and slid down, the archives' published keys, the night elf's
 * model and pictures, and which pieces of her show.
 *
 * Since 2026-10-06 the Lua client is deprecated (173k), and parts written
 * after that (the settings store, 173b1) are checked here on their own,
 * with no Lua twin.
 *
 * Usage: test-client PROJECT_DIR CLIENT_DATA_DIR
 */
#include "../adt.h"
#include "../anim.h"
#include "../blp.h"
#include "../camera.h"
#include "../character.h"
#include "../dbc.h"
#include "../m2.h"
#include "../maps.h"
#include "../mover.h"
#include "../moves.h"
#include "../mpq.h"
#include "../navmesh_slope.h"
#include "../settings.h"
#include "../wmo.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int checks, fails;

/* {{{ check */
static void check(int ok, const char *what)
{
    ++checks;
    if (ok) printf("  ok:   %s\n", what);
    else { printf("  FAIL: %s\n", what); ++fails; }
}
static int near(double a, double b, double tol) { return fabs(a - b) <= tol; }
/* }}} */

/* {{{ made-up grounds: height, then rise per yard along x and y, as the map gives */
static float g_flat(void *c, float x, float y, float *gx, float *gy) { (void)c; (void)x; (void)y; *gx = 0; *gy = 0; return 10; }
static float g_slope(void *c, float x, float y, float *gx, float *gy) { (void)c; (void)y; *gx = -0.5f; *gy = 0; return 10 - x * 0.5f; }
static float g_cliff(void *c, float x, float y, float *gx, float *gy) { (void)c; (void)y; *gx = 0; *gy = 0; return x < 3 ? 10 : -40; }
static double ramp_tan;
static float g_ramp(void *c, float x, float y, float *gx, float *gy)
{
    (void)c; (void)y;
    if (x < 2) { *gx = 0; *gy = 0; return 10; }
    *gx = (float)ramp_tan; *gy = 0;
    return (float)(10 + (x - 2) * ramp_tan);
}
static float g_world(void *c, float x, float y, float *gx, float *gy) { return maps_world_height((MapWorld *)c, x, y, gx, gy); }
/* }}} */

/* {{{ static run: seconds of steps of 0.01 s */
static void run(Mover *m, MoverInput in, double seconds, MoverGround g)
{
    int steps = (int)(seconds * 100 + 0.5);
    for (int i = 0; i < steps; ++i) mover_step(m, &in, 0.01, g, NULL);
}
/* }}} */

int main(int argc, char **argv)
{
    const char *dir = argc > 1 ? argv[1] : "/mnt/mtwo/games/azeroth-core/wow-chat-2026";
    const char *client = argc > 2 ? argv[2] : "/mnt/dile/ritz/games/World of Warcraft 3.3.5a/Data";
    char path[700], why[800], line[300];

    /* {{{ the ground */
    printf("the ground (server map files)\n");
    MapWorld *w = malloc(sizeof *w);
    snprintf(path, sizeof path, "%s/data-files/maps", dir);
    maps_world_init(w, path, 1);
    float gx, gy;
    float z = maps_world_height(w, 2828, -284, &gx, &gy);
    snprintf(line, sizeof line, "Astranaar's flight point stands at %.2f yards (Lua: 106.71)", z);
    check(near(z, 106.71, 0.01), line);
    float worst = 0;
    for (int edge = 25; edge <= 27; ++edge) {
        float x = (32 - edge) * MAPS_GRID_SIZE;
        for (int y = -900; y <= 100; y += 37) {
            float a = maps_world_height(w, x + 0.001f, (float)y, &gx, &gy), b = maps_world_height(w, x - 0.001f, (float)y, &gx, &gy);
            if (a > -10000 && b > -10000 && fabsf(a - b) > worst) worst = fabsf(a - b);
        }
    }
    snprintf(line, sizeof line, "no step where tiles meet (largest %.4f yards)", worst);
    check(worst < 0.05f, line);
    check(maps_world_height(w, 1e6f, 1e6f, &gx, &gy) < -10000, "far outside the world: no ground, not an error");
    /* }}} */

    /* {{{ movement */
    printf("movement at 120%% (made-up ground)\n");
    Mover m;
    MoverInput none = { 0 }, in;
    mover_init(&m, 0, 0, 10, 0, 1.2, 60); in = none; in.forward = 1; run(&m, in, 1, g_flat);
    check(near(m.x, 8.4, 1e-6) && near(m.y, 0, 1e-6), "a second forward: 8.4 yards north");
    mover_init(&m, 0, 0, 10, 0, 1.2, 60); in = none; in.back = 1; run(&m, in, 1, g_flat);
    check(near(m.x, -5.4, 1e-6), "a second back: 5.4 yards");
    mover_init(&m, 0, 0, 10, 0, 1.2, 60); in = none; in.strafe_right = 1; run(&m, in, 1, g_flat);
    check(near(m.y, -8.4, 1e-6) && near(m.x, 0, 1e-6), "a second strafing right (east, -y): 8.4");
    mover_init(&m, 0, 0, 10, 0, 1.2, 60); in = none; in.forward = 1; in.strafe_right = 1; run(&m, in, 1, g_flat);
    check(near(sqrt(m.x * m.x + m.y * m.y), 8.4, 1e-6), "forward and strafing together: still 8.4 yards a second");
    mover_init(&m, 0, 0, 10, 0, 1.2, 60); in = none; in.left = 1; run(&m, in, 1, g_flat);
    check(near(m.o, 3.14159265358979, 1e-6), "a second turning left: half a circle");
    mover_init(&m, 0, 0, 10, 0, 1.2, 60); in = none; in.right = 1; in.strafe_turns = 1; run(&m, in, 1, g_flat);
    check(near(m.o, 0, 1e-9) && near(m.y, -8.4, 1e-6), "with the right button held, D strafes instead of turning");

    mover_init(&m, 0, 0, 10, 0, 1.2, 60);
    in = none; in.jump = 1;
    mover_step(&m, &in, 0.001, g_flat, NULL);
    double top = 10;
    for (int i = 0; i < 200; ++i) { mover_step(&m, &none, 0.005, g_flat, NULL); if (m.z > top) top = m.z; }
    double expect = MOVER_JUMP * MOVER_JUMP / (2 * MOVER_GRAVITY);
    snprintf(line, sizeof line, "a jump rises %.3f yards (expected %.3f)", top - 10, expect);
    check(near(top - 10, expect, 0.02), line);
    check(m.grounded && m.z == 10, "and lands back on the ground");

    mover_init(&m, 0, 0, 10, 0, 1.2, 60); in = none; in.forward = 1; run(&m, in, 1, g_slope);
    check(m.grounded && near(m.z, 10 - m.x * 0.5, 1e-4), "walking down a slope stays on the ground");
    mover_init(&m, 0, 0, 10, 0, 1.2, 60); in = none; in.forward = 1; run(&m, in, 0.5, g_cliff);
    check(!m.grounded && m.z < 10 && m.z > -40, "walking off a cliff falls");
    run(&m, none, 3, g_cliff);
    check(m.grounded && m.z == -40, "and lands at the bottom");
    /* }}} */

    /* {{{ steep ground */
    printf("steep ground (the server's navigation rule)\n");
    snprintf(path, sizeof path, "%s/data-files/mmaps", dir);
    float limit = navmesh_slope_read(path, 1, why, sizeof why);
    snprintf(line, sizeof line, "the server's tiles for Kalimdor say %.1f degrees is the steepest walkable", limit);
    check(near(limit, 60, 1e-4), line);
    ramp_tan = tan(45 * 3.14159265358979 / 180);
    mover_init(&m, 0, 0, 10, 0, 1.2, limit); in = none; in.forward = 1; run(&m, in, 1, g_ramp);
    check(m.x > 6, "up a 45-degree ramp: walks on");
    ramp_tan = tan(70 * 3.14159265358979 / 180);
    mover_init(&m, 0, 0, 10, 0, 1.2, limit); run(&m, in, 1, g_ramp);
    check(m.x < 2.3 && m.z < 10.8, "into a 70-degree slope: stopped at its foot");
    mover_init(&m, 5, 0, 10 + 3 * ramp_tan, 0, 1.2, limit);
    mover_step(&m, &none, 0.01, g_ramp, NULL);
    check(m.sliding && m.x < 5, "on a 70-degree slope with no keys pressed: sliding down it");
    run(&m, none, 3, g_ramp);
    check(m.grounded && !m.sliding && m.x < 2 && m.z == 10, "and comes to rest on the flat at the bottom");
    ramp_tan = 1;
    mover_init(&m, 4, 0, 12, 0, 1.2, limit); run(&m, none, 1, g_ramp);
    check(near(m.x, 4, 1e-9) && !m.sliding, "on a 45-degree slope, standing still stays put");
    /* the real ground: a second's run from the start point stays on the map */
    mover_init(&m, 2717, -400, maps_world_height(w, 2717, -400, &gx, &gy), 3.6, 1.2, limit);
    in = none; in.forward = 1;
    for (int i = 0; i < 100; ++i) mover_step(&m, &in, 0.01, g_world, w);
    check(m.grounded, "a second's run from the start point on Ashenvale's real ground stays on it");
    /* }}} */

    /* {{{ the archives */
    printf("the archives\n");
    check(mpq_hash("(hash table)", 3) == 0xC3AF3770u, "the index's key is C3AF3770");
    check(mpq_hash("(block table)", 3) == 0xEC83B3A3u, "the block list's key is EC83B3A3");
    check(mpq_hash("a/b", 0) == mpq_hash("A\\B", 0), "names match without regard to case or slash");
    MpqChain chain;
    if (mpq_chain_open(&chain, client, "enUS", why, sizeof why)) { printf("  FAIL: %s\n", why); return 1; }
    snprintf(line, sizeof line, "all 13 of the client's archives open (%d)", chain.count);
    check(chain.count == 13, line);
    const char *base = "Character\\NightElf\\Female\\NightElfFemale";
    size_t m2_len, skin_len;
    const char *from = NULL;
    snprintf(path, sizeof path, "%s.m2", base);
    unsigned char *m2 = mpq_chain_read(&chain, path, &m2_len, &from);
    check(m2 && memcmp(m2, "MD20", 4) == 0, "her model is found and begins as a model does");
    check(from && strstr(from, "patch-3.MPQ") != NULL, "and it is the newest patch's copy (patch-3)");
    size_t nolen;
    check(mpq_chain_read(&chain, "No\\Such\\File.m2", &nolen, NULL) == NULL, "a file no archive holds is none, not an error");
    /* }}} */

    /* {{{ her model and pictures */
    printf("her model\n");
    snprintf(path, sizeof path, "%s00.skin", base);
    unsigned char *skin = mpq_chain_read(&chain, path, &skin_len, NULL);
    M2Model model;
    check(m2_read(m2, m2_len, skin, skin_len, &model, why, sizeof why) == 0, "her model and mesh read");
    float zmax = -1e9f;
    for (uint32_t i = 0; i < model.nvertices; ++i) if (model.vertices[i].z > zmax) zmax = model.vertices[i].z;
    snprintf(line, sizeof line, "she stands %.2f yards tall (Lua: 2.29)", zmax);
    check(near(zmax, 2.29, 0.02), line);
    snprintf(line, sizeof line, "%u triangles (Lua: 5148)", model.nindices / 3);
    check(model.nindices / 3 == 5148, line);
    int in_range = 1;
    for (uint32_t i = 0; i < model.nindices; ++i) if (model.indices[i] >= model.nvertices) in_range = 0;
    check(in_range, "every triangle's corners are real points of the model");
    check(model.textures[0].kind == 1 && model.textures[1].kind == 6, "her first picture is her skin, her second her hair");
    m2_free(&model);
    free(m2); free(skin);

    printf("pictures\n");
    size_t len;
    snprintf(path, sizeof path, "%sSkin00_00.blp", base);
    unsigned char *b = mpq_chain_read(&chain, path, &len, NULL);
    BlpImage img;
    check(b && blp_decode(b, len, &img, why, sizeof why) == 0 && img.width == 512 && img.height == 512, "her skin sheet decodes to 512 x 512");
    free(b);
    b = mpq_chain_read(&chain, "Character\\NightElf\\Hair00_00.blp", &len, NULL);
    BlpImage hair;
    int cut = 0;
    if (b && blp_decode(b, len, &hair, why, sizeof why) == 0)
        for (size_t i = 3; i < (size_t)hair.width * hair.height * 4; i += 4) if (hair.rgba[i] < 128) { cut = 1; break; }
    check(cut, "her hair picture has see-through strands (alpha)");
    free(b); blp_free(&hair);
    b = mpq_chain_read(&chain, "DBFilesClient\\CharSections.dbc", &len, NULL);
    Dbc d;
    check(dbc_open(&d, b, len, why, sizeof why) == 0 && d.rows > 1000, "the character pictures table reads (over a thousand rows)");
    free(b);
    /* }}} */

    /* {{{ putting her together */
    printf("putting her together\n");
    Character ch;
    CharacterLook look = { 4, 1, 0, 0, 0, 0 };
    int built = character_build(&chain, &look, &ch, why, sizeof why) == 0;
    check(built, built ? "she is put together" : why);
    if (built) {
        int body = 0, hair2 = 0, others = 0, clothes = 0, bare = 0;
        for (uint32_t i = 0; i < ch.model.npieces; ++i) {
            if (!ch.shown[i]) continue;
            uint32_t id = ch.model.pieces[i].id;
            if (id == 0) body = 1;
            if (id == 2) hair2 = 1;
            if (id >= 3 && id <= 13) others = 1;
            if (id == 1002 || id == 1102 || id == 1202 || id == 1302 || id == 1502 || id == 802) clothes = 1;
            if (id == 401 || id == 501 || id == 702) ++bare;
        }
        check(body && hair2, "her body (0) and hair style 0's piece (2) show");
        check(!others, "no other hair style shows");
        check(!clothes, "no clothing shapes show");
        check(bare == 3, "bare hands, bare feet, and her ears show");
        int changed = 0;
        for (int y = 384; y <= 511; y += 8)
            for (int x = 8; x <= 255; x += 8) {
                size_t o = ((size_t)y * 512 + x) * 4;
                if (ch.skin.rgba[o] != img.rgba[o]) ++changed;
            }
        snprintf(line, sizeof line, "her face is painted onto her skin sheet (%d of 512 samples changed; Lua: 393)", changed);
        check(changed == 393, line);
        check(ch.hair.width > 0, "her hair has its picture");
        character_free(&ch);
    }
    blp_free(&img);
    mpq_chain_close(&chain);
    /* }}} */

    /* {{{ the settings store (173b1) */
    printf("the settings store\n");
    settings_init();
    check(settings_num("cameraYawMoveSpeed") == 180 && !strcmp(settings_text("gxResolution"), "1280x720"),
          "every setting starts at its default (mouse look 180, window 1280x720)");
    check(settings_find("noSuchSetting") == NULL, "an unknown name finds nothing (code asking for it by settings_num stops the client)");
    check(settings_set("cameraYawMoveSpeed", "300", why, sizeof why) && strstr(why, "out of its range") && settings_num("cameraYawMoveSpeed") == 180,
          "a slider refuses a value past its range, says so, and keeps its value");
    check(settings_set("gxResolution", "wide", why, sizeof why) && settings_set("gxResolution", "9000x1000", why, sizeof why),
          "the resolution refuses words and sizes past 7680x4320");
    check(!settings_set("gxResolution", "5120x1440", why, sizeof why) && !settings_set("cameraYawMoveSpeed", "250.0", why, sizeof why)
          && settings_num("cameraYawMoveSpeed") == 250 && !strcmp(settings_text("cameraYawMoveSpeed"), "250"),
          "an ultrawide resolution and a slider value are accepted, the number kept in one written form");
    snprintf(path, sizeof path, "%s/tmp/shared-memory/test-settings.wtf", dir);
    check(!settings_save(path, why, sizeof why), "the changes are saved");
    FILE *saved = fopen(path, "r");
    char text[400] = "";
    size_t got = saved ? fread(text, 1, sizeof text - 1, saved) : 0;
    text[got] = '\0';
    if (saved) fclose(saved);
    check(!strcmp(text, "SET gxResolution \"5120x1440\"\nSET cameraYawMoveSpeed \"250\"\n"),
          "the file holds only the two changed settings, as SET name \"value\" lines");
    settings_init();
    char *log = NULL;
    size_t log_len = 0;
    FILE *report = open_memstream(&log, &log_len);
    int skipped = settings_load(path, report);
    fclose(report);
    check(skipped == 0 && log_len == 0 && settings_num("cameraYawMoveSpeed") == 250 && !strcmp(settings_text("gxResolution"), "5120x1440"),
          "loading it back gives the same values, with nothing to report");
    free(log);
    FILE *bad = fopen(path, "w");
    if (bad) {
        fputs("# a comment\n\nSET cameraDistanceMaxFactor \"1.5\"\nSET nonsense \"1\"\nSET cameraYawMoveSpeed \"20\"\njunk\n", bad);
        fclose(bad);
    }
    settings_init();
    log = NULL;
    report = open_memstream(&log, &log_len);
    skipped = settings_load(path, report);
    fclose(report);
    check(skipped == 3 && settings_num("cameraDistanceMaxFactor") == 1.5 && settings_num("cameraYawMoveSpeed") == 180,
          "a hand-edited file: the good line is taken, three bad lines are skipped");
    check(log && strstr(log, "line 4: no setting named nonsense") && strstr(log, "line 5: cameraYawMoveSpeed \"20\": out of its range (90 to 270)")
          && strstr(log, "line 6: not SET name"),
          "each bad line is reported with its line number and why");
    free(log);
    remove(path);
    settings_init();
    log = NULL;
    report = open_memstream(&log, &log_len);
    skipped = settings_load(path, report);
    fclose(report);
    check(skipped == 0 && log && strstr(log, "no file at") && settings_num("cameraDistanceMaxFactor") == 2,
          "no file yet: said once, every setting at its default");
    free(log);
    /* }}} */

    /* {{{ the ground files (173f) */
    printf("the ground files (the original's ADTs)\n");
    {
        MpqChain gc;
        if (mpq_chain_open(&gc, client, "enUS", why, sizeof why)) { check(0, why); goto ground_done; }
        size_t len;
        const char *from;
        unsigned char *s = mpq_chain_read(&gc, "World\\Maps\\Kalimdor\\Kalimdor.wdt", &len, &from);
        check(s && adt_wdt_big_alpha(s, len, why, sizeof why) == 0, "Kalimdor's blend maps are the 4-bit form");
        free(s);
        s = mpq_chain_read(&gc, "World\\Maps\\Northrend\\Northrend.wdt", &len, &from);
        check(s && adt_wdt_big_alpha(s, len, why, sizeof why) == 1, "Northrend's are the 8-bit form");
        free(s);

        AdtTile *t = malloc(sizeof *t);
        s = mpq_chain_read(&gc, "World\\Maps\\Kalimdor\\Kalimdor_32_26.adt", &len, &from);
        int bad = !s || adt_read(s, len, 0, t, why, sizeof why);
        free(s);
        check(!bad, bad ? why : "Astranaar's tile (Kalimdor_32_26) reads: 256 chunks");
        if (!bad) {
            int found = 0;
            for (int i = 0; i < t->ntextures; ++i) {
                unsigned char *p = mpq_chain_read(&gc, t->textures[i], &len, &from);
                if (p) ++found;
                free(p);
            }
            snprintf(line, sizeof line, "all %d of its ground pictures are in the archives (%d found; first %s)", t->ntextures, found, t->textures[0]);
            check(found == t->ntextures && t->ntextures > 0, line);
            int placed = 1;
            for (int k = 0; k < 256; ++k) {
                AdtChunk *c = &t->chunks[k];
                if (c->ix != k % 16 || c->iy != k / 16 || !near(c->x, 3200 - c->iy * ADT_CHUNK_SIZE, 0.01) || !near(c->y, 0 - c->ix * ADT_CHUNK_SIZE, 0.01)) placed = 0;
            }
            check(placed, "each chunk sits where its row and column say (rows run south, columns east)");
            /* the client's heights against the server's own map file, at
             * every corner and centre of every chunk */
            float worst_h = 0;
            const float step = ADT_CHUNK_SIZE / 8;
            for (int k = 0; k < 256; ++k)
                for (int i = 0; i < 145; ++i) {
                    AdtChunk *c = &t->chunks[k];
                    int r17 = i % 17;
                    float row = (float)(i / 17) + (r17 >= 9 ? 0.5f : 0.0f), col = r17 >= 9 ? (float)(r17 - 9) + 0.5f : (float)r17;
                    float hs = maps_world_height(w, c->x - row * step, c->y - col * step, &gx, &gy);
                    if (hs > -10000 && fabsf(hs - (c->z + c->heights[i])) > worst_h) worst_h = fabsf(hs - (c->z + c->heights[i]));
                }
            snprintf(line, sizeof line, "its 37,120 heights match the server's own map, within %.4f yards", worst_h);
            check(worst_h < 0.01f, line);
            /* 4-bit blend maps: an unpainted last column copies the one before */
            int fixed = 1, painted = 0;
            for (int k = 0; k < 256; ++k)
                for (int l = 1; l < t->chunks[k].nlayers; ++l) {
                    for (int r = 0; r < 64; ++r) if (t->chunks[k].alpha[l][r * 64 + 63] != t->chunks[k].alpha[l][r * 64 + 62]) fixed = 0;
                    for (int i = 0; i < 4096; ++i) if (t->chunks[k].alpha[l][i] != 0 && t->chunks[k].alpha[l][i] != 255) { painted = 1; break; }
                }
            /* placements (173g): doodads stand on the ground; turns go the original's way */
            int on_ground = 0, measured = 0;
            for (int k = 0; k < t->ndoodads; ++k) {
                float hs = maps_world_height(w, t->doodads[k].x, t->doodads[k].y, &gx, &gy);
                if (hs < -10000) continue;
                ++measured;
                if (fabsf(hs - t->doodads[k].z) < 2.0f) ++on_ground;
            }
            snprintf(line, sizeof line, "%d of its %d doodads stand within 2 yards of the server's ground (the rest on rocks, roots or buildings)", on_ground, measured);
            check(t->ndoodads > 500 && on_ground * 10 > measured * 8, line);
            check(t->nbuildings > 0 && t->nplaces > 0, "it places buildings too (WMOs)");
            AdtPlace turn = { .x = 0, .y = 0, .z = 0, .rot = { 0, 30, 0 }, .scale = 2 };
            float pm[16];
            adt_place_matrix(&turn, 0, 0, pm);
            double fx = pm[0], fy = pm[1], up = pm[10];            /* where the model's front (+x) and up (+z) go */
            snprintf(line, sizeof line, "a turn of 30 degrees faces a model's front at 210 degrees (%.1f), upright, twice the size",
                     atan2(fy, fx) / 3.14159265358979 * 180 + (atan2(fy, fx) < 0 ? 360 : 0));
            check(near(atan2(fy, fx), (210 - 360) * 3.14159265358979 / 180, 1e-4) && near(hypot(fx, fy), 2, 1e-4) && near(up, 2, 1e-4), line);
            /* buildings: each reads, and its furnishings land inside the box
             * the ground file gives the building */
            int roots = 0, groups_ok = 1, inside = 0, furnished = 0;
            for (int k = 0; k < t->nplaces; ++k) {
                AdtPlace *pl = &t->places[k];
                unsigned char *rs = mpq_chain_read(&gc, t->buildings[pl->name], &len, &from);
                WmoRoot root;
                if (!rs || wmo_read_root(rs, len, &root, why, sizeof why)) { free(rs); continue; }
                free(rs);
                ++roots;
                char base[260], gpath[300];
                snprintf(base, sizeof base, "%s", t->buildings[pl->name]);
                *strrchr(base, '.') = '\0';
                snprintf(gpath, sizeof gpath, "%s_000.wmo", base);
                unsigned char *gs = mpq_chain_read(&gc, gpath, &len, &from);
                WmoGroup g;
                if (!gs || wmo_read_group(gs, len, &g, why, sizeof why)) groups_ok = 0; else wmo_free_group(&g);
                free(gs);
                float bm[16], fm[16];
                adt_place_matrix(pl, 0, 0, bm);
                for (int si = 0; si < root.nsets; ++si) {
                    if (si != 0 && si != pl->doodad_set) continue;
                    for (int fi = root.sets[si].first; fi < root.sets[si].first + root.sets[si].count; ++fi) {
                        adt_inside_matrix(bm, root.furnishings[fi].pos, root.furnishings[fi].quat, root.furnishings[fi].scale, fm);
                        ++furnished;
                        int in = 1;
                        for (int a = 0; a < 3; ++a) if (fm[12 + a] < pl->lo[a] - 2 || fm[12 + a] > pl->hi[a] + 2) in = 0;
                        inside += in;
                    }
                }
                wmo_free_root(&root);
            }
            snprintf(line, sizeof line, "all %d of its building placements read, with their first parts", t->nplaces);
            check(roots == t->nplaces && groups_ok, line);
            snprintf(line, sizeof line, "%d of their %d furnishings land inside their building's box", inside, furnished);
            check(furnished > 0 && inside == furnished, line);
            check(fixed, "every blend map's last column copies the one before, as the original fills the unpainted edge");
            check(painted, "the blend maps hold soft edges, not only all-or-nothing");
            adt_free(t);
        }
        s = mpq_chain_read(&gc, "World\\Maps\\Northrend\\Northrend_30_20.adt", &len, &from);
        bad = !s || adt_read(s, len, 1, t, why, sizeof why);
        free(s);
        check(!bad, bad ? why : "a Northrend tile with packed and plain 8-bit blend maps reads (Northrend_30_20)");
        if (!bad) adt_free(t);
        free(t);
        mpq_chain_close(&gc);
    }
ground_done:
    /* }}} */

    /* {{{ her animations (173i) */
    printf("her animations\n");
    {
        MpqChain ac;
        if (mpq_chain_open(&ac, client, "enUS", why, sizeof why)) { check(0, why); goto anim_done; }
        size_t len;
        const char *from;
        const char *base = "Character\\NightElf\\Female\\NightElfFemale";
        snprintf(path, sizeof path, "%s.m2", base);
        unsigned char *s = mpq_chain_read(&ac, path, &len, &from);
        Anim a;
        int bad = !s || anim_read(s, len, &a, why, sizeof why);
        free(s);
        snprintf(line, sizeof line, "her skeleton reads (%d bones, %d animations, %u points)", bad ? 0 : a.nbones, bad ? 0 : a.nseqs, bad ? 0 : a.npoints);
        check(!bad && a.nbones > 50 && a.npoints == 4113, bad ? why : line);
        if (bad) { mpq_chain_close(&ac); goto anim_done; }
        int needed = 0, found = 0;
        for (int i = 0; i < a.nseqs; ++i) {
            if (!anim_needs_file(&a, i)) continue;
            ++needed;
            snprintf(path, sizeof path, "%s%04d-%02d.anim", base, a.seqs[i].id, a.seqs[i].variation);
            unsigned char *f = mpq_chain_read(&ac, path, &len, &from);
            if (f) { ++found; anim_attach_file(&a, i, f, len); }
        }
        snprintf(line, sizeof line, "all %d animations kept in .anim files are in the archives (%d found)", needed, found);
        check(found == needed, line);
        static const int USED[] = { MOVE_STAND, MOVE_RUN, MOVE_WALK_BACK, MOVE_SHUFFLE_LEFT, MOVE_SHUFFLE_RIGHT, MOVE_JUMP_START, MOVE_JUMP, MOVE_JUMP_END, MOVE_FALL };
        int all = 1;
        for (unsigned i = 0; i < sizeof USED / sizeof USED[0]; ++i) if (anim_find(&a, USED[i], 0) < 0) all = 0;
        check(all, "she has every animation the mover uses: stand, run, walk back, both turns, jump start, jump, jump end, fall");

        /* poses: her bent body, measured */
        float (*poses)[16] = malloc(sizeof *poses * a.nbones), (*scratch)[16] = malloc(sizeof *scratch * a.nbones);
        float *at0 = malloc(sizeof(float) * 3 * a.npoints), *at1 = malloc(sizeof(float) * 3 * a.npoints);
        uint32_t points_at = (uint32_t)(a.m2[64] | a.m2[65] << 8 | a.m2[66] << 16 | (uint32_t)a.m2[67] << 24);
        #define BEND(seq, ms, outp) do { \
            anim_pose(&a, (seq), (ms), 0, poses); \
            for (uint32_t i = 0; i < a.npoints; ++i) { float in[3]; memcpy(in, a.m2 + points_at + (size_t)i * 48, 12); \
                anim_skin_point(&a, (const float (*)[16])poses, i, in, (outp) + i * 3, NULL, NULL); } } while (0)
        int stand = anim_find(&a, MOVE_STAND, 0), run = anim_find(&a, MOVE_RUN, 0);
        BEND(stand, 0, at0);
        float lo = 1e9f, hi = -1e9f;
        for (uint32_t i = 0; i < a.npoints; ++i) { lo = fminf(lo, at0[i * 3 + 2]); hi = fmaxf(hi, at0[i * 3 + 2]); }
        snprintf(line, sizeof line, "standing, her feet are on the ground (lowest point %.3f) and she is %.2f yards tall", lo, hi);
        check(fabsf(lo) < 0.1f && hi > 1.9f && hi < 2.4f, line);
        BEND(run, 0, at0);
        BEND(run, a.seqs[run].length / 2, at1);
        float most = 0;
        for (uint32_t i = 0; i < a.npoints * 3; ++i) most = fmaxf(most, fabsf(at0[i] - at1[i]));
        snprintf(line, sizeof line, "half a stride apart, the run moves some point of her %.2f yards", most);
        check(most > 0.3f, line);
        BEND(run, a.seqs[run].length, at1);
        most = 0;
        for (uint32_t i = 0; i < a.npoints * 3; ++i) most = fmaxf(most, fabsf(at0[i] - at1[i]));
        check(most < 1e-4f, "the run's end is its start: it loops without a jump");
        #undef BEND

        /* choosing the animation */
        MovesState ms;
        moves_init(&ms, &a);
        check(ms.seq == stand, "she starts standing");
        MovesInput mi = { .forward = 1, .grounded = 1, .speed = 8.4f, .dt = 0.1f };
        moves_step(&ms, &a, &mi);
        snprintf(line, sizeof line, "running at 8.4 yards a second: the run, played %.0f ms in a tenth of a second (made for %.2f, so 121)", ms.ms, a.seqs[run].move_speed);
        check(ms.seq == run && near(ms.ms, 100 * 8.4 / a.seqs[run].move_speed, 0.5), line);
        check(ms.from == stand && ms.blend_left > 0, "and blends in from the stand");
        mi = (MovesInput){ .grounded = 0, .rising = 1, .dt = 0.01f };
        moves_step(&ms, &a, &mi);
        int jstart = anim_find(&a, MOVE_JUMP_START, 0), jump = anim_find(&a, MOVE_JUMP, 0);
        check(ms.seq == jstart, "leaving the ground going up: the jump's start");
        for (uint32_t t = 0; t < a.seqs[jstart].length + 20; t += 10) moves_step(&ms, &a, &mi);
        check(ms.seq == jump, "after it, the jump loops in the air");
        mi = (MovesInput){ .grounded = 1, .dt = 0.01f };
        moves_step(&ms, &a, &mi);
        check(ms.seq == anim_find(&a, MOVE_JUMP_END, 0), "landing standing still: the landing");
        moves_init(&ms, &a);
        mi = (MovesInput){ .grounded = 0, .rising = 0, .dt = 0.01f };
        moves_step(&ms, &a, &mi);
        check(ms.seq == anim_find(&a, MOVE_FALL, 0), "dropping off an edge: the fall");
        moves_init(&ms, &a);
        mi = (MovesInput){ .turn_left = 1, .grounded = 1, .dt = 0.01f };
        moves_step(&ms, &a, &mi);
        check(ms.seq == anim_find(&a, MOVE_SHUFFLE_LEFT, 0), "turning on the spot: the turning shuffle");
        mi = (MovesInput){ .strafe_left = 1, .grounded = 1, .speed = 8.4f, .dt = 0.01f };
        for (int i = 0; i < 50; ++i) moves_step(&ms, &a, &mi);
        snprintf(line, sizeof line, "strafing left: the run, her body turned %.0f degrees toward it", ms.body_turn / 3.14159265358979 * 180);
        check(ms.seq == run && near(ms.body_turn, 3.14159265358979 / 2, 1e-3), line);
        free(poses); free(scratch); free(at0); free(at1);
        anim_free(&a);
        mpq_chain_close(&ac);
    }
anim_done:
    /* }}} */

    /* {{{ the camera (173m) */
    printf("the camera\n");
    {
        settings_init();
        const double deg = 3.14159265358979323846 / 180;
        const float px90 = (float)(90 * deg / 0.006);          /* pixels of drag for 90 degrees at the default speed */
        FollowCamInput idle = { .dt = 0.01f }, held_l = { .left = 1, .dt = 0.01f };
        FollowCam cam;
        double facing;

        /* left drag 90 degrees, then a quarter second of running in style 1 */
        cam = (FollowCam){ .yaw = 0, .pitch = 0.35f, .dist = 12, .rest_pitch = 0.35f };
        facing = 0;
        FollowCamInput drag = { .left = 1, .dx = -px90, .dy = 50, .dt = 0.01f };
        camera_drag(&cam, &drag, 0, &facing);
        float pitch_after_drag = cam.pitch;
        check(near(cam.yaw, 90 * deg, 1e-4) && facing == 0, "a left drag turns the camera 90 degrees and not her");
        for (int i = 0; i < 25; ++i) camera_follow(&cam, &idle, 0, 1, facing);
        snprintf(line, sizeof line, "style 1, a quarter second running: the camera swings back 45 degrees at 180 a second (now %.2f degrees off)", cam.yaw / deg);
        check(near(cam.yaw, 45 * deg, 1e-3), line);
        check(cam.pitch == pitch_after_drag, "style 1 leaves the pitch where it was put");
        for (int i = 0; i < 50; ++i) camera_follow(&cam, &idle, 0, 1, facing);
        check(near(cam.yaw, 0, 1e-5), "and it comes to rest exactly behind her, without overshooting");

        /* standing still in style 1: nothing moves */
        cam.yaw = (float)(90 * deg);
        for (int i = 0; i < 100; ++i) camera_follow(&cam, &idle, 0, 0, facing);
        check(near(cam.yaw, 90 * deg, 1e-6), "style 1, standing still: the camera stays where it was put");

        /* a held button beats the style; letting go mid-run starts the swing that frame */
        for (int i = 0; i < 100; ++i) camera_follow(&cam, &held_l, 0, 1, facing);
        check(near(cam.yaw, 90 * deg, 1e-6), "running while the left button is held: no swing");
        camera_follow(&cam, &idle, 0, 1, facing);
        check(near(cam.yaw, 88.2 * deg, 1e-4), "letting go mid-run: the swing starts that same frame (1.8 degrees in a hundredth of a second)");

        /* the shorter way round */
        cam.yaw = (float)(350 * deg);
        camera_follow(&cam, &idle, 0, 1, facing);
        check(near(cam.yaw, 351.8 * deg, 1e-4), "from 350 degrees it swings on round through 360, the shorter way");

        /* style 4: the pitch returns too */
        check(!settings_set("cameraSmoothStyle", "4", why, sizeof why), "the style can be changed to 4 (only when moving)");
        cam = (FollowCam){ .yaw = (float)(30 * deg), .pitch = 1.0f, .dist = 12, .rest_pitch = 0.35f };
        for (int i = 0; i < 100; ++i) camera_follow(&cam, &idle, 0, 1, facing);
        check(near(cam.yaw, 0, 1e-5) && near(cam.pitch, 0.35, 1e-5), "style 4, running: heading and pitch both return to rest");

        /* style 2: also while standing; style 0: never */
        settings_set("cameraSmoothStyle", "2", why, sizeof why);
        cam.yaw = (float)(30 * deg);
        for (int i = 0; i < 100; ++i) camera_follow(&cam, &idle, 0, 0, facing);
        check(near(cam.yaw, 0, 1e-5), "style 2, standing still: still swings back behind her");
        settings_set("cameraSmoothStyle", "0", why, sizeof why);
        cam.yaw = (float)(30 * deg);
        for (int i = 0; i < 100; ++i) camera_follow(&cam, &idle, 0, 1, facing);
        check(near(cam.yaw, 30 * deg, 1e-6), "style 0, running: never moves on its own");
        check(settings_set("cameraSmoothStyle", "3", why, sizeof why) != 0, "a style the table doesn't have is refused by the store");

        /* follow speed */
        settings_set("cameraSmoothStyle", "1", why, sizeof why);
        settings_set("cameraYawSmoothSpeed", "90", why, sizeof why);
        cam.yaw = (float)(90 * deg);
        for (int i = 0; i < 100; ++i) camera_follow(&cam, &idle, 0, 1, facing);
        check(near(cam.yaw, 0, 1e-4), "Auto Follow Speed 90: a full second to swing back 90 degrees");
        settings_set("cameraYawSmoothSpeed", "180", why, sizeof why);

        /* the keys turn the camera with her, unless the left button holds it */
        cam.yaw = 0;
        camera_follow(&cam, &idle, 0.5, 0, 0.5);
        check(near(cam.yaw, 0.5, 1e-6), "turning her with the keys turns the camera with her");
        camera_follow(&cam, &held_l, 0.5, 0, 1.0);
        check(near(cam.yaw, 0.5, 1e-6), "but not while the left button holds the camera");

        /* the right button */
        cam = (FollowCam){ .yaw = (float)(90 * deg), .pitch = 0.35f, .dist = 12, .rest_pitch = 0.35f };
        facing = 0;
        FollowCamInput press_r = { .right = 1, .dt = 0.01f };
        camera_drag(&cam, &press_r, 0, &facing);
        check(near(facing, 90 * deg, 1e-5), "pressing the right button turns her to where the camera looks");
        FollowCamInput drag_r = { .right = 1, .dx = px90, .dt = 0.01f };
        camera_drag(&cam, &drag_r, 1, &facing);
        check(near(facing, 0, 1e-4) && near(cam.yaw, 0, 1e-4), "a right drag turns her and the camera together");

        /* mouse look speed and invert */
        cam.pitch = 0.35f;
        FollowCamInput down = { .left = 1, .dy = 10, .dt = 0.01f };
        camera_drag(&cam, &down, 0, &facing);
        check(near(cam.pitch, 0.35 + 0.06, 1e-5), "dragging down 10 pixels raises the camera 0.06 radians");
        settings_set("mouseInvertPitch", "1", why, sizeof why);
        camera_drag(&cam, &down, 0, &facing);
        check(near(cam.pitch, 0.35, 1e-5), "with Invert Mouse, the same drag lowers it");
        settings_set("cameraYawMoveSpeed", "90", why, sizeof why);
        cam.yaw = 0;
        camera_drag(&cam, &(FollowCamInput){ .left = 1, .dx = -px90, .dt = 0.01f }, 0, &facing);
        check(near(cam.yaw, 45 * deg, 1e-4), "Mouse Look Speed 90: the same drag turns half as far");
        settings_init();
    }
    /* }}} */

    maps_world_free(w);
    free(w);
    if (fails == 0) printf("All %d checks passed\n", checks);
    else printf("%d of %d checks failed\n", fails, checks);
    return fails ? 1 : 0;
}
