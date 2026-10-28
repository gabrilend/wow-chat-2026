# 148x - Vanilla: Levels 41-60 as the Endgame of a Level-40 Server

## Status
- Created: 2026-10-27
- Phase: 1
- Parent: 148 (the vanilla profile)
- Related: 155f (basic's Outland dungeons at 64), 155k (basic's Outland
  world and gear ladder), 155f1 (basic's level-60 fights balanced), 155i
  (dungeon damage and healing multipliers), 155m (true creature levels),
  155h (Onyxia and Naxxramas at 60, on basic), 803 (level-gap caps)
- Sub-issues: 148x1, 148x2, 148x3, 148x4, 148x5
- Priority: Medium
- State: plan only (issue files, at the owner's ask); nothing built

## Origin

The owner, 2026-10-27:

> oh and for the vanilla profile, can we do the level and equipment
> scaling work that we've been doing with basic, but for vanilla stuff?
> I'd like it if the leveling process from 20-40 was similar to Outland on
> basic. I'll explain:
>
> how about we take the 20 levels above (41-60) and scale them similarly
> to how we scale Outland? The goal being that a group of level 40s can
> take down Ragnaros. But, let's just create issue files for that process.

## Current Behavior

Vanilla starts characters at 20 and caps them at 40 (`docs/profiles/vanilla.md`).
Everything above 40 is stock: the zones of levels 41-60 (the Hinterlands,
Tanaris, Feralas, the Searing Gorge, the Burning Steppes, Winterspring, the
Plaguelands and the rest), the dungeons from Zul'Farrak to Stratholme and
Scholomance, and the raids (Molten Core, Onyxia, Zul'Gurub, Blackwing Lair,
the two Ahn'Qiraj, and Naxxramas in its level-80 form). Their gear needs
levels above 40, so a level 40 can't wear it, and their creatures are up
to 23 levels above the cap, which no level-40 group can hit.

On basic the same shape is solved for Outland: Outland's creatures were
raised a few levels (155k, 155f), its gear made wearable at the cap and its
stats scaled into a ladder above Azeroth's (155k, 155f), and its fights
measured and tuned against a geared level-60 tank (155f1, 155i).

## Intended Behavior

- **Levels 41-60 become vanilla's "Outland"**: the content a capped
  level 40 grows into, from the first zone above 40 up to the raids.
- **Ragnaros is a level-40 raid's fight**: a group of level 40s (players
  and their bots) in the gear of the rung below can kill him. That is the
  test the whole design is held to.
- **The same tools as basic's, given the profile**: each of basic's
  Outland generators is made to take its range (the stock levels it
  reads, the cap, the target ladder) as settings, so the vanilla rows
  come from the same code, not a copy.
- **The pieces** (each its own sub-issue):

  | ID    | Name                                   | Dependencies   | Description |
  |-------|----------------------------------------|----------------|-------------|
  | 148x1 | vanilla-world-above-40-levels          | None           | The open world's creatures of stock levels 41-60 put on the vanilla ladder |
  | 148x2 | vanilla-dungeons-above-40-ladder       | 148x1          | Zul'Farrak to Scholomance: entry at 40, a level ladder, their loot scaled |
  | 148x3 | vanilla-gear-above-40-wearable-at-40   | None           | Every item needing 41-60 wearable at 40, its stats scaled proportionally into a ladder above the 20-40 gear |
  | 148x4 | vanilla-raids-for-level-40s            | 148x1, 148x3   | Molten Core to Ahn'Qiraj (and Onyxia, Naxxramas) as raids of level-40 groups |
  | 148x5 | vanilla-fights-above-40-balanced       | 148x2, 148x4   | Every boss above 40 measured against a geared level-40 tank and tuned |

- **Why split**: the world, the dungeons, the gear, the raids and the
  balancing are separate generators on basic, each with its own data
  (creature levels, dungeon access, item stats, raid access, multipliers)
  and its own tests; one issue would mix five install steps.
- **Order**: 148x1 and 148x3 (foundations, in parallel) → 148x2 (needs
  the world's ladder) → 148x4 (needs the world's ladder and the gear) →
  148x5 (measures what the others built).

## Suggested Implementation Steps

1. Read basic's Outland generators (the world levels step, the dungeon
   ladder step, the gear scaling, the multiplier table) and give each its
   range as settings, with basic's values unchanged (a quick test that
   basic's output is byte for byte the same).
2. The sub-issues in the order above.
3. A demonstration on the vanilla profile: a level-40 raid's numbers
   against Ragnaros.

## Open Questions

1. **How far above 40 the creatures stand.** On basic, Outland's world is
   stock + 4 (63-76 against a cap of 60) and its top dungeon bosses 76-78:
   up to 18 levels over the cap, made fair by the level-gap caps (803) and
   the multipliers (155i). Above 40 the stock range is 41-63 (Ragnaros 63),
   23 over. Proposed: squeeze stock 41-63 onto 41-58 in a straight line
   (each level above 40 times 18/23), so Ragnaros stands where basic's top
   Outland boss does, 18 over the cap. Or squeeze further (onto 41-50, say),
   so less depends on the caps?
2. **Quests above 40**: kept (they give experience a level 40 can't use,
   but their rewards are gear), or removed as basic removed Outland's
   (155l)?
3. **The raids' size**: this client keeps Molten Core, Blackwing Lair and
   Ahn'Qiraj's temple at 40 players, Zul'Gurub and Ahn'Qiraj's ruins at 20,
   Onyxia and Naxxramas at 10/25 (their 3.3.5 forms). Keep those sizes?
4. **Onyxia and Naxxramas**: basic's plan brings them to 60 (155h). On
   vanilla, the same two at the level-40 ladder's top?
