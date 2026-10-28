# 635c - Spell and Gear Preferences per Character

## Status
- Created: 2026-10-27
- Phase: 6
- Parent: 635
- Blocked by: 635b
- Related: the bot module's "skip spells" list and strategies, the gear
  spec (`docs/buddy-gear-spec.md`), 155k2 (spirit on gear)
- Priority: High
- State: plan

## Current Behavior

A bot casts what the bot module's class logic picks for its role. Its gear
follows the gear spec by level band, not a stat order.

**Built 2026-10-27 (the "never" half):** spell designs as data,
`src/lua-basic/data/spell-designs.lua` (the Renew priest: every heal but
Renew skipped; the druid healer: the heals that land at once skipped), and
`scripts/write-spell-design DESIGN CHARACTER`, which turns a design's names
into the bot module's own "skip spells list" (one spell number per name:
the bot module skips every rank of a name) and writes it into the bot's
saved settings, which it reads at every login; offline characters only,
other settings left alone. `scripts/test-spell-designs` (a quick test)
checks the names against the game's spell file, that the spells a design
is built round stay castable, and the tool on scratch databases. What a
skip list can't say: "only in combat" (the druid's downtime exception) and
"prefer" (the paladin's seal, the shaman's Stormstrike first): those need
a behaviour of our own, not yet built. The gear order is not built.

## Intended Behavior

- **A character's spell design**, as data beside its build:
  - **only these**: the druid healer casts only its healing-over-time
    spells (Rejuvenation, Regrowth, Lifebloom) in combat, any heal out of
    it ("Unless it's a downtime period"); Thorns kept up; Moonfire "the
    moon" favoured when it attacks; Moonkin Form never;
  - the Renew priest casts only Renew;
  - **preferred**: the paladin's Seal of the Crusader, Flash of Light when
    instant (The Art of War) and on the Sacred Shield target; the shaman's
    Stormstrike and Thunderstorm.
  - Written into the bot as its skipped-spell list and strategies, so the
    bot module's own logic does the casting.
- **A character's gear order**, a stat priority:
  - bear: stamina and spirit, then armour ("our spirit patch enables
    health healing in combat. I want to see how that dynamic behaviors");
  - paladin: spell power, and a fast two-hander;
  - shaman: a two-handed mace;
  - the healers: their own order (open question).
  Gear chosen by a tool from the items the party may wear (635's third
  question), each pick explained by its stats.

## Suggested Implementation Steps

1. The spell design in the party's file, and a tool that writes the bot
   settings from it (a test: the Renew priest's skip list skips every heal
   but Renew).
2. The gear picker by stat order, with a report of what it chose and why.

## Open Questions

1. The healers' stat order: for the druid and the priest, spirit (the
   spirit patch) and spell power, in which order?
2. "Thunder" for the shaman: Thunderstorm is Elemental's eleventh row and
   Maelstrom Weapon Enhancement's tenth, both shut by basic's talent cap
   (635b's first question). Open to an Enhancement shaman at 60: Lightning
   Shield, Lightning Bolt, Chain Lightning, the Windfury and Flametongue
   weapons. Which is "thunder"?
3. **The paladin's three asks, on basic's rules today**:
   - **Seal of the Crusader** was taken out of the game in Wrath's first
     patch; 3.3.5 has no such seal for players. It is one of the old
     abilities planned for the advanced profile (1101,
     `docs/profiles/advanced-ability-versions.md`).
   - **Sacred Shield** is trained at level 80 (the trainer's own table):
     out of reach at 60.
   - **Instant Flash of Light** comes from The Art of War, a two-rank
     talent in Retribution's seventh row, shut by the cap.
   So the paladin as asked needs either the advanced profile, or this
   party let past basic's rules (as 635b's first question asks for the
   priest).
