# 631 - Anyone Who Can Heal Keeps the Group Up

## Status
- Created: 2026-10-22
- Phase: 6
- Related: 617e5 (fighting together), 625 (buddies favour their talented
  abilities), 622 (a buddy keeps a record of what works)
- Priority: Medium
- State: an idea; open questions first

## Origin

Verbatim, 2026-10-22:

> we should make it so that in dungeons and raids, when the healer dies
> the other characters who are capable of healing will try to do so to
> keep people afloat. If the heals are particularly challenging after
> trying a fight several times and losing because of healing (not
> throughput or positioning), then characters who have healing abilities
> will be more likely to use healing spells while fighting. This reduces
> their DPS overall. When they get overheals they are less likely to cast
> healing spells, and when their healers mana is low they are more likely
> to. That's a good general rule I think.

## Current Behavior

Bots (buddies included) fight by their strategy: a bot with a healer's
strategy heals; one with a damage strategy heals little or not at all,
even when it knows healing spells (a feral druid's or a retribution
paladin's). Nothing changes when the group's healer dies, and nothing is
learned from one try to the next.

## Intended Behavior

In dungeons and raids, a buddy that knows healing spells weighs healing
against its usual work by one number, its **will to heal**, which rises
and falls with what happens:

- **The healer dies:** every buddy that can heal starts healing to keep
  the group up (the will jumps high) until the healer is back.
- **Low healer mana:** the lower the group's healers' mana, the higher the
  will.
- **Overhealing:** each heal that mostly overheals lowers the will.
- **Fights lost to healing:** after several tries at the same fight lost
  because the group couldn't be kept alive (not because damage was too
  low or people stood in the wrong place), the will at that fight starts
  higher next time. This costs damage, on purpose.

## Suggested Implementation Steps

1. Answer the open questions.
2. The will to heal per buddy, 0 to 1, with its rules in one place (a
   table of events and how far each moves it).
3. A healing strategy layered on each healing-capable buddy, whose
   actions' priority is scaled by the will (the bot module's strategies
   and action priorities).
4. The record of fights: per dungeon or raid boss, tries, wins, and how
   each loss went (who died first and of what; the group's damage done
   against the boss's health), kept per owner.
5. "Lost because of healing": a loss where people died with the boss
   still above some share of its health and nobody stood in a hazard: the
   rule to tune.
6. Tests: a made-up fight log, three losses to healing then a win: the
   will at that boss rises and then settles.

## Open Questions

1. **How to tell a loss to healing** from a loss to damage or position:
   is "people died while the boss still had more than half its health,
   and the healer was out of mana or dead" close to what you mean?
2. **"Several times":** how many lost tries before the will rises?
3. **Out of dungeons:** the same rule in the open world, or dungeons and
   raids only?
4. **Players' characters:** buddies only, or every bot (random bots,
   stand-ins)?
