# 155 - The Basic Profile

## Status
- Created: 2026-09-23
- Phase: 1 (Foundation — profile model, alongside 148's vanilla cluster)
- Priority: High — basic is the baseline every later feature is developed
  against, starting with custom classes.
- Sub-issues: 155a through 155o

## Origin

Verbatim, 2026-09-23:

> can we make a new profile that's called "plain" which is the vanilla profile
> except the max level is 60 and the starting level is 1 and the starting gear
> patches are not applied along with other similar patches like pre-trained
> abilities and such. You can consult me if something seems equally plausible.
> The adjusted riding gates is preferred. No need for starting professions at
> level 125. Idk what the starting zone patch is. I'd like to know about the
> death knight class system, but idk if we have it prepared yet. First up on
> the development agenda is custom classes, but the default game level 1-60
> with playerbots and quality of life adjustments should be the initial
> baseline standard that we develop for.

On naming, starting zones and Outland, verbatim, 2026-09-23 (the profile was
drafted as "plain" until this answer):

> let's name it basic/expert, with this being the "basic" tier and "expert"
> being level 61-80 where you start at 60 but it's not built yet.

> we should have characters spawn at a random starting zone. Fully
> randomized. But, it's syncronized, so like the next 30 alliance characters
> spawn in northshire and the next 30 horde characters spawn in Mulgore, then
> after that the next 30 alliance characters spawn in teldrassil and the next
> 30 horde characters spawn in Eversong Woods, etc. Make sure to ensure that
> quests aren't gated by race anymore, only faction.

> let's leave Outland as content available at level cap. That way we can get
> raid quality gear from questing.

> oh and since the early Outland dungeons give blues, let's tune them higher
> (level 64) as a "heroic" mode. Also let's implement the patch that removes
> the accuracy penalty for level gaps.

## What This Profile Is

The ordinary level 1–60 game, with playerbots filling the world and the
quality-of-life layer vanilla already carries. Vanilla is a *constrained*
ladder: characters are born at 20 already kitted, trained, and holding two
professions, then climb to 40. Basic removes the head-start and lengthens
the ladder back to its classic length: born at 1 in a starting valley,
carrying nothing but what the stock game hands out, climbing to 60, with
Outland open at the cap.

The name comes from the OSR Dungeons & Dragons line: the Basic Set covers
the early levels and is complete by itself; the Expert Set continues it.
Basic is levels 1–60. **Expert** (156, not built) is levels 61–80, starting
at 60.

Basic becomes the profile new features are developed against. Custom
classes come first.

## Current Behavior

**Built 2026-09-23 and tested as far as possible without a running system;
in progress until the owner compiles and installs it and the open questions
below are answered.** Every sub-issue's Current Behavior says what exists,
what was tested, and what waits on the install. Test tools:

- `scripts/test-profile-config-gates` — basic's config values (20/20) and
  that no config patch edits a key the configs lack;
- `scripts/test-source-patches basic` — every source patch applies, reports
  success, and reverts byte-identically;
- `scripts/validate-basic-state` — run after install: head-start rows
  absent, stock valleys, riding levels, flight paths, flavor lines, quest
  masks, rotation state, mentors, dungeon creature levels;
- `scripts/test-basic-sql-in-ram` — builds a private MySQL in `/dev/shm`
  (no network port), loads the stock databases plus every upstream update
  the way the server's updater does, runs all of basic's SQL (apply,
  re-apply, revert, apply), then runs the checker above against it.
  2026-09-23: every step ran and all 16 checks passed. The project's MySQL
  is never touched.

Work on basic surfaced bugs in shared machinery. They are fixed and listed
in 155a, 155b and 155c. Two of them change **other** profiles on their next
install: run speed really becomes 80% everywhere (it never was), and beta's
instant flights really turn on.

Before this issue: no profile named `basic` existed. Vanilla is the nearest shape, and vanilla's
head-start patches (starter kit, pretrained abilities, starting
professions, level-20 spawn towns) are welded into its profile lists; there is no
way to get "vanilla minus the head-start" without a new profile name.

## Intended Behavior

A fifth profile, `basic`, built from the same source tree as vanilla
(`source-beta`) with the same module set, and differing from vanilla only
in the rows of this table:

| Vanilla element | Basic | Why |
|---|---|---|
| Level cap 40 | **60** | the classic ladder |
| Start level 20 | **1** | no head-start |
| Racial spawn towns (Menethil, Astranaar, …) | **the eight level-1 starting valleys, taken in rotating batches per faction, regardless of race** (155d) | user decision 2026-09-23 |
| Quests restricted by race | **restricted by faction only** (155e) | a character can start in any of its faction's valleys, so it must be able to do that valley's quests |
| Outland | **open at the cap** (Dark Portal at 58, stock) | user decision 2026-09-23: raid-quality gear from questing |
| Outland dungeons open at ≤60 | **every creature its stock level + 4** (built as a flat 64, to be changed); open world, quests, loot and heroic modes stock (155f) | user directive 2026-09-23, +4 on 2026-09-24 |
| Onyxia and Naxxramas (level-80 versions in this client) | **scaled down to level-60 raids with their original vanilla loot** (155h) | user directive 2026-09-24 |
| Crushing blows | **none from creatures level 64 and up**, as its own patch; armor, resists and aggro radius stay stock (803) | user directive 2026-09-24 |
| Outland quests | **removed** (givers stay); one flight from the Dark Portal to Honor Hold / Thrallmar (155l) | user directive 2026-09-24 |
| Accuracy penalty for level gaps | **capped at ±3 levels** (source patch B005, issue 803) | user directive 2026-09-23 |
| Talents | **nothing from tier 6 down** (30+ points in a tree), as vanilla-era trees (155g) | user directive 2026-09-23 |
| Class starter kit + cloned kit items + bots-wear-the-kit | **not applied** | head-start |
| Pretrained abilities + the config switch that reads them | **not applied** | head-start |
| Starting professions at skill 125 | **not applied** | user directive |
| Riding gates at 40 / 60 | **applied** | user directive: preferred |
| Flight paths removed | **applied** | user decision 2026-09-23 |
| 10× fall damage, 80% run speed | **applied** | user decision 2026-09-23 |
| Race intro cinematic skipped | **applied** | user decision 2026-09-23 |
| Death knights disabled | **allowed, with two limits**: an account needs a level-55 character, and no death-knight bots (C024). Later replaced by the sacrifice mechanic in 718 | user decision 2026-09-23 |
| Bot band 20→40, Eastern Kingdoms only | **no random bots at all; only each player's buddies** (617) | user directive 2026-09-24 (was 1→60 on all three continents) |

## Sub-Issues

| ID | Name | Dependencies | Description |
|---|---|---|---|
| 155a | basic-profile-plumbing | None | Make the name `basic` resolve everywhere a profile name is resolved: trees, databases, realm, scripts |
| 155b | basic-profile-config-gates | 155a | Decide every config patch for basic, one at a time; add the level-60 cap; widen the bot band |
| 155c | basic-world-database-patches | 155a | Which world/character SQL patches basic runs, and where their source SQL lives |
| 155d | rotating-faction-starting-valleys | 155a, 155e | New characters spawn in one of their faction's starting valleys, the valley changing every 30 characters in a shuffled order |
| 155e | faction-not-race-quest-gating | 155a | Quests, and the trainers and gossip a valley needs, are open to the whole faction rather than one race |
| 155g | vanilla-talent-cap | 155a | No talent needing 30+ points in its tree can be learned (Combustion, Repentance and their rows) |
| 155f | outland-dungeons-at-64 | 155a, 155c | Every creature in each Outland dungeon a level 60 can enter gains 4 levels; open world, quests and loot stay stock |
| 155h | vanilla-onyxia-and-naxxramas | 155a, 155c | Onyxia's Lair and Naxxramas become level-60 raids again, dropping their original vanilla loot |
| 155i | dungeon-damage-and-healing-multipliers | 155a | Per-dungeon multipliers on creature damage and on healing, set in a table, so difficulty is tuned without more levels |
| 155j | weekly-world-boss-kazzak | 155a, 155i | Kazzak, Doomwalker and a reworked Fel Reaver: basic's top tier, once per restart; Kazzak's loot drawn by each player's contribution, bots excluded |
| 155k | outland-world-gear-ladder | 155a, 155c | Outland open-world gear wearable at 60, each zone's drops set to an agreed vanilla tier |
| 155l | outland-without-quests | 155a, 155c | No quests in Outland; one flight from the Dark Portal to Honor Hold or Thrallmar; all other flights stay off |
| 155m | true-creature-levels | 155a | Show a high-level creature's real level instead of the skull (an interface addon fed by the server) |
| 155n | outland-without-tradeskills | 155a, 155c | No herb or mining nodes in Outland; no trainer teaches past Artisan (300) |
| 155o | inscription-without-glyphs | 155a, 155n | No glyphs; Inscription becomes a buff-scroll profession to 300 |

Execution order: `155a → (155b ∥ 155c ∥ 155e ∥ 155i) → (155d ∥ 155f ∥ 155h ∥ 155k ∥ 155l ∥ 155m ∥ 155n) → (155j ∥ 155o)`. 155d depends on 155e
because a human sent to Shadowglen before 155e lands arrives in a valley
whose quests it cannot take.

The death-knight redesign the user described for basic lives in **718**
(phase 7), not here: it is scheduled after the custom-class infrastructure
exists, as one of the first classes built on it. Basic ships with an interim
death-knight rule until then.

## Suggested Implementation Steps

1. 155a — plumbing, so the name resolves and fails loudly where it does not.
2. 155b and 155c in either order — each is an audit of an existing patch
   list with a decision per row, recorded in the sub-issue.
3. Install and boot basic (the user runs the compile/install scripts), then
   read every config value back out of `installed-files-basic/etc/` and
   compare with 155b's table.
4. Write `docs/profiles/basic.md` beside `docs/profiles/vanilla.md`, add it to
   `docs/table-of-contents.md`, and update the profile list in `CLAUDE.md`.

## Related Issues

- **148** the vanilla cluster — the profile basic is derived from
- **148a** (completed) — why vanilla disables death knights; its claim that
  the client hard-codes the Acherus start is contradicted by **206**, which
  starts beta death knights at level 1 with no client patch (see 718)
- **152** profile rename — its plan (vanilla → basic, release → expert) is
  superseded by this issue and 156; see 152
- **156** the expert profile — levels 61–80, the continuation of basic
- **204** random spawn point (beta, open) — the roguelike cousin of 155d:
  fully random world points rather than rotating valleys
- **153** / **153a** explore profile — a sibling fifth profile; whichever of
  153a and 155a lands second reuses the first one's sweep
- **136** canonical profile definitions — gains a `basic` entry
- **716** class combination modifier system, and the 700s custom-class
  cluster — the first features to be developed on basic
- **718** death-knight sacrifice and open Acherus — basic's eventual
  death-knight rule, built on the custom-class infrastructure

## Open Questions

- (Answered by Ritz's death-knight reply, 2026-09-23) Interim rule:
  allow stock death knights; a level-55 character is required; no
  death-knight bots. Built as C024.
- (Answered 2026-09-23) Vanilla and release are left alone for now: "we're
  not really working on vanilla and release right now so let's just leave
  them alone." That includes release's current level-20 cap.
- (Answered 2026-09-23) Experience rate 1×.
