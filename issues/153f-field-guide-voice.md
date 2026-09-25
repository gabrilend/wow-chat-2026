# 153f - The Field-Guide Voice

## Status
- Created: 2026-09-03
- Phase: 1
- Parent: 153
- Depends: 153e (something to speak through), 916k (chat prompt and persona)

## Origin

> have interesting things to say about the botany of the plant - no difficult
> words, but images like "see this curved part here? that's the part that
> stores water." or "these prickers are made with a minor poison, you won't get
> hurt if you get poked, just don't lick your fingers." talking about the plant
> as if it were a real, physical plant

## What The Two Examples Establish

The brief comes with two sample lines, and almost every rule this issue needs
can be read straight off them.

> "see this curved part here? that's the part that stores water."

> "these prickers are made with a minor poison, you won't get hurt if you get
> poked, just don't lick your fingers."

**It points.** *This curved part here. These prickers.* The speaker is
standing at the plant with you and indicating a specific piece of it. Not "the
species is characterised by" — *this bit, here*.

**It names the part by what it looks like, not by what a botanist calls it.**
"Prickers", not spines or trichomes. "The curved part", not the sheath. The
plant is described the way somebody who has handled a lot of plants but read no
books would describe it.

**It says what the part is for.** Every one of the two lines pairs a physical
feature with its function — the curve stores water, the prickers carry poison.
The observation is never left as decoration.

**It tells you what to do about it.** *You won't get hurt if you get poked,
just don't lick your fingers.* The second half of the second line is practical
advice at the scale of a person's actual hands. This is the part that makes it
sound like knowledge rather than a label.

**It is short.** Two clauses, one thought.

**It never says the word "botany".** The brief asks for interesting things to
say about the botany of the plant, and the samples contain no scientific
vocabulary at all. Botany is the subject, not the register.

## Current Behavior

The 916 family builds bot speech from a prompt-and-persona module (916k) whose
persona axes are race, class and spec, and whose validator (916i) checks a
response before it is emitted. That is a good machine pointed at a different
target: it makes an orc warrior sound like an orc warrior. It has no notion of
a physical object being described to somebody looking at it.

## Intended Behavior

A voice with four rules and one prohibition, applied to whatever node 153e
identified.

### The rules

1. **Point at one part.** Every line names a specific visible piece of the
   plant or the mineral and locates it — *this curved part, these prickers,
   the underside of these leaves, the green streak running through it.*
2. **Use the word a person would use.** If a plain word exists, it wins.
   "Prickers" beats "spines". "The stem" beats "the petiole". Where no plain
   word exists, describe the shape instead of naming it.
3. **Say what it is for, or what it does.** Structure paired with function.
   A feature mentioned and not explained is a wasted line.
4. **Where there is something to do or avoid, say it at hand-scale.** Don't
   lick your fingers. It'll stain your gloves. Snap it low or it won't grow
   back.

### The prohibition

**No taxonomy, no Latin, no measurements, no rarity, no game.** Not the
genus, not the family, not "found in temperate zones", not "sells for two
silver", not "required for Elixir of Minor Fortitude", not "you need 75
herbalism". The plant is a plant. The moment the voice mentions a skill level
it has stopped being a person looking at a plant and become a tooltip.

### Minerals get the same treatment

The brief says "the plant or mineral", and the rules transfer with one
substitution: a mineral's parts are its faces, its colour banding, its
weight, the way it breaks. *See how this splits flat instead of crumbling?
That's the same reason it takes a polish.* Same pointing, same plain words,
same function.

## Suggested Implementation Steps

1. **Write twenty lines by hand before writing any prompt.** Ten plants, ten
   minerals, in the voice, judged against the two samples. They are the
   specification — a prompt is only ever an attempt to reproduce a target, and
   without the target written down there is nothing to compare a generation to.

2. **Build the persona as a rules list plus those examples**, in 916k's
   existing shape. Few-shot examples do most of the work for a voice this
   specific; the rules mostly exist to catch the failure modes the examples
   do not.

3. **Extend the validator (916i) with the prohibition.** A response containing
   a Latin binomial, a number with a unit, a skill level, an item name, or any
   of a short list of register-breaking words is rejected and regenerated
   rather than emitted. This is a cheap string check and it catches the
   failure that most damages the profile.

4. **Feed it the node name and nothing else.** The only ground truth available
   is the `gameobject_template` name — Peacebloom, Copper Vein, Briarthorn.
   Everything the bot says is generated from that word. This is worth being
   explicit about, because it means the bot is not describing a plant; it is
   describing *what the model believes a plant called Peacebloom looks like*.
   Whether that is acceptable is the question 153g exists to improve.

5. **Read a hundred outputs before turning it on.** The failure mode is not
   wrongness, it is blandness — a hundred lines that all say the leaves are
   broad and store energy. Variety across a species set is the thing to
   measure, and it is measured by reading.

## Affected Files (anticipated)

- a naturalist persona module alongside 916k's chat persona
- the validator's rejection list, extending 916i
- a hand-written reference file of target lines, kept as the specification

## Related Issues

- **916k** chat prompt and persona — the machinery this extends
- **916i** response validator — where the prohibition is enforced
- **153e** the bot that speaks these lines
- **153g** the grounding loop that tries to make the content true rather than
  merely plausible
- **912** automated lore generation — the other generated-text system, and
  worth comparing for tone so the profiles do not all sound the same

## Open Questions

- **Is being plausible good enough?** The bot describes what a model thinks
  Peacebloom looks like. A player who looks at the actual in-game model may see
  something else entirely, and the sprite is the only thing both of them can
  see. 153g is one answer; another is to feed the model the actual icon or
  model texture; a third is to accept invention as the point.
- **Does the same node always get the same line?** Caching one good line per
  species is cheap, consistent, and makes the world feel authored. Generating
  fresh every time is varied and expensive and will contradict itself. A player
  who hears two different accounts of Peacebloom has caught the machine.
- **Whose voice is it?** Every bot has a race and a class from mod-playerbots.
  Does a tauren describe a plant differently from a gnome, or is the naturalist
  voice one voice regardless of who is wearing it?
- **How long is a line?** Both samples are one sentence. Is that the cap, or
  the opening of something longer if the player stays?
