# 148w - Mages Reach Level 20 With Almost No Castable Spells

## Status
- Created: 2026-08-07
- Phase: 1 (Foundation — vanilla profile)
- Parent: 148 (vanilla profile)
- Predecessor: 148j (the level-≤20 pretrain migration this is a
  defect against)
- Sibling: 148o (the validation pass), 148v (the kit render defect
  found in the same session)
- Priority: High — a mage is the class most completely defined by
  its spellbook. A level-20 mage with one rank-1 nuke has no game to
  play, and the damage shortfall reads as the server being broken
  rather than the character being new.

## Source Report (verbatim, 2026-07-22)

> I noticed that mage characters don't get all their learnable skills at
> level 20. This means they have no spells to cast, except for a weak level 1
> spell that will make people upset at the game because it doesn't work or deal
> proper damage for a level 20 character.

## Why This Is a Defect and Not Just Missing Work

148j exists precisely to close this gap. Vanilla creates characters
at level 20 (`StartPlayerLevel=20`, set by C007c), and a level-20
character in stock 3.3.5a has visited a class trainer at every even
level and learned thirty to forty spells and ranks along the way.
Skipping those nineteen trainer visits leaves, in 148j's phrasing,
"a level-1 character wearing a level-20 body."

148j's design pulls the (class, spell) pairs from `npc_trainer`
joined against class-trainer `creature_template` rows filtered to
`ReqLevel <= 20`, and inserts them into
`playercreateinfo_spell_custom` with `race = 0`. Its own acceptance
criteria name the mage case explicitly:

> Mage spellbook contains Frostbolt rank 4, Fireball rank 3+, Frost
> Nova rank 1, Polymorph, Counterspell if ≤20.

`issues/phase-1-progress.md` records 148j as **Implemented** — "287-row
trainer-spell pretrain SQL built. Apply/validate pending." So the
migration exists. The in-game observation says it is not producing
the effect it was designed for, at least for mages.

## Why the Validator Said Everything Was Fine

`scripts/validate-vanilla-starter-state` reports all five of its checks
passing, and one of those checks is that every class has its 148j
pretrain rows. That check was **correct the whole time**. The rows do
exist, they are complete, and their masks are right. Nothing ever read
them.

This is the durable lesson here, and it outlasts the fix: a validator
that inspects the world database can prove data is *present*. It cannot
prove data is *reachable*. Between "the rows are there" and "the
character has the spells" sit a core function and one boolean in a
`.conf` file, and neither is visible from any query against the world
DB.

The check that would have caught it compares what each character
actually knows against what its race and class should have matched.
That spans the world and character databases at once, which is why it
was not in the original data-side sweep. See implementation step 5.

## Measured 2026-08-07: the Data Is Right, the Grant Never Happens

Run against the live `acore_world_vanilla` and
`acore_characters_vanilla`. Every guess in the section above is now
settled, and none of them was the cause.

**First correction: the table schema in 148j is wrong.** 148j
documents `playercreateinfo_spell_custom` as having `race` and `class`
columns holding direct IDs. The actual table is:

| Field | Type |
|---|---|
| `racemask` | int unsigned |
| `classmask` | int unsigned |
| `Spell` | int unsigned |
| `Note` | varchar(255) |

Bitmasks, not IDs. This mattered enough to check carefully, because
writing a class *ID* into a *mask* column silently grants to the wrong
class (class 8 written as mask 8 is bit 3, which is Rogue). **The
generator did not make that mistake** — every stored `classmask` is a
clean power of two and every `racemask` is a plausible multi-race mask.

**The data is present and complete.** 717 rows total, not the 287 the
progress note records, so the SQL has been regenerated since. Per
class:

| classmask | Class | Rows |
|---|---|---|
| 0 | any | 77 |
| 1 | Warrior | 71 |
| 2 | Paladin | 53 |
| 4 | Hunter | 59 |
| 8 | Rogue | 51 |
| 16 | Priest | 99 |
| 64 | Shaman | 52 |
| **128** | **Mage** | **123** |
| 256 | Warlock | 82 |
| 1024 | Druid | 50 |

Mage has the *most* rows of any class. Death Knight (32) is absent,
correct per 148a.

**The reported character has none of them.** The mage in the report is
Kaersenon, guid 22816, Blood Elf, level 20, on account 101 = `RITZ`.
Filtering the pretrain table to what a Blood Elf Mage should receive —
`(racemask = 0 OR racemask & 512) AND (classmask = 0 OR classmask & 128)`
— returns **123 rows**. The character's actual `character_spell`
contents:

| spell | what it is |
|---|---|
| 201 | One-Handed Swords proficiency |
| 1180 | Daggers proficiency |

Two weapon proficiencies and **zero spells**. Exactly the reported
symptom, and precisely 0 of 123.

**A grant path did run — just not this one.** Those two proficiencies
come from the first-login weapon-proficiency grant that ships with
148h/148k, which works. So the character-creation pipeline executed;
the `playercreateinfo_spell_custom` read inside it did not take effect.

**The fleet shows the same split.** Of 23,915 characters, only 453 have
any spell at all. Those 453 sit on accounts 1–101 and almost entirely
below guid 450. Everything created since — 23,462 characters, the
`RNDBOT*` fleet on accounts 51–2362 — has an empty spellbook. So this
is not mage-specific and not player-specific. The grant stopped working
for everyone, some time after roughly guid 450.

## Confirmed Cause: the Table Is Switched Off in Config

A stale-cache theory was floated first and is **wrong** — the
worldserver has been restarted several times across these character
creations, so no amount of restarting explains it. The real cause is
one line of config, and it is exact.

`Player::LearnCustomSpells()`, at
`src/server/game/Entities/Player/Player.cpp:11909`, opens with:

```cpp
void Player::LearnCustomSpells()
{
    if (!sWorld->getBoolConfig(CONFIG_START_CUSTOM_SPELLS))
    {
        return;
    }
    // learn default race/class spells
    PlayerInfo const* info = sObjectMgr->GetPlayerInfo(getRace(), getClass());
    ...
```

Everything that reads `info->customSpells` — which is where
`playercreateinfo_spell_custom` ends up after
`ObjectMgr::LoadPlayerInfo()` parses it — sits below that early return.

The config constant maps to a `.conf` key at
`src/server/game/World/WorldConfig.cpp:550`:

```cpp
SetConfigValue<bool>(CONFIG_START_CUSTOM_SPELLS, "PlayerStart.CustomSpells", false);
```

Default **false**. And the live vanilla config, at
`installed-files-vanilla/etc/worldserver.conf:1699`:

```ini
PlayerStart.CustomSpells = 0
```

No `config/patches/C*.sh` sets it. Nothing has ever set it.

**So the 717 rows have never been read.** Not once, for any character,
on any boot. The table is fully populated, correctly masked, and
completely inert. `LearnCustomSpells()` returns at line 11911 every
time and the migration below it never runs.

This explains every observation at once: why the data checks out, why
mage is not special, why 23,462 characters have empty spellbooks, why
restarts change nothing, and why Kaersenon has exactly the two weapon
proficiencies that come from the *other* grant path (the 148h/148k
first-login hook, which is our own Lua and is not gated by this config).

## The Fix

One config patch, in the same shape as the rest of the `C*.sh` family:

```
config/patches/C0NN-vanilla-custom-spells.sh
    CONFIG_PROFILES="vanilla"
    PlayerStart.CustomSpells = 1
```

It has to be a config patch rather than a hand-edit, because
`installed-files-vanilla/etc/worldserver.conf` is regenerated from
`.dist` at install time and a manual edit would be overwritten on the
next install.

After it applies and the worldserver restarts, a freshly rolled Blood
Elf Mage should come up with 123 spells. Characters created before the
fix stay empty — `playercreateinfo_spell_custom` is read at creation
only and is never revisited — so the entire existing 23,462-character
bot fleet needs regenerating, or the top-up hook in the open questions
below.

**Check the neighbouring flags while in there.** `PlayerStart.AllSpells`
and the rest of the `PlayerStart.*` block sit in the same config
section and govern adjacent behaviour. If `CustomSpells` was missed,
others may have been too.

## Current Behavior

- A mage created on the vanilla profile arrives at level 20 with
  effectively an empty spellbook — the report describes one weak
  rank-1 spell as the only castable option.
- Damage output is therefore roughly a third of what level-20
  content expects, matching 148j's own prediction for the
  un-pretrained case.
- The data-side validator reports the 148j check as passing.
- 148v (cloned kit items rendering invisible) was observed on the
  same mage in the same session; the two defects are independent but
  compound — that character had neither visible gear nor spells.

## Intended Behavior

A mage created on the vanilla profile opens its spellbook at first
login and finds every spell and every rank a stock level-20 mage
would have trained: Frostbolt through rank 4, Fireball through rank
3 or higher, Frost Nova, Polymorph, Arcane Intellect, Fire Blast,
Conjure Water/Food at their level-appropriate ranks, and the wand
and weapon skills the kit assumes. The same holds for every other
enabled class — mage is where it was noticed, not necessarily where
it stops.

## Suggested Implementation Steps

1. Write `config/patches/C0NN-vanilla-custom-spells.sh` gated on
   `CONFIG_PROFILES="vanilla"`, setting `PlayerStart.CustomSpells = 1`.
   Follow the apply/unapply and idempotency conventions the rest of the
   `C*.sh` family uses.
2. Re-install so the config regenerates, restart the worldserver, roll
   a fresh Blood Elf Mage, and count `character_spell`. Expect 123.
3. Roll one of each remaining class and confirm the counts match what
   the pretrain table says each should get. The masks are already
   verified correct, so this is confirming the grant fires, not
   confirming the data.
4. Decide what happens to the 23,462 existing characters with empty
   spellbooks. Regenerating the bot fleet is the blunt option; the
   login-time top-up hook in the open questions is the durable one.
5. **Strengthen the validator.** `scripts/validate-vanilla-starter-state`
   currently asserts that pretrain rows exist in the world database,
   which was true throughout this entire defect. The check that would
   have caught it compares a character's actual `character_spell` count
   against the number of pretrain rows its race and class should have
   matched. That spans two databases, which is why it was not in the
   original data-side sweep — and it is the difference between "the
   rows exist" and "the rows arrived."
6. Audit the rest of the `PlayerStart.*` config block for other flags
   that a migration silently depends on.

## Cross-References

- `issues/148j-pretrain-level-20-abilities.md` — the migration this
  is a defect against. Its Data Source and Granting Mechanism
  sections describe the query and the target table.
- `issues/148o-vanilla-spawn-and-kit-validation-pass.md` — check 4 of
  its per-character checklist is the level/talent check that should
  have surfaced this.
- `issues/148v-cloned-kit-items-render-invisible.md` — the other
  defect from the same session, on the same character.
- `issues/701-quest-spells-to-trainers` — the adjacent question of
  which abilities normally come from quests rather than trainers.
  148j deliberately leaves quest-only spells out of scope, so any
  spell missing from a mage should be checked against that boundary
  before being called a bug.
- `scripts/validate-vanilla-starter-state` — the validator that
  passes today and should not.
- `docs/class-spells-level-1-20.md` — the reference list of what each
  class should know by level 20.

## Open Questions

- **Is the shortfall mage-only or was mage just the one that got
  rolled?** The per-class row count answers this immediately and
  changes the size of the fix considerably.
- **Does the world database use `npc_trainer` or `trainer_spell`?**
  148j's generator was written against `npc_trainer`. Newer
  AzerothCore moved trainer data behind
  `creature_template.trainer_id` → `trainer` → `trainer_spell`. If
  the vanilla profile is tracking upstream HEAD, the generator may
  be querying a legacy table that still exists but is no longer
  populated the same way.
- **Should pretrained spells be re-granted on login rather than at
  creation?** Creation-time granting means any character made before
  a migration lands is permanently short. A login-time top-up hook
  (ALE, same shape as 148k) would make the pretrain set
  self-healing across regenerations — at the cost of running a spell
  reconciliation on every login. Worth deciding deliberately rather
  than by default.
