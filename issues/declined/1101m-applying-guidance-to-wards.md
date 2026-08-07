# 1101m - Applying Guidance to the Wards

## Status
- Created: 2026-08-01
- Parent: Issue 1101 (Bellwether — attended play)
- Phase: 11
- Priority: High
- Depends on: 1101l (parsed directives), 916i and 916j (the apply path)

## Overview

Takes a validated directive and makes it true of a ward. This is the
shortest sub-issue in the family, because issue 916 already built the
machinery — 916i applies directives through the C++ shim, and 916j adds
the `SorenDirected` strategy class that gives directives leverage the
stock strategy palette doesn't have.

What this issue adds is a second caller with different authority, and a
clear statement of what that authority can and cannot do.

## Current Behavior

916's guidance layer applies LLM-derived directives to bots in parties
near a player. Nothing applies a *player's* directives to a family of
altbots being attended from elsewhere.

## Intended Behavior

### Reuse, don't rebuild

The apply path is 916's: strategy adds and removes through
`ChangeStrategy`, action multiplier overrides, and per-bot policy state
read by `SorenDirected`. Bellwether's directives are the same shape and
take the same road.

If they can't — if the shim's entry points assume a party near a player
— then extending them is the work here, and it should extend rather than
fork.

### Two sources, one target, and who wins

A ward could be receiving directives from two places at once: the
player, through this path, and mod-soren-chat's guidance layer, if that
ward happens to be near a real player.

The rule: **the player's guidance wins.** Always, and without a merge.
A player who told their family to stay back and then watched the model
override them because a fight looked winnable would be right to stop
trusting the system.

Mechanically this means per-bot policy state carries its source, and the
916 guidance layer declines to overwrite player-sourced policy. Whether
that's a flag on the policy record or a separate slot that shadows it is
an implementation choice; that it's enforced is not.

### Levers, not control

From `notes/wow-chat-secretary-2`, the standing house position:

> An LLM should have levers to pull, not timestamps to clobber and
> crush. If it could place files anywhere, it could be hacked. It's just
> a security concern, and it violates the bot's autonomy.

Applied here, and it cuts in two directions at once.

The **safety** reading: a bounded directive vocabulary means the worst a
misparse can do is make a ward fight badly. There is no directive that
deletes a character, spends their money, or drops their gear. The set of
levers is the set of things guidance can do, and it should stay small
enough to enumerate.

The **autonomy** reading: these are the player's own characters under
bot control, and guidance sets their posture rather than puppeteering
them. A directive says *how to be*, not *what to do next*. The bot's own
engine keeps making moment-to-moment decisions, which is both faster
than a round trip and the thing that makes a ward feel like someone
rather than a cursor.

### The parity rule

The parent's framing — *the AI is just a different input method to the
same game* — gives a cleaner boundary than any enumerated list can:

**Guidance can do what hands can do, and no more.**

An input method conveys intent to a game that already exists. It does
not extend the game. If a directive would let an attending player do
something a player at the keyboard cannot, the directive is wrong — not
because it's dangerous, but because it means this stopped being an input
method and started being a cheat.

The list below is that rule made concrete for review. If it ever needs
an entry that the parity rule wouldn't already have caught, something
upstream of it has gone wrong.

### What guidance cannot do

Written down explicitly so the list is short and reviewable:

- Cannot delete, unlearn, or respec
- Cannot spend money or vendor items beyond a task's declared scope
- Cannot leave the family or enroll another character
- Cannot alter another player's characters
- Cannot change its own vocabulary

## Implementation Steps

1. Read 916i and 916j and establish whether their entry points serve a
   family of altbots not near a player, or need extension.
2. Route parsed directives from 1101l into the apply path.
3. Add source-tagging to per-bot policy state and the precedence rule.
4. The forbidden list above, enforced at the vocabulary boundary — a
   directive that could express a forbidden action shouldn't exist to be
   validated in the first place.
5. Confirmation back to the pipeline: a directive that applied produces
   a fact ("she's holding back now"), so the listener hears that their
   guidance took. Guidance with no audible effect is guidance the player
   can't trust.
6. Failure back to the pipeline: a directive that couldn't apply — bot
   offline, strategy unknown, ward dead — says so. Never silent.
7. Test the precedence rule directly: guide a ward, then put a real
   player next to it so 916's layer engages, and confirm the player's
   guidance survives.

## Files to Create

- Probably none new — extensions to 916's directive-apply path, plus the
  source-tagging and the forbidden-action boundary

## Open Questions

- Does 916's shim work for altbots not in a party with a live player?
  This is the first thing to find out and it may reshape this issue
  entirely.
- Is "the player always wins" right even when the player has been gone
  for an hour and the standing order has become actively harmful — a
  family holding position while something kills them? A standing order
  with no expiry is a standing order that outlives its context.
- Should applied directives be visible in-world at all? A ward whose
  posture changed could emote it, which gives a present player a way to
  see what an absent player told them.
- What happens to standing orders when a ward is unenrolled and played
  directly by the person? They should stop applying, obviously — but
  should they come back when the ward is re-enrolled?

## Related

- Parent: [1101 - Bellwether](1101-bellwether-attended-play.md)
- [916i - Response validator and directive apply](916i-response-validator-and-directive-apply.md)
  — the apply path being reused
- [916j - SorenDirected strategy class](916j-sorendirected-strategy-class.md)
  — the strategy that gives directives their leverage
- [1101l - Guidance capture](1101l-guidance-capture-and-standing-orders.md)
  — supplies the directives
- [607 - Player bot behavior commands](607-player-bot-behavior-commands.md)
  — the in-game equivalent of this, for a player who is present
- `notes/wow-chat-secretary-2` — the levers principle
</content>
