/*
 * character.h (issue 173k; the C twin of lib/character.lua) - one player
 * character, put together
 *
 * For a general audience: a race's model holds every hair style and
 * clothing shape at once, and its skin is painted from several pictures
 * laid onto one sheet (body, face, scalp, underwear). The game picks which
 * pieces show and which pictures go where from its own tables
 * (CharHairGeosets, CharSections); this does the same for one character's
 * choices. Naked for now: clothes come with items (617r5).
 */
#ifndef EG_CHARACTER_H
#define EG_CHARACTER_H

#include "blp.h"
#include "m2.h"
#include "mpq.h"

typedef struct {
    int race, sex;                         /* ChrRaces id; 0 male, 1 female */
    int skin, face, hair_style, hair_color;/* the character-creation choices, from 0 */
} CharacterLook;

typedef struct {
    M2Model  model;                        /* the whole model */
    uint8_t *shown;                        /* per piece: 1 when it shows */
    BlpImage skin;                         /* texture kind 1: the finished skin sheet */
    BlpImage hair;                         /* texture kind 6 (width 0 when none) */
} Character;

int  character_build(MpqChain *archives, const CharacterLook *look, Character *out, char *why, int why_len);
void character_free(Character *c);

#endif
