# 638 - Buddy Levers and the Semantic Map

## Status
- Created: 2026-10-28
- Phase: 6 (buddy-bots)
- Related: 617 (buddy bots: the levers are more things a buddy can do,
  617's principle "the buddy-bots will eventually be able to do everything
  the players can"), 904 (embeddings, there of creature names), 917 (asking
  the bots in plain text), 617o6 (jumps worked out live, bounciness),
  617e16b (judging)
- Priority: High
- State: in progress

## Origin

The owner, 2026-10-28:

> semantic map, old style AI design, except with the power of embedding
> models, to create automatically labelled segments. use this for the
> buddy-bot AI design. For now, don't think about design - just think about
> empowering them by increasing the number of things they can *do* - give
> them levers, create five hundred more, and then let them sort themselves
> into their world accordingly.

## Current Behavior

A buddy's doings are the bot module's actions and the buddy module's
behaviours (following, roaming, town errands, fighting). Nothing lists
them as one set, nothing describes them in words, and nothing groups them
by meaning. Outside a fight a buddy does almost nothing with its body:
it doesn't emote, sit, kneel (except at the fallen, 617v), hop or turn to
look at anyone.

**Built 2026-10-28 (steps 1-3), untried in game:**
- `scripts/generate-buddy-levers` writes `src/lua-basic/data/buddy-levers.lua`:
  1414 levers today (the tool prints the counts): 1187 text emotes (each
  emote alone and at each of the four kinds of target, with the game's own
  lines; the eight lines that don't open with the doer are reworded
  name-first in the tool, and a new one stops it), 134 motions no emote
  plays, and 93 of the body's own (5 poses, 3 weapon states, facing,
  turning, 33 hops from straight up to a long leap, 24 steps, walking up
  to and back from, 4 walked circles).
- `src/lua-basic/lib/buddy-levers.lua` pulls one (its `.info.md` lists the
  fields); `src/lua-basic/buddy-lever-command.lua` gives game masters
  `.lever NAME LEVER`, `.lever NAME random [WORD]`, `.lever find WORD`
  (WORD matches a segment's label first, then names and sentences).
- `scripts/test-buddy-levers` (a quick test) pulls every lever on a
  stand-in buddy and checks the refusals: 13078 checks pass. It found the
  game's empty lines and the name-inside lines before they reached a
  buddy.
- `scripts/generate-buddy-lever-map` (ollama's `nomic-embed-text:v1.5`,
  with `ollama serve` running) writes `src/lua-basic/data/buddy-lever-map.lua`:
  693 distinct meanings (the four aims of an emote share one), 19
  segments with their labels ("jump hop leap", "greet hello introduce",
  "warn enemy attacking", "step few short", ...), each an example; about
  five minutes, nearly all of it the model server.
- `scripts/generate-buddy-lever-map-page` draws it:
  `docs/HTML/buddy-lever-map.html` (dots by meaning, coloured by segment,
  the segments listed by label, a find box). Its first screenshot is in
  `tmp/shared-memory/buddy-lever-map/page.png`, not yet filed in
  `development-history/` (claimed by another session).

Not built: step 4 (sorting), and no buddy pulls a lever on its own yet
(open question 1). The labels are rough where the emotes' words are
varied ("bad check cold"); the model and the segment count are options of
the tool.

## Intended Behavior

**A lever** is one thing a buddy can do, small and whole. Each is a record:

| Field       | Type   | What it holds |
|---|---|---|
| `id`        | string | a unique, readable name: `emote.bow.at-partner` |
| `say`       | string | one plain-English sentence of what it does, the text the embedding model reads ("bow before your partner") |
| `kind`      | string | how it is done: the key into the puller's table of ways (`text-emote`, `stand`, `emote-state`, `sheathe`, `face`, `hop`, `step`, `circle`, ...) |
| `target`    | string | who or what it is aimed at: `none`, `partner`, `buddy` (another of the partner's), `player` (the nearest other player), `creature` (the nearest creature) |
| `values`    | table of numbers and strings | the kind's own values: an emote's animation number and sentences, a stand state's number, a hop's forward speed, a step's direction in radians |
| `needs`     | table of strings | when it can be pulled: `idle` (out of combat, not following an order to move), `standing`, `outdoors`... |

**The list is generated, not written.** A tool reads the game's own data
and writes every lever:
- every text emote (252 in the game's emote list), once alone and once at
  each kind of target that fits it, with the game's own sentences ("%s bows
  before %s." when aimed, "%s bows down graciously." alone), so a buddy's
  emote reads as a player's would;
- the held states (sit, sleep, kneel, dance, stand), the emote states that
  loop (working, eating, reading, fishing poses), sheathing and drawing;
- small movements of its own body: hopping in place and the small arcs
  forward at several speeds (617o6: "You can jump straight up and then move
  forward to make a tiny arc, so we should treat all of those arcs as
  possibilities"), a step in each of eight directions, turning to face each
  kind of target, a small walked circle each way.
That is over five hundred, from the data rather than by hand: new data
(another emote list, a profile's own) gives more levers by running the tool
again.

**Pulling a lever**: one puller in the server's Lua takes a buddy and a
lever and carries it out, looking the kind up in its table of ways. A
game master can pull any lever on any buddy (`.buddies lever NAME LEVER`),
or a random one from a segment (`.buddies lever NAME random SEGMENT`), to
see it. Movement levers are pulled only while a buddy is idle: the bot
module plans a buddy's movement again every moment, so a step taken while
it is following would be undone at once.

**The semantic map**: every lever's sentence is turned into a list of
numbers by an embedding model running on this computer (ollama's
`nomic-embed-text`, already downloaded), so levers that mean nearly the
same thing lie close together. The levers are then grouped into segments
by nearness (k-means on the vectors), and each segment is **labelled
automatically**: by the words its sentences use much more often than the
rest of the list does. The map is a data file (each lever's segment, each
segment's label and middle point); a page draws it, the levers as dots
placed by the two directions they differ along most, coloured by segment.
The generating and the drawing are separate tools.

**Sorting themselves into their world** (later; the owner: "For now, don't
think about design"): a buddy's moment is described in words too (where it
is, who is near, what just happened), turned into numbers the same way, and
the segments nearest it are the levers that fit. Each buddy keeps its own
leanings (as its bounciness, 617o6), so two buddies in the same moment
reach for different levers.

## Suggested Implementation Steps

1. **The lever generator**: `scripts/generate-buddy-levers`, reading the
   emote lists (`data-files/dbc/EmotesText.dbc`, `EmotesTextData.dbc`,
   `Emotes.dbc`) and its own tables of stand states, movements and
   targets, writing `src/lua-basic/data/buddy-levers.lua`.
2. **The puller**: `src/lua-basic/lib/buddy-levers.lua`, its table of
   ways by kind, and the game masters' command in a script of its own;
   a test that pulls every lever on a stand-in object that records the
   calls, so every generated lever is known to be pullable.
3. **The semantic map**: `scripts/generate-buddy-lever-map` (embeddings
   through ollama, k-means, the labels), writing
   `src/lua-basic/data/buddy-lever-map.lua`; and the page that draws it,
   separately.
4. **Sorting** (later): the moment's words, the nearest segments, each
   buddy's leanings.

## Open Questions

1. **Pulled on their own before the sorting exists?** Until step 4, should
   an idle buddy pull a lever now and then, at random, from the segments
   fit for where it stands, or only when a game master pulls one?
2. **More kinds of lever next**: after the body's own (emotes, poses,
   small movements), which first: using things in the world (sitting on
   chairs, a mailbox, an anvil, reading a book on a table), speaking
   (lines said aloud), or spells a buddy knows cast outside a fight
   (a buff on a passer-by, a light, a mount)?
