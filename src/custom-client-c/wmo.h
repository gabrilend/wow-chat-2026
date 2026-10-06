/*
 * wmo.h (issue 173g) - the game's buildings
 *
 * For a general audience: a building (Astranaar's inn, a cave, a bridge)
 * is a "world map object" (WMO). It comes as a root file, which lists its
 * pictures and materials, how many parts ("groups") it has, and the
 * furnishings placed inside it (barrels, lamps: small models, in named
 * sets), and one file per group (<name>_000.wmo, _001 ...) holding that
 * part's points and triangles, cut into batches of one material each.
 * Points are in the same model space as small models (x front, y left,
 * z up), so a building is placed with the same matrix (adt_place_matrix).
 *
 * Layouts (3.3.5a, version 17; blocks as in ground files: a reversed
 * four-letter tag, a size, then data).
 * Root: MOHD (header: 4 group count, 16 furnishing name count, 20
 *   furnishing count, 24 set count), MOTX (picture names, zero-ended, at
 *   offsets), MOMT (64 bytes a material: 0 flags, 8 blend mode, 12 first
 *   picture's MOTX offset), MODS (32 bytes a set: 20-byte name, 20 first
 *   furnishing, 24 count), MODN (furnishing model names), MODD (40 bytes a
 *   furnishing: 0 name offset in MODN (low 24 bits), 4 position (3
 *   floats), 16 turn (quaternion x, y, z, w), 32 scale, 36 colour).
 * Group: MOGP's 68-byte header (8 flags: 0x2000 indoors, 0x4 has vertex
 *   colours), then inside MOGP: MOPY, MOVI (u16 triangle corners), MOVT
 *   (points), MONR (facings), MOTV (picture positions), MOBA (24 bytes a
 *   batch: 12 first index (u32), 16 count (u16), 23 material (u8)), MOCV
 *   (colours, blue-green-red-alpha: indoor groups' baked light).
 *
 * Material flags: 0x1 unlit, 0x2 no fog, 0x4 two-sided. Blend modes as
 * in models (m2.h): 0 opaque, 1 cut-out, 2 see-through, 3+ added light.
 */
#ifndef EG_WMO_H
#define EG_WMO_H

#include <stddef.h>
#include <stdint.h>

typedef struct { float x, y, z, nx, ny, nz, u, v; uint8_t r, g, b, a; } WmoVertex;
typedef struct { uint32_t first, count; int material; } WmoBatch;

typedef struct {
    uint32_t   flags;                 /* MOGP flags: 0x2000 indoors */
    int        has_colours;           /* MOCV present */
    WmoVertex *vertices;  uint32_t nvertices;
    uint16_t  *indices;   uint32_t nindices;
    WmoBatch  *batches;   int      nbatches;
} WmoGroup;

typedef struct { uint32_t flags, blend; char picture[260]; } WmoMaterial;
typedef struct { char model[260]; float pos[3]; float quat[4]; float scale; } WmoFurnishing;
typedef struct { char name[24]; int first, count; } WmoSet;

typedef struct {
    int            ngroups;
    WmoMaterial   *materials;    int nmaterials;
    WmoFurnishing *furnishings;  int nfurnishings;
    WmoSet        *sets;         int nsets;
} WmoRoot;

int  wmo_read_root(const unsigned char *s, size_t len, WmoRoot *out, char *why, int why_len);
int  wmo_read_group(const unsigned char *s, size_t len, WmoGroup *out, char *why, int why_len);
void wmo_free_root(WmoRoot *r);
void wmo_free_group(WmoGroup *g);

#endif
