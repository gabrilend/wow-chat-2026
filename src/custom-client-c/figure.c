/*
 * figure.c (issues 173i, 173j) - an animated model in the world; see figure.h
 *
 * For a general audience: builds a figure's pieces and skeleton from a
 * model, finds each piece's picture, and each frame bends the model to
 * its animation and draws it.
 */
#include "figure.h"
#include "blp.h"
#include "dbc.h"

#include "raymath.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static uint32_t u32le(const unsigned char *s, size_t at) { return s[at] | s[at + 1] << 8 | s[at + 2] << 16 | (uint32_t)s[at + 3] << 24; }

/* {{{ static texture_of: a decoded picture onto the graphics card */
static Texture2D texture_of(const BlpImage *img)
{
    Image im = { .data = img->rgba, .width = img->width, .height = img->height, .mipmaps = 1,
                 .format = PIXELFORMAT_UNCOMPRESSED_R8G8B8A8 };
    Texture2D t = LoadTextureFromImage(im);
    GenTextureMipmaps(&t);
    SetTextureFilter(t, TEXTURE_FILTER_TRILINEAR);
    SetTextureWrap(t, TEXTURE_WRAP_REPEAT);
    return t;
}
static int load_picture(MpqChain *chain, const char *name, Texture2D *out, char *why, int why_len)
{
    size_t len;
    const char *from;
    unsigned char *s = mpq_chain_read(chain, name, &len, &from);
    if (!s) { snprintf(why, why_len, "the picture %.200s is in none of the client's archives", name); return 1; }
    BlpImage img;
    char inner[300];
    int bad = blp_decode(s, len, &img, inner, sizeof inner);
    free(s);
    if (bad) { snprintf(why, why_len, "the picture %.120s: %.150s", name, inner); return 1; }
    *out = texture_of(&img);
    blp_free(&img);
    return 0;
}
/* }}} */

/* {{{ static build: pieces, points and skeleton from a read model
 * `shown` says which pieces show (NULL: all); `pics` holds one picture
 * per model texture slot (id 0 where the slot has none: its pieces are
 * left out). `base` is the model's archive path without its extension. */
static int build(Figure *f, MpqChain *chain, const M2Model *mod, const uint8_t *shown, const Texture2D *pics,
                 const char *base, char *why, int why_len)
{
    for (uint32_t u = 0; u < mod->nunits && f->npieces < 64; ++u) {
        M2Unit un = mod->units[u];
        if (un.piece >= mod->npieces || un.texture >= mod->ntextures) continue;
        if (shown && !shown[un.piece]) continue;
        if (pics[un.texture].id == 0) continue;
        M2Piece p = mod->pieces[un.piece];
        if (p.count == 0 || p.first + p.count > mod->nindices) continue;
        FigurePiece *fp = &f->pieces[f->npieces];
        Mesh m = { 0 };
        m.vertexCount = (int)p.count;
        m.triangleCount = (int)p.count / 3;
        m.vertices  = MemAlloc(sizeof(float) * 3 * p.count);
        m.normals   = MemAlloc(sizeof(float) * 3 * p.count);
        m.texcoords = MemAlloc(sizeof(float) * 2 * p.count);
        fp->point_of = malloc(sizeof(uint32_t) * p.count);
        for (uint32_t i = 0; i < p.count; ++i) {
            uint32_t k = mod->indices[p.first + i];
            if (k >= mod->nvertices) k = 0;               /* m2_read keeps indices in range; this guards the copy */
            M2Vertex v = mod->vertices[k];
            fp->point_of[i] = k;
            m.vertices[i * 3] = v.x; m.vertices[i * 3 + 1] = v.y; m.vertices[i * 3 + 2] = v.z;
            m.normals[i * 3] = v.nx; m.normals[i * 3 + 1] = v.ny; m.normals[i * 3 + 2] = v.nz;
            m.texcoords[i * 2] = v.u; m.texcoords[i * 2 + 1] = v.v;
        }
        UploadMesh(&m, true);                             /* dynamic: bent every frame */
        fp->mesh = m;
        fp->tex = pics[un.texture];
        fp->blend = un.blend;
        fp->colour = un.colour;
        fp->fade = un.fade;
        fp->layers = un.layers;
        fp->moving_uv = un.moving_uv;
        ++f->npieces;
    }
    if (f->npieces == 0) { snprintf(why, why_len, "%s: nothing to draw (no shown piece has a picture)", f->name); return 1; }
    f->nrest = mod->nvertices;
    f->rest = malloc(sizeof *f->rest * f->nrest);
    memcpy(f->rest, mod->vertices, sizeof *f->rest * f->nrest);

    /* the skeleton, and any animation kept in a .anim file */
    char path[300];
    size_t len;
    const char *from;
    snprintf(path, sizeof path, "%s.m2", base);
    unsigned char *m2 = mpq_chain_read(chain, path, &len, &from);
    char inner[300];
    if (!m2 || anim_read(m2, len, &f->anim, inner, sizeof inner)) {
        snprintf(why, why_len, "%s's skeleton (%s): %s", f->name, path, m2 ? inner : "not in the archives");
        free(m2);
        return 1;
    }
    free(m2);
    for (int i = 0; i < f->anim.nseqs; ++i) {
        if (!anim_needs_file(&f->anim, i)) continue;
        snprintf(path, sizeof path, "%s%04d-%02d.anim", base, f->anim.seqs[i].id, f->anim.seqs[i].variation);
        unsigned char *a = mpq_chain_read(chain, path, &len, &from);
        if (!a) { fprintf(stderr, "%s: %s is in none of the archives; that animation leaves it at rest\n", f->name, path); continue; }
        anim_attach_file(&f->anim, i, a, len);
    }
    if (f->anim.npoints != f->nrest) {
        snprintf(why, why_len, "%s: the skeleton's model has %u points, the mesh %u", f->name, f->anim.npoints, f->nrest);
        return 1;
    }
    f->poses = malloc(sizeof *f->poses * (f->anim.nbones ? f->anim.nbones : 1));
    f->scratch = malloc(sizeof *f->scratch * (f->anim.nbones ? f->anim.nbones : 1));
    f->bent = malloc(sizeof(float) * 6 * f->nrest);
    return 0;
}
/* }}} */

/* {{{ figure_from_character */
int figure_from_character(Figure *f, MpqChain *chain, const CharacterLook *look, char *why, int why_len)
{
    memset(f, 0, sizeof *f);
    f->scale = 1;
    Character ch;
    if (character_build(chain, look, &ch, why, why_len)) return 1;
    snprintf(f->name, sizeof f->name, "%.63s", strrchr(ch.base, '\\') ? strrchr(ch.base, '\\') + 1 : ch.base);
    Texture2D pics[64] = { 0 };
    Texture2D skin = texture_of(&ch.skin), hair = { 0 }, fur = { 0 };
    if (ch.hair.width) hair = texture_of(&ch.hair);
    if (ch.fur.width) fur = texture_of(&ch.fur);
    /* a character's slots: kind 1 its skin sheet, kind 6 its hair, kind 8
     * its fur (a tauren's tail and coat); the rest (capes, armour) wait for
     * items (173p) */
    for (uint32_t t = 0; t < ch.model.ntextures && t < 64; ++t) {
        if (ch.model.textures[t].kind == 1) pics[t] = skin;
        if (ch.model.textures[t].kind == 6) pics[t] = hair;
        if (ch.model.textures[t].kind == 8) pics[t] = fur;
    }
    int bad = build(f, chain, &ch.model, ch.shown, pics, ch.base, why, why_len);
    character_free(&ch);
    return bad;
}
/* }}} */

/* {{{ figure_from_display
 * CreatureDisplayInfo (3.3.5a): 1 id, 2 model (CreatureModelData id),
 * 5 scale (float), 7-9 the three skins (names without folder or .blp).
 * CreatureModelData: 1 id, 3 the model's path (.mdx; the archive holds .m2).
 * Pieces: the body group (ids under 100) and the first variant of every
 * other group (id % 100 == 1), the original's choice when the display
 * names no other (its geoset data, not read yet). */
static int open_table(MpqChain *chain, const char *name, Dbc *d, unsigned char **keep, char *why, int why_len)
{
    size_t len;
    const char *from;
    *keep = mpq_chain_read(chain, name, &len, &from);
    if (!*keep) { snprintf(why, why_len, "%s is in none of the client's archives", name); return 1; }
    return dbc_open(d, *keep, len, why, why_len);
}
int figure_from_display(Figure *f, MpqChain *chain, int display_id, char *why, int why_len)
{
    memset(f, 0, sizeof *f);
    Dbc di, md;
    unsigned char *di_s = NULL, *md_s = NULL;
    if (open_table(chain, "DBFilesClient\\CreatureDisplayInfo.dbc", &di, &di_s, why, why_len) ||
        open_table(chain, "DBFilesClient\\CreatureModelData.dbc", &md, &md_s, why, why_len)) { free(di_s); free(md_s); return 1; }
    int row = -1;
    for (uint32_t r = 0; r < di.rows; ++r) if (dbc_u32(&di, r, 1) == (uint32_t)display_id) { row = (int)r; break; }
    if (row < 0) { snprintf(why, why_len, "no creature display %d in CreatureDisplayInfo", display_id); free(di_s); free(md_s); return 1; }
    uint32_t model_id = dbc_u32(&di, (uint32_t)row, 2), scale_bits = dbc_u32(&di, (uint32_t)row, 5);
    memcpy(&f->scale, &scale_bits, 4);
    if (!(f->scale > 0.01f && f->scale < 100)) f->scale = 1;
    char skins[3][128];
    for (int k = 0; k < 3; ++k) snprintf(skins[k], sizeof skins[k], "%s", dbc_text(&di, (uint32_t)row, 7 + k));
    char base[260] = "";
    for (uint32_t r = 0; r < md.rows; ++r)
        if (dbc_u32(&md, r, 1) == model_id) { snprintf(base, sizeof base, "%s", dbc_text(&md, r, 3)); break; }
    free(di_s); free(md_s);
    if (!base[0]) { snprintf(why, why_len, "display %d names model %u, which CreatureModelData lacks", display_id, model_id); return 1; }
    char *dot = strrchr(base, '.');
    if (dot) *dot = '\0';
    char folder[260];
    snprintf(folder, sizeof folder, "%s", base);
    char *cut = strrchr(folder, '\\');
    if (cut) cut[1] = '\0'; else folder[0] = '\0';
    snprintf(f->name, sizeof f->name, "display %d (%s)", display_id, cut ? base + (cut - folder) + 1 : base);

    char path[300];
    size_t mlen, slen;
    const char *from;
    snprintf(path, sizeof path, "%s.m2", base);
    unsigned char *m2 = mpq_chain_read(chain, path, &mlen, &from);
    snprintf(path, sizeof path, "%s00.skin", base);
    unsigned char *skin = mpq_chain_read(chain, path, &slen, &from);
    if (!m2 || !skin) { snprintf(why, why_len, "%s: its %s is in none of the archives", f->name, !m2 ? ".m2" : "00.skin"); free(m2); free(skin); return 1; }
    M2Model mod;
    char inner[300];
    int bad = m2_read(m2, mlen, skin, slen, &mod, inner, sizeof inner);
    free(m2); free(skin);
    if (bad) { snprintf(why, why_len, "%s: %s", f->name, inner); return 1; }

    Texture2D pics[64] = { 0 };
    for (uint32_t t = 0; t < mod.ntextures && t < 64; ++t) {
        uint32_t kind = mod.textures[t].kind;
        if (kind == 0 && mod.textures[t].file[0]) snprintf(path, sizeof path, "%s", mod.textures[t].file);
        else if (kind >= 11 && kind <= 13 && skins[kind - 11][0]) snprintf(path, sizeof path, "%s%s.blp", folder, skins[kind - 11]);
        else continue;                                     /* a slot this display doesn't fill */
        if (load_picture(chain, path, &pics[t], inner, sizeof inner)) {
            snprintf(why, why_len, "%s: %s", f->name, inner);
            m2_free(&mod);
            return 1;
        }
    }
    uint8_t *shown = calloc(mod.npieces ? mod.npieces : 1, 1);
    for (uint32_t i = 0; i < mod.npieces; ++i) shown[i] = mod.pieces[i].id < 100 || mod.pieces[i].id % 100 == 1;
    bad = build(f, chain, &mod, shown, pics, base, why, why_len);
    free(shown);
    m2_free(&mod);
    return bad;
}
/* }}} */

/* {{{ figure_from_model */
int figure_from_model(Figure *f, MpqChain *chain, const char *path_in, char *why, int why_len)
{
    memset(f, 0, sizeof *f);
    f->scale = 1;
    char base[260], path[300], inner[300];
    snprintf(base, sizeof base, "%s", path_in);
    char *dot = strrchr(base, '.');
    if (dot) *dot = '\0';
    snprintf(f->name, sizeof f->name, "%.63s", strrchr(base, '\\') ? strrchr(base, '\\') + 1 : base);
    size_t mlen, slen;
    const char *from;
    snprintf(path, sizeof path, "%s.m2", base);
    unsigned char *m2 = mpq_chain_read(chain, path, &mlen, &from);
    snprintf(path, sizeof path, "%s00.skin", base);
    unsigned char *skin = mpq_chain_read(chain, path, &slen, &from);
    if (!m2 || !skin) { snprintf(why, why_len, "%s: its %s is in none of the archives", f->name, !m2 ? ".m2" : "00.skin"); free(m2); free(skin); return 1; }
    M2Model mod;
    int bad = m2_read(m2, mlen, skin, slen, &mod, inner, sizeof inner);
    free(m2); free(skin);
    if (bad) { snprintf(why, why_len, "%s: %s", f->name, inner); return 1; }
    Texture2D pics[64] = { 0 };
    for (uint32_t t = 0; t < mod.ntextures && t < 64; ++t) {
        if (mod.textures[t].kind != 0 || !mod.textures[t].file[0]) continue;
        if (load_picture(chain, mod.textures[t].file, &pics[t], inner, sizeof inner)) {
            snprintf(why, why_len, "%s: %s", f->name, inner);
            m2_free(&mod);
            return 1;
        }
    }
    bad = build(f, chain, &mod, NULL, pics, base, why, why_len);
    m2_free(&mod);
    return bad;
}
/* }}} */

/* {{{ figure_tint */
void figure_tint(const Figure *f, int piece, const MovesState *moves, uint32_t global_ms, float rgba[4])
{
    rgba[0] = rgba[1] = rgba[2] = rgba[3] = 1;
    const FigurePiece *p = &f->pieces[piece];
    const unsigned char *m2 = f->anim.m2;
    uint32_t ms = moves->ms > 0 ? (uint32_t)moves->ms : 0;
    if (p->colour >= 0) {
        size_t at = (size_t)u32le(m2, 76) + (size_t)p->colour * 40;
        AnimTrack c = anim_track_at(m2, at), a = anim_track_at(m2, at + 20);
        float col[3] = { 1, 1, 1 }, op = 1;
        anim_track_value(&f->anim, &c, moves->seq, ms, global_ms, ANIM_VEC3, col);
        anim_track_value(&f->anim, &a, moves->seq, ms, global_ms, ANIM_SHARE, &op);
        rgba[0] = col[0]; rgba[1] = col[1]; rgba[2] = col[2]; rgba[3] = op;
    }
    if (p->fade >= 0) {
        AnimTrack t = anim_track_at(m2, (size_t)u32le(m2, 92) + (size_t)p->fade * 20);
        float op = 1;
        anim_track_value(&f->anim, &t, moves->seq, ms, global_ms, ANIM_SHARE, &op);
        rgba[3] *= op;
    }
}
/* }}} */

/* {{{ figure_bend */
void figure_bend(Figure *f, const MovesState *moves, uint32_t global_ms)
{
    moves_pose(moves, &f->anim, global_ms, f->poses, f->scratch);
    for (uint32_t i = 0; i < f->nrest; ++i) {
        float p[3] = { f->rest[i].x, f->rest[i].y, f->rest[i].z }, n[3] = { f->rest[i].nx, f->rest[i].ny, f->rest[i].nz };
        anim_skin_point(&f->anim, (const float (*)[16])f->poses, i, p, f->bent + i * 6, n, f->bent + i * 6 + 3);
    }
    for (int k = 0; k < f->npieces; ++k) {
        Mesh *m = &f->pieces[k].mesh;
        for (int v = 0; v < m->vertexCount; ++v) {
            const float *b = f->bent + f->pieces[k].point_of[v] * 6;
            memcpy(m->vertices + v * 3, b, sizeof(float) * 3);
            memcpy(m->normals + v * 3, b + 3, sizeof(float) * 3);
        }
        UpdateMeshBuffer(*m, 0, m->vertices, (int)(sizeof(float) * 3 * m->vertexCount), 0);   /* buffer 0: positions */
        UpdateMeshBuffer(*m, 2, m->normals, (int)(sizeof(float) * 3 * m->vertexCount), 0);    /* buffer 2: facings */
    }
}
/* }}} */

/* {{{ figure_draw, figure_free */
void figure_draw(const Figure *f, Shader shader, Matrix place)
{
    Material mat = LoadMaterialDefault();
    mat.shader = shader;
    Matrix at = MatrixMultiply(MatrixScale(f->scale, f->scale, f->scale), place);
    for (int k = 0; k < f->npieces; ++k) {
        mat.maps[MATERIAL_MAP_DIFFUSE].texture = f->pieces[k].tex;
        DrawMesh(f->pieces[k].mesh, mat, at);
    }
    MemFree(mat.maps);                                  /* the default material's map list; the shader and pictures are kept */
}
void figure_free(Figure *f)
{
    for (int k = 0; k < f->npieces; ++k) { UnloadMesh(f->pieces[k].mesh); free(f->pieces[k].point_of); }
    anim_free(&f->anim);
    free(f->rest); free(f->poses); free(f->scratch); free(f->bent);
    memset(f, 0, sizeof *f);
}
/* }}} */
