# 617a5 - Buddies Hidden and Locked

## Status
- Created: 2026-09-26
- Phase: 6
- Parent: 617a
- Blocked by: 617a1
- Priority: Medium

## Current Behavior

Nothing built. Read 2026-09-26 in the server source:

- **/who** is built from every player in the world
  (`WhoListCacheMgr::Update`); the only filter is by security level
  (moderators and above hidden from players).
- **Friends**: adding a friend is refused only when the target is on a
  staff account (`Socialhandler.cpp`, the add-friend handler).
- Neither has a script hook. Giving companion accounts a staff security
  level would hide buddies from both with no code, but staff characters
  can carry game-master states (invisibility, no aggro), which a bot must
  never have; so this route is not taken.
- **Bot chat commands**: the bot module answers commands whispered or said
  in party by its master.
- **Renaming** happens only through a game master or a rename flag at
  login; nobody logs into a buddy by hand.

## Intended Behavior

From 617a's decisions of 2026-09-25:
- buddies never appear in /who;
- no one can add a buddy as a friend;
- a buddy ignores the bot module's chat commands (the language-model layer
  reaches the same actions later as tool calls, 917 / 617m);
- no renaming (a rename flag on a buddy is cleared);
- no faction or race change (basic offers none).

## Suggested Implementation Steps

1. A source patch (B-patch) giving /who and the add-friend handler a check
   "is this a buddy" (a lookup the module keeps: the set of buddy guids
   from `buddy_roster`), bracketed for a clean revert.
2. A bot-module patch that drops chat commands to a buddy before parsing.
3. Tests: `scripts/test-source-patches` and `scripts/test-patched-syntax`;
   in game, /who and add-friend against a buddy.

## Related Issues

- **617a** parent; blocked by **617a1** (the buddy list lives there)
