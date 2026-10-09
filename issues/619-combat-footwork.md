# 619 - Combat Footwork

## Status
- Created: 2026-10-08
- Phase: 6
- Related: 617 (buddy bots), 617t (stand-ins), 617e5 (fighting together),
  176a (test scenes: where this was first written down), 176a1 (the
  Alterac Valley scene, whose stand-ins fight this way), 176a2d (Arathi
  Basin squads: formations that break into this footwork), 161 (bot
  wandering and combat repositioning, kiting)
- Priority: Medium

## Origin

The owner, 2026-10-08, asked whether test characters in one run meet:

> um. yes? also they give each other space in combat and make darts
> forward when critting and dodges make them jump back. Parry usually
> moves them to the side and when they interrupt or are interrupted
> they'll move a little bit to apply repositioning (to a more tactical
> advantage in relation to the other characters around them and the
> environment they're at.) Also if they're in danger they'll fall back,
> but they try to do so as a pack, losing ground as steadily as possible
> while keeping their area clear of foes.

Asked whether it gets a plan of its own: "yes, it's a player-bots patch."

## Current Behavior

Not built. Bots played by the playerbots module stand where their
combat strategy puts them (melee at the target, ranged at casting range)
and move only to reach range, to follow, or to flee. Nothing they do
reacts to how a single swing turned out, and two bots on one target can
stand inside each other.

## Intended Behavior

Every bot the playerbots module plays (buddies, stand-ins, and in time
any bot) moves with the fight, not only toward it:

- **Space.** Bots fighting near each other keep a gap, so none stands
  inside another.
- **A critical hit:** the bot that landed it darts a short way forward.
- **A dodge:** the bot that dodged hops back.
- **A parry:** the bot that parried steps to the side.
- **An interrupt,** given or taken: a short move to a better spot, judged
  against the characters around it (allies, enemies) and the ground
  (walls, ledges, water).
- **In danger: a pack retreat.** Bots in trouble fall back together,
  giving ground as steadily as they can while keeping their own area
  clear of enemies, not each running its own way.

Each move is small and quick, so it reads as footwork and never pulls a
bot out of its role.

## Suggested Implementation Steps

1. Read how the playerbots module chooses a bot's position in combat
   (its movement actions and their triggers) and where a swing's result
   (critical, dodge, parry) and an interrupt reach the bot.
2. The reactions as a source patch (`patches/B*.sh`, the
   `upstream-patch-system` conventions), each a short move with its
   direction and length kept together in one table.
3. Spacing between bots on one target.
4. The pack retreat: the group's danger, the direction to give ground,
   and a pace held in common.
5. Tests: the moves worked out offline for a set of fights (a dodge
   moves back, a parry moves aside), and the Alterac Valley scene's logs
   (176a1) showing stand-ins that keep their spacing.

## Open Questions

1. **How far and how fast** each move goes (a dart, a hop, a sidestep),
   and how often one bot may make them.
2. **Who does the footwork:** only buddies and stand-ins, or every bot
   and also creatures?
3. **"In danger":** measured how (the pack's health, the number of
   enemies, a healer down)?
4. **The movement coroutines** (176a's answer 6: orbit a foe, turn while
   walking, jump onto a reachable ledge): are these moves built from
   them, so the same library steers the client's test characters and the
   server's bots?
