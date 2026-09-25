# 153e - Rare Naturalist Companions

## Status
- Created: 2026-09-03
- Phase: 1
- Parent: 153
- Depends: 153a (the profile), 151 (bot population governor)

## Origin

> Also the NPCbots should spawn rarely and have interesting things to say about
> the botany of the plant

## Current Behavior

**Bots are numerous by design.** Issue 151's governor holds the ambient
playerbot fleet between a floor and a ceiling — most recently tuned to between
128 and 256 on vanilla (commit `e6489f7`). That is a crowd, and it is the right
number for a profile whose defining feature is companions.

**Bots exist to fight.** mod-playerbots is a combat-party system: it fields
bots with gear, talents, rotations and a strategy engine that decides what to
cast at what. Its chat vocabulary is a command surface for directing that
combat. A profile with nothing hostile in it uses approximately none of that.

**There is a chat layer, and it is not this.** The 916 family
(`mod-soren-chat`) gives bots LLM-driven speech in two dimensions — a social
chat layer and a gameplay guidance layer — running on an Ollama cluster of
three LAN machines through effil worker threads so the worldserver tick never
blocks. Its chat layer speaks about race, class, spec and surroundings. It does
not know what a plant is.

## Intended Behavior

You walk for a long time alone. Occasionally somebody is there, and they know
about plants.

### Rare

Two numbers change, and they are the same two numbers 151 already owns: the
population floor and the ceiling. Instead of 128 to 256, explore wants
something small enough that meeting one is an event — the actual figure is a
balance decision that belongs in `docs/balance-updates.md` after somebody has
walked around, not in this file.

But "rare" is not only "few". A handful of bots spread across a whole world map
means you meet nobody, ever, which is a different failure from meeting a crowd.
So rarity here is a *proximity* property rather than a population one: the bot
fleet stays small, and the governor's placement logic keeps them within some
distance of where players actually are, so that "occasionally" means
occasionally and not never. Issue 611 already gives bots traveller-style
wandering; this is the same behaviour with the leash length changed.

### Naturalist

The bot's reason for existing is that it can tell you about the thing in front
of you. That means it needs three things it does not have:

1. **To notice a plant or a mineral.** The trigger is proximity to a herb node
   or an ore vein — gameobjects, not creatures. The 916g proximity hook watches
   for players near bots; this watches for *nodes* near both. Herb and ore
   nodes are `gameobject_template.type = 3`, and there are five figures' worth
   of them spawned in the world, so the query for "what is near me" has to be
   a grid lookup rather than a table scan.

2. **To know which node it is looking at.** The node's `gameobject_template`
   row gives a name — Peacebloom, Copper Vein, Briarthorn. That name is the
   subject of everything 153f and 153g then do. It is also the only ground
   truth in the pipeline: everything downstream is generated, and this is the
   one fact that came from the game.

3. **Something to say.** That is 153f, and how it is grounded is 153g.

### They are players, and that is not negotiable

Decided 2026-09-04:

> you should be able to invite them to parties to tell them to follow along.
> They are hired companions and will deduct some copper while they're following
> you. okay that last part's optional haha but you should be able to talk to
> them at a distance too. can't do that with NPCs.

This closes the largest open question in the whole 153 cluster, and the
argument is one the earlier draft of this file missed entirely. It had weighed
mod-playerbots against a plain ALE wandering NPC on the grounds of machinery —
the module brings gear, talents, rotations and a strategy engine for a profile
that fights nothing, so a tenth of the code would do. That reasoning was about
the wrong thing.

**A naturalist you cannot invite to your party is not a companion.** The three
affordances named are all things a *character* has and an NPC does not:

| | A playerbot | A world NPC |
| --- | --- | --- |
| Join your party | yes | no |
| Follow you across the world | yes | only if scripted per-route |
| Be whispered from across a zone | yes | no, gossip needs range and a click |

An NPC is a thing you walk up to. A player is somebody you travel with. The
profile is about walking a long way and occasionally having company, and
company that cannot come with you is scenery. So the unused combat machinery
is simply overhead, accepted knowingly.

### Hired, and paid by the minute

The other half of the same decision, marked optional by the person who
proposed it and recorded because it is the best idea in the file:

> They are hired companions and will deduct some copper while they're following
> you.

A profile with no combat and no quests has no use for money, and no sink to
put it in. This gives it one, and gives the two gathering trainers in 153d a
reason to exist beyond teaching: what you dig up and pick pays for the company
you keep while doing it. It also puts a natural limit on how long a naturalist
walks with you, without anything having to enforce a limit — the walk ends when
you decide it costs too much.

Left optional as proposed. If it is built, the rate is a
`docs/balance-updates.md` number, not a design decision, and it should start
low enough that nobody notices it before anybody has walked around for an hour.

### What it must not become

Not a quest giver, not a vendor, not a guide with a task for you. It looks at
the plant with you and says something about the plant. If the player walks
away mid-sentence, it stops. There is no thread to pick back up.

## Suggested Implementation Steps

1. **Set the population numbers first and walk around with nothing else
   built.** A world with four silent bots wandering it either feels like
   solitude with company in it or feels broken, and that is knowable before a
   single word of dialogue exists. Get the number right while it is cheap.

2. **Keep mod-playerbots — settled 2026-09-04, see below.** The bots are
   playerbots because they must be party-joinable and reachable at a distance,
   which is a player affordance and not an NPC one.

3. **Build the node-proximity trigger.** Given a bot's position, find the
   nearest herb or ore node within a short radius and return its template name.
   Reuse the grid search the ambush and travel systems already use for finding
   nearby objects rather than querying the database at runtime.

4. **Make it speak a hardcoded line first.** Before any inference exists, have
   the bot say "that's a Peacebloom" when it stands near one. That proves the
   whole chain — proximity, identification, emission, rate limiting — with
   nothing expensive in it, and it is the thing 153f and 153g then replace.

5. **Rate-limit the mouth.** A bot standing in a field of Peacebloom will
   trigger on every node it passes. One remark per node type per encounter,
   and a cooldown, or the profile's one pleasure becomes its one irritation.

## Affected Files (anticipated)

- `src/lua-explore/` — the node-proximity trigger and the emission path
- the bot governor's floor and ceiling for the explore profile
- `docs/balance-updates.md` — the population numbers and the speech cooldown

## Related Issues

- **151** bot population governor — owns the numbers this issue changes
- **611** bot wandering, traveller-style — the movement behaviour to reuse
- **916g** proximity detection hook — the same shape of trigger, watching
  players rather than gameobjects
- **916l** chat emission and rate limit — the mouth, already designed
- **917** ask the bots in plain text — the other direction of the same
  conversation; a player who wants to ask about a plant rather than be told

## Open Questions

- **Does hiring have a transaction, or is it ambient?** Copper deducted per
  tick while a companion is in your party is invisible and frictionless. A
  price agreed when you invite them is a moment, and a moment is a small piece
  of characterisation. The second is better and costs a gossip menu.
- **What happens when you run out of copper?** They stop following, presumably.
  Whether they say something about it, and whether that is funny or sad, is a
  153f question.


- **How rare is rare?** Needs walking, not deciding.
- **Does the bot approach the player, or the node?** A bot that walks over
  when you stop at a plant is a companion. A bot that is already at the plant
  when you arrive is a stranger. Both are good and they are different games.
- **What happens if the player has nothing to gather with?** The trainers in
  153d are the only way to learn herbalism and mining. Does a bot comment on a
  plant the player cannot pick, and is that interesting or annoying?
- **Do bots talk to each other?** Two naturalists at the same node is either
  the best thing in the profile or an infinite loop.
