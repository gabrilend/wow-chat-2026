/*
 * mover.c (issue 173k) - see mover.h. Ported line for line from
 * src/custom-client/lib/mover.lua.
 */
#include "mover.h"

#include <math.h>

#define STICK_DOWN 1.5                /* yards: ground this far below a walking character is still walked on */
#define PI 3.14159265358979323846

/* {{{ mover_init */
void mover_init(Mover *m, double x, double y, double z, double o, double speed, double max_slope)
{
    m->x = x; m->y = y; m->z = z; m->o = o;
    m->speed = speed;
    m->vz = 0; m->vx = 0; m->vy = 0;
    m->grounded = 1; m->sliding = 0;
    m->max_grad = tan(max_slope * PI / 180.0);
}
/* }}} */

/* {{{ static gradient
 * The ground's rise per yard along x and y at (x, y), from the map
 * triangle the point lies in; 0 (no slope known) in a hole or off the
 * loaded world, where the fall logic takes over. */
static int gradient(MoverGround ground, void *ctx, double x, double y, double z_top, double *gx, double *gy)
{
    float fx, fy;
    float z = ground(ctx, (float)x, (float)y, (float)z_top, &fx, &fy);
    if (z < -10000.0f) return 0;
    *gx = fx; *gy = fy;
    return 1;
}
/* }}} */

/* {{{ mover_step */
void mover_step(Mover *m, const MoverInput *in, double dt, MoverGround ground, MoverWall wall, void *ctx)
{
    double k = m->speed;
    /* the floor she may stand on: on the ground, anything up to a step
     * above her feet (she walks up it); in the air, only what is below
     * her (she lands on it, never snaps up through a bridge) */
    double reach = m->grounded ? MOVER_STEP_UP : 0.05;

    /* turning (A / D), unless the right button makes them strafes */
    int strafe_l = in->strafe_left  || (in->strafe_turns && in->left);
    int strafe_r = in->strafe_right || (in->strafe_turns && in->right);
    if (!in->strafe_turns) {
        if (in->left)  m->o += MOVER_TURN * dt;
        if (in->right) m->o -= MOVER_TURN * dt;
        m->o = fmod(m->o, 2 * PI);
        if (m->o < 0) m->o += 2 * PI;
    }

    /* the wanted direction in the character's own frame: ahead (+1/-1), to the left (+1/-1) */
    int ahead = (in->forward ? 1 : 0) - (in->back ? 1 : 0);
    int left  = (strafe_l ? 1 : 0) - (strafe_r ? 1 : 0);
    if (ahead != 0 || left != 0) {
        /* one speed whatever the mix of keys: forward or strafing at run
         * speed, any backward part at the backward speed */
        double speed = (ahead < 0 ? MOVER_BACK : MOVER_RUN) * k;
        double len = sqrt((double)(ahead * ahead + left * left));
        double dx = (ahead * cos(m->o) + left * cos(m->o + PI / 2)) / len;
        double dy = (ahead * sin(m->o) + left * sin(m->o + PI / 2)) / len;
        double nx = m->x + dx * speed * dt, ny = m->y + dy * speed * dt;
        /* too steep to climb: a step up onto ground steeper than the limit
         * is not taken (on the ground only); down onto it is allowed, and
         * the slide below takes over there */
        int blocked = 0;
        if (m->grounded) {
            double gx, gy;
            float hx, hy;
            if (gradient(ground, ctx, nx, ny, m->z + reach, &gx, &gy) && gx * gx + gy * gy > m->max_grad * m->max_grad
                && ground(ctx, (float)nx, (float)ny, (float)(m->z + reach), &hx, &hy) > m->z)
                blocked = 1;
        }
        /* a wall: she stops short of it, and slides along it with what is
         * left of her step once the part into the wall is taken away */
        float wx, wy;
        if (!blocked && wall && wall(ctx, m->x, m->y, nx, ny, m->z, &wx, &wy)) {
            double sx = nx - m->x, sy = ny - m->y, into = sx * wx + sy * wy;
            sx -= into * wx; sy -= into * wy;
            nx = m->x + sx; ny = m->y + sy;
            if (wall(ctx, m->x, m->y, nx, ny, m->z, &wx, &wy)) blocked = 1;   /* a corner: no way along */
        }
        if (!blocked) { m->x = nx; m->y = ny; }
    }

    /* sliding: on ground steeper than the limit a character slides down it
     * as on a frictionless slope: g sin(a) along it, g sin(a) cos(a) of it
     * horizontal, downhill; the speed is kept until ground it can stand on */
    if (m->grounded) {
        double gx = 0, gy = 0;
        double g2 = gradient(ground, ctx, m->x, m->y, m->z + reach, &gx, &gy) ? gx * gx + gy * gy : 0;
        if (g2 > m->max_grad * m->max_grad) {
            double g = sqrt(g2), a = atan(g);
            double push = MOVER_GRAVITY * sin(a) * cos(a) * dt;
            m->vx -= gx / g * push;
            m->vy -= gy / g * push;
            m->sliding = 1;
        } else {
            m->vx = 0; m->vy = 0; m->sliding = 0;
        }
    }
    if (m->vx != 0 || m->vy != 0) {
        double sx = m->x + m->vx * dt, sy = m->y + m->vy * dt;
        float wx, wy;
        if (wall && wall(ctx, m->x, m->y, sx, sy, m->z, &wx, &wy)) { m->vx = 0; m->vy = 0; }   /* a slide ends against a wall */
        else { m->x = sx; m->y = sy; }
    }

    /* up and down: walking along the ground, or falling, or a jump */
    float hx, hy;
    double floor_z = ground(ctx, (float)m->x, (float)m->y, (float)(m->z + reach), &hx, &hy);
    if (m->grounded && in->jump) { m->grounded = 0; m->vz = MOVER_JUMP; }
    if (m->grounded) {
        if (floor_z > -10000 && floor_z >= m->z - STICK_DOWN)
            m->z = floor_z;                              /* walking: on the ground, up or down a slope */
        else { m->grounded = 0; m->vz = 0; }             /* walked off an edge (or into a hole): falling */
    }
    if (!m->grounded) {
        m->vz -= MOVER_GRAVITY * dt;
        if (m->vz < -MOVER_TERMINAL) m->vz = -MOVER_TERMINAL;
        m->z += m->vz * dt;
        if (floor_z > -10000 && m->z <= floor_z) { m->z = floor_z; m->vz = 0; m->grounded = 1; }   /* landed */
    }
}
/* }}} */
