/*
 * water.h (issue 173r) - drawing the water
 *
 * For a general audience: each ground file's water layers (adt.h) become
 * flat-ish meshes over their wet cells, at the surface heights the file
 * gives. Each kind of water (LiquidType.dbc) has a numbered run of
 * pictures (lake_a.1.blp, lake_a.2.blp ...) shown one after another so
 * the surface ripples. Water and the sea are tinted by the zone's water
 * colours (light.h: river and ocean, near and deep, by time of day) and
 * drawn see-through over the ground, after the solid world; lava and
 * slime are drawn as their pictures, unlit and solid.
 */
#ifndef EG_WATER_H
#define EG_WATER_H

#include "adt.h"
#include "light.h"
#include "mpq.h"
#include "raylib.h"

/* Reads the liquid table; the chain must outlive the drawer. 0, or 1
 * with `why`. */
int  water_init(MpqChain *chain, char *why, int why_len);

/* Adds a tile's water (tile = tx * 64 + ty), placed relative to the
 * drawing origin; drops it again (173s). */
void water_add_tile(const AdtTile *t, int tile, double ox, double oy);
void water_drop_tile(int tile);

/* Draws all water at `seconds` since start (the ripples' clock). */
void water_draw(Vector3 eye, const LightNow *light, double seconds);

#endif
