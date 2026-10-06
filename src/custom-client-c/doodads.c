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
#include "blp.h"
#include "m2.h"

#include "raymath.h"
#include "rlgl.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>

/* {{{ the shader
 * One copy's place arrives per instance (instanceTransform); `cutoff`
 * cuts out pixels whose alpha is under it (leaves), -1 for none. Lit by
 * the same sun as the ground and her, unless the piece is marked unlit. */
static const char *VS =
    "#version 330\n"
    "in vec3 vertexPosition; in vec3 vertexNormal; in vec2 vertexTexCoord; in mat4 instanceTransform;\n"
    "uniform mat4 mvp; uniform vec3 eye;\n"
    "out vec3 n; out vec2 uv; out float dist;\n"
    "void main() {\n"
    "  vec4 w = instanceTransform * vec4(vertexPosition, 1.0);\n"
    "  n = mat3(instanceTransform) * vertexNormal; uv = vertexTexCoord;\n"
    "  dist = length(w.xyz - eye);\n"
    "  gl_Position = mvp * w;\n"
    "}\n";
static const char *FS =
    "#version 330\n"
    "in vec3 n; in vec2 uv; in float dist; out vec4 frag;\n"
    "uniform sampler2D texture0; uniform vec3 sky; uniform float cutoff; uniform float unlit;\n"
    "void main() {\n"
    "  vec4 t = texture(texture0, uv);\n"
    "  if (t.a < cutoff) discard;\n"
    "  vec3 sun = normalize(vec3(0.45, 0.30, 0.84));\n"
    "  float light = mix(max(dot(normalize(n), sun), 0.0) * 0.6 + 0.45, 1.0, unlit);\n"
    "  float fog = clamp((dist - 120.0) / 520.0, 0.0, 1.0);\n"
    "  frag = vec4(mix(t.rgb * light, sky, fog), t.a);\n"
    "}\n";
/* }}} */

/* {{{ state
 * A model's piece: its mesh, its picture (into pictures[]), how it blends
 * (M2Unit's blend and flags, m2.h). A model: its pieces and its copies'
 * places (as Raylib matrices, relative to the drawing origin). seen[]
 * holds every placement id drawn so far, so a doodad listed by two tiles
 * is drawn once. */
typedef struct { Mesh mesh; int picture; uint16_t blend, flags; } DoodadPiece;
typedef struct {
    char    name[260];
    DoodadPiece  *pieces;   int npieces;
    Matrix *copies;   int ncopies, cap;
} DoodadModel;

static MpqChain *chain;
static DoodadModel    *models;   static int nmodels, models_cap;
static struct { char name[260]; Texture2D tex; } *pictures;
static int       npictures, pictures_cap;
static uint32_t *seen;     static int nseen, seen_cap;
static int       skipped_pieces;
static Shader    shader;
static Material  material;
static int       loc_eye, loc_sky, loc_cutoff, loc_unlit;
/* }}} */

/* {{{ doodads_init */
int doodads_init(MpqChain *c, char *why, int why_len)
{
    chain = c;
    shader = LoadShaderFromMemory(VS, FS);
    if (!IsShaderReady(shader)) { snprintf(why, why_len, "the doodad shader didn't compile (see Raylib's messages above)"); return 1; }
    shader.locs[SHADER_LOC_MATRIX_MODEL] = GetShaderLocationAttrib(shader, "instanceTransform");
    loc_eye = GetShaderLocation(shader, "eye");
    loc_sky = GetShaderLocation(shader, "sky");
    loc_cutoff = GetShaderLocation(shader, "cutoff");
    loc_unlit = GetShaderLocation(shader, "unlit");
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
    free(m2); free(skin);
    if (bad) { fprintf(stderr, "doodads: %s: %s; left out\n", name, why); return nmodels++; }

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
        UploadMesh(&m, false);
        md->pieces[md->npieces++] = (DoodadPiece){ m, pic, un.blend, un.flags };
    }
    m2_free(&mod);
    return nmodels++;
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
        DoodadModel *md = &models[which];
        if (md->ncopies == md->cap) { md->cap = md->cap ? md->cap * 2 : 16; md->copies = realloc(md->copies, sizeof *md->copies * md->cap); }
        float m[16];
        adt_place_matrix(p, ox, oy, m);
        md->copies[md->ncopies++] = (Matrix){ m[0], m[4], m[8], m[12], m[1], m[5], m[9], m[13], m[2], m[6], m[10], m[14], m[3], m[7], m[11], m[15] };
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
            float unlit = (p->flags & 0x1) ? 1.0f : 0.0f;
            SetShaderValue(shader, loc_cutoff, &cutoff, SHADER_UNIFORM_FLOAT);
            SetShaderValue(shader, loc_unlit, &unlit, SHADER_UNIFORM_FLOAT);
            if (see_through) BeginBlendMode(p->blend == 2 ? BLEND_ALPHA : p->blend >= 5 ? BLEND_MULTIPLIED : BLEND_ADDITIVE);
            material.maps[MATERIAL_MAP_DIFFUSE].texture = pictures[p->picture].tex;
            DrawMeshInstanced(p->mesh, material, md->copies, md->ncopies);
            if (see_through) EndBlendMode();
        }
    }
}
void doodads_draw(Vector3 eye, const float sky[3])
{
    SetShaderValue(shader, loc_eye, &eye, SHADER_UNIFORM_VEC3);
    SetShaderValue(shader, loc_sky, sky, SHADER_UNIFORM_VEC3);
    draw_pass(0);
    rlDrawRenderBatchActive();
    rlDisableDepthMask();
    draw_pass(1);
    rlDrawRenderBatchActive();
    rlEnableDepthMask();
}
/* }}} */

/* {{{ doodads_counts */
void doodads_counts(int *nm, int *nc, int *ns)
{
    int copies = 0;
    for (int i = 0; i < nmodels; ++i) copies += models[i].ncopies;
    *nm = nmodels; *nc = copies; *ns = skipped_pieces;
}
/* }}} */
