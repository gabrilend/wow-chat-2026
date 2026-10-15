# 620d - Bots and Buddies Meet

## Status
- Created: 2026-10-14
- Phase: 6
- Parent: 620
- Blocked by: 620a
- Related: 617c2 (proximity party), 617c4 (buddy loyalty), 617a5 (buddies
  hidden and locked), 617j (loot rolls), 617e5 (fighting together), 617s
  (compass formation), 619 (combat footwork)
- Priority: Medium

## Origin

The owner, 2026-10-14: playerbots should "interact with [...] buddy-bots
correctly".

## Current Behavior

Buddies were built for a world where the only other characters are
humans and other buddies. What each buddy rule does when the other side is
an alt bot or a random bot, untested:

- **Invites** (`buddies_loyalty.cpp`, 617c4): a buddy joins only an
  invite from its owner or the owner's group, and answers anyone else
  "Thanks, but I stay with my clan." Random bots invite nearby characters
  into groups on their own; each refusal would be one more line, every
  time a random bot tries again.
- **Commands** (B045): chat commands to a buddy are dropped. An alt bot
  that relays its master's commands to its group would be ignored by
  buddies; nothing breaks.
- **Hidden** (B044, 617a5): buddies are skipped by /who and add-friend;
  random bots that search for players to group with use their own lists,
  not /who, so they may still find buddies.
- **Loot** (B046, 617j): buddies roll need or greed by their own
  judgement. In a party with an alt bot, the alt bot rolls by the bot
  module's stock rules; nobody has looked at whether the two together
  are fair to the human.
- **Trades and duels:** random bots offer trades and accept duels; a
  buddy's answer to either is the bot module's stock answer.
- **Fighting** (617e5, 617s): a buddy helps its own owner and party. A
  random bot fighting next to a buddy is a stranger to it.

## Intended Behavior

A buddy treats an alt bot or random bot exactly as it treats a human who
is not its owner, and the bot treats a buddy as a player of another clan:

- **Invites:** refused quietly. A bot never gets the spoken refusal (it
  cannot read it); the random bot's invite logic skips buddies so it does
  not ask again.
- **Trades and duels:** a buddy declines both from anyone outside its
  clan, human or bot.
- **Loot in a mixed party:** alt bots in a human's party roll greed on
  anything a human or buddy in the party could use as an upgrade (see
  open questions).
- **Fighting:** a buddy helps any friendly character fighting within its
  roam area, the same way it helps a stranger human (617e5's rule for
  strangers, or none, whichever 617e5 settles).
- **The owner's alt bot is family:** an alt bot whose master is the
  buddy's owner counts as in the owner's group for loyalty, so the owner
  can party their buddies with their alts.

## Suggested Implementation Steps

1. Loyalty (`buddies_loyalty.cpp`): with 620a's kind, refuse a bot's
   invite without the spoken line; accept from an alt bot of the owner.
2. The random bot's group-finding (bot module, a B-patch): skip any
   character on the companion list.
3. Trades and duels: refuse from outside the clan (mod-buddies, on the
   server's trade-request and duel-request hooks).
4. Loot: a B-patch beside B046 so an alt bot in a party with a human
   greeds where B046 would let a buddy or human need.
5. Test in game: a human with an alt bot and two buddies in one party,
   in a dungeon; a random bot inviting a buddy (on cc-test, which can place
   one).
6. Update 617c4, 617j and 617e5's Current Behavior with the bot cases.

## Open Questions

- **Loot:** should an alt bot roll at all in its master's party, or pass
  everything (the master can trade it anything later)?
- **Is an alt bot "family"** to its master's buddies (shares the owner's
  clan rules), or a stranger like any other bot?
