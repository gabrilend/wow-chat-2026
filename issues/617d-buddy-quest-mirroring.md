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
the world is rewarded the quest directly, never taking it into its log
(since 2026-10-22, waiting for a compile; before, it was taken into the
log and completed first, and a buddy with a full log got nothing).
Skipped if done before and not repeatable. A reward item that doesn't fit its bags is
mailed by the server's own reward step, and the buddy collects its mail at
the town's nearest mailbox, first of its town errands (owner: "for full
bags, can you mail them the item instead? make sure they actually check
their mail"; `buddies_town.cpp`, the mail errand). Choice rewards by the bot
module's own rule, written out there (its function is private).
Requirements are not checked. A buddy's own reward is never passed on.

**A buddy offline catches up at its login** (built 2026-10-22, waiting
for a compile; `buddies_xp.cpp`, the catch-up). At a buddy's login (a
buddy account's character named in the roster), every quest its owner has
finished and it hasn't is marked finished: progress only, no reward (no
items, money, experience or blessing), because a buddy made today logs in
lacking every quest its owner ever did, and paying them all would flood it
with mail and gold and level it past its owner. The owner's quests are
read from the owner itself when online (the database only has them as of
its last save), else from the database. Any quest in the buddy's log is
dropped. A quest the buddy has and the owner doesn't stays. The login
line in the server log says how many were marked and dropped; quests the
server no longer knows are logged as an error and passed over. Before
2026-10-22 a buddy offline at the turn-in missed the quest for good.

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
- **No quests, ever; the owner's progress, exactly** (owner, 2026-10-22:
  "it should give the reward to each buddy in your clan unconditionally",
  then: "buddies should never have quests. They should have perfectly
  synced quest progress with the player."). A buddy's set of finished
  quests is always its owner's:
  - at the owner's turn-in, every buddy in the world is rewarded the
    quest directly, never taking it into its log (the server's reward
    step works without the quest in the log: it only clears a log slot
    if there is one, `Player::RewardQuest`), so a full log can't stop it
    and no buddy ever shows a quest;
  - at each buddy's login (set aside and back, or simply logged out), any
    quest its owner has finished and it hasn't is marked finished, as
    progress only (answered 2026-10-22: a buddy only briefly away is
    treated the same, "I don't see this being a common situation"), so one
    offline at the turn-in catches up; a quest it has that the
    owner doesn't (from before this rule) stays, as it can't be taken
    back cleanly;
  - quests a buddy somehow holds in its log (the bot module's own quest
    taking, if any) are dropped at login.
  (Superseded the same day: rewards caught up at login were to come as at a turn-in (items, money, a
  giver's blessing; experience is the buddy module's own matter, 617a6's
  levelling with the owner). Progress only, as above.)
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
