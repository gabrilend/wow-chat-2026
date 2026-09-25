# 155b - Basic Profile Config Gates

## Status
- Created: 2026-09-23
- Phase: 1
- Parent: 155
- Blocked by: 155a
- Priority: High

## Current Behavior

**Built and tested offline 2026-09-23.** Each file in `config/patches/`
edits values in the generated `.conf` files and carries a gate naming the
profiles it runs for. Basic's gates are set as in the table below; new
patches C006d (level cap 60), C023 (no random bots, see below) and C024 (death knights: an account needs a level-55
character; no death-knight bots — the interim rule, taken from the owner's
answer in 718) exist.

`scripts/test-profile-config-gates` runs every config patch gated to a
profile against scratch copies of the stock config files, reads each
promised value back, and also checks that every key any patch edits
exists in the stock configs. For basic it reports 20 of 20 values correct
and no missing keys. Run it after touching any C-patch.

That last check found three patches that had never done anything, on any
profile, because they edited keys the configs do not have. All three are
fixed:

| Patch | Wrote | Real key | Effect of the bug |
|---|---|---|---|
| C003 run speed 80% (all) | `Rate.Run.Speed` | `Rate.MoveSpeed.Player` (source-beta); `Rate.MoveSpeed` (alpha) | nobody has ever run at 80%; **every profile gets slower on its next install** |
| C009 instant flights (beta) | `Instant.Taxi` | `InstantFlightPaths` | beta's flights were never instant |
| C014 / C023 gear persistence | `EquipmentPersistence` | `EquipAndSpecPersistence` | harmless: the module default was already 1 |

C003 and C009 now stop with an error if their key is missing, instead of
editing nothing.

**Random bots off (built 2026-09-24, config-gate test passes).** Ritz,
2026-09-24: "this is what we want" (the world populated only by players and
their buddies), and "switched off." C023 is now
`config/patches/C023-basic-no-random-bots.sh` (renamed from
`C023-basic-playerbot-progression.sh`): `AiPlayerbot.RandomBotAutologin = 0`
(random bots never log in, which holds even if the hand-run bot-governor
script later raises the counts), `MinRandomBots = 0`, `MaxRandomBots = 0`.
C020 (population band) and C018 (account count) are gated to `vanilla`
only again. Buddies (617) are not random bots: they are ordinary bot
characters on an account linked to their player, so this switch does not
touch them. Until 617 is built, the basic world has no bots at all.
`scripts/test-profile-config-gates` reads the three values back (18 of 18
expectations pass).

## Intended Behavior

Every config patch is decided for basic, one row at a time:

| Patch | Currently gated to | Basic | Change needed |
|---|---|---|---|
| C001 database connections | all | yes | add `basic` arm (155a) |
| C002 directory paths | all | yes | add `basic` → `source-beta` arm (155a) |
| C003 run speed 80% | all | **yes** (user decision) | key fixed (see Current Behavior) |
| C004 fall damage 10× | beta release vanilla | **yes** (user decision) | add `basic` |
| C005 experience rate 2× | beta release | **no** — vanilla runs at 1× and basic is the unconstrained baseline | none |
| C006a/b/c max level 80/20/40 | alpha / beta release / vanilla | **no** | new **C006d max level 60**, gated `basic` |
| C007a/b/c start level 40/1/20 | alpha / beta release / vanilla | **C007b (level 1)** | add `basic` to C007b's gate |
| C008 GM login state | all | yes | check its `case` has a `basic` arm (vanilla gets admin; basic matches vanilla) |
| C009 instant taxi | beta | no — flight paths are removed on basic anyway (155c) | none |
| C010 network ports | all | yes | add `basic` to the shared-ports arm (155a) |
| C011 realmlist setup | all | yes | none |
| C012 bot level 1..20 | beta release | no | — |
| C014 vanilla bot progression 20→40, Eastern Kingdoms | vanilla | **no** | **C023 basic no random bots** (2026-09-24; it first held a 1→60 bot band): random bots never log in, population 0 |
| C015 disable death knights | vanilla | **no** | basic allows stock death knights with two restrictions: new **C024** |
| C016 backfill missing keys | release beta vanilla | yes | add `basic` |
| C017 level-correlated caps | release beta vanilla | yes — it reads the cap C006d wrote, so it follows to 60 automatically | add `basic` |
| C018 bot account count 110 | vanilla | **no** (2026-09-24: no random bots) | removed `basic` |
| C019 realm id | all | yes | realm 5 (155a) |
| C020 bot population 128–256 | vanilla | **no** (2026-09-24: no random bots) | removed `basic` |
| C021 SOAP console | all | yes | none |
| C022 custom starting spells (reads the pretrain table) | vanilla | **no** — pretrained abilities are a head-start | none |

The interim death-knight rule is "allow, with restrictions" (the owner's
answer, recorded in 718). Stock knobs cover it without new code (C024):

- `CharacterCreating.MinLevelForHeroicCharacter = 55` in `worldserver.conf`
  (already the upstream default: an account needs a level-55 character on
  the realm before it may create a death knight);
- `AiPlayerbot.DisableDeathKnightLogin = 1` in `playerbots.conf` (no
  death-knight bots log in).

The config patches are named for what they set, not for the profile they
serve. C014, C015, C018, C020 and C022 carry `vanilla` in their names, and
the three that basic now shares (C015 conditionally, C018, C020) keep their
filenames: the function name is derived from the filename, so renaming is a
separate sweep, best folded into 152's.

## Suggested Implementation Steps

1. Write `config/patches/C006d-max-level-60.sh` by the shape of C006c.
2. Write `config/patches/C023-basic-no-random-bots.sh`:
   `RandomBotAutologin = 0`, `MinRandomBots = 0`, `MaxRandomBots = 0`
   (anchored keys, as in C020).
3. Extend the gates listed in the table.
4. Apply the death-knight row once the interim rule is answered.
5. After the user's install run, read each value back from
   `installed-files-basic/etc/worldserver.conf` and
   `installed-files-basic/etc/modules/playerbots.conf` and compare with this
   table. That comparison is the test: a gate that did not match yields a
   running server with upstream values.
6. Record the change in `docs/balance-updates.md`.

## Related Issues

- **155** parent; **155a** blocks this
- **148** / **148a** — origin of C014, C015, C018, C020, C022
- **152** — the rename sweep that should also rename the `vanilla`-named
  patches basic now shares

## Open Questions

- (Answered 2026-09-24) "no random bots in basic. Just playerbot buddies."
  Whether the module starts cleanly with a population of 0 is checked when
  the switch is built (a startup-log check in the install test).
- (Answered 2026-09-24) The auction house and battlegrounds are covered by
  buddies instead: buddies list at auction houses in towns that have one
  (617h) and follow their owner into battleground queues (617i).
- (Answered 2026-09-24) Random bots are switched off on basic; only buddies.
- (Answered 2026-09-23) Experience rate stays 1×.
