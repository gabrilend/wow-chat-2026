# 629b - Road Forks by Deck

## Status
- Created: 2026-10-17
- Phase: 6
- Parent: 629 (battleground fronts)
- Blocked by: None
- Related: 176a2c (Arathi Basin's roads taken in turn: the same idea kept
  per side, not per bot), 617c3 (the dungeon draw: a bag drawn without
  replacement)
- Priority: Medium

## Origin

See 629 (the owner's words, 2026-10-17, quoted in full there): "at each
road Y intersection, the NPC takes a direction. They choose through a
shuffled random pick, meaning, deck of cards shuffled without
replacement. In this way, we don't have to do random number
calculations, we can just flip a switch back and forth everytime they
use it for each NPC. And we can save them up and batch them for calls to
the database if we want".

## Current Behavior

**On paper, 2026-10-17** (homework branch): `Front.new_deck` and
`Front.deal` in `src/lua-basic/lib/battleground-front.lua`, checked by
`scripts/test-battleground-front` (two branches flip every pass, across
the refill too; three branches take each once a round, 100 each in 300
passes; six bots' orders differ; one seed deals the same cards). The
first version swapped a two-branch deck's order at each refill, which
dealt a, b, b, a; the test caught it. In the paper matches every fork is
a two-way split (the road tree in `Front.road_path`), so every deck there
is a switch. Not in the buddy module.

Arathi Basin's routes (176a2c, built on paper) keep one pointer per side,
per crossing, per road arrived by, and turn it for the next squad, so
squads of one side alternate.

## Intended Behavior

- **Roads toward the front.** A bot that appears (at its graveyard or
  home) follows roads (629's question 3) to the front its objective lies
  on (629a).
- **Each bot's own deck, at each fork.** At a fork, the branches leading
  on (every road but the one it came by) are a deck of cards. The bot
  holds one deck per fork: shuffled once when it first reaches that fork,
  dealt one card each time it passes, shuffled again when every card has
  been dealt. Over its passes it takes every branch equally, in an order
  that differs from bot to bot.
- **Two branches: a switch.** With two branches, the deck is a switch:
  which way first is the only random draw, and after that it flips each
  pass. With three or more, one shuffle per round of the deck.
- **Kept and batched.** A bot's decks (per fork: the order and how far
  dealt) are small: a few bits per fork. They live in memory during the
  match; when they are kept past it (a stand-in kept for reuse, 617t), they
  are written together, all bots at once, at the match's end, not per
  pass.

Deck: per fork, the shuffled order of its branches (a short list of
branch numbers, each a small integer) and the index of the next card (a
small integer). A switch is the same with two cards.

## Suggested Implementation Steps

1. The deck in the Lua rules beside 176a2c's routes: shuffle, deal,
   reshuffle; the switch case. Tested: over many passes every branch is
   taken equally; two bots' orders differ; the same seed repeats.
2. In the buddy module: the decks per bot, the batch written at match end.

## Open Questions

1. Arathi Basin's roads already alternate per side (176a2c). Should those
   become per bot too, or do squads keep the side's pointer and lone bots
   use their own decks?
2. **Kept, or worked out?** The starting-valley deck (155d1,
   `src/lua-basic/lib/valley-deck.lua`) gives each character a fixed order
   worked out from its id every time and never stored. A bot's fork decks
   could work the same way: the order from the bot's id and the fork's
   number, with only "how many times has it passed this fork" to count.
   That would need no database writes at all, batched or not. Which do
   you want: decks kept and written in a batch, or orders worked out from
   the id?
