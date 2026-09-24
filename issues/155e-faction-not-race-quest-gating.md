# 155e - Quests Open to the Faction, Not the Race

## Status
- Created: 2026-09-23
- Phase: 1
- Parent: 155
- Blocked by: 155a
- Blocks: 155d
- Priority: Medium

## Origin

Part of the starting-valley directive quoted in 155d: "Make sure to ensure
that quests aren't gated by race anymore, only faction."

## Current Behavior

**Built 2026-09-23; tested against a throwaway RAM database** (`scripts/test-basic-sql-in-ram`; 404 quests widened, 23 mentors spawned, 204 placeholders removed, 1,937 class-list spells). Setup step E022 installs
`sql/basic/db_world.src/08-faction-quest-gating.apply.sql`. Its statements
are set-based and work on whatever quests the database holds, so upstream
additions are covered. Each quest whose race mask names only one faction's
races becomes that faction's full mask, after the original mask is saved in
`basic_155e_quest_race_backup`. Quest-availability race conditions (types
19/20) are widened the same way, with their own backup; stock data has none
today. The revert restores every original mask from the backups.

Scope decision: gossip race conditions (types 14/15: 37 gossip menus and 96
gossip options in stock data) are **not** widened. They gate dialogue and
trainer/vendor options, not quests, and the owner asked about quests. The
trainer question below covers the part of that which matters for 155d.

**Trainers.** Owner's answers, 2026-09-23, verbatim:

> universal class trainer who only trains classes that aren't present in that
> valley.

> they shouldn't have every ability to teach, I think the window breaks. They
> should only have the spells for the classes that are missing trainers in
> that area. We might have to gate it with a conversation dialogue option,
> that might make things easier and a bit more abstracted and organized rather
> than just throwing them all into one trainer window. "Hello can you teach me
> druid spells" sure thing here they are

> can you pick a powerful level 40ish trainer's model instead of the
> placeholder goblin? for one of the missing classes and add it to that zone
> instead. So like eversong woods might have a tauren druid model class
> trainer that teaches the abilities of druid, and any other class that blood
> elves can't be like shaman. But that way they feel a bit more thematic.

Built as setup step E025 (`sql/basic/db_world.src/10-valley-universal-trainers.apply.sql`)
plus source patch B029:

- **Where:** one **Visiting Mentor** at every place the stock world sends
  new characters to train (owner, 2026-09-23: "yes. No duplicates!"). The
  stock data marks these places with stacks of nine placeholder NPCs
  (entries 26324–26332, goblin "Druid Trainer", "Warrior Trainer", …): 24
  sites, three per race (starting valley, first town, capital). Each site
  lacking at least one class gets exactly one mentor, standing where the
  placeholders stood, and the placeholders there are removed (saved in
  `basic_155e_goblin_backup` for the revert). Stormwind trains every class
  and gets none, so there are 23 mentors.
- **Which classes:** those with no real class trainer at the site. The
  real trainers are each assigned to their nearest site (within 700 yards),
  so a capital's trainers count for the capital and not the next town.
  Death knights are excluded.
- **Dialogue:** one line per missing class ("Can you teach me the ways of
  the druid?"), each opening that class's own list. The stock server hides
  a trainer line whose list is for another class, so each player sees only
  their own class's line; a player whose class is trained at the site sees
  only the greeting.
- **Class lists:** trainer ids 155101–155111 (155100 + class), each the
  union of that class's stock lists, with the stock class requirement kept.
- **B029** (`patches/B029-gossip-option-trainer-list.sh`) lets a trainer
  dialogue line name the list it opens, through the line's ActionMenuID,
  exactly as the stock server already lets a vendor line name its shop.
  It applies only to NPCs without a list of their own, so no stock trainer
  changes. The server remembers which list a player opened, because the
  buy-spell message names only the NPC. The patch applies and reverts
  byte-identically, and its files pass the compiler check.
- **Looks:** each mentor borrows the look (and faction) of a level 50+
  trainer of one of its missing classes, taken from elsewhere in its
  faction, and no look is used twice. The eight valleys use the looks
  picked with the owner (e.g. a tauren druid on Sunstrider Isle, a night elf
  druid in Northshire). Name "Visiting Mentor", subname "Class Trainer".
- **Generated, not hand-written:** `scripts/generate-basic-mentor-hubs`
  (LuaJIT) reads the stock SQL and the client's faction table, computes
  the sites, missing classes and looks, and rewrites only the GENERATED
  block of the apply SQL. It prints a table of the result, and re-running
  it is byte-stable.

`scripts/validate-basic-state` checks after install that no within-faction
race mask remains, that the backup table exists, and that eight mentors are
spawned, each teaching at least one spell and none of the death knight's.

Before this issue: each quest carries a race mask: a number with one bit per race (bit
values human 1, orc 2, dwarf 4, night elf 8, undead 16, tauren 32, gnome 64,
troll 128, blood elf 512, draenei 1024). A quest is offered only to races
whose bit is set. Stock data uses it in three ways:

- **zero**: every race;
- **a whole faction**: Alliance 1101 (1+4+8+64+1024), Horde 690 (2+16+32+128+512);
- **a subset of a faction**: the starting-valley chains, racial class quests
  (a race-specific letter sending a new warrior to its race's trainer), and
  racial mount and lore chains.

A second race gate sits in the server's conditions table, where a condition
can require a race for quest availability, gossip options and some NPC
interactions.

A character sent to a different race's valley (155d) is offered almost
nothing there, because the valley's opening chain is gated to the valley's
own races.

Two more race-shaped gaps show up in a foreign valley, and neither is a
quest gate:

- **Class trainers.** Each valley only has trainers for the classes its races
  can play. Shadowglen has no paladin, mage, warlock or shaman trainer; a
  human paladin landing there cannot train until it leaves the island.
- **Class quest letters** point to the home valley's trainer. With the mask
  widened, a human warrior in Shadowglen is handed the night elf warrior
  letter, which points at Shadowglen's warrior trainer. That works, as long as
  a trainer for the class exists there.

## Intended Behavior

On basic, no quest is gated by race below the faction level:

- every quest whose race mask names only races of one faction gets that
  faction's full mask;
- masks of zero, masks already equal to a full faction, and masks that
  name races of both factions are left alone;
- race conditions on quest availability that restrict within a faction are
  widened the same way (gossip conditions are left alone; see Current
  Behavior);
- every valley can train every class its faction can play: its own
  trainers, plus a Visiting Mentor for the rest.

The rewrite is set-based SQL rather than a generated list of quest ids: it
selects the rows to widen by their mask at apply time, so it needs no
database at authoring time and covers quests upstream adds later. Before
changing a row it saves the original mask in a backup table, and the revert
restores each row's original mask from there, not a guess.

## Suggested Implementation Steps

1. Count the rows in each category (whole-faction, within-faction subset,
   cross-faction, zero) with one query per category. Record the query in this
   issue, not the counts.
2. Do the same for race conditions (condition type 16 in the conditions
   table), grouped by what they gate.
3. Write the generator script in `scripts/` and the E-patch step that
   installs its output.
4. List the classes each valley can train, and decide the trainer question
   below.
5. Test: a character of each race, in each of its faction's four valleys,
   is offered that valley's first quest. The check runs as a script against
   the live database after the user's install.

## Related Issues

- **155** parent; **155d** depends on this
- **502** universal class trainers (open, currently being edited) —
  one possible answer to the trainer gap
- **701** quest spells to trainers — prior work on what quests teach

## Open Questions

- (Answered 2026-09-23) Trainers in foreign valleys: one universal mentor
  per valley for the missing classes. Built as E025.
- (Answered 2026-09-23) Racial mounts stay racial. Gossip and vendor race
  conditions are not widened, which already keeps them racial.
- (Answered 2026-09-23) The goblin placeholders at the valleys are replaced
  by the mentors.
- (Answered 2026-09-23) Every trainer location gets a mentor, never two:
  built (23 sites).
