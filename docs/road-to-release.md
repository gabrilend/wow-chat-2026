# Road to Release

Written 2026-09-28, from the open issues. "Release" here means the basic
profile (levels 1-60, then Outland at 60) open to the public, with buddies.
The custom client, generated 3D models and the later profiles come after,
in the last section. Each milestone names its issues (number and name);
the issues hold the detail. Counts of done and open work come from
`progress-dashboard.lua <project> -m`, not from this page.

Order (the owner, 2026-09-28): the foundations first, then buddy
behaviour, then the rest; the first real run comes last, since problems in
compiling and starting are implementation details, worked through when
everything is tested at once. Security (Milestone 4) is mostly in hand.
Dungeon damage and healing multipliers (155i) and true creature levels
(155m) can wait.

## Milestone 5 (last): the first real run

Almost everything built in September has never run on a server: it compiles
and passes its offline tests, no more. Build and install basic, and try
each piece in game.

- Buddies: the companion account and creation (617a1-a3), login and
  logout (617c1), Sargobras and clan naming (617b, 617l), talent plans
  (617g), the roam strategy and roaming core (617e1, 617e2), creatures,
  chests and nodes (617e3), town visits, beds and fishing (617e4),
  exploration modes (617e6), the proximity and far parties with the human-
  only group bonus (617c2).
- The clan lock (617l), the death knight sacrifice (718).
- Basic rules: the talent cap (155g), crushing blows from 8 levels up
  (B031, 803), the uncapped honor and respecs (155r), closed world
  channels (155x), world boss respawns, Kazzak's swarm and size, and the
  battle bonus (155j).
- Each piece's issue lists what to try. What breaks is fixed; what works
  is marked done and committed.

## Milestone 1: the basic profile's foundations

Most of basic's content issues wait on these being finished and checked.

- Plumbing, config gates, world-database and source patches (155a, 155b,
  155c).
- Rotating starting valleys and faction-wide quests (155d, 155e).
- (Can wait: true creature levels instead of the skull (155m); dungeon
  damage and healing multipliers (155i).)

## Milestone 2: buddies, complete

- A buddy's start: its starting kit, with food (617a4); hidden from other
  players and locked to its owner (617a5); loyal, refusing strangers'
  invitations (617c4).
- Following the owner into dungeons (617c3); quests completed alongside
  the owner (617d).
- Fighting together in game: helping clanmates, the kraken pattern, pulls
  and kiting, party character by composition (617e5); the dungeon scene's
  tunnel fixes first (617e5, findings of 2026-09-28).
- The zone view from above (617e7) as the check that roaming reads right
  at zone scale.
- The economy around buddies: auction house (617h), loot rolls and
  upgrades (617j), professions, including cooking, first aid and fishing
  for all (617k), task hunts (617m), battlegrounds (617i).
- Sargobras's own look (617f), waiting on the custom client for anything
  beyond a stock appearance.

## Milestone 3: the world from 1 to 60, and Outland at 60

- Vanilla Onyxia and Naxxramas (155h); Outland dungeons at 64 (155f); the
  Outland gear ladder, without quests and without tradeskills (155k, 155l,
  155n); inscription without glyphs (155o); sockets and socket bonuses
  (155p); ability tomes for levels 61-80 (155q).
- Glyph traders in the capitals (155t); battleground rewards (155u).
- World bosses finished: the contribution score and loot rules, the Fel
  Reaver rework, and the tuning of Kazzak's size and speed (155j).
- Aldor and Scryer by deeds (155v), then faction by reputation (161).

## Milestone 4: safe to open to strangers

- Player machine safety (158): the database password rotated and read
  from untracked files (107); administration ports closed to the
  internet; login lockout; only data shipped, never programs, each release
  file checksummed and signed; a sandboxing guide and launcher; the known
  client bugs researched; an encrypted connection for the friends stage;
  backups advised.
- Three-machine deployment (157a-f): database, login and world servers on
  their own machines, one command to deploy and check them.
- The client's cache follows the server's content (160), so changed items
  show correctly.

**Release**: basic open to the public.

## After release: the custom client and generated content

- **The custom client**, built in world-edit-to-execute: readers for the
  game's files (W01), drawing its models (W03), a capture rig (W04), then
  the asset forge that finds or generates replacement models (W05), a
  shared theme (W06). This is where client patches become possible, and
  so everything above that waited on them: Sargobras's look, Kazzak's
  hitbox, new item models, the gem vault's bag-per-tab.
- **Generated 3D models, Feldowinn first** (506): the ComfyUI build
  finished and tested (it is installing its packages; then image-to-3D
  weights, possibly on a remote host); concept art (506b); the 40-view
  camera rings and multi-view generation (506e); meshes and textures from
  the views (506f); reducing them to an item's budget; borrowing a
  skeleton and its animations (506g); our own format first, with export
  to the stock client's M2 (506h); generated animations, pose by pose
  (506i). The gallery and votes steer it (506a, 506d).
- The equipment portrait grid (159) and the explore profile's images
  (153).
- Friends and guilds across servers (1007), the multi-machine cluster
  (913a-h), bots guided by a language model and asked in plain words
  (916, 917), mirror companions (918).
- Later profiles: expert, levels 61-80 (156); Northrend at sixty (155s).

## Related documents

- `docs/roadmap.md`: the earlier roadmap, from the beta profile's design.
- `docs/profiles/basic.md`: what basic is.
- `docs/feldowinn-3d-pipeline.md`: the 3D pipeline in detail.
