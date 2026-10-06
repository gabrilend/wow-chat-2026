/*
 * adt.c (issue 173f) - the original client's ground files; see adt.h
 *
 * For a general audience: takes one ground file apart into its 256
 * chunks, each with its heights, its up-to-four ground pictures and how
 * strongly each shows at every point, and its baked shadow.
 */
#include "adt.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* {{{ readers: little-endian numbers at a byte offset */
static uint32_t u32(const unsigned char *s, size_t at) { return s[at] | s[at + 1] << 8 | s[at + 2] << 16 | (uint32_t)s[at + 3] << 24; }
static float    f32(const unsigned char *s, size_t at) { uint32_t u = u32(s, at); float f; memcpy(&f, &u, 4); return f; }
/* a block's tag reads as text reversed: "MCNK" is stored "KNCM" */
static int is_tag(const unsigned char *s, size_t at, const char *tag)
{
    return s[at] == tag[3] && s[at + 1] == tag[2] && s[at + 2] == tag[1] && s[at + 3] == tag[0];
}
/* }}} */

/* {{{ adt_wdt_big_alpha */
int adt_wdt_big_alpha(const unsigned char *s, size_t len, char *why, int why_len)
{
    for (size_t at = 0; at + 8 <= len; at += 8 + u32(s, at + 4))
        if (is_tag(s, at, "MPHD")) {
            if (at + 12 > len) break;
            return (u32(s, at + 8) & 0x4) ? 1 : 0;
        }
    snprintf(why, why_len, "the map's WDT file has no MPHD block (read %zu bytes)", len);
    return -1;
}
/* }}} */

/* {{{ static read_alpha: one layer's 64 x 64 strengths from MCAL
 * 4-bit: two points a byte, low half first, each 0-15 scaled to 0-255.
 *   Unless the chunk says otherwise (flags 0x8000), the last row and
 *   column were never painted and copy the ones before them, as the
 *   original client does.
 * 8-bit plain: 4096 bytes.
 * 8-bit packed: runs; a byte's high bit says "repeat the next byte" (set)
 *   or "copy the next bytes" (clear), its low 7 bits how many.
 * Returns the bytes used, or 0 when the data runs out. */
static size_t read_alpha(const unsigned char *s, size_t avail, int big, int packed, int fix, uint8_t *out)
{
    if (!big) {
        if (avail < 2048) return 0;
        for (int i = 0; i < 2048; ++i) {
            out[i * 2]     = (uint8_t)((s[i] & 0x0f) * 17);
            out[i * 2 + 1] = (uint8_t)((s[i] >> 4) * 17);
        }
        if (fix)
            for (int r = 0; r < 64; ++r) {
                out[r * 64 + 63] = out[r * 64 + 62];
                if (r == 63) memcpy(out + 63 * 64, out + 62 * 64, 64);
            }
        return 2048;
    }
    if (!packed) {
        if (avail < 4096) return 0;
        memcpy(out, s, 4096);
        return 4096;
    }
    size_t at = 0;
    int n = 0;
    while (n < 4096) {
        if (at >= avail) return 0;
        int fill = s[at] & 0x80, count = s[at] & 0x7f;
        ++at;
        for (int k = 0; k < count && n < 4096; ++k) {
            if (at >= avail) return 0;
            out[n++] = s[at];
            if (!fill) ++at;
        }
        if (fill) ++at;
    }
    return at;
}
/* }}} */

/* {{{ static read_chunk: one MCNK block, `at` at its tag */
static int read_chunk(const unsigned char *s, size_t len, size_t at, int big_alpha, AdtChunk *c, char *why, int why_len)
{
    size_t size = u32(s, at + 4), h = at + 8;
    if (h + 128 > len || at + 8 + size > len) { snprintf(why, why_len, "MCNK block at byte %zu runs past the file's end", at); return 1; }
    uint32_t flags = u32(s, h);
    c->ix = (int)u32(s, h + 4);
    c->iy = (int)u32(s, h + 8);
    c->nlayers = (int)u32(s, h + 12);
    c->holes = (uint16_t)u32(s, h + 60);
    c->x = f32(s, h + 104);
    c->y = f32(s, h + 108);
    c->z = f32(s, h + 112);
    if (c->ix > 15 || c->iy > 15 || c->nlayers < 1 || c->nlayers > 4) {
        snprintf(why, why_len, "MCNK at byte %zu: index (%d, %d) or layer count %d out of range", at, c->ix, c->iy, c->nlayers);
        return 1;
    }
    /* each sub-block found by its header offset, its tag checked */
    #define SUB(off, tag, need) \
        size_t off##_at = at + u32(s, h + (off)); \
        if (off##_at + 8 + (need) > at + 8 + size || !is_tag(s, off##_at, tag)) { \
            snprintf(why, why_len, "chunk (%d, %d): no %s block where its header says (byte %zu)", c->ix, c->iy, tag, off##_at); \
            return 1; }
    enum { OFS_MCVT = 20, OFS_MCLY = 28, OFS_MCAL = 36, OFS_MCSH = 44 };
    SUB(OFS_MCVT, "MCVT", 145 * 4)
    for (int i = 0; i < 145; ++i) c->heights[i] = f32(s, OFS_MCVT_at + 8 + i * 4);
    SUB(OFS_MCLY, "MCLY", (size_t)c->nlayers * 16)
    size_t mcal_at = at + u32(s, h + OFS_MCAL), mcal_size = 0;
    if (c->nlayers > 1) {
        if (mcal_at + 8 > at + 8 + size || !is_tag(s, mcal_at, "MCAL")) {
            snprintf(why, why_len, "chunk (%d, %d): %d layers but no MCAL block where its header says", c->ix, c->iy, c->nlayers);
            return 1;
        }
        /* the size comes from the chunk header (offset 40, which counts
         * MCAL's own 8-byte head), not from MCAL's size field: in packed
         * tiles that field can be far too small (Northrend_30_20 chunk 0:
         * 512 in MCAL, 3688 in the header, and the blend maps use 3680) */
        uint32_t told = u32(s, h + 40);
        if (told < 8 || mcal_at + told > at + 8 + size) {
            snprintf(why, why_len, "chunk (%d, %d): its header gives MCAL %u bytes, which doesn't fit in the chunk", c->ix, c->iy, told);
            return 1;
        }
        mcal_size = told - 8;
    }
    memset(c->alpha[0], 255, 4096);
    for (int l = 0; l < c->nlayers; ++l) {
        size_t ly = OFS_MCLY_at + 8 + (size_t)l * 16;
        c->tex[l] = (int)u32(s, ly);
        uint32_t lflags = u32(s, ly + 4), offset = u32(s, ly + 8);
        if (l == 0) continue;
        if (!(lflags & 0x100)) { memset(c->alpha[l], 0, 4096); continue; }   /* a layer with no blend map doesn't show */
        if (offset >= mcal_size || !read_alpha(s + mcal_at + 8 + offset, mcal_size - offset, big_alpha, (lflags & 0x200) != 0,
                                               !(flags & 0x8000), c->alpha[l])) {
            snprintf(why, why_len, "chunk (%d, %d) layer %d: its blend map runs past MCAL's end (offset %u of %zu)", c->ix, c->iy, l, offset, mcal_size);
            return 1;
        }
    }
    /* the shadow is optional: a chunk with none is all lit */
    memset(c->shadow, 0, 4096);
    if (u32(s, h + 48) >= 512) {
        SUB(OFS_MCSH, "MCSH", 512)
        for (int i = 0; i < 4096; ++i) c->shadow[i] = (s[OFS_MCSH_at + 8 + i / 8] >> (i % 8)) & 1;
    }
    /* colour tints, when the chunk says it has them */
    memset(c->tint, 127, sizeof c->tint);
    if (flags & 0x40) {
        enum { OFS_MCCV = 116 };
        SUB(OFS_MCCV, "MCCV", 145 * 4)
        for (int i = 0; i < 145; ++i) {
            c->tint[i][0] = s[OFS_MCCV_at + 8 + i * 4 + 2];
            c->tint[i][1] = s[OFS_MCCV_at + 8 + i * 4 + 1];
            c->tint[i][2] = s[OFS_MCCV_at + 8 + i * 4];
        }
    }
    #undef SUB
    return 0;
}
/* }}} */

/* {{{ adt_read */
int adt_read(const unsigned char *s, size_t len, int big_alpha, AdtTile *out, char *why, int why_len)
{
    memset(out, 0, sizeof *out);
    int nchunks = 0;
    for (size_t at = 0; at + 8 <= len; at += 8 + u32(s, at + 4)) {
        size_t size = u32(s, at + 4);
        if (at + 8 + size > len) { snprintf(why, why_len, "a block at byte %zu says it is %zu bytes, past the file's end (%zu)", at, size, len); adt_free(out); return 1; }
        if (is_tag(s, at, "MTEX")) {
            int n = 0;
            for (size_t i = 0; i < size; ++i) if (s[at + 8 + i] == 0) ++n;
            out->textures = calloc(n ? n : 1, sizeof *out->textures);
            const char *name = (const char *)s + at + 8;
            for (int k = 0; k < n; ++k) {
                snprintf(out->textures[k], sizeof out->textures[k], "%s", name);
                name += strlen(name) + 1;
            }
            out->ntextures = n;
        } else if (is_tag(s, at, "MCNK")) {
            if (nchunks == 256) { snprintf(why, why_len, "more than 256 MCNK blocks"); adt_free(out); return 1; }
            AdtChunk c;
            if (read_chunk(s, len, at, big_alpha, &c, why, why_len)) { adt_free(out); return 1; }
            out->chunks[c.iy * 16 + c.ix] = c;
            ++nchunks;
        }
    }
    if (nchunks != 256) { snprintf(why, why_len, "%d MCNK blocks, not 256", nchunks); adt_free(out); return 1; }
    for (int i = 0; i < 256; ++i)
        for (int l = 0; l < out->chunks[i].nlayers; ++l)
            if (out->chunks[i].tex[l] < 0 || out->chunks[i].tex[l] >= out->ntextures) {
                snprintf(why, why_len, "chunk %d layer %d names picture %d; the tile lists %d", i, l, out->chunks[i].tex[l], out->ntextures);
                adt_free(out);
                return 1;
            }
    return 0;
}
void adt_free(AdtTile *t) { free(t->textures); t->textures = NULL; t->ntextures = 0; }
/* }}} */
