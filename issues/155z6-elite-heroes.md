# 155z6 - Elite Heroes

## Status
- Created: 2026-10-04
- Phase: 1
- Parent: 155z (the Dark Portal front)
- Blocked by: 155z5
- Priority: Medium
- Related: 617r (the outfit format), 617f (mirror-image looks)

## Origin

See 155z (the owner's words, 2026-10-04, quoted in full there).

## Current Behavior

Not built. 617r holds outfits in the elite format, made for Growth's
buddies; elites proper (hero NPCs) don't exist yet.

## Intended Behavior

Now and then an elite appears among the reinforcements as a hero unit: an
NPC that belongs to no player, at about level 60, looking like a player of
its race in its outfit (mirror image). Its gear is specialised in a stat
it can use but which is not its best (mp5 on a restoration druid), so
heroes are strong but not perfect. It fights like a buddy: a ranged class
casts its one ranged spell kind and clumps on one side of the causeway;
healers heal.

Spell priorities per class are a short list each. Owner's examples:
priests heal and Smite; druids Wrath (never Moonfire) and Rejuvenation on
a random injured ally nearby every 5 seconds or so.

A suggested table (class, role, off-best stat, the one ranged spell kind,
priorities) is printed for the owner when this is built, as asked.

## Suggested Implementation Steps

1. The table as data, one row per class and role.
2. Outfits in 617r's format, chosen by the same rule check, with the
   off-best stat as a scoring rule.
3. The spell priority loop (one spell kind, a heal on a timer).

## Open Questions

None yet; the table will raise them.
