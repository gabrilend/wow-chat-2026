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
#include "../blp.h"
#include "../camera.h"
#include "../character.h"
#include "../dbc.h"
#include "../m2.h"
#include "../maps.h"
#include "../mover.h"
#include "../mpq.h"
#include "../navmesh_slope.h"
#include "../settings.h"

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
