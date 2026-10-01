# Road to 1.0

Written 2026-09-28, revised 2026-10-01. Starts where
`docs/road-to-release.md` ends (basic open to the public, running on the
stock client) and runs to 1.0: the game on its own client, still showing
Blizzard's art, with our generators and galleries working to replace it.
After 1.0 comes the full version, every asset our own, which can be sold.

## What 1.0 is, and what comes after (owner, 2026-10-01)

> our client, their art, our generators / galleries and such, with the
> promise that with the hard work of people who care enough to play the
> game and vote on models and such, soon we will be able to release a
> full version which can be sold to support further development. We
> shouldn't work on the project very much while we aren't getting any
> money from it, but we should build it to be functional enough that, if
> people care, it can be developed into something that does create money.

So 1.0 does not wait on replacing the art; it waits on the machinery that
replaces it (the client, the generators, the gallery and its votes, the
similarity score) working end to end. Replacing every asset is the full
version's work, paced by the players who vote and the money that comes in.

## The three projects

- **This project** (Everland Ghostsong): the server, its game and its
  buddies.
- **world-edit-to-execute**
  (`/home/ritz/programming/ai-stuff/world-edit-to-execute/`): the WC3
  engine; its phase W holds the readers, the capture rig and the asset
  forge.
- **The custom client** (`/mnt/mtwo/games/azeroth-core/custom-client/`):
  a third project, separate from both, that plays the assets and gameplay
  of both. The other two do most of the work on it.

The client work starts this week (owner, 2026-10-01). It is not on
world-edit-to-execute's critical path, and this project's 1.0 waits on it
without that being recorded there as a block.

## Stage A: the client becomes ours (world-edit-to-execute, phase W)

- Readers for the game's archives, tables, textures and models (W01), in
  the custom client's library.
- Drawing the game's models (W03), and the capture rig that photographs the
  real client for comparison (W04).
- The asset forge (W05): find an openly licensed model or generate one,
  fit it to the original's size and pivot, rate it, install the best into
  an override pack; its similarity score, borrowed skeletons, the "default
  client compatible" seal, the clean-room describe/build/check loop, the
  body-plan fit (W05a-e).
- One theme across every model (W06), and the phase demo (W07).
- From here on, changing the client is allowed: everything that waited on
  "no client patches" can be done.

## Stage B: the asset pipeline (issue 506 and its sub-issues)

One pipeline for both projects (owner, 2026-10-01: "same pipeline"): a
model made here passes the gallery's votes *and* world-edit-to-execute's
similarity score (W05a), like any model made there.

- ComfyUI finished and tested, built-in nodes only; image-to-3D weights,
  on a remote GPU host if the 1080 Ti can't hold them.
- Concept art per design, voted in the gallery (506a, 506b, 506d).
- Views on the camera rings: 8 compass views at 1, 3 or 5 heights
  (506e).
- Meshes and textures from the views (506f), reduced to each item's
  triangle budget, textures converted for the client.
- Skeletons borrowed from stock models, then generated animations, pose
  by pose from before/after pairs (506g, 506i).
- Our own model format first; export to the stock M2 where the stock
  client still matters (506h).

## Stage C: 1.0

- Our client, Blizzard's art, our generators and galleries, the basic
  game with buddies, open to the public, with the safety work of 158
  carried over to shipping a client (signed builds, checksums).
- Players vote in the gallery; generation runs as credits allow (see the
  open question below).

## Stage D: the full version, every asset our own

- A Retribution Paladin set first; then every class's gear.
- Body armour as real models on our client (the stock client paints it
  onto the body as textures).
- Creatures and bosses: Kazzak with a hitbox that fits his size;
  Sargobras's own look (617f).
- Items and interfaces that waited on the client: the gem vault's bag per
  tab (617l), item icons (the stones-per-icon work), crowsign's spirit
  stones and their server-wide element boons (future exploration).
- The equipment portrait grid (159) and the explore profile's images
  (153).
- What needs a "replaced" measure (owner, 2026-10-01): only what is pulled
  directly from the game and then used as an input to an AI process.
  Other Blizzard-derived content (quests, NPC text, spell data from the
  server's database) is examined later and changed if necessary.
- Sold to support further development.
- Also after 1.0: friends and guilds across servers (1007), the
  multi-machine cluster (913), language-model guidance for bots (916,
  917), the expert profile (156), Northrend at sixty (155s).

## Open questions

1. **Paying for generation.** Model generation and rendering cost money.
   The owner's idea (2026-10-01): each donation buys that much generation
   credit, and a soramech running in the server chooses what to spend it
   on, moving between three heuristics as the project needs: the next
   model in the queue, the model still most similar to its original, or
   the most downvoted. Waits on the owner's Linode host. (Choosing *which*
   model to rework by its score is allowed; the score is still never
   shown to whatever builds the next candidate, W05a.)
2. **Which machine renders the startup photoshoot** (W05a): the game
   server draws nothing, so a copy of the custom client, drawing off
   screen, has to do it while logins wait.

## Related documents

- `docs/road-to-release.md`: from today to the public release.
- `docs/gear-3d-pipeline.md`: the 3D pipeline in detail.
- world-edit-to-execute `docs/wow-client-bridge.md` and
  `issues/W05a-similarity-to-original-score.md`: the client bridge and the
  similarity score.
