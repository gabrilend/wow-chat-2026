# 625 - Buddies Favour the Abilities Their Talents Touch

## Status
- Created: 2026-10-15
- Phase: 6
- Related: 617g (talent shapes), 622 (a buddy's own record of what works),
  309 (monsters that choose their attacks)
- Priority: Medium
- State: an idea; the design is open

## Origin

Verbatim, 2026-10-15:

> would it be possible to cause buddy-bots to be more likely to use the
> abilities that are mentioned or affected by the spec talents they are
> slotted? Just... in general.

## Current Behavior

A buddy fights by the bot module's strategies for its class and the tree
the module guesses from its talents; each action has a fixed priority.
A talent that improves an ability (more damage, less cost, a shorter
cooldown) changes nothing about how often that ability is chosen. Seen
the same day: the hunter Montahmu's strategy asked 41,000 times for
Trueshot Aura, a talent it does not have.

## Intended Behavior

Every ability a buddy's talents name or change counts for more when the
buddy chooses what to do: the more talent points spent on it, the more
it is favoured. Abilities its talents never mention keep their ordinary
weight, and an ability it does not know is never asked for.

## Suggested Implementation Steps

1. Answer the open questions.
2. From the client's tables, for each talent, the abilities it affects
   (its spell's effects that modify another spell's family flags, or that
   teach one), gathered once.
3. For a buddy, a weight per ability from the talent points it has in
   talents that touch it.
4. Those weights raise the priority of the bot module's matching actions
   (a source patch to the bot module's action choice, or the buddy
   module's own strategy), and an action for an unknown spell is dropped.

## Open Questions

1. How much more: a fixed raise per talent point, or as much as the
   talent's own effect (a talent adding 15% damage raises it by 15%)?
2. Should this live in the bot module (a patch, every bot) or only for
   buddies?
