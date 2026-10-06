/*
 * m2.c (issue 173k) - see m2.h. Ported from src/custom-client/lib/m2.lua.
 */
#include "m2.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* {{{ static readers */
static uint32_t u16(const unsigned char *s, size_t at) { return (uint32_t)s[at] | ((uint32_t)s[at + 1] << 8); }
static uint32_t u32(const unsigned char *s, size_t at)
{
    return (uint32_t)s[at] | ((uint32_t)s[at + 1] << 8) | ((uint32_t)s[at + 2] << 16) | ((uint32_t)s[at + 3] << 24);
}
static float f32(const unsigned char *s, size_t at) { float f; uint32_t v = u32(s, at); memcpy(&f, &v, 4); return f; }
/* }}} */

/* {{{ m2_read */
int m2_read(const unsigned char *m2, size_t m2_len, const unsigned char *skin, size_t skin_len,
            M2Model *out, char *why, int why_len)
{
    memset(out, 0, sizeof *out);
    if (!m2 || m2_len < 136 || memcmp(m2, "MD20", 4) != 0) { snprintf(why, why_len, "not an M2 model (no MD20 mark)"); return -1; }
    if (u32(m2, 4) != 264) { snprintf(why, why_len, "model version %u; this reader knows 264 (3.3.5a)", u32(m2, 4)); return -1; }
    if (!skin || skin_len < 44 || memcmp(skin, "SKIN", 4) != 0) { snprintf(why, why_len, "the .skin file has no SKIN mark"); return -1; }

    uint32_t nv = u32(m2, 60), ov = u32(m2, 64);
    out->vertices = malloc(sizeof(M2Vertex) * (nv ? nv : 1));
    out->nvertices = nv;
    for (uint32_t i = 0; i < nv; ++i) {
        size_t at = ov + (size_t)i * 48;
        M2Vertex *v = &out->vertices[i];
        v->x = f32(m2, at); v->y = f32(m2, at + 4); v->z = f32(m2, at + 8);
        v->nx = f32(m2, at + 20); v->ny = f32(m2, at + 24); v->nz = f32(m2, at + 28);
        v->u = f32(m2, at + 32); v->v = f32(m2, at + 36);
    }

    uint32_t nt = u32(m2, 80), ot = u32(m2, 84);
    out->textures = calloc(nt ? nt : 1, sizeof(M2Texture));
    out->ntextures = nt;
    for (uint32_t i = 0; i < nt; ++i) {
        size_t at = ot + (size_t)i * 16;
        uint32_t len = u32(m2, at + 8), off = u32(m2, at + 12);
        out->textures[i].kind = u32(m2, at);
        if (len > 1 && len < sizeof out->textures[i].file) memcpy(out->textures[i].file, m2 + off, len - 1);
    }
    uint32_t nl = u32(m2, 128), ol = u32(m2, 132);

    /* the skin: which model point each skin point is, then the triangles */
    uint32_t ni = u32(skin, 4), oi = u32(skin, 8);
    uint32_t ntri = u32(skin, 12), otri = u32(skin, 16);
    out->indices = malloc(sizeof(uint32_t) * (ntri ? ntri : 1));
    out->nindices = ntri;
    for (uint32_t i = 0; i < ntri; ++i) {
        uint32_t k = u16(skin, otri + (size_t)i * 2);
        out->indices[i] = k < ni ? u16(skin, oi + (size_t)k * 2) : 0;
    }
    uint32_t np = u32(skin, 28), op = u32(skin, 32);
    out->pieces = malloc(sizeof(M2Piece) * (np ? np : 1));
    out->npieces = np;
    for (uint32_t i = 0; i < np; ++i) {
        size_t at = op + (size_t)i * 48;
        out->pieces[i].id = u16(skin, at);
        out->pieces[i].first = u16(skin, at + 8) + u16(skin, at + 2) * 65536;   /* the "level" field carries the high part */
        out->pieces[i].count = u16(skin, at + 10);
    }
    uint32_t nu = u32(skin, 36), ou = u32(skin, 40);
    out->units = malloc(sizeof(M2Unit) * (nu ? nu : 1));
    out->nunits = nu;
    for (uint32_t i = 0; i < nu; ++i) {
        size_t at = ou + (size_t)i * 24;
        uint32_t look = u16(skin, at + 16);
        out->units[i].piece = u16(skin, at + 4);
        out->units[i].texture = look < nl ? u16(m2, ol + (size_t)look * 2) : 0;
    }
    return 0;
}
/* }}} */

/* {{{ m2_free */
void m2_free(M2Model *m)
{
    free(m->vertices); free(m->textures); free(m->pieces); free(m->indices); free(m->units);
    memset(m, 0, sizeof *m);
}
/* }}} */
