/*
 * ground.h (issue 173f) - the painted ground
 *
 * For a general audience: draws the ground as the original client paints
 * it. For each map tile near her it reads the tile's ground file (adt.h),
 * makes one small mesh per 33-yard chunk from its heights, loads the
 * chunk's ground pictures (each loaded once and shared), and packs the
 * chunk's blend maps into one small picture: red, green and blue say how
 * strongly layers 1, 2 and 3 show, alpha holds the baked shadow (for
 * 173h). A shader then blends the pictures point by point, lights them by
 * the sun and fades them into the sky, as the first-light ground was.
 *
 * Drawing needs Raylib and a window; reading (adt.c) doesn't, and is what
 * the tests check.
 */
#ifndef EG_GROUND_H
#define EG_GROUND_H

#include "maps.h"
#include "mpq.h"
#include "raylib.h"

/* Readies the painter for one map: `map_name` is the map's folder in the
 * archives ("Kalimdor"); the chain stays open and must outlive the painter.
 * Reads the map's WDT for its blend-map form. 0, or 1 with `why`. */
int  ground_init(MpqChain *chain, const char *map_name, char *why, int why_len);

/* Loads tile (tx, ty), placed relative to the drawing origin (ox, oy).
 * Light comes from the server's heights in `world` (the same ground; the
 * tests hold the two together), smooth across chunk and tile edges.
 * 0 loaded; 1 the map has no ground file there (open sea); -1 an error,
 * with `why`. */
int  ground_load_tile(int tx, int ty, double ox, double oy, MapWorld *world, char *why, int why_len);

/* Draws every loaded tile. `eye` is the camera's position (for the fog). */
void ground_draw(Vector3 eye, const float sky[3]);

#endif
