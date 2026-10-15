# 620e - Bots Learn from Our Trainers

## Status
- Created: 2026-10-14
- Phase: 6
- Parent: 620
- Blocked by: 620a
- Related: 155e (Visiting Mentors), 155e1 (the profession mentor), 155p1
  (each jewelcrafter teaches different cuts), 155q (class books for
  61–80 abilities), 155n (Outland without tradeskills), 617n (buddy spell
  learning), 617p (NPC awareness)
- Priority: Medium

## Origin

The owner, 2026-10-14: playerbots should work with "all the other
features we've added". Training is the one every bot meets first.

## Current Behavior

The trainers a bot meets on basic are not the stock ones:

- **Visiting Mentors** (155e, `sql/basic/db_world.updater/z_10-valley-
  universal-trainers.sql`): one creature per valley, first town and
  capital that lacks a class's trainer. Its trainer lists are opened
  from dialogue lines ("Can you teach me the ways of the Mage?"), each
  naming its list (B029). The creature has the trainer flag, but the bot
  module's trainer action reads only the creature's own list, so an alt
  bot told to train there learns nothing, or the wrong class's lessons.
- **The profession mentor** (155e1) and **the eccentric jewelcrafter**
  (155p1): planned, the same dialogue-line mechanism.
- **Class books** (155q): abilities 61–80 come only from books dropped in
  raids. Random bots learn spells automatically by level and class from
  the bot module's own tables, not from trainers or books.
- **Buddies** learn by walking to a trainer and paying (617n, 617p),
  through mod-buddies, not through the bot module's action.

## Intended Behavior

- **An alt bot told to train** at a Visiting Mentor learns its own
  class's lessons there: the bot module's trainer action reads the list
  the mentor's dialogue line for that class names.
- **Random bots learn from trainers like buddies do**, walking to the
  nearest trainer (stock or mentor) that has lessons they can afford,
  instead of learning automatically. The 617p walk-up is the model; it
  may simply be given to random bots.
- **Professions:** the same for the profession mentor and the eccentric
  jewelcrafter once they exist.
- **Class books:** a bot uses any class book it carries that it can learn
  (a bag scan on level-up and loot).
- **Outland and Northrend profession trainers teach nothing** (owner,
  2026-10-13); bots never try them.

## Suggested Implementation Steps

1. B-patch on the bot module's trainer action: when the creature is a
   Visiting Mentor (has gossip trainer options, B029), use the list named
   by the option for the bot's class.
2. Random bots: turn off the bot module's automatic learning on basic
   (config patch) and give them 617p's walk-to-a-trainer behaviour
   (mod-buddies, gated on 620a's kind).
3. Class books: a use-what-you-can-learn step after loot.
4. Test in game: an alt mage in Sunstrider Isle told to train at the
   mentor; a random bot at level 4 in a valley (cc-test scene).
5. Update 155e, 155q and 617n's Current Behavior with the bot case.

## Open Questions

- Should random bots really give up automatic learning (slower, but they
  then play the same game), or keep it and be held only to basic's limits
  (620f)?
