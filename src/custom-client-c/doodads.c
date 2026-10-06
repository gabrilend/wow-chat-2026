/*
 * doodads.c (issue 173g) - trees, rocks and other small models; see doodads.h
 *
 * For a general audience: keeps one entry per model the map uses. Each
 * entry holds the model's pieces (one mesh and one picture each, with how
 * the piece blends) and the list of places it stands. Drawing goes model
 * by model, piece by piece, all copies at once: solid and cut-out pieces
 * first, then see-through and glowing ones over them.
 */
#include "doodads.h"
#include "anim.h"
#include "blp.h"
#include "collide.h"
#include "m2.h"
#include "particles.h"
#include "sky.h"
#include "wmo.h"

#include "raymath.h"
#include "rlgl.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>

/* {{{ the shader
 * One copy's place arrives per instance (instanceTransform); `cutoff`
 * cuts out pixels whose alpha is under it (leaves), -1 for none. Lit by
 * the zone's sun and shade (173n), unless the piece is marked unlit.
 * A building's indoor parts are lit by the light baked into their points
 * instead (`indoor`; MOCV colours, plus a little ambient light: this
 * client's first reading of it, to be compared with the original's). */
static const char *VS =
    "#version 330\n"
    "in vec3 vertexPosition; in vec3 vertexNormal; in vec2 vertexTexCoord; in vec4 vertexColor; in mat4 instanceTransform;\n"
    "uniform mat4 mvp; uniform vec3 eye;\n"
    "out vec3 n; out vec2 uv; out vec4 col; out float dist;\n"
    "void main() {\n"
    "  vec4 w = instanceTransform * vec4(vertexPosition, 1.0);\n"
    "  n = mat3(instanceTransform) * vertexNormal; uv = vertexTexCoord; col = vertexColor;\n"
    "  dist = length(w.xyz - eye);\n"
    "  gl_Position = mvp * w;\n"
    "}\n";
static const char *FS =
    "#version 330\n"
    "in vec3 n; in vec2 uv; in vec4 col; in float dist; out vec4 frag;\n"
    "uniform sampler2D texture0; uniform float cutoff; uniform float unlit; uniform float indoor; uniform vec3 sun_dir, sun_col, shade_col, fog_col; uniform vec2 fog_range;\n"
    "void main() {\n"
    "  vec4 t = texture(texture0, uv);\n"
    "  if (t.a < cutoff) discard;\n"
    "  vec3 light = mix(shade_col + sun_col * max(dot(normalize(n), sun_dir), 0.0), vec3(1.0), unlit);\n"
    "  light = mix(light, col.rgb + 0.35, indoor);\n"
    "  float fog = clamp((dist - fog_range.x) / max(fog_range.y - fog_range.x, 1.0), 0.0, 1.0);\n"
    "  frag = vec4(mix(t.rgb * light, fog_col, fog), t.a);\n"
    "}\n";
/* }}} */

/* {{{ state
 * A model's piece: its mesh, its picture (into pictures[]), how it blends
 * (M2Unit's blend and flags, m2.h). A model: its pieces and its copies'
 * places (as Raylib matrices, relative to the drawing origin). seen[]
 * holds every placement id drawn so far, so a doodad listed by two tiles
 * is drawn once. */
typedef struct { Mesh mesh; int picture; uint16_t blend, flags; int indoor; uint32_t *point_of; } DoodadPiece;
/* A model that moves while standing (trees swaying, lamps flickering)
 * also keeps its skeleton, its points as made, and per piece which model
 * point each mesh corner is (point_of); every frame its points are bent
 * once and all its copies share that pose, as the original plays them, in
 * step. `anim` is NULL for a model that doesn't move. */
typedef struct {
    char    name[260];
    DoodadPiece  *pieces;   int npieces;
    Matrix *copies;   int ncopies, cap;
    Anim   *anim;     int stand;
    int     moving;                   /* its stand animation moves bones: bend it */
    M2Vertex *rest;   uint32_t nrest;
    float (*poses)[16];
    float  *bent;
    /* particles (173o): the model's emitters, each one's picture, and one
     * run per emitter per copy (copy * nemitters + emitter), made when
     * first needed and grown as copies are added */
    Emitter    *emitters;  int nemitters;
    int        *emit_pic;
    EmitterRun *runs;      int nruns;
    /* its solid shape (173q): triangles, 9 floats each, model space; every
     * copy placed adds them, placed, to the collision world */
    float      *solid;     int nsolid;
} DoodadModel;
#define PARTICLE_REACH 150.0f         /* yards: copies further from the camera run no particles */

static MpqChain *chain;
static CollideWorld *solids;          /* where placed copies' solid shapes go (doodads_init) */
static DoodadModel    *models;   static int nmodels, models_cap;
static struct { char name[260]; Texture2D tex; } *pictures;
static int       npictures, pictures_cap;
static uint32_t *seen;     static int nseen, seen_cap;
/* buildings: the model entry holding its pieces, and its root (for the
 * furnishings, placed when the building is) */
typedef struct { int model; WmoRoot root; } Building;
static Building *buildings; static int nbuildings, buildings_cap;
static uint32_t *seen_b;    static int nseen_b, seen_b_cap;
static int       skipped_pieces, moving_models, emitting_models;
static Shader    shader;
static Material  material;
static int       loc_eye, loc_cutoff, loc_unlit, loc_indoor;
static Vector3   view_right = { 1, 0, 0 }, view_up = { 0, 0, 1 };   /* the camera's, for particles (doodads_animate) */
/* }}} */

/* {{{ doodads_init */
int doodads_init(MpqChain *c, CollideWorld *collide, char *why, int why_len)
{
    chain = c;
    solids = collide;
    shader = LoadShaderFromMemory(VS, FS);
    if (!IsShaderReady(shader)) { snprintf(why, why_len, "the doodad shader didn't compile (see Raylib's messages above)"); return 1; }
    shader.locs[SHADER_LOC_MATRIX_MODEL] = GetShaderLocationAttrib(shader, "instanceTransform");
    loc_eye = GetShaderLocation(shader, "eye");
    loc_cutoff = GetShaderLocation(shader, "cutoff");
    loc_unlit = GetShaderLocation(shader, "unlit");
    loc_indoor = GetShaderLocation(shader, "indoor");
    material = LoadMaterialDefault();
    material.shader = shader;
    return 0;
}
/* }}} */

/* {{{ static picture: a picture by archive name, loaded once; -1 if unreadable */
static int picture(const char *name)
{
    for (int i = 0; i < npictures; ++i) if (!strcasecmp(pictures[i].name, name)) return i;
    size_t len;
    const char *from;
    unsigned char *s = mpq_chain_read(chain, name, &len, &from);
    if (!s) { fprintf(stderr, "doodads: the picture %s is in none of the client's archives; pieces using it are left out\n", name); return -1; }
    BlpImage img;
    char why[300];
    int bad = blp_decode(s, len, &img, why, sizeof why);
    free(s);
    if (bad) { fprintf(stderr, "doodads: the picture %s: %s; pieces using it are left out\n", name, why); return -1; }
    if (npictures == pictures_cap) {
        pictures_cap = pictures_cap ? pictures_cap * 2 : 256;
        pictures = realloc(pictures, sizeof *pictures * pictures_cap);
    }
    Image im = { .data = img.rgba, .width = img.width, .height = img.height, .mipmaps = 1, .format = PIXELFORMAT_UNCOMPRESSED_R8G8B8A8 };
    Texture2D t = LoadTextureFromImage(im);
    blp_free(&img);
    GenTextureMipmaps(&t);
    SetTextureFilter(t, TEXTURE_FILTER_TRILINEAR);
    SetTextureWrap(t, TEXTURE_WRAP_REPEAT);
    snprintf(pictures[npictures].name, sizeof pictures[npictures].name, "%s", name);
    pictures[npictures].tex = t;
    return npictures++;
}
/* }}} */

/* {{{ static load_model: a model by its MMDX name, loaded once
 * The ground files name models with .mdx or .m2; the file in the archives
 * is always .m2, with its first view in <name>00.skin. A model that can't
 * be read is kept with no pieces (so it is reported once, not per copy). */
static int load_model(const char *name)
{
    for (int i = 0; i < nmodels; ++i) if (!strcasecmp(models[i].name, name)) return i;
    if (nmodels == models_cap) {
        models_cap = models_cap ? models_cap * 2 : 256;
        models = realloc(models, sizeof *models * models_cap);
    }
    DoodadModel *md = &models[nmodels];
    memset(md, 0, sizeof *md);
    snprintf(md->name, sizeof md->name, "%s", name);

    char base[260], path[280];
    snprintf(base, sizeof base, "%s", name);
    char *dot = strrchr(base, '.');
    if (dot) *dot = '\0';
    size_t mlen, slen;
    const char *from;
    snprintf(path, sizeof path, "%s.m2", base);
    unsigned char *m2 = mpq_chain_read(chain, path, &mlen, &from);
    snprintf(path, sizeof path, "%s00.skin", base);
    unsigned char *skin = mpq_chain_read(chain, path, &slen, &from);
    M2Model mod;
    char why[400];
    if (!m2 || !skin) {
        fprintf(stderr, "doodads: %s: %s is in none of the client's archives; left out\n", name, !m2 ? "the .m2" : "its 00.skin");
        free(m2); free(skin);
        return nmodels++;
    }
    int bad = m2_read(m2, mlen, skin, slen, &mod, why, sizeof why);
    free(skin);
    if (bad) { free(m2); fprintf(stderr, "doodads: %s: %s; left out\n", name, why); return nmodels++; }

    /* does it move while standing? (its stand animation, id 0, moving
     * any bone) If so it keeps its skeleton and is bent every frame. */
    Anim *an = calloc(1, sizeof *an);
    int moving = 0;
    if (!anim_read(m2, mlen, an, why, sizeof why)) {
        md->stand = anim_find(an, 0, 0);
        if (md->stand >= 0 && anim_needs_file(an, md->stand)) {
            snprintf(path, sizeof path, "%s%04d-%02d.anim", base, an->seqs[md->stand].id, an->seqs[md->stand].variation);
            size_t alen;
            unsigned char *af = mpq_chain_read(chain, path, &alen, &from);
            if (af) anim_attach_file(an, md->stand, af, alen);
            else fprintf(stderr, "doodads: %s is in none of the archives; %s stands still\n", path, name);
        }
        moving = md->stand >= 0 && an->npoints == mod.nvertices && anim_moves(an, md->stand);
        /* its particle emitters, each with its picture (the model's own
         * picture slot, named in the file) */
        if (particles_read(an, &md->emitters, &md->nemitters, why, sizeof why))
            fprintf(stderr, "doodads: %s's particles: %s; it shows none\n", name, why);
        if (md->nemitters) {
            md->emit_pic = malloc(sizeof(int) * md->nemitters);
            for (int i = 0; i < md->nemitters; ++i) {
                int slot = md->emitters[i].slot;
                md->emit_pic[i] = (slot < (int)mod.ntextures && mod.textures[slot].kind == 0 && mod.textures[slot].file[0])
                                  ? picture(mod.textures[slot].file) : -1;
                if (md->emit_pic[i] < 0) fprintf(stderr, "doodads: %s's emitter %d has no picture it can use; it shows none\n", name, i);
            }
            ++emitting_models;
        }
    } else {
        fprintf(stderr, "doodads: %s's skeleton: %s; it stands still\n", name, why);
    }
    if (m2_collision(m2, mlen, &md->solid, &md->nsolid, why, sizeof why))
        fprintf(stderr, "doodads: %s's solid shape: %s; it is walked through\n", name, why);
    free(m2);
    md->moving = moving;
    if (moving || md->nemitters) {
        md->anim = an;
        md->poses = malloc(sizeof *md->poses * (an->nbones ? an->nbones : 1));
    }
    if (moving) {
        md->nrest = mod.nvertices;
        md->rest = malloc(sizeof *md->rest * md->nrest);
        memcpy(md->rest, mod.vertices, sizeof *md->rest * md->nrest);
        md->bent = malloc(sizeof(float) * 6 * md->nrest);
        ++moving_models;
    }
    if (!md->anim) {
        anim_free(an);
        free(an);
    }

    md->pieces = calloc(mod.nunits ? mod.nunits : 1, sizeof *md->pieces);
    for (uint32_t u = 0; u < mod.nunits; ++u) {
        M2Unit un = mod.units[u];
        if (un.piece >= mod.npieces || un.texture >= mod.ntextures) continue;
        if (mod.textures[un.texture].kind != 0) { ++skipped_pieces; continue; }   /* picture chosen at run time */
        int pic = picture(mod.textures[un.texture].file);
        if (pic < 0) continue;
        M2Piece p = mod.pieces[un.piece];
        if (p.first + p.count > mod.nindices || p.count == 0) continue;
        Mesh m = { 0 };
        m.vertexCount = (int)p.count;
        m.triangleCount = (int)p.count / 3;
        m.vertices  = MemAlloc(sizeof(float) * 3 * p.count);
        m.normals   = MemAlloc(sizeof(float) * 3 * p.count);
        m.texcoords = MemAlloc(sizeof(float) * 2 * p.count);
        int ok = 1;
        for (uint32_t i = 0; i < p.count; ++i) {
            uint32_t k = mod.indices[p.first + i];
            if (k >= mod.nvertices) { ok = 0; break; }
            M2Vertex v = mod.vertices[k];
            m.vertices[i * 3] = v.x; m.vertices[i * 3 + 1] = v.y; m.vertices[i * 3 + 2] = v.z;
            m.normals[i * 3] = v.nx; m.normals[i * 3 + 1] = v.ny; m.normals[i * 3 + 2] = v.nz;
            m.texcoords[i * 2] = v.u; m.texcoords[i * 2 + 1] = v.v;
        }
        if (!ok) { UnloadMesh(m); fprintf(stderr, "doodads: %s: a piece names a point the model doesn't have; piece left out\n", name); continue; }
        uint32_t *point_of = NULL;
        if (md->moving) {
            point_of = malloc(sizeof(uint32_t) * p.count);
            for (uint32_t i = 0; i < p.count; ++i) point_of[i] = mod.indices[p.first + i];
        }
        UploadMesh(&m, md->moving);                        /* a moving model's meshes are refreshed every frame */
        md->pieces[md->npieces++] = (DoodadPiece){ m, pic, un.blend, un.flags, 0, point_of };
    }
    m2_free(&mod);
    return nmodels++;
}
/* }}} */

/* {{{ static load_building: a building by name, loaded once
 * Its pieces are every group's batches, kept as one model entry so its
 * copies draw like any doodad's. A group or picture that can't be read is
 * reported and left out; a root that can't be read leaves the building
 * out (reported once). */
static int load_building(const char *name)
{
    for (int i = 0; i < nbuildings; ++i) if (!strcasecmp(models[buildings[i].model].name, name)) return i;
    if (nbuildings == buildings_cap) {
        buildings_cap = buildings_cap ? buildings_cap * 2 : 64;
        buildings = realloc(buildings, sizeof *buildings * buildings_cap);
    }
    if (nmodels == models_cap) {
        models_cap = models_cap ? models_cap * 2 : 256;
        models = realloc(models, sizeof *models * models_cap);
    }
    Building *b = &buildings[nbuildings];
    memset(b, 0, sizeof *b);
    b->model = nmodels;
    DoodadModel *md = &models[nmodels++];
    memset(md, 0, sizeof *md);
    snprintf(md->name, sizeof md->name, "%s", name);

    size_t len;
    const char *from;
    char why[400], path[300];
    unsigned char *s = mpq_chain_read(chain, name, &len, &from);
    if (!s) { fprintf(stderr, "buildings: %s is in none of the client's archives; left out\n", name); return nbuildings++; }
    int bad = wmo_read_root(s, len, &b->root, why, sizeof why);
    free(s);
    if (bad) { fprintf(stderr, "buildings: %s: %s; left out\n", name, why); return nbuildings++; }

    char base[260];
    snprintf(base, sizeof base, "%s", name);
    char *dot = strrchr(base, '.');
    if (dot) *dot = '\0';
    for (int gi = 0; gi < b->root.ngroups; ++gi) {
        snprintf(path, sizeof path, "%s_%03d.wmo", base, gi);
        s = mpq_chain_read(chain, path, &len, &from);
        if (!s) { fprintf(stderr, "buildings: %s is in none of the client's archives; that part is left out\n", path); continue; }
        WmoGroup g;
        bad = wmo_read_group(s, len, &g, why, sizeof why);
        free(s);
        if (bad) { fprintf(stderr, "buildings: %s: %s; that part is left out\n", path, why); continue; }
        /* its solid triangles (173q), kept in the building's own space */
        int nt = (int)(g.nindices / 3);
        md->solid = realloc(md->solid, sizeof(float) * 9 * (size_t)(md->nsolid + nt + 1));
        for (int t = 0; t < nt; ++t) {
            if ((uint32_t)t >= g.nflags || !wmo_solid(g.tri_flags[t])) continue;
            for (int c = 0; c < 3; ++c) {
                WmoVertex v = g.vertices[g.indices[t * 3 + c]];
                float *o = md->solid + (size_t)md->nsolid * 9 + c * 3;
                o[0] = v.x; o[1] = v.y; o[2] = v.z;
            }
            ++md->nsolid;
        }
        md->pieces = realloc(md->pieces, sizeof *md->pieces * (md->npieces + g.nbatches + 1));
        for (int k = 0; k < g.nbatches; ++k) {
            WmoBatch bt = g.batches[k];
            if (bt.material >= b->root.nmaterials || bt.count == 0) continue;
            WmoMaterial mat = b->root.materials[bt.material];
            int pic = picture(mat.picture);
            if (pic < 0) continue;
            Mesh m = { 0 };
            m.vertexCount = (int)bt.count;
            m.triangleCount = (int)bt.count / 3;
            m.vertices  = MemAlloc(sizeof(float) * 3 * bt.count);
            m.normals   = MemAlloc(sizeof(float) * 3 * bt.count);
            m.texcoords = MemAlloc(sizeof(float) * 2 * bt.count);
            m.colors    = MemAlloc(4 * bt.count);
            for (uint32_t i = 0; i < bt.count; ++i) {
                WmoVertex v = g.vertices[g.indices[bt.first + i]];
                m.vertices[i * 3] = v.x; m.vertices[i * 3 + 1] = v.y; m.vertices[i * 3 + 2] = v.z;
                m.normals[i * 3] = v.nx; m.normals[i * 3 + 1] = v.ny; m.normals[i * 3 + 2] = v.nz;
                m.texcoords[i * 2] = v.u; m.texcoords[i * 2 + 1] = v.v;
                m.colors[i * 4] = v.r; m.colors[i * 4 + 1] = v.g; m.colors[i * 4 + 2] = v.b; m.colors[i * 4 + 3] = 255;
            }
            UploadMesh(&m, false);
            int indoor = (g.flags & 0x2000) && g.has_colours;
            md->pieces[md->npieces++] = (DoodadPiece){ m, pic, (uint16_t)mat.blend, (uint16_t)mat.flags, indoor, NULL };
        }
        wmo_free_group(&g);
    }
    return nbuildings++;
}
/* }}} */

/* {{{ static add_copy: one more place for model `which` */
static void add_copy(int which, Matrix at)
{
    DoodadModel *md = &models[which];
    if (md->ncopies == md->cap) { md->cap = md->cap ? md->cap * 2 : 16; md->copies = realloc(md->copies, sizeof *md->copies * md->cap); }
    md->copies[md->ncopies++] = at;
    if (solids && md->nsolid) collide_add(solids, md->solid, md->nsolid, MatrixToFloatV(at).v);
}
/* }}} */

/* {{{ doodads_add_tile */
int doodads_add_tile(const AdtTile *t, double ox, double oy, char *why, int why_len)
{
    (void)why; (void)why_len;
    for (int k = 0; k < t->ndoodads; ++k) {
        const AdtPlace *p = &t->doodads[k];
        int dup = 0;
        for (int i = 0; i < nseen && !dup; ++i) dup = seen[i] == p->uid;
        if (dup) continue;
        if (nseen == seen_cap) { seen_cap = seen_cap ? seen_cap * 2 : 4096; seen = realloc(seen, sizeof *seen * seen_cap); }
        seen[nseen++] = p->uid;
        int which = load_model(t->models[p->name]);         /* may grow (move) the models list */
        float m[16];
        adt_place_matrix(p, ox, oy, m);
        add_copy(which, (Matrix){ m[0], m[4], m[8], m[12], m[1], m[5], m[9], m[13], m[2], m[6], m[10], m[14], m[3], m[7], m[11], m[15] });
    }
    /* buildings, and the furnishings of the set each placement asks for
     * (set 0 holds what every placement shows, so it is always added) */
    for (int k = 0; k < t->nplaces; ++k) {
        const AdtPlace *p = &t->places[k];
        int dup = 0;
        for (int i = 0; i < nseen_b && !dup; ++i) dup = seen_b[i] == p->uid;
        if (dup) continue;
        if (nseen_b == seen_b_cap) { seen_b_cap = seen_b_cap ? seen_b_cap * 2 : 256; seen_b = realloc(seen_b, sizeof *seen_b * seen_b_cap); }
        seen_b[nseen_b++] = p->uid;
        int bi = load_building(t->buildings[p->name]);
        float m[16];
        adt_place_matrix(p, ox, oy, m);
        Matrix place = { m[0], m[4], m[8], m[12], m[1], m[5], m[9], m[13], m[2], m[6], m[10], m[14], m[3], m[7], m[11], m[15] };
        add_copy(buildings[bi].model, place);
        for (int si = 0; si < buildings[bi].root.nsets; ++si) {
            if (si != 0 && si != p->doodad_set) continue;
            WmoSet set = buildings[bi].root.sets[si];
            for (int fi = set.first; fi < set.first + set.count; ++fi) {
                WmoFurnishing f = buildings[bi].root.furnishings[fi];
                if (!f.model[0]) continue;
                float fm[16];
                adt_inside_matrix(m, f.pos, f.quat, f.scale, fm);
                int which = load_model(f.model);
                add_copy(which, (Matrix){ fm[0], fm[4], fm[8], fm[12], fm[1], fm[5], fm[9], fm[13], fm[2], fm[6], fm[10], fm[14], fm[3], fm[7], fm[11], fm[15] });
            }
        }
    }
    return 0;
}
/* }}} */

/* {{{ doodads_draw
 * Two passes: blend 0 and 1 (solid, cut-out) writing depth; then 2-6
 * (see-through, added, multiplied) over them without writing depth. */
static void draw_pass(int see_through)
{
    for (int i = 0; i < nmodels; ++i) {
        DoodadModel *md = &models[i];
        if (!md->ncopies) continue;
        for (int k = 0; k < md->npieces; ++k) {
            DoodadPiece *p = &md->pieces[k];
            if ((p->blend >= 2) != see_through) continue;
            float cutoff = p->blend == 0 ? -1.0f : p->blend == 1 ? 0.5f : 1.0f / 255.0f;
            float unlit = (p->flags & 0x1) ? 1.0f : 0.0f, indoor = p->indoor ? 1.0f : 0.0f;
            SetShaderValue(shader, loc_indoor, &indoor, SHADER_UNIFORM_FLOAT);
            SetShaderValue(shader, loc_cutoff, &cutoff, SHADER_UNIFORM_FLOAT);
            SetShaderValue(shader, loc_unlit, &unlit, SHADER_UNIFORM_FLOAT);
            if (see_through) BeginBlendMode(p->blend == 2 ? BLEND_ALPHA : p->blend >= 5 ? BLEND_MULTIPLIED : BLEND_ADDITIVE);
            material.maps[MATERIAL_MAP_DIFFUSE].texture = pictures[p->picture].tex;
            DrawMeshInstanced(p->mesh, material, md->copies, md->ncopies);
            if (see_through) EndBlendMode();
        }
    }
}
/* the particles: squares facing the camera (its right and up), each from
 * its picture's cell, coloured and sized by its age, blended as its
 * emitter says (2 see-through, 3-4 added light; 0-1 drawn see-through),
 * without writing depth, after everything solid */
static void draw_particles(Vector3 right, Vector3 up)
{
    for (int i = 0; i < nmodels; ++i) {
        DoodadModel *md = &models[i];
        if (!md->nemitters || !md->nruns) continue;
        for (int k = 0; k < md->nemitters; ++k) {
            const Emitter *e = &md->emitters[k];
            if (md->emit_pic[k] < 0) continue;
            BeginBlendMode(e->blend >= 3 ? BLEND_ADDITIVE : BLEND_ALPHA);
            rlSetTexture(pictures[md->emit_pic[k]].tex.id);
            rlBegin(RL_QUADS);
            for (int c = 0; c < md->ncopies; ++c) {
                const EmitterRun *run = &md->runs[c * md->nemitters + k];
                for (int q = 0; q < run->n; ++q) {
                    const Particle *p = &run->ps[q];
                    float rgba[4], size[2];
                    particles_look(e, p, rgba, size);
                    int cell = p->cell;
                    if (e->cell.n) {                    /* the cell follows its life */
                        float t = p->age / p->life;
                        int kk = 0;
                        while (kk + 1 < e->cell.n && t >= e->cell.t[kk + 1]) ++kk;
                        cell = (int)e->cell.v[kk][0];
                    }
                    cell %= e->rows * e->cols;
                    float u0 = (float)(cell % e->cols) / e->cols, v0 = (float)(cell / e->cols) / e->rows;
                    float u1 = u0 + 1.0f / e->cols, v1 = v0 + 1.0f / e->rows;
                    float sx = size[0], sy = size[1];
                    Vector3 c0 = { p->p[0], p->p[1], p->p[2] };
                    rlColor4f(rgba[0], rgba[1], rgba[2], rgba[3]);
                    rlTexCoord2f(u0, v1); rlVertex3f(c0.x - right.x * sx - up.x * sy, c0.y - right.y * sx - up.y * sy, c0.z - right.z * sx - up.z * sy);
                    rlTexCoord2f(u1, v1); rlVertex3f(c0.x + right.x * sx - up.x * sy, c0.y + right.y * sx - up.y * sy, c0.z + right.z * sx - up.z * sy);
                    rlTexCoord2f(u1, v0); rlVertex3f(c0.x + right.x * sx + up.x * sy, c0.y + right.y * sx + up.y * sy, c0.z + right.z * sx + up.z * sy);
                    rlTexCoord2f(u0, v0); rlVertex3f(c0.x - right.x * sx + up.x * sy, c0.y - right.y * sx + up.y * sy, c0.z - right.z * sx + up.z * sy);
                }
            }
            rlEnd();
            rlSetTexture(0);
            EndBlendMode();
        }
    }
}

void doodads_draw(Vector3 eye, const LightNow *light)
{
    SetShaderValue(shader, loc_eye, &eye, SHADER_UNIFORM_VEC3);
    sky_light_shader(shader, light);
    draw_pass(0);
    rlDrawRenderBatchActive();
    rlDisableDepthMask();
    draw_pass(1);
    rlDrawRenderBatchActive();
    draw_particles(view_right, view_up);
    rlDrawRenderBatchActive();
    rlEnableDepthMask();
}
/* }}} */

/* {{{ doodads_animate
 * Each moving model's stand animation at `ms` (its own length wraps it;
 * global sequences use `ms` too), its points bent and copied into its
 * pieces' meshes. Only models with copies placed are bent. */
static void run_particles(DoodadModel *md, uint32_t ms, float dt, Vector3 eye)
{
    int want = md->ncopies * md->nemitters;
    if (md->nruns < want) {
        md->runs = realloc(md->runs, sizeof *md->runs * want);
        memset(md->runs + md->nruns, 0, sizeof *md->runs * (want - md->nruns));
        md->nruns = want;
    }
    for (int c = 0; c < md->ncopies; ++c) {
        float at[16];
        memcpy(at, MatrixToFloatV(md->copies[c]).v, sizeof at);
        float dx = at[12] - eye.x, dy = at[13] - eye.y, dz = at[14] - eye.z;
        int near_eye = dx * dx + dy * dy + dz * dz < PARTICLE_REACH * PARTICLE_REACH;
        for (int k = 0; k < md->nemitters; ++k) {
            EmitterRun *run = &md->runs[c * md->nemitters + k];
            if (!near_eye) { run->n = 0; continue; }       /* far copies hold none */
            /* the emitter's bone in the world: the copy's place times the bone's pose */
            const float *b = md->poses[md->emitters[k].bone];
            float w[16];
            for (int row = 0; row < 4; ++row)
                for (int col = 0; col < 4; ++col) {
                    float sum = 0;
                    for (int q = 0; q < 4; ++q) sum += at[q * 4 + row] * b[col * 4 + q];
                    w[col * 4 + row] = sum;
                }
            particles_step(md->anim, &md->emitters[k], run, w, md->stand, ms, dt);
        }
    }
}
void doodads_animate(uint32_t ms, float dt, Vector3 eye, Vector3 target)
{
    Vector3 ahead = Vector3Normalize(Vector3Subtract(target, eye));
    view_right = Vector3Normalize(Vector3CrossProduct(ahead, (Vector3){ 0, 0, 1 }));
    view_up = Vector3CrossProduct(view_right, ahead);
    for (int i = 0; i < nmodels; ++i) {
        DoodadModel *md = &models[i];
        if (!md->anim || !md->ncopies) continue;
        anim_pose(md->anim, md->stand, ms, ms, md->poses);
        if (md->nemitters) run_particles(md, ms, dt, eye);
        if (!md->moving) continue;
        for (uint32_t k = 0; k < md->nrest; ++k) {
            float p[3] = { md->rest[k].x, md->rest[k].y, md->rest[k].z }, n[3] = { md->rest[k].nx, md->rest[k].ny, md->rest[k].nz };
            anim_skin_point(md->anim, (const float (*)[16])md->poses, k, p, md->bent + k * 6, n, md->bent + k * 6 + 3);
        }
        for (int j = 0; j < md->npieces; ++j) {
            DoodadPiece *pc = &md->pieces[j];
            Mesh *m = &pc->mesh;
            for (int v = 0; v < m->vertexCount; ++v) {
                const float *b = md->bent + pc->point_of[v] * 6;
                memcpy(m->vertices + v * 3, b, sizeof(float) * 3);
                memcpy(m->normals + v * 3, b + 3, sizeof(float) * 3);
            }
            UpdateMeshBuffer(*m, 0, m->vertices, (int)(sizeof(float) * 3 * m->vertexCount), 0);   /* positions */
            UpdateMeshBuffer(*m, 2, m->normals, (int)(sizeof(float) * 3 * m->vertexCount), 0);    /* facings */
        }
    }
}
/* }}} */

/* {{{ doodads_counts */
void doodads_counts(int *nm, int *nc, int *ns, int *nmoving, int *nemitting)
{
    int copies = 0;
    for (int i = 0; i < nmodels; ++i) copies += models[i].ncopies;
    *nm = nmodels; *nc = copies; *ns = skipped_pieces; *nmoving = moving_models; *nemitting = emitting_models;
}
/* }}} */
