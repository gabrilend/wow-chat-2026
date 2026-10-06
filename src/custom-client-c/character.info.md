# character

*Written by `scripts/generate-custom-client-info` from `character.h`; don't edit, re-run it.*

character.h (issue 173k; the C twin of lib/character.lua) - one player
character, put together

For a general audience: a race's model holds every hair style and
clothing shape at once, and its skin is painted from several pictures
laid onto one sheet (body, face, scalp, underwear). The game picks which
pieces show and which pictures go where from its own tables
(CharHairGeosets, CharacterFacialHairStyles, CharSections); this does
the same for one character's choices, and dresses it in its items
(173p).

## What it offers

- `type CharacterLook`
  the slots a character wears things in (173p), in the order they are
  painted onto the skin sheet when two cover the same region: what lies
  under is painted first
- `type CharacterAttachment`
  an item model hung from one of the character's attachment points (173p):
  model and picture archive paths, and the point (M2 attachment id: 1
  right hand, 2 left hand, 0 shield, 5 right shoulder, 6 left shoulder,
  11 helm)
- `type Character`
- `int character_build(MpqChain *archives, const CharacterLook *look, Character *out, char *why, int why_len);`
- `void character_free(Character *c);`
