/*
 * figure.h (issues 173i, 173j) - an animated model in the world
 *
 * For a general audience: a "figure" is one animated model drawn in the
 * world: her, another player's race, or a creature. It holds the model's
 * pieces (one mesh and picture each), its points as made, and its
 * skeleton and animations (anim.h). Each frame its bones are posed (by a
 * MovesState, moves.h), its points bent to follow, and each piece's mesh
 * refreshed from them.
 *
 * Where a figure's pictures come from:
 *   a character (figure_from_character): its finished skin sheet and its
 *     hair, as character.c paints them;
 *   a creature (figure_from_display): the creature's display row in the
 *     client's CreatureDisplayInfo table names its model (through
 *     CreatureModelData) and up to three skins; a model's pictures of kind
 *     11, 12 and 13 are those skins, found in the model's own folder;
 *   any model: pictures of kind 0 are named inside the model.
 */
#ifndef EG_FIGURE_H
#define EG_FIGURE_H

#include "anim.h"
#include "character.h"
#include "moves.h"
#include "mpq.h"
#include "raylib.h"

typedef struct {
    Mesh       mesh;
    Texture2D  tex;
    uint32_t  *point_of;              /* per mesh corner: the model point it is */
    uint16_t   blend;                 /* the piece's blend mode (m2.h: 0 solid ... 4 added light) */
    int        colour, fade;          /* its animated tint's tracks (m2.h's M2Unit), -1 none */
    int        layers, moving_uv;     /* two-picture pieces and moving picture positions (not drawn right yet) */
} FigurePiece;

typedef struct {
    char         name[64];            /* for messages */
    FigurePiece  pieces[64];  int npieces;
    M2Vertex    *rest;        uint32_t nrest;      /* points and facings as made */
    Anim         anim;
    float      (*poses)[16], (*scratch)[16];
    float       *bent;                /* per point: bent position, then facing */
    float        scale;               /* the display's size (1 for characters) */
} Figure;

int  figure_from_character(Figure *f, MpqChain *chain, const CharacterLook *look, char *why, int why_len);
int  figure_from_display(Figure *f, MpqChain *chain, int display_id, char *why, int why_len);

/* Any model by its archive path (.mdx or .m2): every piece shows, every
 * picture is named inside the model (kind 0); for skyboxes (173n). */
int  figure_from_model(Figure *f, MpqChain *chain, const char *path, char *why, int why_len);

/* A piece's animated tint now (red, green, blue, opacity, 0-1): its colour
 * track pair times its transparency track at the moves' animation and
 * moment; white and whole when it has none. */
void figure_tint(const Figure *f, int piece, const MovesState *moves, uint32_t global_ms, float rgba[4]);

/* Poses the bones by `moves` and bends the points into the meshes. */
void figure_bend(Figure *f, const MovesState *moves, uint32_t global_ms);

/* Draws it at `place` (turn and position; the figure's own scale is
 * applied inside) with `shader` (the model shader: texture0, cut-outs). */
void figure_draw(const Figure *f, Shader shader, Matrix place);

void figure_free(Figure *f);

#endif
