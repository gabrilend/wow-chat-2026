# 1103 - Pictures Redrawn from Their Recipe

## Status
- Created: 2026-10-30
- Phase: 1 (tooling)
- Related: 1102 (the answer pages, whose gifs were the first set), the gif
  tools (`scripts/compose-architecture-gifs`, `scripts/render-gif-scores`)
- Priority: Medium
- State: built; one open question

## Origin

The owner, 2026-10-30, on being told the full-size gifs live only in RAM
and the gif tools can redraw them exactly:

> the gif tools can redraw the originals exactly if we pin a specific
> version of the gif generator in the description of the gifs. Then we
> should have capability to automatically downgrade to that version,
> deterministically recreate the gifs, then re-apply updates to return to
> baseline. Ideally, in a separate branch or something. Then, we don't
> need the shrunk versions, we can always use the full versions, and
> archive in git the prompt that made them (inputs) and the pinned
> project version that did (parameters)

## Current Behavior

**Built 2026-10-30.** The gifs are drawn by the sibling gif generator
(`/mnt/mtwo/programming/ai-stuff/gif-generator`, inside the ai-stuff
repository) from scores this project's composer writes.
- `scripts/render-gif-scores` pins the generator (its repository, folder
  and commit) and writes `recipe.json` beside every drawing, with each
  score's and gif's sha256; it refuses to draw with uncommitted changes in
  the generator's code (`--no-recipe` draws unpinned, as the redraw does).
- `scripts/redraw-gifs SET` checks the scores against the recipe, takes
  the generator's code at the pinned commit out of its repository with
  `git archive` into `tmp/shared-memory/gif-generator-<commit>/`, draws
  with that copy and checks every gif's sha256. The generator's own
  checkout is never touched.
- The first set, the 25 ideas for the architecture pages, is kept as its
  scores and recipe in `assets/gifs/architecture-ideas/attempt-1/`
  (generator at 9d32166e6). Proven twice: drawn again pinned, all 25 were
  identical to the originals of 2026-10-29; redrawn from the archive, all
  25 matched the recipe.
- The shrunk copies are gone from the dormant answer pages; their README
  says how to redraw.

## Intended Behavior

- **A recipe beside every drawing.** When a set of gifs is drawn, a
  recipe is written with it: the generator's repository, its folder in
  it, the commit it was at, and for each gif its score's fingerprint and
  the gif's own (sha256). A generator with uncommitted changes in its code
  can't be pinned, and the drawing says so and stops, rather than write a
  recipe that couldn't be followed.
- **Kept in git: inputs and parameters, not pictures.** The scores (the
  inputs, the "prompt that made them") and the recipe (the pinned version,
  the parameters) are committed. The gifs themselves are not: they are
  drawn again on demand, full size.
- **Redrawn by the pinned version, apart from the live one.** The redraw
  tool takes the generator's code at the pinned commit straight out of its
  repository (`git archive`) into a folder of its own in the RAM drive,
  draws the scores with that copy, and checks every gif's fingerprint
  against the recipe. The generator's own checkout is never touched: no
  downgrade, no branch to return from; the live version stays where it
  is, which is the "return to baseline" for free.
- **No shrunk copies.** Pages that show the gifs point at the redrawn
  full-size ones.

## Suggested Implementation Steps

1. `scripts/render-gif-scores` writes `recipe.json` beside each drawing,
   and refuses to draw with a generator whose code has uncommitted changes.
2. `scripts/redraw-gifs RECIPE`: the pinned code out of the repository,
   every score drawn with it, every fingerprint checked; a mismatch is an
   error naming the gif.
3. The first set (the 25 ideas for the architecture pages, drawn
   2026-10-29) archived as scores and recipe in
   `assets/gifs/architecture-ideas/attempt-1/`, and redrawn once to prove
   the redraw gives the same bytes.
4. The shrunk copies removed from the dormant answer pages; their README
   says how to redraw.

## Open Questions

1. When the gif generator moves to its own repository one day, should
   recipes name the repository by its path on this computer (as now) or
   by a remote address, so another computer can follow them?
