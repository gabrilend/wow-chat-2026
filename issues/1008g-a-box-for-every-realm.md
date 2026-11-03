# 1008g - A Box for Every Realm

## Status
- Created: 2026-10-28
- Parent: Issue 1008 (journals-of-what-each-player-saw), beside 1008f
  (the connection page this dresses)
- Phase: 10

## Origin

Asked whether a buddy is the same feature as a playerbot, for the
connection page's comparison table, the owner, 2026-10-28:

> describe it like you're walking through best-buy after a 2 hour car
> ride and you've been obsessed with fantasy because of Lord of the Rings
> and Dragon Warrior so you stumble across a box for World of Warcraft
> right in the center of Circuit City or Costco and you're reading on the
> back of the box about... well, one box per realm. Actually inside of the
> frutiger aero theming can you create box art for each of them? It can
> use stable diffusion at /mnt/kaun/stable-diffusion/ but it shouldn't use
> any of the other IP licensed stuff for world of warcraft - if you want
> to say something like "orc" or "night-elf" or similar make sure you say
> "off-brand night elf" and make sure it's tied to the token that you're
> using, so it treats "night-elf" as one token even though it's two words
> and "off-brand night-elf" as one token, even though it's four words. It
> should be a different token than "night-elf" not a modification to it -
> in this way, we are emphasizing the discrepancies, and everyone knows
> the original is the best, the knock-off is typically lower quality and
> definitely of slightly different proportions. Some even call it a form
> of inanimate uncanny valley. There's nothing quite like the real
> thing... Anyway that should help keep us separate enough while still
> having the type of pictures we want.

## Overview

Each realm on the connection page becomes a game box on a shop shelf: a
front with generated cover art and the realm's name, and a back, read
when the realm is opened, written in the voice of a kid who has just
found it after a long car ride. The cover art is made by Stable Diffusion
(Dreamshaper 8, through the ComfyUI installation at
`/mnt/kaun/stable-diffusion/`) from prompts that never name the game, its
maker, or its own peoples.

## Current Behavior

Built and checked:

- `config/box-art/off-brand-tokens.lua`: eight off-brand peoples, each
  one token (night-elf, orc, dwarf, gnome, undead, bull-folk,
  death-knight, demon), with their plain words and the shared knock-off
  words.
- `scripts/make-off-brand-embeddings`: reads Dreamshaper 8's own word
  table and vocabulary, refuses any word that is not one whole word to
  the encoder (it caught "fangs" and "runes"), and wrote the eight files
  into `/mnt/kaun/stable-diffusion/models/embeddings/` (each one vector,
  scaled to a word's usual length, about 0.39).
- `config/box-art/realms.lua`: per realm, the cover prompt (off-brand
  tokens only; EasyNegative and "text, letters, logo, ..." on the
  negative side) and the box's back, five lines in the kid's voice, each
  a fact from that realm's page.
- `scripts/write-connection-page`: each realm row is a box (a front
  turned on its spine, the realm's name and number on it; turned
  face-on when opened) and an opened realm shows the box's back first.
  A realm with no kept cover gets a plain glass front, allowed with a
  warning only in a `--preview` page.

Built, not yet run: `scripts/make-box-art` (the workflow, the batch per
realm, the candidates and their notes, `--keep`). ComfyUI does not start
today: its run script says the installation has not finished an update
since its dependencies moved, and asks for
`/mnt/kaun/stable-diffusion/update`, which is that project's own install
step, left to the owner.

## Intended Behavior

### One token per off-brand people

A prompt word like "night elf" is two words to Stable Diffusion's text
encoder (CLIP), and both carry what the encoder learned from pictures of
the original. The owner's rule: an off-brand people is **one token of
its own**, "a different token than night-elf, not a modification to it".

In ComfyUI a token can be an embedding file: a named vector, written in a
prompt as `embedding:NAME`, that the text encoder uses in place of a word.
Each off-brand people is one such vector, made **only from plain words**
(for example "elf", "violet", "moonlit", "tall") and from words for a
knock-off ("plastic", "bootleg", "uncanny", "lopsided"): the average of
those words' own vectors in the encoder's table, scaled to a word's usual
length. The original name is never one of the words, so nothing the
encoder learned from the original is in the token. The knock-off words
are in every off-brand token, so the result is, as asked, "of slightly
different proportions".

No "night-elf" token (the original, as one token) is made: the pictures
need only the off-brand ones, and making the original would put the
original's look in a file of ours.

### The prompts

- Never name the game, its maker, its places or its peoples; the
  off-brand tokens stand in for peoples.
- Every prompt's negative side names what to keep away from: logos, text
  and lettering (Stable Diffusion's letters are noise; the title is set
  in the page's own type over the art), and the original's trademarks.
- Style words shared by all six: a late-2000s PC game box cover, glossy,
  painted, dramatic light, with the page's sky-glass-and-bubble palette
  where it suits the realm.

### The box on the page

Closed, a realm is a box front (the art, the realm's name, a small level
range sticker from the comparison table) in a shelf row. Opened, the box
turns to show its back: the blurb, then the realm's points as the page
already shows them, and the "Connect" button. Boxes turn with a 3D
transform; with reduced motion asked for, they swap without turning.

### Keeping the pictures

Stable Diffusion's results vary with its seed, so the pictures are kept,
not regenerated on every build: `assets/box-art/<realm>.png`, each with a
`.info` beside it (prompt, negative prompt, seed, steps, model, the
embeddings and their fingerprints). `scripts/make-box-art <realm>` makes
new candidates in `tmp/shared-memory/box-art/`; `--keep N` files
candidate N as the realm's picture.

## Suggested Implementation Steps

1. The off-brand tokens and their maker (LuaJIT: reads the text
   encoder's word table and vocabulary from the model's own files,
   writes the embedding files). Test: each token's vector is the scaled
   average of exactly its listed words, and the original's name is in no
   list.
2. The realms' prompts and back text.
3. `scripts/make-box-art`: the workflow (API format) built in the
   script, sent to ComfyUI's `/prompt`, pictures collected from its
   output; a goodbye receipt (pictures made, seconds, seeds).
4. The boxes on the page.

## Open Questions

1. **Where the embedding files go.** ComfyUI reads embeddings from
   `/mnt/kaun/stable-diffusion/models/embeddings/` (it holds EasyNegative,
   which the negative prompts use). The
   maker writes them there, named `ghostsong-...` so they cannot be
   mistaken for that project's own. Acceptable, or should that project
   point ComfyUI at a folder of ours instead?

## Related
- `issues/1008f-how-to-connect-and-read-your-journal.md`
- `/mnt/kaun/stable-diffusion/ai-stuff/docs/012-the-models.md`: the
  model and what an embedding is
