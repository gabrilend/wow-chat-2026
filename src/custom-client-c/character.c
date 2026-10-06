/*
 * character.c (issue 173k) - see character.h. Ported from
 * src/custom-client/lib/character.lua.
 */
#include "character.h"

#include "dbc.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* {{{ races: ChrRaces ids and their model folder names */
static const char *race_folder(int race)
{
    static const char *const NAMES[12] = { NULL, "Human", "Orc", "Dwarf", "NightElf", "Scourge", "Tauren", "Gnome", "Troll",
                                           NULL, "BloodElf", "Draenei" };
    return (race >= 0 && race < 12) ? NAMES[race] : NULL;
}
/* }}} */

/* {{{ the skin sheet's patches
 * Where each picture goes, as the 3.3.5a client has it built in, for a
 * 256 x 256 sheet (x, y, width, height); doubled for 512 x 512 sheets. */
enum { R_FACE_UPPER, R_FACE_LOWER, R_TORSO_UPPER, R_LEG_UPPER };
static const int REGION[4][4] = {
    { 0, 160, 128, 32 },          /* face upper */
    { 0, 192, 128, 64 },          /* face lower */
    { 128, 0, 128, 64 },          /* torso upper */
    { 128, 96, 128, 64 },         /* leg upper */
};
/* }}} */

/* {{{ static naked
 * Which pieces show on a naked character besides the body (0) and the hair
 * style: 401 bare hands, 501 bare feet, 702 ears, 1301 bare legs, 1501 the
 * back without a cape. Everything else belongs to clothes or effects. */
static int naked(uint32_t id) { return id == 401 || id == 501 || id == 702 || id == 1301 || id == 1501; }
/* }}} */

/* {{{ static paste
 * Lays `img` onto `sheet` (RGBA, sw wide) inside region r scaled by k,
 * stretched by nearest pixel, blended by the picture's own alpha. */
static void paste(uint8_t *sheet, int sw, const BlpImage *img, const int *r, int k)
{
    int rx = r[0] * k, ry = r[1] * k, rw = r[2] * k, rh = r[3] * k;
    for (int y = 0; y < rh; ++y) {
        int sy = y * img->height / rh;
        for (int x = 0; x < rw; ++x) {
            int sx = x * img->width / rw;
            const uint8_t *s = img->rgba + ((size_t)sy * img->width + sx) * 4;
            double a = s[3] / 255.0;
            if (a > 0) {
                uint8_t *o = sheet + ((size_t)(ry + y) * sw + rx + x) * 4;
                for (int c = 0; c < 3; ++c) o[c] = (uint8_t)(o[c] * (1 - a) + s[c] * a + 0.5);
                o[3] = 255;
            }
        }
    }
}
/* }}} */

/* {{{ static picture */
static int picture(MpqChain *c, const char *name, BlpImage *img, char *why, int why_len)
{
    size_t len;
    unsigned char *s = mpq_chain_read(c, name, &len, NULL);
    if (!s) { snprintf(why, why_len, "the client's archives hold no %s", name); return -1; }
    char w2[200];
    int rc = blp_decode(s, len, img, w2, sizeof w2);
    free(s);
    if (rc) snprintf(why, why_len, "%s: %s", name, w2);
    return rc;
}
/* }}} */

/* {{{ character_build */
int character_build(MpqChain *archives, const CharacterLook *look, Character *out, char *why, int why_len)
{
    memset(out, 0, sizeof *out);
    const char *folder = race_folder(look->race);
    if (!folder) { snprintf(why, why_len, "no model folder known for race %d", look->race); return -1; }
    const char *sexname = look->sex == 1 ? "Female" : "Male";
    char base[200], name[260];
    snprintf(base, sizeof base, "Character\\%s\\%s\\%s%s", folder, sexname, folder, sexname);

    size_t m2_len, skin_len;
    snprintf(name, sizeof name, "%s.m2", base);
    unsigned char *m2 = mpq_chain_read(archives, name, &m2_len, NULL);
    snprintf(name, sizeof name, "%s00.skin", base);
    unsigned char *skin = mpq_chain_read(archives, name, &skin_len, NULL);
    if (!m2 || !skin) { free(m2); free(skin); snprintf(why, why_len, "the client's archives hold no %s model or skin", base); return -1; }
    char w2[300];
    int rc = m2_read(m2, m2_len, skin, skin_len, &out->model, w2, sizeof w2);
    free(m2); free(skin);
    if (rc) { snprintf(why, why_len, "%s: %s", base, w2); return -1; }

    /* the hair style's piece (CharHairGeosets: ID, race, sex, variation, geoset, ...) */
    size_t len;
    unsigned char *t = mpq_chain_read(archives, "DBFilesClient\\CharHairGeosets.dbc", &len, NULL);
    Dbc d;
    if (dbc_open(&d, t, len, w2, sizeof w2)) { free(t); snprintf(why, why_len, "CharHairGeosets: %s", w2); return -1; }
    long hair_piece = -1;
    for (uint32_t r = 0; r < d.rows; ++r)
        if ((int)dbc_u32(&d, r, 2) == look->race && (int)dbc_u32(&d, r, 3) == look->sex && (int)dbc_u32(&d, r, 4) == look->hair_style)
            hair_piece = dbc_u32(&d, r, 5);
    free(t);
    if (hair_piece < 0) { snprintf(why, why_len, "no hair style %d for race %d sex %d", look->hair_style, look->race, look->sex); return -1; }

    out->shown = calloc(out->model.npieces ? out->model.npieces : 1, 1);
    for (uint32_t i = 0; i < out->model.npieces; ++i) {
        uint32_t id = out->model.pieces[i].id;
        out->shown[i] = id == 0 || id == (uint32_t)hair_piece || naked(id);
    }

    /* the pictures: CharSections rows are ID, race, sex, section (0 skin,
     * 1 face, 2 facial hair, 3 hair, 4 underwear), three texture names,
     * flags, variation, colour */
    t = mpq_chain_read(archives, "DBFilesClient\\CharSections.dbc", &len, NULL);
    if (dbc_open(&d, t, len, w2, sizeof w2)) { free(t); snprintf(why, why_len, "CharSections: %s", w2); return -1; }
    char sect[5][3][260];
    int have[5] = { 0 };
    for (uint32_t r = 0; r < d.rows; ++r) {
        if ((int)dbc_u32(&d, r, 2) != look->race || (int)dbc_u32(&d, r, 3) != look->sex) continue;
        int s = (int)dbc_u32(&d, r, 4), variation = (int)dbc_u32(&d, r, 9), colour = (int)dbc_u32(&d, r, 10);
        int want_v, want_c;
        switch (s) {                          /* which variation and colour each section wants */
            case 0: want_v = 0;                want_c = look->skin;       break;
            case 1: want_v = look->face;       want_c = look->skin;       break;
            case 3: want_v = look->hair_style; want_c = look->hair_color; break;
            case 4: want_v = 0;                want_c = look->skin;       break;
            default: continue;
        }
        if (variation == want_v && colour == want_c) {
            for (int k = 0; k < 3; ++k) snprintf(sect[s][k], 260, "%s", dbc_text(&d, r, 5 + k));
            have[s] = 1;
        }
    }
    free(t);
    if (!have[0]) { snprintf(why, why_len, "no skin colour %d", look->skin); return -1; }

    /* the skin sheet: body, then face, scalp, underwear on top */
    if (picture(archives, sect[0][0], &out->skin, why, why_len)) return -1;
    int k = out->skin.width / 256;
    struct { int s, t, region; } lays[] = {
        { 1, 0, R_FACE_LOWER }, { 1, 1, R_FACE_UPPER },
        { 3, 1, R_FACE_LOWER }, { 3, 2, R_FACE_UPPER },
        { 4, 0, R_LEG_UPPER },  { 4, 1, R_TORSO_UPPER },
    };
    for (size_t i = 0; i < sizeof lays / sizeof lays[0]; ++i) {
        if (!have[lays[i].s] || !sect[lays[i].s][lays[i].t][0]) continue;
        BlpImage img;
        if (picture(archives, sect[lays[i].s][lays[i].t], &img, why, why_len)) return -1;
        paste(out->skin.rgba, out->skin.width, &img, REGION[lays[i].region], k);
        blp_free(&img);
    }
    if (have[3] && sect[3][0][0] && picture(archives, sect[3][0], &out->hair, why, why_len)) return -1;
    return 0;
}
/* }}} */

/* {{{ character_free */
void character_free(Character *c)
{
    m2_free(&c->model);
    free(c->shown);
    blp_free(&c->skin);
    blp_free(&c->hair);
}
/* }}} */
