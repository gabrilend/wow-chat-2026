# 148t - Racemate NPCs in the Vanilla Starting Towns

> *the forsaken are forsaken by the night elves to their fate*
>
> — the user's flavor line, filed verbatim (preserved as-is; it is the
> mood this ticket dresses the world in, not a spec to parse).

## Status
- Created: 2026-07-15 (sorted from the `please-sort-me` capture note)
- Phase: 1 (Foundation — profile world-dressing)
- Parent: 148 (vanilla profile)
- Predecessor: 148n (per-race starting-zone spread — this ticket
  populates the towns 148n sends each race to)
- Priority: Low (world-feel / flavor; does not block launch)

## Problem

148n scatters the ten races across six towns so a freshly-created
level-20 character wakes up somewhere lore-adjacent instead of in a
crowded two-town faction bucket. But the towns themselves are still
dressed in their *canonical* residents: a Gnome rolling into Astranaar
is surrounded entirely by Night Elves, a Blood Elf at Sun Rock Retreat
sees only Tauren. The spawn point says "this is your town"; the
population says "you are a stranger here."

The fix is to seed each starting town with a handful of NPCs of the
race (or races) 148n assigns to it, so the opening view includes a few
faces that look like the player's own — a hometown, not a waystation.

## Current Behavior

Each 148n anchor town is populated only by its canonical inhabitants.
The per-race spread and its innkeeper anchors (from 148n / the
`auto-equip-starter-kit` hearth table):

| Town (map, zone) | Innkeeper anchor | 148n races sent here | Native? |
|---|---|---|---|
| Menethil Harbor — Wetlands (0, 38) | Innkeeper Helbrek | Human (native), Dwarf | Dwarf is the transplant |
| Darkshire — Duskwood (0, 10) | Innkeeper Trelayne | Draenei | both non-native (Human town) |
| Astranaar — Ashenvale (1, 331) | Innkeeper Kimlya | Night Elf (native), Gnome | Gnome is the transplant |
| Ratchet — N. Barrens (1, 17) | Innkeeper Wiley | Orc | non-native (goblin-neutral town) |
| Tarren Mill — Hillsbrad (0, 267) | Innkeeper Shay | Undead (native), Troll | Troll is the transplant |
| Sun Rock Retreat — Stonetalon (1, 406) | Innkeeper Jayka | Tauren (native), Blood Elf | Blood Elf is the transplant |

So the work concentrates on the **transplanted** races per town —
Dwarf, Draenei, Gnome, Orc, Troll, Blood Elf — since the native race
already has representation.

## Intended Behavior

At each town, a small set of existing resident NPCs is **reskinned**
to the transplanted race's character model, so the town visibly
includes racemates for every character 148n spawns there. Explicitly
called out in the capture note:

- **Gnome NPCs in Astranaar (Ashenvale)** — "dress them up like
  menardi." (Styling cue preserved verbatim; the menardi look is the
  intended silhouette for the reskinned Gnome residents.)
- **Blood Elf NPCs in Sun Rock Retreat (Stonetalon).**
- **…and the same for the remaining transplanted races** at their
  towns (Dwarf @ Menethil, Draenei @ Darkshire, Orc @ Ratchet,
  Troll @ Tarren Mill).

Guiding constraints from the note:

- **Reskin, don't respawn.** Swap the *character model* of NPCs
  already standing in the town rather than adding new spawns — spawn
  positions, pathing, and NPC counts stay untouched.
- **Keep the names.** The reskinned NPC keeps its existing name for
  world-consistency; only its look (and maybe its gossip) changes.
- **Equipment usually stays.** Whatever the existing NPC already wears
  is normally fine and environment-appropriate; only touch it where a
  swap looks obviously wrong for the new model.
- **Gossip is optional flavor.** Some reskinned NPCs may get tweaked
  gossip-menu text so a racemate greets the player in-voice; not
  required for every NPC.

## Implementation Mechanism — Reskin existing residents

A new vanilla world migration (same shape as 148n's zones file and the
other `sql/vanilla/db_world.src/` migrations), scoped to
`acore_world_vanilla` only, that UPDATEs the display model of a curated
set of existing town-resident creatures.

Relevant tables (list, not snippets):

- **`creature_template_model`** (AC 3.3.5a's per-creature display list;
  columns `CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`,
  `Probability`) — the reskin target. Repoint the chosen town NPCs'
  display id to a target-race model. Older single-column
  `creature_template.modelid1..4` is the fallback if a given fork still
  keys off that.
- **`creature`** — the spawn rows; used to *select which* residents to
  reskin (by `map`/`zone`/area around the town anchor) but NOT modified.
- **`gossip_menu` / `gossip_menu_option` / `npc_text`** — optional
  gossip-text tweaks for the reskinned NPCs.
- **`creature_equip_template`** — only touched where the existing
  equipment reads wrong on the new model.

**Where the display ids come from — data-derived, not from memory.**
The target-race model ids are DBC data (`CreatureDisplayInfo`), which
is *not* fully populated in the world DB (`spell_dbc` is a partial;
`skilllineability_dbc` is empty — see the 148h investigation). So do
NOT type race display ids from memory. Source them from the live DB by
sampling `creature_template_model` / `creature_template` rows of
canonical NPCs that *already* use the target race's male/female models
(e.g. pull an existing Gnome townsfolk's `CreatureDisplayID` and reuse
it). The generator/migration reads real display ids rather than
guessing.

## Files To Add

| Path | Action | Note |
|---|---|---|
| `sql/vanilla/db_world.src/NN-starting-town-racemates.apply.sql` | add | UPDATEs the display model of the curated per-town NPC set; idempotent, Note/comment-tagged `vanilla-148t-` for re-apply + audit |
| `sql/vanilla/db_world.src/NN-starting-town-racemates.revert.sql` | add | restores the original display ids (snapshot the originals in the apply header, mirroring 148h's clone/revert discipline) |
| `patches/E-patches.sh` | add | `patch_ENNN_vanilla_starting_town_racemates` + `unpatch_*`, following the E009/E018 cp-into-place pattern |

(Choose the next free `NN` migration index and `ENNN` patch number at
implementation time; the vanilla `db_world.src/` set currently runs
01–06 with 05 free.)

## Implementation Steps

1. For each town, query the DB for the resident creatures near the
   148n anchor and pick a handful to reskin (favor idle/ambient
   townsfolk over quest-critical or vendor NPCs, so gameplay wiring is
   untouched).
2. For each target race, pull real `CreatureDisplayID`s (male/female)
   from existing canonical NPCs of that race — the data-derived source
   of truth for the model swap.
3. Write the apply migration: snapshot each chosen NPC's original
   display id in a comment/sidecar, then UPDATE to the target-race
   display id. Tag every row `vanilla-148t-`.
4. Write the revert migration from the snapshot.
5. (Optional) Add gossip-text tweaks for a few of the reskinned NPCs
   so a racemate greets the player in-voice.
6. Register the E-patch; apply against `acore_world_vanilla`.
7. Validate in-client alongside the 148o pass: roll a transplanted
   race (Gnome, Blood Elf, …), confirm the spawn town now shows
   racemate faces and that names/vendors/quests still work.

## Open Questions

- **How many racemates per town?** A few (3–6) reads as "some of your
  people are here" without overwriting the town's native identity;
  reskinning everyone would erase the "frontier outpost" feel 148n's
  lore notes lean on. Tune during the validation pass.
- **The "menardi" look for Gnomes.** The note asks that Astranaar's
  Gnome reskins be "dressed up like menardi" — pin down which
  display/equipment that refers to before building the Gnome set.
- **Native-race top-up.** Should the native race at each town also get
  a couple extra reskins (more Night Elves in Astranaar, etc.), or is
  the native population already sufficient? Leaning: transplants only.
- **Model gender spread.** Reuse each NPC's existing gender where the
  target race has both, to avoid re-rigging equipment awkwardly.

## Cross-References

- `issues/148n-vanilla-racial-starting-zones.md` — the per-race spawn
  spread and innkeeper anchors this ticket dresses; the town list above
  is 148n's mapping.
- `issues/148o-vanilla-spawn-and-kit-validation-pass.md` — the in-client
  pass that would also eyeball the reskinned towns per race.
- `src/lua-vanilla/auto-equip-starter-kit.lua` — the hearth-bind table
  (`HEARTH_BY_RACE`) that names each town's innkeeper anchor.
