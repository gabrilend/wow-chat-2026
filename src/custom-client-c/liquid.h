/*
 * liquid.h (issue 173r) - where the water is, for the mover
 *
 * For a general audience: keeps every water layer of every loaded tile
 * (adt.h's AdtLiquid), filed by chunk, and answers "how high is the
 * water's surface here, and what kind of water is it?". The surface
 * between a cell's four corners is blended, as the ground's is.
 * Buildings' pools (WMO MLIQ) are not here yet.
 */
#ifndef EG_LIQUID_H
#define EG_LIQUID_H

#include "adt.h"

typedef struct LiquidWorld LiquidWorld;

LiquidWorld *liquid_new(void);
void         liquid_free(LiquidWorld *w);

/* Files tile (tx, ty)'s water layers (from its ground file). */
void  liquid_add_tile(LiquidWorld *w, int tx, int ty, const AdtTile *t);

/* Forgets tile (tx, ty)'s water (the tile is dropped, 173s). */
void  liquid_drop_tile(LiquidWorld *w, int tx, int ty);

/* The highest water surface at world (x, y): its height, and its kind
 * (LiquidType.dbc id) in *kind; below -10000 when there is no water. */
float liquid_surface(const LiquidWorld *w, double x, double y, int *kind);

#endif
