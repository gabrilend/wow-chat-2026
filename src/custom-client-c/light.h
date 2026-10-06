/*
 * light.h (issue 173n) - the zone's light, by place and time of day
 *
 * For a general audience: the original lights each part of the world by
 * its own tables. Light.dbc places light spheres on each map (Ashenvale
 * has its own, as does Astranaar's valley), plus one default per map for
 * anywhere no sphere reaches. Each light names a parameter set whose
 * colours (LightIntBand.dbc: the sun's light, the shade's light, five sky
 * colours from overhead to the horizon, the fog's colour, and more) and
 * distances (LightFloatBand.dbc: how far the fog ends, and where it
 * starts) each change through the day: a list of up to 16 (time, value)
 * pairs, blended between. This reads those tables and answers "what is
 * the light here, now?".
 *
 * Layouts (3.3.5a):
 *   Light: 1 id, 2 map, 3-5 position (x, y, z, all times 36, in
 *     placement space: world x = 17066.67 - z/36, world y = 17066.67 -
 *     x/36, height y/36), 6 inner radius, 7 outer radius (times 36), 8
 *     clear-weather parameter set. A light at position 0, 0, 0 is the
 *     map's default.
 *   LightIntBand: 1 id (= set * 18 - 17 + band), 2 count, 3-18 times
 *     (half-minutes since midnight, 0-2880), 19-34 colours (0xRRGGBB).
 *     Bands used: 0 sun, 1 shade (ambient), 2-6 sky overhead to horizon,
 *     7 fog, 14-15 ocean near and deep, 16-17 river near and deep (173r).
 *   LightFloatBand: 1 id (= set * 6 - 5 + band), 2 count, 3-18 times,
 *     19-34 values. Band 0: where the fog ends (times 36), band 1: where it
 *     starts, as a share of that.
 *
 * Inside a sphere's inner radius its light is used whole; between inner
 * and outer it blends into whatever lies beyond (the default, or a
 * larger sphere), by distance.
 *
 * A LightNow, field by field (colours are red, green, blue, 0 to 1):
 *   sun[3], shade[3]     the sun's light and the light in shadow
 *   sky[5][3]            the sky's colours, overhead first, horizon last
 *   fog[3]               the fog's colour
 *   water[4][3]          ocean near, ocean deep, river near, river deep
 *   fog_start, fog_end   float, yards
 *   sun_dir[3]           a unit vector toward the sun (world axes)
 */
#ifndef EG_LIGHT_H
#define EG_LIGHT_H

#include "dbc.h"
#include "mpq.h"

typedef struct {
    float sun[3], shade[3];
    float sky[5][3];
    float fog[3];
    float water[4][3];
    float fog_start, fog_end;
    float sun_dir[3];
} LightNow;

typedef struct {
    unsigned char *files[3];          /* the tables' bytes, kept while open */
    Dbc light, ints, floats;
} LightTables;

int  light_open(LightTables *t, MpqChain *chain, char *why, int why_len);
void light_close(LightTables *t);

/* The light at world (x, y, z) on map `map` at `hours` since midnight
 * (0-24). Returns the id of the light whose colours weigh most (for
 * reports), or -1 when the map has no lights at all (then `out` holds a
 * plain grey day, and the caller is told). */
int  light_at(const LightTables *t, int map, float x, float y, float z, float hours, LightNow *out);

#endif
