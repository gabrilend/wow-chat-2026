# 718 - Death Knight: The Sacrifice, and Acherus as an Open Zone

## Status
- Created: 2026-09-23
- Phase: 7 (Custom class / race-class infrastructure)
- Priority: Medium
- Blocked by: the custom-class infrastructure. The user places this
  "second or fourth" among the classes built once that infrastructure
  exists. Which 700s issues count as "the infrastructure" is an open question
  below.
- First profile: basic (155)

## Origin

Verbatim, 2026-09-23, answering "what should basic do with death knights":

> allow stock DKs, but there are no bot DKs allowed and level 55 is required.
> When you create a DK it deletes that level 55 character that you leveled to
> that level. This is the replacement mechanic. It might need a special custom
> NPC or something, with newly created DKs who don't choose being unable to
> leave acherus until they choose. Alternatively, we can just skip the DK intro
> zone and teach them all the abilities they would have gained from quests at
> the level when they should have gained it. The DK starting zone becomes a
> normal leveling zone, with whichever area being unlocked (within a level
> range) is randomized. So for example the first area will always be pretty
> easy because it needs low level noobs to learn there (level 55) but the later
> parts like in the city can be low level coded. And the parts by the chapel
> and the distant docks can be starting areas that can be flight path flown
> to. But each one is different at different times, they cycle around in the
> most fair way possible. I can describe better if you don't have ideas,
> especially with some context provided about how the level zones are
> distributed in terms of phases and geographic location in the DK starting
> zone.

And, on scheduling:

> but the DK issue file could come after the custom classes start being
> implemented, it could be the second or fourth one after we've developed the
> custom-class infrastructure

## Current Behavior

Three different death-knight arrangements exist, one per profile family:

- **Stock (release, alpha):** a new death knight is created at level 55 in
  Acherus, the floating necropolis above the Scarlet Enclave, and plays a
  scripted quest chain there before being released into Eastern
  Plaguelands. An account needs a level-55 character on the realm first
  (`CharacterCreating.MinLevelForHeroicCharacter = 55`, the upstream
  default).
- **Beta (issue 206, completed):** death knights start at **level 1**, still
  inside Acherus. A Lua script auto-completes the exit quests so they can
  step on the teleport pads and leave immediately. Stats were generated
  for levels 1–20 and custom trainers teach a streamlined ability kit at
  levels 2–20. It covers 1–20 only, so it does not fit a 1–60 profile.
- **Vanilla (148a, completed):** death knights are disabled. 148a's reason
  was that the client hard-codes the Acherus start and a client patch would
  be needed. 206 shows otherwise: beta starts death knights at level 1
  with no client patch. The start location is the server's
  `playercreateinfo` table, not the client.
- **Basic:** an interim rule (see 155's open questions) until this issue
  lands.

### What Acherus is made of (from the server's own data, 2026-09-23)

Acherus is **map 609**, zone "Plaguelands: The Scarlet Enclave". Numbers
below come from `source-beta/data/sql/base/db_world/`; re-derive rather than
trust them if upstream changes.

**Every one of its 59 quests is level 55, minimum level 55.** There is no
level gradient anywhere in the data, so "easy area" and "hard area" would
be something this issue creates, not something it reads out of the zone.

**Four quests teach a spell or grant one directly**, and these are the
abilities a skipped intro would have to hand out another way:

| Quest | Grants |
|---|---|
| The Emblazoned Runeblade | Runeforging (weapon enchanting unique to the class) |
| The Might Of The Scourge | a display-only reward spell (51721); needs identifying |
| Into the Realm of Shadows | the Acherus Deathcharger mount |
| The Light of Dawn | Death Gate (the class teleport home) |

Several other class features (the Ghoul, presences, Death Grip's use on
the Scarlet line) are introduced by the chain's scripting rather than by a
reward field. They have to be found by reading the quest scripts before
the "teach abilities at the right level" alternative can be specified.

**The zone changes shape as the chain progresses.** The world is phased: a
quest's completion swaps the player into a different copy of the same
ground. The transitions, keyed to quest completions:

| After completing | The world becomes |
|---|---|
| Victory At Death's Breach | the Scarlet line is broken; the assault on New Avalon opens |
| The Plaguebringer's Request | the Crypt of Remembrance plague stage |
| Bloody Breakout | the prisoner-escape stage |
| A Meeting With Fate / The Scarlet Onslaught Emerges | the Scarlet counter-attack |
| Scarlet Armies Approach | the siege; lasts until An End To All Things |
| An End To All Things | the frost-wyrm razing of New Avalon; the final state |

**Geography**, as named in the quest titles, runs roughly: Death's Breach
(the landing under Acherus) → Havenshire (farms, stables, mine, lumber mill
— "The Scarlet Harvest", "Tonight We Dine In Havenshire", "Grand Theft
Palomino") → Light's Point (the tower overlook, "Massacre At Light's Point",
"Ambush At The Overlook") → New Avalon (the city: town hall, forge, orchard,
the Crypt of Remembrance) → the Chapel of the Crimson Flame → King's Harbor
(the distant docks and the Scarlet fleet) → Light's Hope Chapel, just
outside the map, where the chain ends ("The Light of Dawn"). Creature spawns
per phase cover x 1284–2838, y −6193 to −5125; the exact centre and radius
of each named place should be measured from spawn clusters, not recalled
from memory.

## Intended Behavior

Two layers, one per half of the user's design.

### Layer 1 — the price of a death knight

- A death knight can only be created by an account that owns a level-55
  character on the realm (stock knob, already in place).
- **Creating the death knight consumes that character.** The level-55
  character is deleted as part of the creation: the new death knight is
  what that character became.
- Bots never play death knights (`AiPlayerbot.DisableDeathKnightLogin`).
- The user named two ways to make the choice of *which* level-55 character is
  consumed:
  - **(a) a chooser NPC in Acherus.** A freshly created death knight cannot
    leave Acherus until it has named its former self. The character is
    deleted when the choice is made.
  - **(b) skip the intro.** Handled by Layer 2, with the choice made some
    other way (open question).

### Layer 2 — Acherus as a leveling zone

- The scripted intro chain no longer gates anything. Abilities the chain
  would have taught are taught at the level at which the chain would have
  taught them.
- The Scarlet Enclave becomes an ordinary leveling area with **level bands
  per region**, which the data does not provide and this issue assigns.
  The landing area (Death's Breach, and Havenshire's near edge) is always
  the gentlest band, because every new death knight arrives there at 55.
- **Unlocks rotate.** Which region holds which band is shuffled over time,
  "in the most fair way possible". The Chapel of the Crimson Flame and the
  King's Harbor docks can serve as alternative arrival points reached by
  flight path, so the rotation also moves where the rest of the zone is
  entered from.
- Basic's flight paths are otherwise removed (155c); the Enclave's internal
  flight paths are an exception that has to be carved out of that removal.

## Suggested Implementation Steps

1. Answer the open questions; the user offered to describe the rotation
   further once this context is in front of them.
2. Measure each named region's centre and radius from creature and game
   object spawn clusters on map 609, per phase, and write the table into
   this issue.
3. Read the chain's scripts (`smart_scripts`, and the C++ scripts under
   the core's Scarlet Enclave directory) to list every ability and item the
   chain hands out.
4. Split into sub-issues along the two layers once the design is settled:
   the sacrifice (creation hook, deletion, bot exclusion), the chooser if
   (a) is kept, the ability schedule, the region bands, and the rotation.
5. Build on whatever the custom-class infrastructure provides for level-gated
   ability grants, rather than inventing a parallel mechanism.

## Related Issues

- **155** the basic profile — first home for this design
- **206** (completed) beta's level-1 death knight — proves the start location
  is server-side; its auto-complete and teleport-pad handling is prior art
- **148a** (completed) vanilla's death-knight disablement — its client-patch
  premise needs correcting in light of 206
- the 700s custom-class cluster (**702** custom spells, **705** class
  selection NPC, **709** class Lua format, **711** class configuration
  schema, **716** class combinations) — the infrastructure this waits on

## Open Questions

- **Which issues are "the custom-class infrastructure"?** This issue is
  scheduled second-to-fourth after it. The owner's description (recorded
  verbatim in 705, 2026-09-23): a middle-ground class learns chosen abilities
  from other classes' trainers, with borrowed abilities re-costed in its own
  resource by cast tempo. That points at 705 (selection and trainers), 709 and
  711 (the class format and schema) and 710 (resources). Note the existing Lua
  for it is disabled (`src/lua-beta/custom-classes.lua.disabled`) and
  beta-only, so on basic the infrastructure starts from a port, not a switch.
- **(a) or (b), or both?** Does the chooser NPC survive if the intro is
  skipped, or does the choice move somewhere else (the character-creation
  screen cannot ask, so something in-world has to)?
- **What if the account has several level-55+ characters?** Choose any; or
  only the highest; or only ones at exactly 55?
- **Deletion or retirement?** "Deletes" could mean a true delete, or a
  character kept but made unplayable (a gravestone). Deletion cannot be
  undone.
- **Rotation clock.** "Each one is different at different times": what
  moves the rotation — real time (hours, days), server restarts, or the
  number of death knights that have passed through?
- **Is 148a's premise simply wrong?** If the start location is purely
  server-side (206), should 148a's "future work" section be corrected now
  rather than when this lands?
