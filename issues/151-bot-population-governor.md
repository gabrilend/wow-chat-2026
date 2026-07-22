# 151 - Bot Population Governor (host-load-driven bot count)

**Phase:** 1 (Infrastructure - server operation scripts)
**Effect:** The random-bot fleet grows to fill quiet hardware and sheds itself
when the machine runs hot, so the population ceiling can be raised well above
the fixed install-time band without risking the host.
**Status:** In progress (built and bench-verified; the SRP6 math reproduces
the verifiers of server-created accounts exactly, all selection queries run
against the live schema, setup has minted the governor account, and the
preflight passes except the one check that needs a running worldserver —
restart it once, then `./scripts/bot-governor check` should go fully green
before the first governed `run`)

---

## Current Behavior

The vanilla profile holds 128-256 ambient random bots via the install-time
config patch `config/patches/C020-vanilla-playerbot-population.sh`. That band
is static: chosen once at install, blind to how the machine is actually doing.

Inside the module, population control is one-directional. The random-bot
manager's update loop picks a target count inside the configured band and
**only ever logs bots in** when below it — there is no code path that logs
excess bots out when the target drops. A bot leaves the world only when its
personal in-world timer expires, and that timer is rolled between **2 hours
and 14 days** at login. Lowering the band therefore shrinks the fleet at a
glacial drain rate, never quickly.

There is also no channel for an outside script to speak to the running world
server: the SOAP endpoint (`SOAP.Enabled`) and the remote-access telnet
console (`Ra.Enable`) both ship disabled, no config patch enables them, no
script sends commands, and no administrator game account exists for such a
channel to authenticate against.

Net result: if the server begins starving the machine (compiles, other
services, or simply too ambitious a bot ceiling), nothing reduces the load
short of editing the config and restarting the world server — which logs out
*everyone*, including real players.

## Intended Behavior

A governor daemon (`scripts/bot-governor`) runs alongside the world server
and closes the loop between host hardware pressure and bot population:

- **Watch.** Each cycle it samples whole-machine meters — CPU busy percent,
  memory in use, and/or normalized load average (a checkbox set selects which
  meters count).
- **Shed when hot.** When any selected meter reaches the *hot* threshold
  (default 50%), it reduces the fleet. The escalation listens to results:
  the shed amount doubles (capped) only when demand *rose* since the
  previous shed; when demand held or fell, the same amount goes again —
  never fewer within a hot episode. And when several consecutive sheds fail
  to reduce demand at all, the governor concludes the load is not
  bot-shaped (a compile, another service) and stops shedding until the
  episode ends. A jitter deadband keeps one-point meter wiggles from
  counting as movement.
- **Regrow when cool.** After a sustained streak of every meter sitting below
  the *cool* threshold (default 35%), it raises the fleet target step by
  step, up to a ceiling higher than the old static band — this is how the bot
  population actually *increases* over the C020 baseline: quietly, whenever
  the hardware has room.
- Both thresholds, the poll cadence, the floor/ceiling, and the step sizes
  are user-adjustable in a dedicated config file.

**How it actuates** (two levers, used together, because the module cannot
shed on its own):

1. **Pin the band.** Rewrite `MinRandomBots` and `MaxRandomBots` in the
   installed `playerbots.conf` to a single pinned value (min = max = target)
   and send `playerbots rndbot reload` through the SOAP loopback endpoint.
   Pinning min to max matters: the module caches its chosen target for 30
   minutes to 2 hours, but re-rolls immediately when the cached value falls
   outside the configured band — and with a one-value band, the re-roll is
   deterministic. This stops the module from replacing anything we remove.
2. **Kick the excess.** Log out chosen bots *now* with the core `.kick`
   command over the same SOAP channel (kick is console-capable). The pinned
   band prevents re-login. Which bots get kicked is the radio-button choice
   below.

**Logout method — radio enum** (`GOVERNOR_LOGOUT_METHOD`, exactly one):

- `idle-first` — kick the bots that look idle from outside the process:
  ungrouped, on continent maps, in zones no real player occupies. (The
  module's true idle flag — travel state — is not visible externally, so
  this is the honest database approximation.)
- `random` — kick uniformly at random.
- `newest-first` — kick the most recently logged-in bots first; the
  least-settled bots go before long-lived world fixtures.
- `drain` — never kick; only squeeze the band and let bots age out on their
  own in-world timers. Gentle, but hours-to-days slow — the honest name for
  what the module does natively.

**Method options — checkbox set** (`GOVERNOR_LOGOUT_OPTIONS`, any number):

- `spare-grouped` — never kick a bot grouped with a real player.
- `spare-dungeoneers` — never kick a bot inside an instance.
- `spare-nearby` — never kick a bot sharing a zone with a real player.
- `persist-shrunken-band` — on governor shutdown, leave the last pinned band
  in the conf instead of restoring the configured floor/ceiling band.
- `announce` — broadcast a server announcement when shedding or growing.

The spare-* options modify the three kick methods and are rejected with an
error when combined with `drain` (which never targets individuals) — strict
validation over silent inapplicability.

**The day/night tide** (off by default): when enabled and *zero* real
players are online, the population stops answering the load meters and
instead follows a slow wave — sinking toward the floor for "night", rising
toward the ceiling for "peak hours", one full cycle every 3-4 real hours
(a knob). Idle-looking bots drift off a few at a time on the ebb, bounded
per cycle so the tide never becomes a stampede, and the wave is anchored
to wall-clock time so governor restarts rejoin it mid-phase. While the
tide runs, the hot/cool thresholds are deliberately dormant: the empty
server belongs to the bots, and the one way to turn the performance
demands down is to log in and play — a real player online suspends the
tide and restores load-governing. The world should feel sparse at some
hours and crowded at others.

**The spirit pause**: a real player who dies, releases, and stays a ghost
for fifteen minutes or longer (a knob) pauses the *entire* governor — no
shedding, no growing, no tide — until they return to their body or log
off. Spirits have seniority. This doubles as an in-game hold switch:
detection is by corpse age (a resurrectable player corpse older than the
threshold whose owner is still online), so the pause is something a player
*does* in the world, not a config file they edit outside it.

**Speaking to the server** requires two one-time enablements, both automated:

- Config patch `C021` flips `SOAP.Enabled = 1` (loopback ip, port 7878) for
  all profiles at install time.
- `bot-governor setup` mints a dedicated administrator game account for the
  governor: it computes the SRP6 salt/verifier pair itself (SHA1 via
  `sha1sum`, 256-bit modular exponentiation via `bc` — no Python), upserts
  the `account` and `account_access` (gmlevel 3, all realms) rows over the
  project MySQL socket, stores the credentials via the existing `@CRED`
  mechanism in `scripts/credentials`, and flips SOAP on in the *installed*
  worldserver.conf so no reinstall is needed (one worldserver restart is —
  the SOAP listener only spawns at boot).

**Subcommands:** `run` (the loop, foreground, also `--once` for a single
decision cycle), `setup` (account + SOAP enablement), `status` (meters,
band, online bot count, channel health), `check` (preflight: dependencies,
config validation, SOAP and database round-trips).

## Suggested Implementation Steps

1. Write `config/patches/C021-soap-loopback-console.sh` in the C-patch shape
   (self-registering function + `CONFIG_PROFILES` entry, profile `all`,
   anchored seds per the C020 lesson — anchor key names with
   `[[:space:]]*=` so greedy patterns cannot bleed into longer keys).
2. Write `config/bot-governor.conf`: thresholds, meters checkbox, cadence,
   floor/ceiling, shed/grow steps, the logout-method radio block, the
   options checkbox block. Comments carry the radio `(o)`/checkbox `[x]`
   semantics and per-option explanations.
3. Write `scripts/bot-governor` in house style (hard-coded `${DIR}`,
   `--dir`/`--profile`/`--config` overrides, vimfolds, self-documenting
   help). Order of internals: config load + strict validation, credential
   load, SOAP envelope sender, SRP6 registration math, database queries
   (online bots, kick-candidate selection per method/options), the two
   levers (pin-band, kick-list), meter sampling, then the decide loop with
   escalation/cool-streak state and a restore-band exit trap.
4. Candidate selection is one SQL query built from method + options: base
   set = online characters on `rndbot`-prefixed accounts (prefix read from
   the installed playerbots.conf, not hard-coded); spare-* become WHERE
   exclusions (group membership with real players / instance maps / shared
   zones); the method becomes the ORDER BY; shed count becomes LIMIT.
5. Document the data path in `docs/bot-governor.md`, add it to the table of
   contents.
6. Verify: `check` passes end-to-end against a running server; a `--once`
   run under artificial load sheds the expected escalating counts; regrow
   raises the pinned band after the cool streak; `drain` changes conf but
   never kicks.

## Constraints Discovered (record these — they shaped the design)

- Module logout path: none. `RandomPlayerbotMgr::UpdateAIInternal` only adds
  (`AddRandomBots`) when online < target; excess survives until each bot's
  `add` event TTL (2h-14d, `MinRandomBotInWorldTime`/`MaxRandomBotInWorldTime`)
  expires. Hence the kick lever.
- `playerbots bot remove <name>` refuses random bots (master-owned only) and
  the advertised `rndbot add/remove` subcommands are not implemented; the
  core `.kick` command (console-capable, `cs_misc.cpp`) is the working
  logout instrument.
- `playerbots rndbot reload` re-initializes the module config live; band
  changes take effect on the next update tick (~20s,
  `RandomBotUpdateInterval`). Editing the conf without reload does nothing.
- The live target is cached in the `playerbots_random_bots` events table
  (`bot_count`, TTL 30min-2h) and re-rolled *only* when out of band — the
  min=max pin makes that re-roll deterministic. Writing the database row
  directly would be ignored: the module lazily loads each bot's events into
  an in-memory cache on first touch and never re-reads the table (only
  `rndbot reset` clears it), so external SQL writes are invisible to a
  running server.
- **Kicked bots rebound — unless the pin lands first.** A kicked bot keeps
  its valid `add` event (no logout hook clears it, the bot stays in the
  manager's roster), and the update loop's offline sweep re-logs any
  roster bot whose event is valid — but that sweep is gated by the login
  budget, which is zero whenever online count >= target. Pin the band down
  *before* kicking and the count never dips below target, so the rebound
  path never fires. Kick before pinning and every kick undoes itself
  within a tick. Order is the entire mechanism.
- SOAP auth is a real game account with gmlevel >= 3; accounts store SRP6
  `salt`/`verifier` binary(32) pairs (g=7, the classic WoW 256-bit modulus,
  little-endian digest interpretation), so the setup step must speak SRP6.
- Account headroom: C018 pins 110 bot accounts x 10 characters, and the
  module's own account formula supports a ceiling up to roughly 590; the
  governor validates its configured ceiling against that limit and errors
  above it, pointing at C018.
- SOAP.Enabled is read once at worldserver boot (`Main.cpp`) — enabling it
  requires one restart; everything after that is runtime.
- Ghost state is not persisted as a flag, but the `corpse` table exposes it
  faithfully: `corpse.guid` is the owning player's guid (one resurrectable
  corpse per character), `corpseType != 0` separates a waiting body from
  bones, and `time` stamps the death — corpse age *is* ghost duration.

## Relevant Files / Symbols

- `scripts/bot-governor` — the governor (new)
- `config/bot-governor.conf` — its knobs (new)
- `config/patches/C021-soap-loopback-console.sh` — SOAP enablement (new)
- `docs/bot-governor.md` — datapath documentation (new)
- `config/patches/C020-vanilla-playerbot-population.sh` — the static band
  this governs over; stays as the boot-time baseline
- `config/patches/C018*` (`RandomBotAccountCount`) — account headroom
- `scripts/credentials` / `credentials.dist` — gains `soap_user`/`soap_pass`
- `source-beta/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp` —
  `UpdateAIInternal` (band enforcement), `ProcessBot` (TTL logout),
  `HandlePlayerbotConsoleCommand` (`rndbot reload`/`update`/`stats`)
- `source-beta/src/server/apps/worldserver/ACSoap/ACSoap.cpp` — the SOAP
  listener and its Basic-auth check
- `source-beta/src/server/scripts/Commands/cs_misc.cpp` — `.kick`

## Related

- **C020** set the 128-256 vanilla band and its login-stampede rationale;
  the governor's default ceiling (512) deliberately exceeds it because the
  governor, unlike a static band, can retreat when the machine objects.
- **107** (credential manager) — the `@CRED` store the governor reuses.
- **106** (ingame config control board) — sibling idea: runtime config
  manipulation, from inside the game rather than outside the process.
