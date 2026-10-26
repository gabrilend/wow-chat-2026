# 186 - Gear of Equal Strength

## Status
- Created: 2026-10-14
- Phase: 1
- Blocked by: 175 (custom items told to the client ahead of time: a made
  copy is drawn as nothing until the client knows it)
- Related: 617x (prestige: reborn at a lower level), 617a6 (buddies by
  stage: de-levelling), 617r7 (buddies' own copies of items, the same
  copy-making), 155k (the level-60 gear ladder and its stat-budget view),
  `scripts/change-character-class` (first user), 197 (2026-10-25: a
  class change now dresses the character in a buddy's gearset and mails
  its old gear; whether this issue stays for level changes is 197's open
  question 2; answered 2026-10-25: "it's for level changes and class
  changes"; then, the same day: "buddy gear if we go up in level,
  suitable copies of old gear at equal strength if they go down in level.
  Remember, we aren't using copies of the old gear, but rather choosing
  new copies of new gear - the level 4 with the level 12 weapon gets a
  level 12 weapon, not a level 60 epic weapon with reduced stats. for the
  class change, just the buddy-gear sets." So this issue is for going
  down in level: each item replaced by a real item of the new level chosen
  for equal strength; going up in level takes the buddy gearsets, and a
  class change takes the buddy gearsets only (197))
- Priority: Medium

## Origin

The owner, 2026-10-14, while a character (Felicity) was being changed from
warlock to priest by the new class-change tool:

> make sure when we switch equipment we try and match a similar quality /
> ilevel tier. if we can't find something in that tier, for example if we
> scale our level down to level 14 and there's no epics at that level...
> then we try to match proportionally via stat value. Think about the HTML
> document we made where there are different tiers of equipment dropped in
> various Outland dungeons and Azeroth raids and such. In that mapgraph
> there's this concept of "adjusted ilevel" which tries to balance the stat
> differentialese comparing multiple quality levels. Like... purple has
> more stats than blue at the same tier ilevel wise, so... we can create a
> new item that is destroyed when the player drops it that's a BoP version
> of whatever item but it has no required item level. This means that a new
> level 4 might get like, a level 12 green sword to modulate their stats
> roughly the same as their old weapon did, because it was like... an epic
> or something.

## Current Behavior

Not built. When a character changes class (`scripts/change-character-class`)
its gear is left exactly as it was; items the new class cannot use are
listed, not replaced. Nothing changes a character's level downward yet;
prestige (617x) and buddies by stage (617a6) are planned.

The measure already exists, as a picture: `docs/HTML/basic-gear-ladder.html`
has a "Stat budget (≈ epic item level)" view. It converts an item level at
each quality into the epic item level with the same amount of stats:

| Quality | Stat budget from item level |
|---|---|
| green | (ilvl − 4) ÷ 2 |
| blue | (ilvl − 1.84) ÷ 1.6 |
| epic | (ilvl − 1.3) ÷ 1.3 |

A blue at item level 63 and an epic at 50 carry about the same stats.

## Intended Behavior

Whenever a character's class or level changes, each item it wears is
swapped for one of about the same strength that it can use now:

1. **Measure** the old item: its stat budget, by the table above
   (the ladder page's curves; whites as greens with no stats).
2. **Same tier first:** look among existing items for one in the same
   slot (same inventory type: one-hand sword for one-hand sword, or the
   new class's nearest weapon kind), usable by the new class, of the same
   quality, with an item level close to the old one and a required level
   at or below the character's level. Closest budget wins; stats the new
   class wants (its spec profile, 617r6) break ties.
3. **No such item** (a level-14 character has no epics to choose from):
   **match proportionally.** How strong the old item was for its old level
   (its budget against the usual budget at that level) is carried to the
   new level, and the existing item at the new level whose budget is
   nearest that target, any quality, is chosen. A level-60 epic sword,
   well above an ordinary level-60 item, becomes a level-12 green sword for
   a level-4 character: well above an ordinary level-4 item by about the
   same amount.
4. **A copy, not the original:** the chosen item is given as a copy that
   binds when picked up, has no required level, and is destroyed when it
   leaves the character (see open questions for what "dropped" covers),
   so it can't be traded or sold to break the rules. The copy is made the
   same way 617r7 makes buddies' copies.
5. **Old gear** goes to the character's mail, or stays in its bags (see
   open questions).

## Suggested Implementation Steps

1. Write the budget curves once, as a Lua library (`scripts/lib/`),
   used by the swap and checked against the ladder page's numbers.
2. A planner beside `scripts/lib/class-change-sql.lua` that, given the
   character's worn items (entry, quality, item level, slot) and its new
   class and level, picks a replacement per slot from `item_template`
   (same tier, then proportional), and writes the SQL for the copies and
   the swap. Data generation, then application, as the class change does.
3. The copies: rows in `item_template` in a reserved entry range (617r7's
   range if it has one), BoP, required level 0, and the flag or hook that
   destroys them when they leave the character; told to the client ahead
   of time (175).
4. Hook it into `scripts/change-character-class` (an option at first),
   and later into prestige (617x) and de-levelling (617a6).
5. Tests: an offline test of the curves and of the proportional choice
   (an epic at 60 to a level-4 character gives a green of about item
   level 12); in game, change a test character's class and level and read
   its gear.

## Open Questions

- **"Destroyed when the player drops it":** when it is thrown away only
  (stock behaviour already destroys an item dropped from the bags), or
  also when traded, mailed, sold, or put in the bank?
- **The old gear:** mailed to the character, kept in its bags, or kept
  aside and given back when it returns to the old level or class?
- **The usual budget at a level** (step 3 needs it): the budget of an
  ordinary quest green at that level, or the ladder's own rung for that
  level?
- **Which changes swap gear:** class change, prestige and de-levelling;
  also the level-up command (185) going down? And upward, when a
  character outgrows its copies?
- **Felicity now:** her gear is cloth and a staff, all usable by a
  priest, so nothing was swapped. Should the swap still run for her once
  built, to fit her gear to the shadow spec's stats?
