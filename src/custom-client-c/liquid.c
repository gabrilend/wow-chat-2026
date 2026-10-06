/*
 * liquid.c (issue 173r) - where the water is; see liquid.h
 *
 * For a general audience: one list of water layers per chunk, found by
 * the chunk a spot lies in; within a layer's wet cell, the surface is
 * blended between the cell's corners.
 */
#include "liquid.h"

#include <math.h>
#include <stdlib.h>
#include <string.h>

/* {{{ the store: per chunk of the world (64 tiles x 16 chunks a side),
 * the layers on it, in a hash of chains */
#define BUCKETS 16384
typedef struct { int gx, gy; AdtLiquid q; float x0, y0; int next; int tile; } Layer;   /* x0, y0: the chunk's north-west corner */
struct LiquidWorld { Layer *layers; int n, cap; int head[BUCKETS]; };
static unsigned hash(int gx, int gy) { return ((unsigned)gx * 2654435761u ^ (unsigned)gy * 40503u) % BUCKETS; }
LiquidWorld *liquid_new(void)
{
    LiquidWorld *w = calloc(1, sizeof *w);
    for (int i = 0; i < BUCKETS; ++i) w->head[i] = -1;
    return w;
}
void liquid_free(LiquidWorld *w) { free(w->layers); free(w); }
/* }}} */

/* {{{ liquid_add_tile */
void liquid_add_tile(LiquidWorld *w, int tx, int ty, const AdtTile *t)
{
    for (int i = 0; i < t->nliquids; ++i) {
        const AdtLiquid *q = &t->liquids[i];
        const AdtChunk *c = &t->chunks[q->chunk];
        if (w->n == w->cap) { w->cap = w->cap ? w->cap * 2 : 256; w->layers = realloc(w->layers, sizeof *w->layers * w->cap); }
        Layer *l = &w->layers[w->n];
        /* the world's chunk grid: rows run south with world x, columns
         * east with world y, as tiles do (maps.h) */
        l->gx = tx * 16 + c->iy;
        l->gy = ty * 16 + c->ix;
        l->q = *q;
        l->tile = tx * 64 + ty;
        l->x0 = c->x;
        l->y0 = c->y;
        unsigned h = hash(l->gx, l->gy);
        l->next = w->head[h];
        w->head[h] = w->n++;
    }
}
/* }}} */

/* {{{ liquid_drop_tile: the kept layers close up and are chained afresh */
void liquid_drop_tile(LiquidWorld *w, int tx, int ty)
{
    int tile = tx * 64 + ty, kept = 0;
    for (int i = 0; i < w->n; ++i) if (w->layers[i].tile != tile) w->layers[kept++] = w->layers[i];
    if (kept == w->n) return;
    w->n = kept;
    for (int i = 0; i < BUCKETS; ++i) w->head[i] = -1;
    for (int i = 0; i < w->n; ++i) {
        unsigned h = hash(w->layers[i].gx, w->layers[i].gy);
        w->layers[i].next = w->head[h];
        w->head[h] = i;
    }
}
/* }}} */

/* {{{ liquid_surface */
float liquid_surface(const LiquidWorld *w, double x, double y, int *kind)
{
    const double grid = 533.33333 / 16, step = grid / 8;
    int gx = (int)floor((32.0 * 533.33333 - x) / grid), gy = (int)floor((32.0 * 533.33333 - y) / grid);
    float best = -100000.0f;
    for (int i = w->head[hash(gx, gy)]; i >= 0; i = w->layers[i].next) {
        const Layer *l = &w->layers[i];
        if (l->gx != gx || l->gy != gy) continue;
        double fr = (l->x0 - x) / step, fc = (l->y0 - y) / step;   /* cell row and column, with fractions */
        int r = (int)fr, c = (int)fc;
        if (r < 0 || r > 7 || c < 0 || c > 7 || !l->q.wet[r][c]) continue;
        float u = (float)(fc - c), v = (float)(fr - r);
        float h = (l->q.height[r][c] * (1 - u) + l->q.height[r][c + 1] * u) * (1 - v)
                + (l->q.height[r + 1][c] * (1 - u) + l->q.height[r + 1][c + 1] * u) * v;
        if (h > best) { best = h; *kind = l->q.kind; }
    }
    return best;
}
/* }}} */
