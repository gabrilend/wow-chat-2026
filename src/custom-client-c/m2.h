/*
 * m2.h (issue 173k; the C twin of lib/m2.lua) - the game's models
 *
 * For a general audience: a model comes as two files: the .m2 holds every
 * corner point (where, which way its surface faces, where on its picture
 * it sits) and its list of pictures; the .skin file holds how the points
 * join into triangles, grouped into pieces ("geosets": the body, each hair
 * style, bare hands or gloves...), and which picture each piece uses. A
 * character's model holds every hair style and clothing shape at once;
 * character.c picks the ones that show. Resting pose (no bones yet).
 *
 * Layouts: the 3.3.5a client's (model version 264); see lib/m2.lua for
 * every offset, which this follows exactly.
 */
#ifndef EG_M2_H
#define EG_M2_H

#include <stddef.h>
#include <stdint.h>

typedef struct { float x, y, z, nx, ny, nz, u, v; } M2Vertex;          /* model space: +x front, +y left, +z up */
typedef struct { uint32_t kind; char file[260]; } M2Texture;          /* kind 0 named file; 1 skin; 2 cape; 6 hair; ... */
typedef struct { uint32_t id, first, count; } M2Piece;                 /* id = group * 100 + variant; first/count: triangle indices */
typedef struct { uint32_t piece, texture; } M2Unit;                    /* 0-based into pieces and textures */

typedef struct {
    M2Vertex  *vertices;  uint32_t nvertices;
    M2Texture *textures;  uint32_t ntextures;
    M2Piece   *pieces;    uint32_t npieces;
    uint32_t  *indices;   uint32_t nindices;       /* model vertex numbers, three a triangle */
    M2Unit    *units;     uint32_t nunits;
} M2Model;

int  m2_read(const unsigned char *m2, size_t m2_len, const unsigned char *skin, size_t skin_len,
             M2Model *out, char *why, int why_len);
void m2_free(M2Model *m);

#endif
