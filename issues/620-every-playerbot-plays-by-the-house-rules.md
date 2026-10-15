# 620 - Every Playerbot Plays by the House Rules

## Status
- Created: 2026-10-14
- Phase: 6 (Companions — bot behaviors)
- Related: 617 (buddy bots), 617b (Sargobras), 617c2 (proximity party),
  617a5 (buddies hidden and locked), 617t (stand-ins), 151 (bot population
  governor), 155 (basic profile), 718 (death knights and the Acherus
  Sargobras), 176a (test scenes)
- Sub-issues: 620a–620h
- Priority: Medium (needed before any player brings alt bots to basic, and
  before basic's random bots are ever switched back on)
- First profile: basic

## Origin

The owner, 2026-10-14:

> hi can we add issue files for making the playerbots interact with
> Sargobras and buddy-bots correctly? And all the other features we've
> added.

Asked which playerbots: **alt-character bots** (a player's own other
characters, logged in as bots with the bot module's add command) **and
random bots** (the bot module's wandering population, switched off on basic
today by `config/patches/C023-basic-no-random-bots.sh`). Not other players'
buddies.

Asked what such a bot does when it meets a buddy-only feature: **it uses it
like a player.** An alt bot or a random bot can be owed buddies, can ask
Sargobras for them, can found a clan, can train at a Visiting Mentor; each
feature then lists its own exceptions.

## Current Behavior

Every custom feature on basic was designed for two kinds of character:
human players, and the buddies that serve them (plus stand-ins, 617t). The
buddy module (`modules/mod-buddies/`) sorts every character that logs in by
its **account**, in this order:

1. on the stand-in account → a stand-in (no owner, no placement);
2. on a companion account (one hidden account per owner, 617a2) → a buddy;
3. anything else → an **owner**.

An alt bot and a random bot both land in case 3. So, untested and
unplanned, an alt bot that logs in is queued as an owner: it would be owed
a buddy at level 1 and at each tenth level, would get a companion account,
would have the wandering Sargobras summoned behind it from level 10, and
its buddies would try to form a proximity party with it while it is
already in its master's group. None of this has been tried; basic has
had no bots but buddies since 2026-09-24.

On the Lua side, `sargobras.lua` registers its login, level-up, map-change
and logout handlers for every player with no test at all. Only one Lua
script (`world-boss-respawn.lua`) asks whether a player is a bot.

The bot module itself knows nothing of basic's rules. Its own shortcuts
(automatic gear, automatic spell and talent learning for random bots, the
"maintenance" command) hand out what basic deliberately withholds: gear off
the level-60 ladder, dual specs, glyphs, flying mounts, Northrend spells.
It also cannot read our custom NPCs: a trainer list opened from a dialogue
line (the Visiting Mentor, `patches/B029-gossip-option-trainer-list.sh`)
and anything scripted through Lua gossip (Sargobras, the soul trade, the
glyph traders, the eccentric jewelcrafter) are invisible to it.

## Intended Behavior

An alt bot or a random bot on basic lives the same game a human player
does, by the same rules, through the same doors:

- It is recognised as what it is, everywhere, by one shared test (620a).
- It is owed buddies, and its buddies serve it, without tangling the
  human's party (620b).
- It talks to Sargobras on its own and chooses (620c).
- It and buddies meet each other in the world correctly: invites, trades,
  loot, parties, help in a fight (620d).
- It learns from the trainers basic actually has (620e).
- The bot module's shortcuts never give it what basic withholds from
  players (620f).
- It takes part in the world features we added (620g).
- One test scene walks a bot through all of the above and says what worked
  and what did not (620h).

## Sub-issues

| ID | Name | Dependencies | Description |
|---|---|---|---|
| 620a | one-test-for-who-is-who | None | One shared answer to "human, alt bot, random bot, buddy or stand-in?", in C++ and Lua |
| 620b | bots-own-buddies-too | 620a | Alt bots and random bots are owed buddies; roster, companion account, clan, party |
| 620c | bots-ask-sargobras | 620a, 620b | A bot walks to Sargobras, chooses a buddy and names its clan by itself |
| 620d | bots-and-buddies-meet | 620a | Invites, trades, loot rolls, shared fights and parties between bots and buddies |
| 620e | bots-learn-from-our-trainers | 620a | Visiting Mentors, the profession mentor, the eccentric jewelcrafter, class books |
| 620f | bot-shortcuts-obey-basic | 620a | Automatic gear, learning and talents held to basic's rules |
| 620g | bots-in-the-world-features | 620a, 620f | World bosses, battleground rewards, sockets, Outland, the auction house |
| 620h | bot-rules-test-scene | 620b–620g | A scene that walks an alt bot and random bots through every feature |

Rationale: the features touched live in different places (the buddy
module, the Lua scripts, the bot module's own strategies, its config) and
each can be built and tried alone. 620a comes first because every other
piece asks the same question it answers.

Execution order:

```
620a (foundation)
 ├── 620b ── 620c
 ├── 620d
 ├── 620e
 └── 620f ── 620g
              └── 620h (capstone, after all of the above)
```

## Suggested Implementation Steps

1. Build 620a, then the sub-issues in the order above.
2. In each, write the bot case into the feature's own issue file as well
   (its Current Behavior), so a reader of that feature learns how bots
   meet it.
3. Finish with 620h's scene run, and a section in `docs/profiles/basic.md`
   saying what bots do on basic.

## Open Questions

- **Are random bots coming back to basic?** `docs/profiles/basic.md` says
  the only bots are each player's buddies. If random bots return, how many,
  and does the population governor (151) count their buddies too? 500
  random bots each owed up to seven buddies is 4,000 bots.
- **Death knights.** Basic says no playerbot plays a death knight. Does
  that stay, or should a bot be able to make the soul trade with the
  Acherus Sargobras (718) too?
- **Other profiles.** Buddies exist on basic and cc-test only. Do vanilla,
  beta and release need any of this, or is it basic's alone?
