/*
 * doodads.h (issue 173g) - trees, rocks and other small models on the map
 *
 * For a general audience: every ground file lists the small models placed
 * on its tile (trees, rocks, fences, lamps: "doodads"), each with a
 * position, a turn and a size. This loads each model once (its points,
 * pieces and pictures, through m2.c and blp.c) and draws all its copies
 * in one go per piece (instancing), standing in their resting pose.
 * A doodad standing on two tiles is listed in both with one unique id,
 * and drawn once.
 *
 * How a placement becomes a position and a turn is adt_place_matrix
 * (adt.h), shared with the buildings.
 */
#ifndef EG_DOODADS_H
#define EG_DOODADS_H

#include "adt.h"
#include "mpq.h"
#include "raylib.h"

/* Readies the drawer; the chain must outlive it. 0, or 1 with `why`. */
int  doodads_init(MpqChain *chain, char *why, int why_len);

/* Adds a tile's doodads, placed relative to the drawing origin (ox, oy),
 * loading any model not seen before. A model that can't be read is
 * reported once by name and left out; 0, or -1 with `why` for a fault
 * that stops the client (the graphics card refusing a shader). */
int  doodads_add_tile(const AdtTile *t, double ox, double oy, char *why, int why_len);

/* Draws every doodad. `eye` is the camera's position (for the fog). */
void doodads_draw(Vector3 eye, const float sky[3]);

/* Bends every moving model (one whose standing animation moves: trees
 * swaying) to its pose at `ms` since start; all copies share it. */
void doodads_animate(uint32_t ms);

/* How many models and copies are loaded, how many pieces were left out
 * because their picture is chosen by the game at run time, and how many
 * models move (for the start-up report). */
void doodads_counts(int *models, int *copies, int *skipped_pieces, int *moving);

#endif
