# 617a5 - Buddies Hidden and Locked

## Status
- State: completed 2026-10-23: built; its in-game check taken as done (the owner, 2026-10-23: "let's mark all the issues that are just waiting on a visual check as complete")
- Created: 2026-09-26
- Phase: 6
- Parent: 617a
- Blocked by: 617a1
- Priority: Medium

## Current Behavior

**Built 2026-10-02. The patches apply and revert cleanly and are
syntax-checked. Not yet compiled or tried in game.**

- **One list, "companion accounts"** (source patch B044): a new header in
  the server's cache folder (`CompanionAccounts.h`), with the list itself
  appended to the who cache's file behind a reader-writer lock. The list is
  keyed by account, not by character: every buddy of an owner lives on that
  owner's one companion account, so a buddy made later is covered without
  any further step.
- **/who** (B044): the who cache skips a character whose account is on the
  list.
- **Add friend** (B044): a character on a listed account gets the reply
  "player not found", the same as a name that doesn't exist.
- **Chat commands** (B045, bot module): both of the bot module's
  chat-command entry points return at once for a bot on a listed account.
  Every chat path (whisper, party, guild, channel) ends in one of them.
  Chat itself still arrives.
- **Filling the list** (`patches/B036-mod-buddies/mod-buddies/src/buddies_hidden.cpp`): at
  startup, every companion account in buddy_clan; an owner whose id was
  never recorded is looked up by the account's deterministic name. Also at
  a buddy's creation, and at a buddy's login, which covers accounts made
  after startup. It must be registered after the roster check, because it
  reads whether buddies are on.
- **Rename, faction and race flags:** a rename flag stops a character from
  loading at all ("tried to login while forced to rename", read in the
  character loader), so clearing it at login would be too late. The flags
  are cleared in the characters table at startup and once a minute, and
  from memory at every save of an online buddy (the save hook runs just
  before the character row is written). The faction and race change flags
  are cleared with it, because basic offers neither.
- **The whispered answer** (`patches/B036-mod-buddies/mod-buddies/src/buddies_whisper.cpp`,
  built 2026-10-02, syntax-checked with B044's header supplied, not yet
  compiled): the private-chat hook, called inside every whisper a player
  sends (`Player::Whisper`, which the typed-whisper handler ends in), sees
  a whisper whose receiver is on the companion list and queues an answer
  behind a lock; the world's update hook sends it 1.5 s later on the
  world's thread. The answer is the placeholder line, in a whisper packet
  built by hand with Orcish (to an Alliance whisperer) or Common (to a
  Horde one), because `Player::Whisper` forces every whisper to the
  universal language. No answer to a bot (no bot-to-bot loops), none to a
  neutral side, at most one per whisperer per 10 s (a flood gets one
  reply), and none if either logged out during the pause. Nothing is
  logged per whisper. The server never scrambles chat itself (no
  language-word code in it; /say travels as plain text plus a language
  number), so the scrambling is the client's: confirmed for /say, to be
  seen in game for a whisper.
- **No achievements** (`buddies_hidden.cpp`, built 2026-10-02,
  syntax-checked with B044's header supplied, not yet compiled): the
  player hook that runs before any achievement criterion moves refuses it
  for a character on the companion list, so a buddy counts nothing, saves
  nothing and completes nothing; the hook before an achievement completes
  refuses it too, for awards that skip the criteria (a game master's grant,
  a script's direct award). No "realm first" or guild line ever names a
  buddy. Both hooks are stock (`AchievementMgr.cpp` calls them), so no
  source patch was needed.

Untested until the owner compiles: in game, /who and add-friend against a
buddy, a whisper "follow" to a buddy (ignored, and answered in scrambled
Orcish or Common), and `.character rename` on a buddy (cleared within a
minute, and the buddy still logs in).

Read 2026-09-26 in the server source, before building:

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
- **A whisper gets an answer nobody can read** (Ritz, 2026-10-02: "they
  should respond in a language that you don't know. Like... Orcish if
  you're alliance or something. It should just say something like 'I'm
  sorry, I am a large language model and I have no idea what you're
  saying'. This is placeholder behavior for when we build proper LLM
  systems."): a buddy whispered by anyone whispers back that line, sent in
  a language the whisperer doesn't know (Orcish to the Alliance, Common to
  the Horde), so the client shows it scrambled. Placeholder until the
  language-model chat layer (916/917) answers properly.
- **No achievements** (Ritz, 2026-10-02: "Can we disable achievements for
  buddybots?"): a buddy never progresses or completes an achievement, so
  none is ever announced in its name.

## Suggested Implementation Steps

1. A source patch (B-patch) giving /who and the add-friend handler a check
   "is this a buddy" (a lookup the module keeps: the set of companion
   account ids from `buddy_clan`, which covers every buddy of every owner),
   bracketed for a clean revert.
2. A bot-module patch that drops chat commands to a buddy before parsing.
3. Tests: `scripts/test-source-patches` and `scripts/test-patched-syntax`;
   in game, /who and add-friend against a buddy.

## Related Issues

- **617a** parent; blocked by **617a1** (the buddy list lives there)

## Open Questions

- (2026-10-02) **Does the client scramble a whisper?** It scrambles /say
  in a language its character doesn't know; whether it does the same for a
  whisper only the game can show. If the line arrives readable, the server
  would have to scramble it itself (from the client's own word lists in
  `LanguageWords.dbc`, which the server doesn't load today).
- (Answered 2026-10-02) **Game masters** may know every language and so
  read the line plainly: "yeah that's fine." (Ritz)
