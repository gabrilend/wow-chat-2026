# 617d - Buddy Quest Mirroring

## Status
- Created: 2026-09-23
- Phase: 6
- Parent: 617
- Blocked by: 617c
- Priority: Medium

## Origin

Verbatim, 2026-09-23: "They instantly receive every quest that you do and
complete it automatically whenever you do."

## Current Behavior

**Built 2026-09-29, not yet compiled or tried in game** (owner: "we're
going to auto-complete buddy quests to ensure they level up alongside
you"): `patches/B036-mod-buddies/mod-buddies/src/buddies_xp.cpp`, at its end. On the
server's quest-reward hook for an owner, each of the owner's buddies in
the world is given the quest, has it completed and rewarded in one step
(skipped if done before and not repeatable; a full quest log is logged as
an error and nothing is given). A reward item that doesn't fit its bags is
mailed by the server's own reward step, and the buddy collects its mail at
the town's nearest mailbox, first of its town errands (owner: "for full
bags, can you mail them the item instead? make sure they actually check
their mail"; `buddies_town.cpp`, the mail errand). Choice rewards by the bot
module's own rule, written out there (its function is private).
Requirements are not checked. A buddy's own reward is never passed on.

**A buddy offline misses it.** Only buddies in the world at that moment
get the quest; one set aside (roster stage 5), not yet logged in, or
still arriving misses it for good. The owner, 2026-10-22: "it should give
the reward to each buddy in your clan unconditionally."

**Fixed 2026-10-22, the crash.** Until then the reward step was called
with no quest giver, and the server reads the giver unchecked in two
places: a quest whose reward includes a spell (a giver's blessing) and a
quest that sends a follow-up letter. The first such quest turned in with
a buddy in the world crashed the worldserver (Glowsticks, "A Fistful of
Slivers", spell 24829). The buddy is now named as its own giver (the Lua
engine's own reward call does the same with the player); a blessing the
reward step then can't cast (it looks for a creature with the buddy's id)
the buddy casts on itself. `scripts/test-quest-reward-has-a-giver` (a
quick test) fails if any of the project's C++ names no giver again.
Takes effect at the next compile.

Before: nothing mirrored quests. The core fires `OnPlayerQuestAccept(player, quest)`
and `OnPlayerCompleteQuest(player, quest)`
(`src/server/game/Scripting/ScriptDefines/PlayerScript.h`). Bots keep
ordinary quest logs.

## Intended Behavior

- **Owner, 2026-09-27: "we also don't need to track quest progress for
  bots - it is irrelevant. They get a completed quest when you turn yours
  in."** So a buddy never holds the quest in its log: nothing happens on
  accept or abandon, and on the owner's turn-in each buddy is given the
  quest as completed, with its rewards. (Replaces the accept and abandon
  mirroring below.)
- *(Superseded 2026-09-27)* When the owner accepts a quest, every buddy
  (grouped or not) gets it, regardless of whether they could have picked
  it up themselves.
- When the owner turns a quest in, every buddy completes it and receives
  its experience, money and a reward item. For a choice reward, a buddy
  picks the way every playerbot already does (Ritz, 2026-09-23: "what
  would the playerbots pick? they level up according to the same rules that
  the player does"). In `TalkToQuestGiverAction::BestRewards`
  (`modules/mod-playerbots/src/Ai/Base/Actions/TalkToQuestGiverAction.cpp`)
  each choice is ranked by what the bot could do with it: an upgrade it
  can equip beats gear it could wear but that isn't better, which beats
  anything merely usable. Ties go to the highest score from the bot's
  spec stat weights (`StatsWeightCalculator`). Bots owned by a player
  ("alt" bots, which buddies are) pick on their own only when
  `AiPlayerbot.AutoPickReward = yes` (the default); `ask` would make them
  list the choices to the owner instead.
- Kill credit and collection are not tracked for buddies; their copy
  completes when the owner's does.
- *(Superseded 2026-09-27)* Abandoning a quest abandons it for the buddies.

## Suggested Implementation Steps

1. A hook in mod-buddies on the owner's quest reward only.
2. For each buddy: add the quest, mark it complete and reward it through
   the core's own quest-reward path in one step, so follow-up quests
   unlock normally.
3. Offline buddies can't exist (they log in with the owner, 617c), so no
   queue is needed.
4. Test: accept, kill-quest, turn in; check every buddy's log and reward.

## Related Issues

- **617**, **617c**

## Open Questions

- (Answered 2026-09-23) Reward items: the stock bot rule above.
- **Every buddy, unconditionally** (owner, 2026-10-22: "it should give the
  reward to each buddy in your clan unconditionally"). A buddy not in the
  world when its owner turns a quest in (set aside, not yet logged in,
  still arriving) gets it at its next login: the turn-in is written to a
  characters-database list of owed quests (buddy, quest), and its login
  pays each one. A full quest log doesn't stop it either. Open: for a
  full log, reward the quest without taking it into the log at all (the
  server's reward step works from the quest itself; taking it into the
  log first is what needs a free slot), or something else?
