# 155k1 - Stamina Scaled to the Threat

## Status
- Created: 2026-10-04
- Phase: 1
- Parent: 155k (the Outland gear ladder)
- Priority: High (players die too fast in Outland's +4 dungeons)
- Related: 155f (Outland dungeons' level steps), 155k's ladder page:
  the "Level-60 Gear Ladder" artifact,
  https://claude.ai/artifact/MZ1mumH84gVxVicSnskvD8 (stat budget as
  "≈ epic item level" per gear source, and the creature levels fought for
  it)

## Origin

Verbatim, 2026-10-04:

> We're doing a test dungeon HFR and our characters are equipped with
> Molten Core gear. We should be able to address the challenges, but
> unfortunately the players have too little health. Can we scale the
> stamina on gear a bit harder? WotLK is notoriously low-health, rapid
> healing requirements, so things like Spellpower are useless for healers
> and only sustained pressure is required. Blizzard buffed health in
> Cataclysm, the next expansion, but they had to overcorrect a bit later
> on. So, let's try something similar, except we should scale the
> difficulty curve (calculated from things like combat attack damage and
> spell damage from NPCs multiplied by effective DPS of the enemy groups)
> according to the HTML document we created recently listing the
> equipment ratios per item level post-scaling.

## Current Behavior

Not built. Gear's stamina is stock (vanilla items) or scaled with the rest
of an item's stats (155k's Outland rescale). Hellfire Ramparts (+4:
creature levels 63-66, its blues ≈ epic item level 69) is entered in
Molten Core gear (≈ epic 61-71), and party members die faster than
healers can answer.

## Intended Behavior

Health keeps pace with the damage of the content each gear tier is for, so
a fight is sustained pressure rather than spike deaths:

- **The threat of a tier**: for each row of the gear ladder, the damage per
  second its creatures deal: per creature, melee damage per swing (the
  server's per-level damage table, `creature_classlevelstats`, times the
  creature's damage modifier) divided by its swing time, plus its spells'
  damage per second where known; per pull, the creatures that come
  together (spawn groups and creatures standing close), summed. A tier's
  threat is the median pull's damage per second.
- **The target**: "time to die", the seconds a character in that tier's
  gear survives the tier's median pull with no healing. One number (or one
  per role) chosen by the owner, Cataclysm-like: longer than WotLK's.
- **The stamina**: every item's stamina is multiplied by the factor its
  ≈ epic item level needs so that a character fully in gear of that level
  reaches the target: factor(E) = target × threat(E) ÷ (stock health of a
  character in E-gear). Between ladder rows, the factor is interpolated by
  ≈ epic item level. Only stamina changes; nothing else on the item.

## Suggested Implementation Steps

1. A measuring tool (data generation, separate from any viewing): per
   ladder row, the median pull's damage per second and the stock health
   of a character in that gear; written as a table to the RAM tier
   (`tmp/shared-memory/`).
2. A page drawing that table (threat, health, time to die per tier, stock
   and proposed), for the owner to pick the target.
3. The stamina factor curve, then the item rescale as an install step with
   saved originals and an exact revert (as 155k's).
4. In game: Hellfire Ramparts in Molten Core gear.

## Open Questions

1. The target time to die: one number, or one per role (a tank longer)?
2. Spells: count only creatures' melee at first, or estimate spell damage
   from their spell lists from the start?
3. All gear, or only gear from level 60 up?
