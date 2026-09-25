# 153 - The Explore Profile

## Status
- Created: 2026-09-03
- Phase: 1 (Foundation — profile model, alongside 148's vanilla cluster)
- Priority: Medium
- Sub-issues: 153a through 153g

## Origin

Verbatim, 2026-09-03:

> Can we add issue files to add a "explore" profile which just has wowchat
> spawn profession trainers for herbalism and mining, and triple the number of
> critters in the world. All NPCs should be removed from the world, except
> critters. Also the NPCbots should spawn rarely and have interesting things to
> say about the botany of the plant - no difficult words, but images like "see
> this curved part here? that's the part that stores water." or "these prickers
> are made with a minor poison, you won't get hurt if you get poked, just don't
> lick your fingers." talking about the plant as if it were a real, physical
> plant, and it should be imagining stable-diffusion generated images of the
> plant or mineral and used as input so that it knew what it was looking at.
> Just, one after another, a new one for each token of output. Yes this means
> slowing down the output phase, but it means more accurate results throughput.

## What This Profile Is

A profile with the combat taken out and the looking-at-things left in.

The other profiles all answer "what happens to you". Vanilla is a constrained
survival ladder, beta is the wow-chat design corpus, release and alpha are
level-80 baselines. Explore answers a different question: **what is in the
world, and what is it made of.** The player walks, finds a plant or a seam of
ore, and somebody who knows about plants and ore tells them something true
about it. Nothing attacks. Nothing sells anything. Nothing has a quest.

Concretely, four departures from every other profile:

1. **The world holds critters and nothing else that breathes.** No monsters,
   no vendors, no guards, no quest givers, no class trainers.
2. **Three times as many critters**, so the emptiness reads as a meadow
   rather than a vacuum.
3. **Exactly two trainers exist** — herbalism and mining — and they wander
   in rather than standing in towns.
4. **Companions are rare and are naturalists.** A bot turns up occasionally,
   and what it has to say is about the physical construction of the plant or
   the mineral in front of you, in the words a person would actually use.

## Why It Earns Its Own Profile

Every one of those four is a *removal* or a *narrowing* of something another
profile depends on. Stripping the world of trainers would break vanilla's
ability pretraining; making bots rare would break beta's companion design;
tripling critters would compete with the ambush system for spawn budget in
both. None of it can be a config flag on an existing profile without making
that profile worse. It is its own thing, and the profile mechanism (a `.profile`
value selecting a source tree, an installed tree, a database set, a Lua
directory and a set of config-patch gates) is exactly the machine for holding
a fourth "its own thing".

The profile also has a research purpose that the others cannot serve: it is
the only place the image-per-token grounding loop in 153g can be run without
its latency mattering. There is no combat to interrupt, no rotation to time,
nothing on a global cooldown. A bot that takes forty seconds to compose a
sentence about a plant is not late for anything.

## The Sub-Issues

| Issue | What it builds | Depends on |
| ----- | -------------- | ---------- |
| 153a | Profile plumbing — trees, databases, gates, scripts | 136, 133 |
| 153b | The world emptied to critters only | 203 |
| 153c | Critter density tripled | 153b |
| 153d | Herbalism and mining trainers, delivered by the travel system | 153a, 503 |
| 153e | Rare naturalist companions | 153a, 151 |
| 153f | The plain-language field-guide voice | 153e, 916k |
| 153g | Image-per-token grounding | 153f, 916d, 916e |

The order is a build order. 153a through 153d give a walkable world with two
trainers in it and nothing else; that is already the profile, and it is
playable without a single line of inference code. 153e through 153g add the
voice, and each of those three works without the next one — a bot that says
nothing, a bot that says something written by a plain prompt, and a bot that
says something grounded in re-imagined pictures are three increasingly
expensive versions of the same feature.

## What It Inherits Rather Than Rebuilds

- **The world-stripping SQL** from issue 203, which already removes every
  static creature except spirit healers and critters. That issue's outcome is
  this profile's starting state; 153b is mostly a matter of running it on a
  different database and taking the spirit healers out too.
- **The travel system** from phase 5. Trainers wandering in rather than
  standing still is exactly what `travel.lua` does, and 153d is a new
  category in its table rather than new machinery.
- **The bot population governor** from issue 151, which already holds a bot
  fleet between a floor and a ceiling. "Rarely" is a number in that governor,
  not a new system.
- **The Ollama cluster and effil worker pool** from the 916 family, which
  already run inference off the worldserver tick across three LAN machines.
  153g is a new kind of request into an existing pipe.

## Related Issues

- **148** the vanilla profile cluster — the structural precedent for a profile
  parent in phase 1 with lettered content sub-issues underneath it.
- **136** canonical profile definitions — the spec this adds a fifth row to.
- **152** profile rename (vanilla → basic, release → expert) — if that lands
  first, this profile joins a four-name scheme and `explore` should be checked
  against it for tone.
- **203** drop all creatures except spirit healers — completed; the world
  state this profile starts from.
- **151** bot population governor — the knob 153e turns down.
- **916** mod-soren-chat — the inference infrastructure 153f and 153g sit on.

## Open Questions

- **Does explore share `source-beta` or need its own tree?** Nothing here
  obviously needs a different C++ build from beta's, which argues for sharing.
  But 153g's per-token image loop may want engine support that no other
  profile should carry. Decide when 153g's shape is settled, not before.
- **Is there any combat at all?** The brief removes every NPC but critters,
  and critters are not hostile. So a character cannot die, cannot level by
  fighting, and cannot lose. Is that intended — a pure walking-and-looking
  mode — or does something eventually threaten the player?
- **How does a character progress, if at all?** Herbalism and mining are the
  only two trainers, so skill points in those two are the only ladder. Is
  that the whole progression, or does the profile inherit vanilla's level cap
  and XP curve with nothing to earn XP from?
- **What is the level cap?** Every other profile sets one in a `C006*` patch.
  If nothing grants XP the cap is decorative, but it still has to be set to
  something, and it decides what herb and ore nodes the character can work.
- **Does the player have a gathering skill at all to start with?** The two
  trainers teach herbalism and mining, which implies the character arrives
  without them. Confirm — 148q gave vanilla characters starting professions,
  and if explore inherits that hook the trainers have nothing to teach.
