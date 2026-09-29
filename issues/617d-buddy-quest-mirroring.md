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

Nothing mirrors quests. The core fires `OnPlayerQuestAccept(player, quest)`
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
