# 1202c - The Robots Speak Kindly: the Chat Layer for Children

## Status
- Created: 2026-10-17
- Phase: 12
- Parent: 1202 (the robot stage show)
- Blocked by: 916d (the model runner)
- Related: 916k (personas), 916l (the chat grammar and filter), 916i
  (checking replies), 916o (prompt scrubbing, untrusted places)
- Priority: High within 1202: nothing is shown to a child before this
  works

## Current Behavior

The buddies' chat layer (916) is designed for players in World of
Warcraft: a persona per bot (916k), one plain sentence per reply held
to a grammar llama.cpp enforces (916l: a capital, up to 180 characters,
no line breaks, brackets or addresses, one sentence end), and a filter
on every reply. None of it was made for children.

## Intended Behavior

The same layer, with rules for children at every point where a model's
words could go wrong:

- **Personas written by hand**, not generated: three or four robots, each
  a short paragraph (the curious one, the worried one, the joker, the
  one who sings), kind and a little silly, never cross, never scary.
- **A smaller grammar**: one sentence of at most 12 words, the 916l
  shape but shorter, so a small child can follow it when it is read
  aloud.
- **A word list**: every word in a reply must be on a list of words
  for young children (a few thousand, the project's own list, kept in a
  file), and the grammar is built from it, so the model **cannot** use
  any other word. This is the strongest guard: not a filter after the
  fact but a vocabulary the model is held to while it writes.
- **What goes in**: the prompt holds only the persona, the scene, the
  thing that was clicked and the last two lines said. Nothing about the
  child: there is nothing to scrub because nothing is asked (1202d).
- **What comes out**: every line still passes a filter (916l's, plus a
  list of words never wanted even if a grammar allowed them), is spoken
  by the browser's speech or another voice (open question) and shown as
  a caption. A refused line is counted in the run's receipt, and the
  robot says a stock line instead ("Ooh, look at that!"), from a short
  list written by hand.
- **Where the model runs**: a trusted place only (916d's in-server or
  beside), never a contributed one: these words go to children.

## Suggested Implementation Steps

1. The word list and its source (open question), with a tool that
   builds the grammar from it.
2. The personas, the prompt shape, the stock lines.
3. Check with `scripts/check-llama-grammar` that the word-list grammar
   parses (it will be large: one alternative per word).
4. A test with a text-writing model: a thousand replies, every word on
   the list, none refused by the filter; and a person reads a hundred of
   them before anything is shown to a child.

## Open Questions

1. **The word list.** Written by us from scratch, or taken from a
   published list of early-reading words (whose licence must allow it)?
2. **Live words, or approved words?** Live is surprising; approved (the
   model writes ahead, a person approves, the show says only approved
   lines) is safest. Proposed: approved lines for the first public
   version, live only at home with a parent watching.
3. Does a word-list grammar this large slow llama.cpp's sampling
   noticeably? Measured in step 3 with a real model.
