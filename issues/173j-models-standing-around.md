# 173j - Models Standing Around

## Status
- Created: 2026-10-05
- Phase: 1
- Parent: 173 (the custom client)
- Blocked by: 173i
- Priority: Medium (fifth of the owner's next five)

## Origin

See 173f (the owner's order, 2026-10-05: "then summon a couple arbitrary
models that just stand around and do various animations").

## Current Behavior

**Built 2026-10-06**, in C:
- **`figure.h` / `figure.c` make any animated model a "figure".** A
  figure has its pieces, its points as made, its skeleton and
  animations, and its bending each frame. A figure comes from either:
  - a character's look (her, a tauren), with pictures painted by
    `character.c`; or
  - a creature display: the client's CreatureDisplayInfo row gives the
    model (through CreatureModelData), its size, and up to three skins,
    which fill the model's picture slots of kind 11-13.
- **Creature pieces:** the body group (ids under 100) and the first
  variant of each other group show. The display's own geoset choice
  isn't read yet.
- **She is now a figure too.** `main.c` lost its own copy of the model
  code.
- **The bystanders**, in a table in `main.c` (configuration in
  structure, not in the settings file):
  - a tauren man;
  - a furbolg (display 145);
  - the ancient protector (display 860, which the game draws at 0.33
    size, about 2 yards: no model is called a treant);
  - a nightsaber (display 321, the black-striped tiger model).
  They stand 7 to 14 yards ahead of her start, facing her. Each casts a
  ground shadow sized by its scale.
- **Cycling:** each holds an animation for 4 seconds, then moves to the
  next its model has: stand, talk, roar, unarmed attack, ready, dance,
  wave, bow, cheer, cast. The changes are blended, and staggered so the
  figures don't change together.
- **Calls added to `moves.c`** for figures with no mover: one plays an
  animation, one advances its clock.
- **A gap found with the tauren:** the client's CharSections table names
  pictures its archives don't hold (a scalp, and a hair picture named
  like a face). The character builder now leaves such a layer unpainted
  and reports it by name, rather than refusing the whole character.
  Recorded in 173d.
- **Tests:** two checks. A bystander's next animation blends in, and
  loops at its own pace.
- **Pictures:** all four stand facing her.

## Intended Behavior

A few models (creatures and other races, chosen from the archives) stand
near her, each cycling through several of its own animations (idle,
talk, emotes, attack stands), proving the animation reader works on
models other than hers.

## Suggested Implementation Steps

1. A small list of models and their animations, in the client's
   settings.
2. Place them round the start point; cycle animations on a timer.
3. A picture.

## Open Questions

None. (Which models: the first pick, with the ancient protector for the
treant and the tiger model for the nightsaber; 2026-10-06.)
