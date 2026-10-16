# 617n - Buddy Spell Learning

## Status
- Created: 2026-10-03
- Phase: 6
- Parent: 617
- Blocked by: 617a3 (buddies are made), 617e4 (the town visit and its
  errands)
- Related: 617a4 (the starting kit, made at the same moment as the first
  lessons), 617h (the town errand order)
- Priority: High (a buddy without its abilities can't fight)

## Current Behavior

**Refined the same day (verbatim):** "the buddy-bot at each tier spawns
in with possibly a different weapon type equipped. That one they should
know. Otherwise, they should learn a random weapon skill from what their
class can know, one for each of the player's learned weapon skills. Then,
at capital cities and such, they can learn more." Built that way: the
kind of every weapon its kit hands it is always learned (a re-dress too);
when it is made (the starting kit, at each tier it is made at), random
kinds its class and race can learn are added until it knows as many as
its owner (`BuddyFillWeaponKinds`). The "past the count, refused" rule
below is gone. **Not built:** learning more at weapon masters in the
capitals (a town errand, like the class trainer's).

On stand-ins (verbatim): "When they are instantiated as buddy-bots, they
might lose weapon skills! That's fine. ... If the stand-in-becoming-
buddy-bot wore a weapon in a battleground / dungeon, then they should
have that skill trained first from among the potential weapon skills
learned when instantiated. I don't think it could be the case that a
player would have fewer than the buddy-bot has weapon appearances, but
we should account for that possibility too." No stand-in becomes a
buddy yet (617t); when one does, the kinds of the weapons it wore are
kept first, even past its new owner's count.

**Weapon kinds as many as the owner's, and quest spells first,
2026-10-15; syntax-checked, not yet rebuilt or run** (`buddies_spells.cpp`):
- The owner's rule: "buddy-bots should have one weaponskill trained
  (minimum 1, the weapon they have equipped at the start of the game) per
  weaponskill that the player trains." A buddy may know as many weapon
  kinds (Axes, Staves, Guns ... the skill lines weapon items ask for) as
  its owner knows, at least one; what it starts with counts and is never
  forgotten. The kit teaches a kind when it hands over a weapon of that
  kind and the buddy is under the count, main hand first; past the count
  the weapon is refused and the old one kept (617r2). Weapon masters are
  filed as profession trainers, so their lessons are gathered separately.
  Stand-ins have no owner and are not bound by a count. Five level-44
  buddies made that day had kit weapons refused for want of the kind
  (the hunter Montahmu fought Uldaman with its fishing pole); `.buddy
  kit <name>` re-dresses them under the new rule.
- Quest spells are learned before the trainers' lessons, not after: the
  first totem of each element and Bear Form come from class quests, and
  the later ranks (Searing Totem 2, Maul, Swipe, Dire Bear Form...) ask
  for them. A level-44 druid had been made knowing Bear Form and no bear
  ability; a shaman knowing the first totems and no later rank. The owner:
  "They were just in the capital, they are fully trained." Town training
  learns quest spells first too, so buddies made before buy the missing
  ranks at their next trainer visit. Checked against the five buddies'
  rows: every other unknown lesson needs a talent (Aimed Shot,
  Counterattack, Insect Swarm), as intended. One unexplained: the rogue
  Drerjokin has the Dual Wield skill but not the Dual Wield spell (674).

**Gap, 2026-10-04:** weapon masters are not visited and the armour
proficiencies a trainer teaches at 40 are not known to be in the creation
lessons (item 7 below); level-60 buddies made earlier lacked Plate Mail,
Mail, bows and guns.

**Written 2026-10-03, syntax-checked with the build's own flags, not yet
built or run** (`modules/mod-buddies/src/buddies_spells.cpp`):
- the town visit's train errand (`buddies_town.cpp`) now calls
  `BuddyTrainAtTrainer`: one lesson at a time, the cheapest it can learn
  now (equal costs: lower level first), paid with the trainer's
  reputation discount; the first it can't afford ends the visit (a debug
  log line and a trace line); then the quest spells its level allows,
  free;
- the quest spells come from `buddies_quest_spells.h`, written by
  `scripts/generate-buddy-quest-spells` from every one-class quest that
  rewards a spell (48 rows today); at learning time a row is only taught
  when the game's own skill tables list the spell for that class and race
  (which passes over pre-3.0 priest racial spells and a quest's bomb), and
  a "teach" spell's taught spells are added rather than the teach spell;
- a new buddy (`buddies_create.cpp`, after the starting kit) learns,
  free, every lesson of every class trainer valid for its class and race
  up to its level, pass after pass so ranks arrive in order, then its
  quest spells; the count is logged;
- a hunter buddy of 10 or more without a pet gets a random tameable beast
  of its level at login, and a new one whenever its talents are reset
  (its owner's respec resets them, `buddy-talents.lua`), made the bot
  module's own way.

Before this:
A buddy knows only what the game gives a new character of its class, plus
what its town visits teach:

- **In a town**, the visit's "learn at the class trainer" errand
  (`modules/mod-buddies/src/buddies_town.cpp`, the train errand and its
  lesson list) walks to a class trainer of the town that has something to
  teach and asks for every lesson in the trainer's own list order. The
  server charges each one from the buddy's purse; a lesson it can't afford
  fails silently and the next is tried, so an expensive early lesson can
  block nothing but a cheap later one is still bought out of order.
- **When made above level 1** (a level-10+ Sargobras pick), the buddy is
  made at its owner's level knowing nothing beyond the level-1 defaults
  until its first town with a trainer.
- **Quest-reward class spells** (the warlock's demons, the hunter's pet
  taming, the druid's forms, the shaman's totems and so on) and **pet
  spells** are never learned: no trainer teaches them.
- The bot module's own "learn on level-up" switches
  (`AiPlayerbot.AutoLearnTrainerSpells`, `AutoLearnQuestSpells`) are on in
  the config but apply to the server's random bots only
  (`AutoMaintenanceOnLevelupAction.cpp`, the random-bot check), and a
  buddy is not one; this issue does not change that.

## Intended Behavior

The owner, 2026-10-03, on when buddies learn: "they can't lag behind
because that's also when the player can learn new spells, so... they'll
always be roughly equivalent. Just on town visits, and only if there's a
trainer in that town." On paying: "It's own money. If it gets to the
trainer and realizes it doesn't have enough money, it should mark the task
as complete. It should learn the lowest cost spells first." On a buddy made
above level 1: "Everything up to it's level." On quest and pet spells: "we
can manually add the quest-reward spells and pet spells and such to the
list of spells we teach to each class."

1. **Town lessons, cheapest first.** The train errand gathers every lesson
   the trainer can teach the buddy now, sorts them by cost (cheapest
   first; equal costs by required level, then by the trainer's order, so a
   rank is still learned before the rank that needs it), and buys them in
   that order. The first lesson it can't afford ends the errand: it is
   marked done and the visit moves to its next errand (debug log only).
2. **Quest and pet spells at the trainer.** A per-class list of the class
   spells that quests reward, with the level each becomes available, is
   taught at the same class trainer visit, after the paid lessons, once the
   buddy's level allows. Free: a player gets them by doing the quest, not
   by paying.
3. **Everything at creation.** A buddy made above level 1 is taught, when
   it is made and free of charge, every lesson a class trainer of its own
   race could teach at its level and every quest spell its level allows,
   as if it had visited trainers and done its class quests on the way.
4. **Nothing on level-up.** Between towns a buddy learns nothing, exactly
   as its owner learns nothing between towns.
5. **Hunter pets are given, not tamed.** A hunter buddy (from level 10,
   when a player hunter can first tame) is given a random tameable beast
   as its pet when made, and a new random one, at once, every time its
   owner respecs. It never tames in the world.
6. **Running out of money is normal**: the errand just ends; nothing is
   said, and only a debug-level log line records it.
7. **Proficiencies are lessons too.** Armour proficiencies a class
   trainer teaches at 40 (Plate Mail for warriors and paladins, Mail for
   shamans and hunters) and the weapon skills a weapon master teaches
   (bows, guns, crossbows, thrown, and each weapon kind the class may use)
   are learned like any other lesson: at creation for a buddy made above
   the level, and from the town's trainer and weapon master on visits.
   Found 2026-10-04: Growth's level-60 buddies, made before item 3 runs,
   had none of them, and the game refused their Tier 1 armour and their
   bows and guns. `.elite` (617r) now teaches a missing proficiency before
   it equips an item and says so in its report; that is a mend, and this
   item is the fix.

## Suggested Implementation Steps

1. **The quest-spell list is generated, not written by hand.** A script
   (`scripts/generate-buddy-quest-spells`) reads the world database's
   class quests (`quest_template` with `quest_template_addon`'s allowed
   classes) whose reward teaches a spell (the reward's display spell is
   the spell learned), and writes a header beside the kit's tier table:
   class, race mask, quest minimum level, spell. Quests of other races'
   versions of the same lesson (the warlock's "The Binding" exists once
   per starting city) collapse to one row per class, spell and level.
   Hand additions (pet spells no quest covers) go in a small separate
   list in the same header, each with a comment saying where a player gets
   it.
2. **Town lessons**: in the train errand, collect the teachable lessons,
   sort by money cost (with the trainer's reputation discount), teach in
   order, stop at the first unaffordable one; then the quest spells from
   step 1 the buddy lacks and its level allows.
3. **Hunter pets**: a pick from the world's tameable beasts (creature
   templates flagged tameable, of a level the buddy could tame) made into
   the buddy's pet when it is made and on its owner's respec (the respec
   hook that already re-rolls talents, 617g).
4. **Creation lessons**: right after the starting kit
   (`buddies_create.cpp`), find a class trainer whose lessons are valid for
   the buddy's race (the world's creature list joined to its trainer
   data), and teach every lesson its level allows, without charge, in
   required-level order (so ranks arrive in sequence); then the quest
   spells. Log what was taught as a count, and log as an error a class with
   no valid trainer found.
5. **Test**: an offline test of the cheapest-first ordering and the stop
   rule (`scripts/test-buddy-lessons`), with a lesson list where the
   trainer's order and the cost order differ and the purse runs out
   mid-list; and a database check that every class has at least one quest
   spell row and a valid trainer per race.

## Open Questions

- Weapon masters in the capitals: how many more kinds may a buddy learn
  there (up to every kind its class can, or a few per visit), and does it
  pay the 10 silver like a player?
- "One for each of the player's learned weapon skills": built as "until
  it knows as many kinds as its owner" (its starting kinds count). Or
  should it be that many random kinds on top of what it starts with?

- (Answered 2026-10-03) Creation lessons are free at every level, level 1
  included: "Yes."
- (Answered 2026-10-03) Hunter pets: "It should start with one randomly.
  Everytime the player respecs, they should pick a new pet and get it
  instantly. They don't need to tame their pets, let's say." See
  Intended Behavior 5.
- (Answered 2026-10-03) Running out of money at the trainer says nothing
  and logs nothing in normal running: "don't even need a log line except
  for debug to make sure it works, it should be a normal occurence." A
  debug-level log line only.

## Related Issues

- **617** parent; blocked by **617a3**, **617e4**; related **617a4**,
  **617h**
