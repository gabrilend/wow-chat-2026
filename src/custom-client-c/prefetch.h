/*
 * prefetch.h (issue 173u) - reading ahead of her, on a second thread
 *
 * For a general audience: when she walks into a new map tile, the client
 * loads that tile's ground, buildings and doodads, and most of the time
 * that takes is unpacking their files out of the game's archives. This
 * runs a helper thread that is told which tiles she is likely to reach
 * next (the ring just beyond those loaded) and unpacks their files ahead
 * of time into the archive reader's memory (mpq.h): the tile's ground
 * file, each doodad's model and skin and the pictures it names, each
 * building's root, parts and pictures. When the tile really loads, its
 * files are already unpacked. The helper only reads; it draws nothing and
 * changes nothing the main thread uses except that shared memory (which
 * the archive reader guards with a lock).
 */
#ifndef EG_PREFETCH_H
#define EG_PREFETCH_H

#include "mpq.h"

/* Starts the helper for map `map_name` (its tiles are
 * World\Maps\<map>\<map>_<ty>_<tx>.adt); the chain must outlive it. */
void prefetch_start(MpqChain *chain, const char *map_name);

/* Asks for tile (tx, ty) to be read ahead (once; repeats are ignored). */
void prefetch_tile(int tx, int ty);

/* Waits until every asked-for tile is read (for the tests and pictures). */
void prefetch_wait(void);

/* How many tiles the helper has read ahead, and the files it unpacked. */
void prefetch_counts(int *tiles, int *files);

/* Stops the helper (it finishes the tile it is on). */
void prefetch_stop(void);

#endif
