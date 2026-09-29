# Road to 1.0

Written 2026-09-28. Starts where `docs/road-to-release.md` ends (basic open
to the public, running on the stock client) and runs to 1.0: the game on
its own client, with all of its own assets. It interlocks with
world-edit-to-execute (`/home/ritz/programming/ai-stuff/world-edit-to-execute/`),
built from the week of 2026-10-05.

The owner's timeline (2026-09-28): basic with buddies complete within two
weeks, a prototype before 2026-10-01 if possible; asset creation from the
third week on.

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

## Stage C: every asset our own

- Feldowinn's Retribution Paladin set first; then every class's gear.
- Body armour as real models on our client (the stock client paints it
  onto the body as textures).
- Creatures and bosses: Kazzak with a hitbox that fits his size;
  Sargobras's own look (617f).
- Items and interfaces that waited on the client: the gem vault's bag per
  tab (617l), item icons (the stones-per-icon work), crowsign's spirit
  stones and their server-wide element boons (future exploration).
- The equipment portrait grid (159) and the explore profile's images
  (153).

## Stage D: 1.0

- Our client, our assets, the basic game with buddies, open to the
  public, with the safety work of 158 carried over to shipping a client
  (signed builds, checksums).
- After 1.0: friends and guilds across servers (1007), the multi-machine
  cluster (913), language-model guidance for bots (916, 917), the expert
  profile (156), Northrend at sixty (155s).
