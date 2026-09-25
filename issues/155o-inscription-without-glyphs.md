# 155o - Inscription Without Glyphs

## Status
- Created: 2026-09-24
- Phase: 1
- Parent: 155
- Blocked by: 155a, 155n (the 300 skill cap)
- Priority: Medium

## Origin

Verbatim, 2026-09-24:

> We should remove inscription though. Actually, let's remove the glyphs
> from inscription, and just make it a buff-scroll creation profession.
> Players have buddies to buff now, so buff scrolls should be more valuable
> than expected. Tell me what inscription looks like without glyphs?

Later the same day, verbatim:

> how about we make all stat scrolls available, even the WotLK scrolls,
> and we scale them in a similar fashion as we did with the ilevel scaling.
> Proposals for this solution?

> Is there a way to make it so that each character can have one scroll
> effect active at once, but maybe their timer is lowered to compensate?

> let's make it so that scrolls do stack with class buffs, but each
> character can only have one at a time active at once.

And, verbatim, 2026-09-24:

> I want to make inscriptionists valuable, because we're removing their
> main functionality. So let's keep the stock numbers. However... Isn't it
> just +132 stamina OR +750 armor? If only one scroll can be active at
> once?

> We will have to make rank III craftable if we want vellums to be used at
> all.

> the darkmoon faire will not be running. We should make them just,
> magically summon a small arcane circle on the ground. A voidwalker should
> walk out and say "here... is your item..." then add it to the player's
> bag. There will always be space because summoning the voidwalker removes
> the card item. Then it adds the item to their bag after a couple seconds
> delay to allow the animation to play out. If they log out or otherwise
> are made indisposed (joined a battleground) or something, then the item
> is mailed to them.

> The level 60 darkmoon cards give an epic trinket I think, can you look
> into how that works for me? I never investigated.

> [scroll duration:] let's say 30 minutes for now.

> can we make the darkmoon faire tarot card items never bind? So they can
> always be sold.

And, verbatim, 2026-09-24:

> oh interesting. Can we make each Tempest Keep dungeon boss drop one of
> those cards, and MGT bosses have a 50% chance to drop 2, 50% chance to
> drop none? Also, Kael-thas always drops 3 random cards. Actually that's
> rude let's just make MGT bosses drop 2.

> The trinkets and the low level equipment like necklaces and such should
> never bind too. Nothing from a tarot deck should bind.

> [choose-one rewards:] offer a choice. Instead of mailing the item, let's
> mail the deck.

> [Burning Crusade decks' trinkets at 60, summoned by the voidwalker:] yes
> and yes.

## Current Behavior

**Built 2026-09-24** as install step E029,
`sql/basic/db_world.src/14-inscription-without-glyphs.apply.sql` (+ revert),
its recipe lists generated from the client's profession and spell tables by
`scripts/generate-basic-inscription-sql` (347 glyph and research recipes;
42 stat-scroll and rank-III vellum recipes), plus source patch B032. Runs
after E027 (which removes every recipe above 300):

1. glyph recipes and glyph research are removed from every trainer;
2. every stat-scroll recipe and both rank-III vellums need their stock skill
   × 300/425 (rank VIII 405–425 → 286–300; Vellum III 350/400 → 247/282);
   recipes E027 removed are put back at that rank;
3. the scroll items' required level × 0.75 (VI 45, VII 53, VIII 60); buff
   values and the 30-minute duration are stock;
4. scrolls leave the "stronger one wins" stacking groups they shared with
   class buffs (spell groups 1083–1086, 1088) and stay in the "Scrolls"
   group (1087): one scroll per character, on top of class buffs;
5. **B032** (`patches/B032-no-buff-level-restriction.sh`, doc
   `docs/patches/no-buff-level-restriction.md`): the stock server refuses to
   put a buff on a target more than 10 levels below the buff's lowest rank,
   which would stop a level-60 player reading rank VII (spell level 70) or
   VIII (80) on anyone else. Found while building this; Ritz: "sounds like we
   should make a patch to remove that restriction." Not yet compiled.

Tested: `scripts/test-basic-sql-in-ram` (with the exact-revert checksum,
`spell_group` included) and `scripts/validate-basic-state` (no glyph at a
trainer, every scroll recipe within 300, required levels 3/4 of stock, the
stacking groups); `scripts/test-source-patches` round-trips B032 with the
other 24 basic source patches.

**Darkmoon, built 2026-09-24** as install step E030,
`sql/basic/db_world.src/15-darkmoon-cards.apply.sql` (+ revert): every
Darkmoon card of every suit, the four tarots, the Darkmoon Card item, every
deck a Faire quest takes and every item those quests give (trinkets and the
low-level gear) never bind (stock bindings saved); a new reference loot
table (1550155) holds the 32 Burning Crusade cards at equal chance, rolled
once by each Mechanar, Botanica and Arcatraz boss (Harbinger Skyriss, whom
the Arcatraz script summons, included), twice by each Magisters' Terrace
boss and three times by Kael'thas; normal mode only.

**Not built yet: the voidwalker delivery.** A deck has no "use" in the
client (no spell on the item), so right-clicking it does nothing and no
server hook fires. The plan: give each deck a harmless use-spell in its
item row (the item row, spells included, is sent to the client by the
server, so no client patch is needed), catch the use in a Lua item hook,
cancel the spell, and run the voidwalker scene there. Which spell to borrow
decides the "Use:" line players read in the tooltip; it needs a try in game
(see Open Questions).

Stock numbers, for reference. Read from the client's profession tables (SkillLineAbility.dbc,
Spell.dbc) and the world database, 2026-09-24. Inscription has 449
entries; **345 are glyphs**, 155 of them within skill 300.

**What is left within 300 once glyphs are gone** (skill where each
becomes available, approximately):

- **Milling and inks** (the raw materials): Milling; Ivory Ink 15, Moonglow
  45, Midnight 75, Hunter's 85, Lion's 95, Dawnstar 125, Jadefire 145,
  Royal 170, Celestial 195, Fiery 220, Shimmering 245, Ink of the Sky 290,
  Ethereal 295. Most inks exist to feed glyphs.
- **Stat scroll values by rank** (Spell.dbc, stock): Stamina I 3, II 5, III
  16, IV 25, V 34, VI 43, VII 63, VIII 132; Intellect V 21, VI 24, VII 32,
  VIII 48; Spirit V 26, VI 32, VII 40, VIII 64; Agility and Strength V 15,
  VI 20, VII 25, VIII 30; Protection (armor) V 240, VI 285, VII 340, VIII
  750. Required levels: I 1, II 15, III 30, IV 40, V 50, VI 60, VII 70,
  VIII 80.
- **Stat scrolls** (Stamina, Intellect, Spirit, Agility, Strength): ranks
  I (35), II (75–85), III (160–180), IV (210–230), V (255–275); Stamina VI
  at 300, the other VIs at 305–320 (beyond basic's cap). Scroll of
  Protection (armor) is a drop, not crafted. Size at rank V (required level
  50): Stamina +34, Spirit +26, Intellect +21, Agility +15, Strength +15,
  Protection +240 armor. Rank VI (required level 60): +43, +32, +24, +20,
  +20, +285 armor.
- **Scroll of Recall** I (60) and II (215): a teleport scroll.
- **Vellums** for enchanters: Armor Vellum I (75) and II (210), Weapon
  Vellum I (100) and II (250), which hold an enchantment so it can be sold
  or traded. The ranks differ in which enchantments they can hold (item
  descriptions): I only enchantments with no level restriction, II those
  restricted to level 35 or lower, III (skill 355/405, past the cap) those
  restricted to level 60 or lower.
- **Off-hand books**: Mystic Tome, Tome of the Dawn, Book of Survival,
  Tome of Kings, Royal Guide of Escape Routes, Fire Eater's Guide, Book of
  Stars, Stormbound Tome, Manual of Clouds (125–290).
- **Tarot cards and Darkmoon items**: Mysterious, Strange, Arcane and
  Shadowy Tarot, Darkmoon Card (125–290). Each tarot gives a random card of
  one deck; a full deck is handed in at the Darkmoon Faire for a reward:
  Rogues (Mysterious Tarot) → level-10 chest armor (item level 20); Swords
  (Strange) → level-20 shoulders (25); Mages (Arcane) → level-30 necklaces
  (35); Demons (Shadowy) → level-40 weapons (45).
- **The Darkmoon Card recipe (skill 290) is the level-60 trinket path.**
  It creates one random card out of 32: Ace to Eight of Beasts, Warlords,
  Elementals or Portals (the recipe's spell loot table). Using the Ace with
  all eight of one suit in the bags combines them into a deck; the deck
  was handed in at the Darkmoon Faire for an epic trinket, item level 66,
  required level 60: Beasts → Darkmoon Card: Blue Dragon (2% chance on a
  spellcast to keep 100% of mana regeneration while casting for a short
  time); Warlords → Heroism (sometimes heals the bearer when they hit in
  melee); Elementals → Maelstrom (a chance to strike the melee target with
  lightning); Portals → Twisting Nether (10% chance to be able to
  resurrect on death). Burning Crusade and Wrath decks (Blessings, Storms,
  Furies, Lunacy → item level 100 trinkets requiring 70; Prisms, Chaos,
  Nobles, Undeath → item level 200 requiring 80) come from creature drops
  in their own lands, not from this recipe.
- **Binding today**: tarots, all 116 cards and 13 decks never bind; the
  four low-level decks (Rogues, Swords, Mages, Demons) are quest items;
  the trinkets bind when equipped.
- Certificate of Ownership (205); Minor Inscription Research (125), a
  daily that discovers glyphs, pointless without them.

**How scrolls stack today** (the server's spell-stacking groups): **only
one scroll can be active on a character at a time**, whatever its stat
(the "Scrolls" group is exclusive). Each scroll also competes with the
class buff for the same stat, and only the stronger one stays: a Scroll
of Stamina against Power Word: Fortitude, Intellect against Arcane
Intellect, Spirit against Divine Spirit, Strength and Agility against
their class and totem buffs, Protection against other armor buffs. Class
buffs at 60 are larger than rank V or VI scrolls (e.g. Fortitude at 60
gives more Stamina than a +43 scroll), so a buddy who can cast the class
buff makes the scroll worthless.

## Intended Behavior

- No glyphs: every glyph recipe, the glyph research daily, and glyph
  trainers' entries are removed on basic.
- Inscription is a **buff-scroll profession** up to 300: inks, stat
  scrolls, Scroll of Recall, vellums, books and tarot stay.
- **Scrolls stack with class buffs; one scroll per character at a time**
  (Ritz, 2026-09-24). In the server's stacking table: the scrolls leave
  the "stronger one wins" groups they share with class buffs (Single
  Stamina, Intellect, Spirit Buffs; Armor Buffs; Strength and Agility
  Buffs) and stay in the "Scrolls" group, which already allows only one
  at a time.
- **All eight ranks available within 300**, scaled onto levels 1–60 the
  way item levels were (proposal below). Scroll durations can be changed
  per spell through the spell-corrections patch (155i) if a shorter timer
  should balance the stacking (see Open Questions).
- **Scaling**: required levels × 0.75 (I 1, II 11, III 23, IV 30, V 38,
  VI 45, VII 53, VIII 60); skill needed × 300/425 (rank VIII's 405–425
  becomes about 290–300); **stock values kept** (Ritz: "let's keep the
  stock numbers"). With one scroll at a time, a character chooses one of
  them: rank VIII is +132 Stamina **or** +48 Intellect **or** +64 Spirit
  **or** +30 Agility or Strength **or** +750 armor, on top of class buffs.
  Duration stays 30 minutes.
- **Vellum III is craftable within 300** (armor and weapon), so vellums
  can hold the level-60 enchantments enchanters actually use.
- **No Darkmoon Faire; decks summon their reward.** Using a complete deck
  consumes it, draws a small arcane circle on the ground, and a voidwalker
  walks out and says "here... is your item..."; after a couple of seconds
  (for the animation) the reward is put in the player's bags. The deck's
  slot guarantees room. If the player logs out or becomes unavailable
  (enters a battleground, a loading screen) before it arrives, **the deck
  is mailed back** instead, to be used again. Covers the four low-level
  decks, the four level-60 decks and the four Burning Crusade decks; the
  reward is the one the Faire would have given. Where the Faire let the
  player choose (Rogues, Swords, Mages, Demons: two or three items), **the
  voidwalker offers the choice** before handing it over.
- **Burning Crusade deck trinkets** (Crusade, Wrath, Vengeance, Madness,
  item level 100) **require level 60** on basic, like other Outland gear.
- **Burning Crusade cards from dungeon bosses**: each boss of the Tempest
  Keep dungeons (Mechanar, Botanica, Arcatraz) drops one random card of
  the 32 (Ace to Eight of Blessings, Storms, Furies, Lunacy); each
  Magisters' Terrace boss drops two, and **Kael'thas drops three** (Ritz,
  2026-09-24: "three. He's the highest level boss in the game!"). Their stock drops from Outland
  creatures stay.
- **Nothing Darkmoon ever binds**: tarots, cards, decks (the four
  quest-item decks included) and every reward a deck gives, the trinkets
  (all 15) and the low-level armor, necklaces and weapons alike.

## Suggested Implementation Steps

1. A generator removes glyph recipes (trainer rows and recipe items) and
   the research spell; revert restores them.
2. Scroll stacking and strength per the answers below (spell-stacking
   table rows and, if needed, the scroll spells' values through the
   spell-corrections patch, 155i).
3. Test: a level-60 scribe crafts every remaining recipe up to 300; a
   character carries several scrolls at once if the stacking change is
   made.

## Related Issues

- **155** parent; **155n** tradeskills capped at 300
- **155i** spell changes (for scroll values)

## Open Questions

- Voidwalker delivery: which existing spell should a deck borrow as its
  "Use:" (its tooltip text shows)? It must be castable by anyone with no
  reagent, and the Lua hook cancels it. Needs a try on a running server.

- (Answered 2026-09-24) Choice offered by the voidwalker; the deck, not
  the item, is mailed on interruption; nothing from a deck binds; Burning
  Crusade trinkets at 60 through the voidwalker; card drops from Tempest
  Keep (1) and Magisters' Terrace (2) bosses, Kael'thas 3.
- Keep the off-hand books, or trim?
- (Answered 2026-09-24) Stock scroll values; 30 minutes; Vellum III at
  300; voidwalker delivery; Darkmoon items never bind; scrolls stack with
  class buffs, one per character, all ranks available and scaled.
