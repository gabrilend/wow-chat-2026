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
enum { R_ARM_UPPER, R_ARM_LOWER, R_HAND, R_FACE_UPPER, R_FACE_LOWER, R_TORSO_UPPER, R_TORSO_LOWER, R_LEG_UPPER, R_LEG_LOWER, R_FOOT };
static const int REGION[10][4] = {
    { 0, 0, 128, 64 },            /* arm upper */
    { 0, 64, 128, 64 },           /* arm lower */
    { 0, 128, 128, 32 },          /* hand */
    { 0, 160, 128, 32 },          /* face upper */
    { 0, 192, 128, 64 },          /* face lower */
    { 128, 0, 128, 64 },          /* torso upper */
    { 128, 64, 128, 32 },         /* torso lower */
    { 128, 96, 128, 64 },         /* leg upper */
    { 128, 160, 128, 64 },        /* leg lower */
    { 128, 224, 128, 32 },        /* foot */
};
/* an item's picture for each region: ItemDisplayInfo's fields 16-23, in
 * the region's own folder (Item\TextureComponents\<folder>\<name>_<F, M or
 * U>.blp: the wearer's sex, or U for either) */
static const struct { int field, region; const char *folder; } ITEM_REGION[8] = {
    { 16, R_ARM_UPPER, "ArmUpperTexture" },   { 17, R_ARM_LOWER, "ArmLowerTexture" },
    { 18, R_HAND, "HandTexture" },            { 19, R_TORSO_UPPER, "TorsoUpperTexture" },
    { 20, R_TORSO_LOWER, "TorsoLowerTexture" }, { 21, R_LEG_UPPER, "LegUpperTexture" },
    { 22, R_LEG_LOWER, "LegLowerTexture" },   { 23, R_FOOT, "FootTexture" },
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

/* {{{ static picture
 * -1 and `why` on a fault; -2 when the archives hold no such file (the
 * layers above the skin treat that as "not painted", see below). */
static int picture(MpqChain *c, const char *name, BlpImage *img, char *why, int why_len)
{
    size_t len;
    unsigned char *s = mpq_chain_read(c, name, &len, NULL);
    if (!s) { snprintf(why, why_len, "the client's archives hold no %s", name); return -2; }
    char w2[200];
    int rc = blp_decode(s, len, img, w2, sizeof w2);
    free(s);
    if (rc) snprintf(why, why_len, "%s: %s", name, w2);
    return rc;
}
/* }}} */

/* {{{ static wear: each slot's item painted onto the skin sheet, and the
 * body pieces it asks for switched on (173p)
 * ItemDisplayInfo (3.3.5a): 1 id, 2-3 model names, 4-5 model pictures,
 * 8-10 its piece choices (gg[0..2]), 16-23 its region pictures.
 * The pieces, this client's reading of the original's rule (to check
 * against it): a group g shows piece g*100 + variant, variant 1 when
 * bare. Shirt and chest: sleeves g8 = 1 + gg0, g10 = 1 + gg1, and a robe
 * (gg2) its skirt g13 = 1 + gg2 (chest only). Legs: g9 = 1 + gg0, g11 =
 * 1 + gg1 when gg1, g13 = 1 + gg2 when gg2. Feet g5, hands g4, waist g18,
 * back (the cape) g15 = 1 + gg0; the tabard g12 = 2. Slots are applied in
 * their painting order, so a robe's skirt wins over the legs'. A group
 * with no piece of the chosen variant shows nothing (said once). */
static int wear(MpqChain *archives, const CharacterLook *look, Character *out, int k, char *why, int why_len)
{
    int any = 0;
    for (int s = 0; s < SLOT_COUNT; ++s) any |= look->items[s] != 0;
    if (!any) return 0;
    size_t len;
    unsigned char *t = mpq_chain_read(archives, "DBFilesClient\\ItemDisplayInfo.dbc", &len, NULL);
    Dbc d;
    char w2[300];
    if (!t || dbc_open(&d, t, len, w2, sizeof w2)) { free(t); snprintf(why, why_len, "ItemDisplayInfo: %s", t ? w2 : "not in the archives"); return -1; }
    int variant[20];
    for (int g = 0; g < 20; ++g) variant[g] = -1;
    for (int s = 0; s < SLOT_COUNT; ++s) {
        if (!look->items[s]) continue;
        int row = -1;
        for (uint32_t r = 0; r < d.rows; ++r) if ((int)dbc_u32(&d, r, 1) == look->items[s]) { row = (int)r; break; }
        if (row < 0) { fprintf(stderr, "character: no item look %d in ItemDisplayInfo; slot %d is left bare\n", look->items[s], s); continue; }
        int gg[3] = { (int)dbc_u32(&d, (uint32_t)row, 8), (int)dbc_u32(&d, (uint32_t)row, 9), (int)dbc_u32(&d, (uint32_t)row, 10) };
        switch (s) {
            case SLOT_SHIRT: case SLOT_CHEST:
                variant[8] = 1 + gg[0]; variant[10] = 1 + gg[1];
                if (s == SLOT_CHEST && gg[2]) variant[13] = 1 + gg[2];
                break;
            case SLOT_LEGS:
                variant[9] = 1 + gg[0];
                if (gg[1]) variant[11] = 1 + gg[1];
                if (gg[2]) variant[13] = 1 + gg[2];
                break;
            case SLOT_FEET:   variant[5] = 1 + gg[0]; break;
            case SLOT_HANDS:  variant[4] = 1 + gg[0]; break;
            case SLOT_WAIST:  variant[18] = 1 + gg[0]; break;
            case SLOT_BACK:   variant[15] = 1 + gg[0]; break;
            case SLOT_TABARD: variant[12] = 2; break;
            default: break;
        }
        /* the region pictures, the wearer's sex first, then either sex */
        for (int r = 0; r < 8; ++r) {
            const char *name = dbc_text(&d, (uint32_t)row, (uint32_t)ITEM_REGION[r].field);
            if (!name || !name[0]) continue;
            char path[300];
            BlpImage img;
            snprintf(path, sizeof path, "Item\\TextureComponents\\%s\\%s_%s.blp", ITEM_REGION[r].folder, name, look->sex == 1 ? "F" : "M");
            int got = picture(archives, path, &img, w2, sizeof w2);
            if (got == -2) {
                snprintf(path, sizeof path, "Item\\TextureComponents\\%s\\%s_U.blp", ITEM_REGION[r].folder, name);
                got = picture(archives, path, &img, w2, sizeof w2);
            }
            if (got == -2) { fprintf(stderr, "character: item look %d's %s picture %s is in no archive; left unpainted\n", look->items[s], ITEM_REGION[r].folder, name); continue; }
            if (got) { free(t); snprintf(why, why_len, "%s", w2); return -1; }
            paste(out->skin.rgba, out->skin.width, &img, REGION[ITEM_REGION[r].region], k);
            blp_free(&img);
        }
    }
    free(t);
    /* the pieces: each chosen group shows its variant alone */
    for (int g = 1; g < 20; ++g) {
        if (variant[g] < 0) continue;
        uint32_t want = (uint32_t)(g * 100 + variant[g]);
        int found = 0;
        for (uint32_t i = 0; i < out->model.npieces; ++i) {
            uint32_t id = out->model.pieces[i].id;
            if (id / 100 != (uint32_t)g) continue;
            out->shown[i] = id == want;
            found |= id == want;
        }
        /* variant 1 missing is a group with nothing bare (sleeves, belts):
         * no fault; a missing higher variant is the item asking for a
         * shape the model lacks, said once */
        if (!found && variant[g] > 1) fprintf(stderr, "character: the model has no piece %u (group %d's choice); the group shows nothing\n", want, g);
    }
    return 0;
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
    snprintf(out->base, sizeof out->base, "%s", base);

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

    /* the skin sheet: body, then face, scalp, underwear on top. The body
     * must exist. A layer above it that CharSections names but the
     * archives lack is left unpainted, as the original leaves it (found
     * with a tauren man: CharSections names Character\Tauren\
     * ScalpUpperHair00_00.blp, which no archive holds); each such layer
     * is reported by name. */
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
        int got = picture(archives, sect[lays[i].s][lays[i].t], &img, why, why_len);
        if (got == -2) { fprintf(stderr, "character: %s; that layer is left unpainted\n", why); continue; }
        if (got) return -1;
        paste(out->skin.rgba, out->skin.width, &img, REGION[lays[i].region], k);
        blp_free(&img);
    }
    /* the fur (kind 8): the skin row's second picture, where the race has
     * one (a tauren's tail and coat; found 2026-10-06, the owner's missing
     * tail: the pieces using it were skipped for want of a picture) */
    if (sect[0][1][0]) {
        int got = picture(archives, sect[0][1], &out->fur, why, why_len);
        if (got == -2) fprintf(stderr, "character: %s; the fur is left unpainted\n", why);
        else if (got) return -1;
    }
    if (have[3] && sect[3][0][0]) {
        int got = picture(archives, sect[3][0], &out->hair, why, why_len);
        if (got == -2) fprintf(stderr, "character: %s; the hair is left unpainted\n", why);
        else if (got) return -1;
    }
    return wear(archives, look, out, k, why, why_len);
}
/* }}} */

/* {{{ character_free */
void character_free(Character *c)
{
    m2_free(&c->model);
    free(c->shown);
    blp_free(&c->skin);
    blp_free(&c->hair);
    blp_free(&c->fur);
}
/* }}} */
