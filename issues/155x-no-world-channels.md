# 155x - No World Channels

## Status
- Created: 2026-09-27
- Phase: 1
- Parent: 155
- Blocked by: None
- Priority: Medium

## Origin

The owner, 2026-09-27, relayed by the session's coordinator (the owner's
own words as passed on): the General, Trade and LocalDefense channels are
closed on basic "to keep news from spreading". WorldDefense carries the
same kind of news (attacks announced across the world), so it is closed
too; that part is a reading, stated here to be confirmed.

## Current Behavior

**Built 2026-09-27; compile-checked, not yet run** (needs the owner's build
and install).

- **The refusal** (source patch `patches/B038-refused-channels.sh`, in
  `Channel::JoinChannel`): a join of a built-in channel whose number is in
  the worldserver setting `Basic.RefusedChannels` returns at once, silently
  (no error line, the channel simply isn't there). Every join ends in that
  one function: a player's client asking at login, the server moving a
  player between zone channels on a zone change
  (`Player::UpdateLocalChannels`), and the bot module joining its bots
  (`PlayerbotHolder`, `PlayerbotMgr.cpp`); no script hook sees all three,
  which is why this is a patch and not a rule in `basic_rules.cpp`. The
  list is read once, at the first join after start.
- **The list** (config patch `config/patches/C031-basic-refused-channels.sh`,
  basic only): `Basic.RefusedChannels = "1 2 22 23 25 26"`, the client's
  channel numbers in ChatChannels.dbc: 1 General, 2 Trade, 22 LocalDefense,
  23 WorldDefense, 25 GuildRecruitment, 26 LookingForGroup. Other profiles have no setting, so nothing is refused
  there. Checked by `scripts/test-profile-config-gates`.
- **The startup report** (`src/cpp-basic/basic_rules.cpp`): the server log
  names the refused channels at start, or says the setting is missing.
- **Unaffected**: players' own channels (`/join anything`), guild and
  party chat, whispers.

## Intended Behavior

Nobody on basic is ever in General, Trade, LocalDefense, WorldDefense,
GuildRecruitment or LookingForGroup: players, bots, anyone. No message about it. Custom channels work as stock.

## Suggested Implementation Steps

1. (Done) B038 at the top of `Channel::JoinChannel`, reading the list.
2. (Done) C031 sets the list on basic; its expectation in
   `test-profile-config-gates`.
3. (Done) The startup report in `basic_rules.cpp`.
4. In game: log in in Elwynn Forest (no General, LocalDefense, WorldDefense
   in the chat channel list), walk into Westfall (still none), go to
   Stormwind (no Trade); `/join test` still works.

## Related Issues

- **155** parent

## Open Questions

- **WorldDefense**: closed with the others ("it carries the same kind of
  news"). Right?
- (Answered 2026-09-27) "Should Looking For Group and Guild Recruitment
  close too? — yes": closed (25, 26).
