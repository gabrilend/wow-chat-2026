# Conversation Summary: agent-a15df132023df51af

Generated on: 2026-09-27 12:51:01
Models: claude-opus-5-5

--------------------------------------------------------------------------------

### User Request 1

Your directive: You are the fork building the 2026-09-27 decisions now written
in issues 617c2 ("Decisions, 2026-09-27 (Ritz): the group bonus, login grouping,
far parties") and 617e1 ("Decisions, 2026-09-27 (Ritz): grind, food, walking").
Read both sections first. Files you own:
modules/mod-buddies/src/buddies_party.cpp, buddies_roam_strategy.cpp, a new
buddies_xp.cpp, buddies_loader.cpp, a new playerbots B-patch under patches/
(follow the upstream-patch-system skill at
/home/ritz/programming/ai-stuff/skills/ and the existing B-patches' pattern, and
add it to basic's list in patches/patches.sh; run scripts/test-source-patches
/mnt/mtwo/games/azeroth-core/wow-chat-2026 basic and scripts/test-patched-syntax
/mnt/mtwo/games/azeroth-core/wow-chat-2026 basic — note: the first argument is
the project dir, the profile second), a new config C-patch for basic (pattern:
config/patches/C029) plus its expectation in scripts/test-profile-config-gates
(run it). Another fork is editing buddies_town.cpp/.h, buddies_create.cpp and
adding bed/fishing/mount files at the same time — don't touch those.

Build:
1. Group bonus from humans only (OnPlayerRewardKillRewarder, float& rate): scale
   by xp_in_group_rate(humans in range) / xp_in_group_rate(all in range) where
   "humans" = members not on a companion account (BuddyIsCompanionAccount), "in
   range" as KillRewarder counts it (alive, at group reward distance of the
   victim, or the killer); explain the reading in comments; only for
   non-battleground, non-raid-map kills (where the stock rate applies) — check
   KillRewarder to get this exactly right.
2. Playerbots login grouping switch: a B-patch adding
   AiPlayerbot.InviteAltsOnLogin (default 1 = stock) read into
   sPlayerbotAIConfig and checked before the login GroupInviteOperation in
   PlayerbotMgr::OnBotLogin (and wherever else the master-login invite happens
   — check; also the "leave group without master" check tied to
   KeepAltsInGroup may be moot then, say so); a C-patch setting it to 0 on
   basic. Keep C029 (KeepAltsInGroup=1) unless it becomes pointless — decide
   and explain.
3. Far parties: merge when a member of one is within 70 yd of a member of the
   other (fits in five); a far-party member farther than 74 yd from every other
   member leaves (then may join another far party within 70).
4. Grind off for buddies (-grind in the pass, both in the open and towns); -food
   (playerbots' food strategy: cheat eating) for buddies; the module's meal no
   longer falls back to playerbots' cheat action: with nothing to eat, log once
   per buddy and skip the meal (no sitting pretend) — update comments/issue
   accordingly.
5. Walking where they can't ride, roaming outside instances: if the buddy can
   mount here (outdoors, has a mount spell usable at its level, playerbots'
   mount strategy may mount it — check how playerbots decides; keep its
   "mount" strategy for that), fine; if it can't, the roam walking uses walk
   mode (not run). In instances (dungeon/raid/battleground maps) leave movement
   stock.
Compile-check every module file with
/tmp/claude-1000/-mnt-mtwo-games-azeroth-core-wow-chat-2026/f654b718-5d4e-4cda-a776-07b578174b84/scratchpad/syntax-buddies2.sh.
Update issues 617c2 and 617e1 Current Behavior in place; claim script-written
files with claim-own-change. Absolute paths, never cd, don't commit, don't build
the server. Report: files, test outputs (source patches, patched syntax, config
gates, compile), decisions made, open questions.

--------------------------------------------------------------------------------

### Assistant Response 1

> Now registering it in basic's list with a witness:

> All source patches apply and round-trip, B037 included. Now the config patch
> that turns the switch off on basic:

> Now the expectation line, added with the editor this time:

> Config test: 24/24, no missing keys. Now the module; reading the party file:

> Rewriting the far-party rules to your distances: join or merge within 70
> yards, leave past 74 from every other member.

> Party rules done. Now the group-bonus hook. Checking the exact hook name and
> what the reward object exposes:

> Now the roaming file. First, how playerbots decides when to mount, which
> determines the walking rule:

> Both exist. Making the roaming-file changes: no grind or food, no cheat
> fallback, walking unless mounted, running from the moment a fight starts.

> No errors. Confirming the checker really compiled the three files I touched,
> by planting a mistake in a scratch copy of the new file:

> The checker catches the planted mistake, and my three files compile clean. The
> other agent added its beds line to the loader alongside mine, and both are
> present. Now the patched-syntax test:

> Rewriting both issues' Current Behavior:

> While the patched-syntax test runs, recording the files I changed through
> scripts:

> Passed. Checking that it covered the playerbots files B037 touches:

I built all of it. Every module file compiles, but nothing has been built into
the server or run in game.

**1. Group bonus from human players only.**
- A new file, `buddies_xp.cpp`, uses the server's kill-reward hook to scale each
  member's share by the bonus for the humans near the kill divided by the bonus
  for everyone near it.
- "Near" is counted exactly the way the server counts it: alive, and either the
  killer or within the group reward distance of the victim.
- Battlegrounds and raid dungeons stay stock, since the server gives no bonus
  there to begin with.
- The file is registered in `buddies_loader.cpp`. The other fork's
  `AddSC_buddies_beds` line is in the same file, and both are present.

**2. No playerbots group invite at login.**
- The new patch `patches/B037-playerbots-invite-alts-on-login.sh` adds a
  setting, `AiPlayerbot.InviteAltsOnLogin` (default 1, which is stock
  behaviour). It sits in the playerbots config header, code and config template.
- When the setting is 0, the login invite in `PlayerbotMgr::OnBotLogin` is
  skipped for a player's own bot; random bots are never affected. That is the
  only place playerbots sends this invite.
- B037 is added to basic's patch list in `patches.sh`, with a check that says
  whether it is applied.
- `config/patches/C030-basic-buddies-no-login-invite.sh` sets it to 0 on basic.
  If the installed config predates B037 and lacks the key, it appends it.
- I kept C029 (`KeepAltsInGroup = 1`). Without it, playerbots still makes a bot
  leave, at login, any group its player isn't in. So C029 lets far parties
  survive a relog instead of being disbanded and rebuilt. It isn't strictly
  required, just less churn.

**3. Far parties** (`buddies_party.cpp`):
- An ungrouped far buddy joins a far party that has room if one of its members
  is within 70 yards; otherwise it pairs up with another loose far buddy within
  70.
- A far-party buddy leaves its party when it is within 74 yards of the owner, or
  more than 74 yards from every other member of the party.
- Two far parties merge when a member of one is within 70 yards of a member of
  the other and together they fit in five.
- Your later addition, leaving "when it could join the player's party": a buddy
  within 60 yards is also within 74, so it already leaves its far party in step
  1 and joins the owner's party in step 2 of the same pass, if there's room. I
  stated this in the code comments and in 617c2.

**4. Grind and food** (`buddies_roam_strategy.cpp`):
- The pass now turns off `grind` and `food` for buddies, both in the open and in
  towns.
- The meal no longer falls back to the food cheat. With nothing to eat there is
  no meal, logged once per buddy, and no pretend sitting.
- The now-unused rest timer and cheat-aura constant are removed.

**5. Walking where they can't ride:**
- A roaming buddy walks unless it is mounted. Playerbots' own mount behaviour
  mounts it outdoors when it has a mount and the level.
- A new enter-combat hook sets a walking buddy back to running as soon as a
  fight starts.
- The old pass line that forced running every 3 seconds is gone.
- Instances are untouched, since roaming doesn't run there.

**Test results:**
- `test-source-patches <project> basic`: every patch applies, including B037,
  and the tree round-trips byte-identical. 0 problems.
- `test-patched-syntax <project> basic`: 0 files failed, including
  `PlayerbotMgr.cpp` and `PlayerbotAIConfig.cpp` (no errors).
- `test-profile-config-gates`: 24 of 24 pass, with 0 edited keys missing from
  the stock configs.
- Module compile check: no errors in any module file. A planted mistake in a
  scratch copy of `buddies_xp.cpp` was caught.

**Other updates:**
- The Current Behavior sections of issues 617c2 and 617e1 are rewritten in
  place. 617c2's decisions section also records your "or when it could join the
  player's party" addition. Both pass `validate-issues`.
- I recorded the script-written files with `claim-own-change` (whole files):
  `patches.sh`, B037, C030, `buddies_party.cpp`, `buddies_roam_strategy.cpp`,
  617c2 and 617e1.
- Nothing is committed.

**Open questions:**
- A buddy that can mount but hasn't been mounted yet (playerbots decides that on
  its own schedule) walks until it is. Is that acceptable, or should the roam
  action mount it itself?
- Since grind is off, neutral or passive monsters are never fought unless
  they're attacked first. Leave that to 617e5?
- With no food, buddies regenerate only by sitting through the normal
  out-of-combat regeneration. That is acceptable until the starting kit exists.

--------------------------------------------------------------------------------

