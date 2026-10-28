# 635 - The Botanica Checkpoint Party

## Status
- Created: 2026-10-27
- Phase: 6 (buddies and the bots' behaviour)
- Related: 197 (class changes with buddy gear: `scripts/change-character-class`),
  155f (the Botanica on basic: boss level 75), 155f1 (fights balanced),
  155k2 (spirit on gear) and the spirit patch (health from spirit in
  combat), 617 (buddies), `scripts/generate-basic-talent-data`,
  `src/lua-basic/data/gearsets/`
- Sub-issues: 635a, 635b, 635c, 635d, 635e
- Priority: High (the owner's ask for today)
- State: plan; open questions below

## Origin

The owner, 2026-10-27:

> We should build tools and utilities for this along the way if you
> please. can we get a character built and set up for a group fight on The
> Botanica? Dungeon battle. I want to use it as sort of a "checkpoint" so
> make sure you can re-assemble it easily and quickly. the dungeon party
> should consist of: an enhancement shaman using a 2h mace, properly
> talented away from off-hand attacks. also a retribution paladin with a
> fast 2hander who prefers seal of the crusader and instant flash of
> light's with sacred shield. And Quel'Delar.
>
> the healer should be two characters, a 2 parts balance 1 part resto
> druid, and a 2 parts shadow 1 part holy priest. also the ret paladin
> should prefer spellpower, to boost the power of seals and judgement.
> also there should be a feral bear tank, who prioritizes stamina and
> spirit. remember, our spirit patch enables health healing in combat. I
> want to see how that dynamic behaviors.
>
> the balance druid should not spec into boomkin, and they should only
> cast healing over time spells. Unless it's a downtime period or
> something. the holy priest should only cast renew, but take all the
> empowered talents for it, no matter how far down the tree she has to go.
> [new functionality, need additional build support for it] the idea of
> having a build target "favor this talent tree, but spend as much as you
> need to get to these select talents, and max them out. build
> requirements"
>
> ret paladin, prefer fast attack speed spellpower. enh shaman, prefer
> stormstrike and thunder. feral druid, prefer components and armor.
>
> the player should be able to play as any of them. a group of players
> should be able to queue as any of them. they can swap the roles. they can
> be seen from all angles. they are to be believed.
>
> balance druid favor thorns and the moon.
>
> can we make it so that the origin point of the moonfire orbits the
> target? And if there's more balance druids casting moonfire, it'll come
> from the same point more often. But, each druid uses the same "moon" to
> reflect off of, floating around and orbiting in 3d space. So long as it
> doesn't collide with the terrain or doodads, it can be made to always
> take a consistent and stable course. Then, with many moonfire druids, it
> will look like a near constant blaze. Allies will come to know how many
> of them there are based on the strength and consistency of their beams.
> Starfall comes from a random direction each time.

## Current Behavior

Nothing of this exists as a whole. What exists to build on:
- **Class changes** with lessons and skills (`scripts/change-character-class`)
  and buddy dressing to the gear spec (`.buddy spec`, `.buddy kit`).
- **Talent plans** for buddies: thirds of the points per tree, ten fixed
  plans (`buddies_loot.cpp`, its plan table); no way to say "these
  talents, maxed, whatever it costs".
- **Gearsets** by level band (`src/lua-basic/data/gearsets/`), not by
  stat preference.
- **The bots' spell choice** is the bot module's own per class and role.
  It has a per-bot list of spells to skip (its "skip spells" whisper
  command), but nothing writes such lists from a design.
- **No saving and restoring a group as a whole.** The class-change tool's
  backups hold one character's rows, for undoing a change.

## Intended Behavior

**The party** (level 60, basic, at the Botanica's entrance):

| Seat | Class, build | Plays as |
|---|---|---|
| Tank | Feral druid, bear | Stamina and spirit first, then armour; "prefer components and armor" |
| Healer 1 | Druid, 2/3 Balance, 1/3 Restoration, no Moonkin Form | Healing over time only, except out of combat; Thorns; "the moon" (Moonfire) |
| Healer 2 | Priest, 2/3 Shadow, 1/3 Holy | Renew only, with every talent that empowers it, however deep |
| Damage 1 | Shaman, Enhancement, a two-handed mace | Talented away from off-hand attacks; Stormstrike and Thunderstorm first |
| Damage 2 | Paladin, Retribution, a one-handed sword and an off-hand item (the owner, 2026-10-27: "the paladin uses 1h sword and off-hand item, because they have stamina while shields have armor"; replaces the first ask's fast two-hander) | Spell power for seals and Judgement; Seal of the Crusader; instant Flash of Light with Sacred Shield |

**The pieces** (each its own sub-issue):

| ID   | Name                                   | Dependencies   | Description |
|------|----------------------------------------|----------------|-------------|
| 635a | party-checkpoint-save-and-restore      | None           | A tool that saves a whole party (characters, talents, gear, spells, bot settings, place) under a name and puts it back in one command |
| 635b | talent-builds-with-required-talents    | None           | A build target: a favoured tree, and named talents maxed whatever they cost; the rest by thirds |
| 635c | spell-and-gear-preferences-per-character | 635b         | Which spells a character's bot casts or skips, and which stats its gear favours, from a written design |
| 635d | any-player-in-any-seat                 | 635a           | A player, or a group of players, logs in as any seat; the rest are bots; seats can be swapped |
| 635e | moonfire-from-a-shared-moon            | None           | Moonfire's beam comes from one moon orbiting the target, shared by every druid; Starfall from a random direction |

- **Why split**: the checkpoint is a tool (shell and SQL), the talent
  builds are data and the talent spender, the preferences are the bot
  module's settings, the seats are accounts and logins, and the moon is a
  visual made in the server. Each is built and tested apart.
- **Order**: 635b → 635c (the builds feed the preferences); 635a in
  parallel; 635d after 635a; 635e on its own.
- **The party itself is data**: one file describing the five seats
  (class, race, build, weapon, stat order, spells), read by the tools, so
  the next checkpoint party is a new file, not new code.

## Suggested Implementation Steps

1. The party's file (seats as data) and 635b's build targets.
2. 635c's preferences; 635a's save and restore; the party made and saved
   as the first checkpoint.
3. 635d's seats.
4. 635e's moon.
5. A run through the Botanica, recorded (the movement recording, Debug
   build), as the checkpoint's proof.

## Open Questions

1. **Quel'Delar**: "And Quel'Delar." Its two two-handed forms (Might of
   the Faithful, Ferocity of the Scorned) are swords of item level 251 for
   level 80, at 3.6 and 3.4 seconds a swing: slow, not fast. With the
   paladin now on a one-handed sword, its one-handed forms fit: Cunning of
   the Shadows (one-hand, 2.7 s) and Lens of the Mind (main hand, 2.1 s, a
   caster's sword), item level 251 for 80. Proposed: Lens of the Mind, for
   spell power, scaled to 60 as the Kael'thas epics were (item level 100).
   Yes?
2. **Who the five are**: new characters made for this, or existing ones
   (Feldowinn's buddies, say) changed to fit?
3. **Gear**: the Botanica's bosses are level 75 on basic. Dress the party
   in the gear of the dungeon before it on the ladder, so it is a fair
   fight, or in the Botanica's own, so it is a sure one?
4. **Basic's rules against the asks.** Several asks reach past what basic
   allows a level 60: Seal of the Crusader (removed in Wrath), Sacred
   Shield (trained at 80), The Art of War, Thunderstorm, Maelstrom Weapon
   and the deep Renew talents (past basic's talent cap). See 635b's and
   635c's questions. Is this party basic's, the advanced profile's, or a
   test party allowed past the rules?
5. **"They can be seen from all angles. They are to be believed."** Kept
   verbatim. Does it ask for something to be built (a camera tour of the
   party, the gear gallery's views), or is it a quality the party must
   have?
