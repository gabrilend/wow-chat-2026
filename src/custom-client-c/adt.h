/*
 * adt.h (issue 173f) - the original client's ground files
 *
 * For a general audience: the game keeps each 533-yard square of a map in
 * its own ground file (an "ADT", World\Maps\<map>\<map>_<ty>_<tx>.adt, the
 * west-east tile number first). Each file is cut into 16 x 16 chunks of
 * 33.3 yards. For every chunk it holds the ground's heights, and up to
 * four ground pictures (grass, dirt, rock ...) with a blend map for each
 * picture above the first, saying how strongly it shows at each of
 * 64 x 64 points. The client paints the ground by blending them. It also
 * holds a baked shadow map per chunk (173h) and the list of trees,
 * rocks and buildings placed on the tile (173g, not read here yet).
 *
 * File layout (3.3.5a; little-endian; every block is a four-letter tag
 * stored reversed, then its size, then its data): MVER, MHDR, MCIN,
 * MTEX (the tile's picture names, each ended by a zero byte), MMDX, MMID,
 * MWMO, MWID, MDDF, MODF, MH2O, then 256 MCNK blocks, one per chunk.
 *
 * MCNK header (128 bytes), the fields read here, by byte offset:
 *    0 flags (0x8000: the blend maps' last row and column are real, not
 *      to be copied from the row and column before them)
 *    4 index x (west to east, 0-15)        8 index y (north to south)
 *   12 layer count (1-4)                  20 offset of MCVT (heights)
 *   24 offset of MCNR (normals)           28 offset of MCLY (layers)
 *   36 offset of MCAL (blend maps)        40 MCAL's size, counting its own
 *                                            8-byte head (trusted over the
 *                                            size inside MCAL, which can be
 *                                            wrong in packed tiles)
 *   44 offset of MCSH (shadow)            48 MCSH's size
 *   60 holes (16 bits: 4 x 4, each bit hiding 2 x 2 cells)
 *  104 position: world x (north), world y (west), base height
 *  116 offset of MCCV (colour tints; present when flags & 0x40)
 * Offsets count from the MCNK tag and point at each block's own tag.
 *
 * MCVT: 145 floats, heights above the base: a row of 9 corners, then a
 * row of 8 cell centres, and so on ((9 + 8) x 8 + 9). Rows run south
 * (world x falls by 33.3 / 8 yards a row) and columns run east (world y
 * falls); adt_corner / adt_centre give the index. Checked against the
 * server's own heights for the same ground (tests/test_client.c).
 * MCLY: 16 bytes a layer: picture number in MTEX, flags (0x100: has a
 * blend map; 0x200: the blend map is run-length packed), its offset in
 * MCAL, a ground-effect number.
 * MCAL: per layer above the first, 64 x 64 strengths. The map's WDT says
 * which form: 4 bits a point (2048 bytes; Kalimdor) or 8 bits (4096,
 * plain or packed).
 * MCSH: 64 x 64 bits, 8 bytes a row, lowest bit first; 1 = shadowed.
 * MCCV: 145 colours (blue, green, red, alpha bytes), one per height, in
 *   MCVT's order; 127 means "unchanged", so the ground's colour is
 *   multiplied by value / 127 (0 to 2). Added in 3.3.5a.
 *
 * An AdtTile, field by field:
 *   textures     char[nt][128]: the picture names (MTEX), in file order
 *   ntextures    int
 *   chunks[256]  AdtChunk, by row (index y) * 16 + column (index x)
 * An AdtChunk:
 *   ix, iy       int: column (west to east) and row (north to south)
 *   x, y, z      float: world position of the chunk's north-west corner,
 *                and the height the 145 heights are added to
 *   heights[145] float: above z, MCVT order
 *   holes        uint16_t: MCNK's low-resolution hole bits
 *   nlayers      int, 1-4
 *   tex[4]       int: each layer's picture number (into textures)
 *   alpha[4][4096] uint8_t: each layer's strength, 0-255, row by row
 *                (row = south, column = east); layer 0's is all 255
 *   shadow[4096] uint8_t: 1 where shadowed, 0 where lit
 *   tint[145][3] uint8_t: red, green, blue per height, 127 = unchanged
 *                (all 127 when the chunk has no MCCV)
 */
#ifndef EG_ADT_H
#define EG_ADT_H

#include <stddef.h>
#include <stdint.h>

#define ADT_CHUNK_SIZE  (533.33333f / 16)   /* yards a chunk side */

typedef struct {
    int      ix, iy;
    float    x, y, z;
    float    heights[145];
    uint16_t holes;
    int      nlayers;
    int      tex[4];
    uint8_t  alpha[4][4096];
    uint8_t  shadow[4096];
    uint8_t  tint[145][3];
} AdtChunk;

typedef struct {
    char   (*textures)[128];
    int      ntextures;
    AdtChunk chunks[256];
} AdtTile;

/* Whether a map's blend maps are 8 bits a point, from its WDT file
 * (MPHD flags & 0x4). Returns 1 or 0, or -1 with `why` set when the WDT
 * can't be read. */
int adt_wdt_big_alpha(const unsigned char *s, size_t len, char *why, int why_len);

/* Reads one ground file. 0 on success; otherwise `why` names what was
 * wrong and where (block tag, chunk index). `out` is large (about 5 MB):
 * allocate it, don't put it on the stack. */
int adt_read(const unsigned char *s, size_t len, int big_alpha, AdtTile *out, char *why, int why_len);
void adt_free(AdtTile *t);

/* MCVT index of corner (row 0-8, col 0-8) and centre (row 0-7, col 0-7). */
static inline int adt_corner(int row, int col) { return row * 17 + col; }
static inline int adt_centre(int row, int col) { return row * 17 + 9 + col; }

#endif
