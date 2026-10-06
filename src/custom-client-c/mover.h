/*
 * mover.h (issue 173k; the C twin of lib/mover.lua) - how a character moves
 *
 * For a general audience: one step of a character's movement, given what
 * the player is pressing and how much time passed: turning, walking along
 * the ground, falling, jumping, and sliding down ground too steep to
 * stand on. The numbers are the game's own base speeds, times the speed
 * bonus (the owner asked for 120%). No drawing here, so it is tested alone.
 *
 * Facing is the game's: radians, 0 = north (+x), rising toward west (+y).
 */
#ifndef EG_MOVER_H
#define EG_MOVER_H

/* the game's movement numbers */
#define MOVER_RUN      7.0            /* yards a second forward (and strafing) */
#define MOVER_BACK     4.5            /* yards a second backward */
#define MOVER_TURN     3.14159265358979323846    /* radians a second (half a circle) */
#define MOVER_GRAVITY  19.29110527    /* yards a second squared */
#define MOVER_JUMP     7.95554        /* yards a second upward at take-off */
#define MOVER_TERMINAL 60.148003      /* the fastest fall, yards a second */

typedef struct {
    double x, y, z, o;                /* position (yards), facing (radians); doubles, as the Lua twin */
    double speed;                     /* times the base speeds (1.2 for 120%) */
    double vz;                        /* upward speed, yards a second */
    double vx, vy;                    /* sliding speed, yards a second */
    int   grounded, sliding;
    double max_grad;                  /* rise per yard at the slope limit */
} Mover;

typedef struct {
    int forward, back, left, right, strafe_left, strafe_right, jump;
    int strafe_turns;                 /* the right mouse button: A and D strafe */
} MoverInput;

/* The ground at (x, y): the highest surface at or below `z_top` (the
 * map's ground, or a model's floor: a bridge, a stair, 173q), its height
 * (below -10000 for none: a hole, or the edge of the loaded world), and
 * its rise per yard along x and along y. */
typedef float (*MoverGround)(void *ctx, float x, float y, float z_top, float *gx, float *gy);

/* Walls (173q): whether a step from (x0, y0) to (x1, y1), feet at z,
 * runs into something too steep to stand on; if so, its facing along the
 * ground in (nx, ny). NULL: no walls (the map's ground alone). */
typedef int (*MoverWall)(void *ctx, double x0, double y0, double x1, double y1, double z, float *nx, float *ny);

/* how high a ledge she walks up without jumping (173q; the original's own
 * number is not yet measured) */
#define MOVER_STEP_UP  1.0

/* max_slope: degrees, the steepest walkable ground (navmesh_slope_read). */
void mover_init(Mover *m, double x, double y, double z, double o, double speed, double max_slope);
void mover_step(Mover *m, const MoverInput *in, double dt, MoverGround ground, MoverWall wall, void *ctx);

#endif
