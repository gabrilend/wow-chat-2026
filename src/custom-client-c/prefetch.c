/*
 * prefetch.c (issue 173u) - reading ahead of her, on a second thread; see prefetch.h
 *
 * For a general audience: a queue of tiles, a thread that takes them one
 * at a time, and for each the list of files the tile will want, read
 * through the archive reader (which keeps them). Reading a file it
 * already holds costs a copy, so asking twice is cheap; each tile is
 * still asked only once.
 */
#include "prefetch.h"
#include "adt.h"
#include "m2.h"
#include "wmo.h"

#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* {{{ state: the queue (tile numbers tx * 64 + ty), which tiles were ever
 * asked, and the thread */
static MpqChain       *chain_;
static char            map_[64];
static int             queue_[64 * 64], head_, tail_;
static unsigned char   asked_[64 * 64];
static int             busy_, stopping_, started_;
static int             tiles_done_, files_read_;
static pthread_t       thread_;
static pthread_mutex_t lock_ = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t  wake_ = PTHREAD_COND_INITIALIZER, idle_ = PTHREAD_COND_INITIALIZER;
/* }}} */

/* {{{ static touch: a file read through the chain (and so kept), then let go */
static unsigned char *touch(const char *name, size_t *len)
{
    const char *from;
    unsigned char *s = mpq_chain_read(chain_, name, len, &from);
    if (s) __atomic_add_fetch(&files_read_, 1, __ATOMIC_RELAXED);
    return s;
}
/* }}} */

/* {{{ static read_tile: everything tile i's load will read */
static void read_tile(int i)
{
    int tx = i / 64, ty = i % 64;
    char path[300];
    size_t len;
    snprintf(path, sizeof path, "World\\Maps\\%s\\%s_%d_%d.adt", map_, map_, ty, tx);
    unsigned char *s = touch(path, &len);
    if (!s) return;                                      /* open sea: no ground file */
    AdtTile *t = malloc(sizeof *t);
    char why[400];
    int bad = adt_read(s, len, 0, t, why, sizeof why);   /* the blend-map form doesn't matter for names */
    free(s);
    if (bad) { free(t); return; }                        /* the load itself will say what is wrong */
    /* each ground picture */
    for (int k = 0; k < t->ntextures; ++k) free(touch(t->textures[k], &len));
    /* each doodad: its model, skin, and the pictures it names */
    for (int k = 0; k < t->nmodels; ++k) {
        char base[260];
        snprintf(base, sizeof base, "%s", t->models[k]);
        char *dot = strrchr(base, '.');
        if (dot) *dot = '\0';
        size_t ml, sl;
        snprintf(path, sizeof path, "%s.m2", base);
        unsigned char *m2 = touch(path, &ml);
        snprintf(path, sizeof path, "%s00.skin", base);
        unsigned char *skin = touch(path, &sl);
        M2Model mod;
        if (m2 && skin && !m2_read(m2, ml, skin, sl, &mod, why, sizeof why)) {
            for (uint32_t x = 0; x < mod.ntextures; ++x) if (mod.textures[x].kind == 0 && mod.textures[x].file[0]) free(touch(mod.textures[x].file, &len));
            m2_free(&mod);
        }
        free(m2); free(skin);
    }
    /* each building: its root, its parts, and its materials' pictures */
    for (int k = 0; k < t->nbuildings; ++k) {
        size_t rl;
        unsigned char *r = touch(t->buildings[k], &rl);
        WmoRoot root;
        if (r && !wmo_read_root(r, rl, &root, why, sizeof why)) {
            char base[260];
            snprintf(base, sizeof base, "%s", t->buildings[k]);
            char *dot = strrchr(base, '.');
            if (dot) *dot = '\0';
            for (int g = 0; g < root.ngroups; ++g) { snprintf(path, sizeof path, "%s_%03d.wmo", base, g); free(touch(path, &len)); }
            for (int m = 0; m < root.nmaterials; ++m) if (root.materials[m].picture[0]) free(touch(root.materials[m].picture, &len));
            wmo_free_root(&root);
        }
        free(r);
    }
    adt_free(t);
    free(t);
}
/* }}} */

/* {{{ static work: the thread's loop */
static void *work(void *unused)
{
    (void)unused;
    pthread_mutex_lock(&lock_);
    for (;;) {
        while (head_ == tail_ && !stopping_) pthread_cond_wait(&wake_, &lock_);
        if (stopping_) break;
        int i = queue_[head_];
        head_ = (head_ + 1) % (64 * 64);
        busy_ = 1;
        pthread_mutex_unlock(&lock_);
        read_tile(i);
        pthread_mutex_lock(&lock_);
        busy_ = 0;
        ++tiles_done_;
        if (head_ == tail_) pthread_cond_broadcast(&idle_);
    }
    pthread_mutex_unlock(&lock_);
    return NULL;
}
/* }}} */

/* {{{ prefetch_start, prefetch_tile, prefetch_wait, prefetch_counts, prefetch_stop */
void prefetch_start(MpqChain *chain, const char *map_name)
{
    chain_ = chain;
    snprintf(map_, sizeof map_, "%s", map_name);
    stopping_ = 0;
    if (pthread_create(&thread_, NULL, work, NULL) == 0) started_ = 1;
    else fprintf(stderr, "prefetch: the helper thread couldn't start; tiles load without reading ahead\n");
}
void prefetch_tile(int tx, int ty)
{
    if (!started_ || tx < 0 || tx > 63 || ty < 0 || ty > 63) return;
    int i = tx * 64 + ty;
    pthread_mutex_lock(&lock_);
    if (!asked_[i]) {
        asked_[i] = 1;
        queue_[tail_] = i;
        tail_ = (tail_ + 1) % (64 * 64);
        pthread_cond_signal(&wake_);
    }
    pthread_mutex_unlock(&lock_);
}
void prefetch_wait(void)
{
    if (!started_) return;
    pthread_mutex_lock(&lock_);
    while (head_ != tail_ || busy_) pthread_cond_wait(&idle_, &lock_);
    pthread_mutex_unlock(&lock_);
}
void prefetch_counts(int *tiles, int *files)
{
    pthread_mutex_lock(&lock_);
    *tiles = tiles_done_;
    pthread_mutex_unlock(&lock_);
    *files = __atomic_load_n(&files_read_, __ATOMIC_RELAXED);
}
void prefetch_stop(void)
{
    if (!started_) return;
    pthread_mutex_lock(&lock_);
    stopping_ = 1;
    pthread_cond_broadcast(&wake_);
    pthread_mutex_unlock(&lock_);
    pthread_join(thread_, NULL);
    started_ = 0;
}
/* }}} */
