# 182 - Legendary Items

## Status
- Created: 2026-10-08
- Phase: 1
- Profile: basic
- Related: 181 (richer monster drops), 178 (experience: fight above your
  level), 179 (the hearthstone network), 617 (buddies), 617l (the clan),
  617t (stand-ins), 718 (Sargobras and the souls), 617e12 (the town rule,
  and the owner's red notebook)
- Priority: Low

## Origin

The owner, 2026-10-08: "Did you say we can create items? I think we
should make legendary items. Can we design some just for fun?"

### The owner's answers, 2026-10-08

First, the whole design:

> we should make all legendaries only findable if the searcher is a low
> level, but require a very high level, so they are encouraged to trade it
> to a friend. Can you take all the legendary items up until WotLK
> including Shadowburnfury or whatever it's called, and scale them down to
> level 60? Use the other items at that level as reference, like Ashbringer
> and Thunderfury. The stats for Ashbringer are correct. Remember, found by
> low level, must be traded to high level, disappears when the bearer
> reaches the required level. Upon pickup and at login, this message is
> delivered again. This should force them to have to trade it to someone
> who's already that required level. We should have a discrete scaler that
> allows them all to be heirlooms. So, randomly chosen, if it requires
> level 44... then a level 44 could equip it, and suddenly it's an heirloom
> that grows with them and can be traded to their clanmates or other
> toons. No exp bonuses. Stat value roughly equivalent to a blue.
> Unsellable, because if you try they get snatched into the void
> dimension, ready for you to claim a single copy of them from some
> aetheric wind-trader who lives in one capital city per side. Gnomeregan
> as well, and Halaa if you ever capture it.

Then, for now:

> the legendary items should be the legendaries that already are in the
> game files, for now. They should scaled like heirlooms, including their
> secondary effects. If that requires a client patch to properly display
> the tooltips, then we will wait on that feature. They won't scale like
> heirlooms, they will simply be available as rare drops at level 60, and
> require level 60, and we can put the "noobie giving to an elder" thing on
> hold as well, until we can do the custom client.

On finding them: "small drop from everything. If that's just... too much
sql, then we can say they are high level vanilla raid drops, from an
appropriate raid boss. They should be rare, about 1 in 10 kills has even
one." And: "1 in 10 kills has even one per raid."

So, now: **the game's own legendaries, scaled to level 60, rare raid
drops.** On hold until the custom client: found only by low levels,
required level drawn at random, gone when the finder reaches it, the
heirloom scaling, the void and the aetheric wind-trader. The six designs
first drawn up for this issue (the Everland Ghostsong, the Hauberk of the
Last Stand, Sargobras's Ledger, the Red Notebook, the Hearthstone of Every
Home, the Banner of the Unbroken Clan) are set aside, kept below for
later.

Later the same day:
- **Effects scaled now, tooltips wrong for a while**: "scale them now and
  accept bad tooltips. They will get fixed automatically when custom
  tooltips are implemented."
- **The lent weapons left out**: "we probably don't want to spawn
  kael'thas's weapons. Or Andonisus, it seems op." Checked: Kael'thas's
  weapons deal 122 to 159 damage a second (Sulfuras 80) with item-level-175
  stats and vanish after 15 minutes; Andonisus is near Sulfuras in damage
  (81) but carries a spell-power effect made for one fight, and vanishes
  after 10. They could be scaled like the rest; the owner leaves them out.
- **From any boss, once in ten runs**: "any from all, not just end bosses.
  once in ten runs. Gives reason to run lower level raids." Every boss of
  every vanilla raid can drop any of them, at chances that give about one
  legendary per ten runs of that raid.

- **New items, originals untouched**: "follow your instincts and leave
  the originals untouched." The level-60 versions are new rows from
  1,820,001; the stock items stay as they are.
- **Atiesh: one drop that becomes the right staff**: "we could drop a
  dummy item that, upon being looted, automatically transforms into the
  correct variant of the four." A single "Atiesh" drops; when a character
  loots it, it is replaced by the version for that character's class (the
  four stock versions are the mage's, warlock's, priest's and druid's:
  22589, 22630, 22631, 22632, to be confirmed from their effects; all four
  allow every class in the item data, the class tie being the stock
  questline's).

## Current Behavior

**2026-10-08: built, not yet installed** (install step E054, basic).
`scripts/generate-basic-legendaries-sql` writes
`sql/basic/db_world.src/35-legendaries.{apply,revert}.sql`:
- **Six new items**: Atiesh's generic staff (1820001, unbound, turned into
  the looter's version by `src/lua-basic/legendaries.lua`), and level-60
  copies (required level 60, item level 80) of the Warglaives (1820002,
  1820003), Thori'dal (1820004), Val'anyr (1820005) and Shadowmourne
  (1820006). Stats are scaled by item level (80 over the original's); a
  stat the original carried as a shared spell ("Attack Power 44") becomes
  an ordinary stat, scaled; weapon damage matches the best level-60 weapon
  of its kind that players can get (Warblade of the Hakkari, Grand
  Marshal's Bullseye, Aurastone Hammer, Dark Edge of Insanity).
- **Four effects scaled in place** in `spell_dbc` (each used by one item
  only, so the server's scripts for them keep working): the Warglaives'
  set haste 450 to 231, Shadowmourne's Chaos Bane 1900 to 535 damage and
  270 to 76 strength, its Soul Fragment 30 to 8. Val'anyr's absorb is a
  share of the heal, nothing to scale; its second spell (68496) is a
  server-made spell, left as it is.
- **One shared roll** on 42 bosses of Zul'Gurub, Molten Core, Blackwing
  Lair and both Ahn'Qiraj raids (from the game's encounter list), picking
  any of nine (Thunderfury, Sulfuras and Ashbringer as they are, and the
  six above), at 1.05% to 1.74% a boss so a whole run finds one 10% of the
  time. Majordomo Executus drops a chest, not loot of his own: no roll.
`scripts/test-basic-legendaries` (37 checks): the numbers; the SQL
applied twice and reverted on session-only copies of the real tables;
the Atiesh swap for every class, and with full bags.

Install step E054 was run for basic on 2026-10-08 (the owner); it takes
effect at the worldserver's next start.

**Next, asked 2026-10-08: scaling with your gear.** "how about for the
legendaries we make them level 80, item level, but they scale to 120,
according to the highest ilevel item you have equipped at the time?" A
legendary would start at item level 80 and rise to 120, following the
highest item level among the wearer's other equipped items. The stock
heirloom scaling follows the character's level, not its gear, so this is
the server's own work: when gear changes, the legendary's stats (and
damage, and effects: open question 7) recalculated and applied as a
hidden bonus, the stock tooltip showing the item-level-80 numbers.

Before this, not built. The world database's legendary (orange) weapons and pieces,
read 2026-10-08 (item level, required level):

| Era | Item | Entry | Item level | Requires |
|---|---|---|---|---|
| vanilla | Thunderfury, Blessed Blade of the Windseeker | 19019 | 80 | 60 |
| vanilla | Sulfuras, Hand of Ragnaros | 17182 | 80 | 60 |
| vanilla | Ashbringer (a game-master item; "the stats for Ashbringer are correct") | 13262 | 76 | 60 |
| vanilla | Atiesh, Greatstaff of the Guardian (four, one per class group) | 22589, 22630, 22631, 22632 | 90 | 60 |
| vanilla | Andonisus, Reaper of Souls (lent for the Kel'Thuzad fight) | 22736 | 100 | 60 |
| vanilla | Glaive of the Defender | 23051 | 86 | 60 |
| TBC | Warglaive of Azzinoth (main hand, off hand) | 32837, 32838 | 156 | 70 |
| TBC | Thori'dal, the Stars' Fury | 34334 | 164 | 70 |
| TBC | Kael'thas's weapons (lent for his fight: Warp Slicer, Infinity Blade, Staff of Disintegration, Phaseshift Bulwark, Devastation, Cosmic Infuser, Netherstrand Longbow, Nether Spike) | 30311-30319 | 175 | 70 |
| WotLK | Val'anyr, Hammer of Ancient Kings | 46017 | 245 | 80 |
| WotLK | Shadowmourne ("Shadowburnfury or whatever it's called") | 49623 | 284 | 80 |

Thunderfury and Sulfuras are crafted from raid drops; Atiesh from
splinters (Naxxramas); the TBC and WotLK ones drop or are built at their
own level, far above basic's 60.

## Intended Behavior

- **Scaled to level 60.** Each legendary above level 60 gets a level-60
  version: required level 60, item level that of vanilla's legendaries
  (80, as Thunderfury and Sulfuras; Atiesh's 90 the ceiling), its stats
  brought down by the game's own stat budget for that item level and slot,
  its weapon damage matched to the vanilla legendaries of its kind (a
  two-hander to Sulfuras and Ashbringer, a one-hander to Thunderfury, a
  bow to the best vanilla bows). Ashbringer's stats stand as they are.
- **Their effects scaled too** ("including their secondary effects"): a
  proc's damage, healing or chance brought to level 60. The tooltip text
  is the client's, so scaled effects wait for the custom client if the
  stock client would describe them wrongly (open question 1).
- **Rare raid drops, from every boss.** Any legendary from any boss of
  any vanilla raid (Molten Core, Onyxia, Blackwing Lair, Zul'Gurub, Ruins
  and Temple of Ahn'Qiraj, Naxxramas), the chance per boss set so a whole
  run of a raid sees one about one time in ten. The lent weapons
  (Andonisus, Kael'thas's eight) are left out.

## Suggested Implementation Steps

1. A script reading the legendaries from the world database and writing
   their level-60 versions: stats by item budget, weapon damage by the
   vanilla references, as new rows (from 1,820,001) or changed originals
   (open question 3); an install step for basic.
2. Atiesh's dummy: one new item in the shared loot group; a Lua loot
   event replaces it with the looter's class's version.
3. Their drops: one shared loot group (every legendary, equal chance) on
   every vanilla raid boss, its chance per boss set from the raid's boss
   count so a full run gives about 10% (for a raid of n bosses, 1 - 0.9^(1/n)
   per boss).
3. Effects scaled now through the server's own spell data (the server
   reads its own copy of the spell table; the stock client's tooltips will
   state the old numbers until the custom client's own tooltips).
4. A test: every level-60 version requires 60, sits at or below item
   level 90, and has weapon damage within the vanilla references' range.

## Open Questions

1. (Answered 2026-10-08: scale now, tooltips fixed by the custom client) **Effects now or later:** keep each legendary's stock effect as it is
   (Shadowmourne's soul fragments, Val'anyr's shields, Thori'dal's endless
   arrows: strong at 60), switch them off until the custom client can show
   scaled ones, or scale them now and accept stock tooltips that state the
   old numbers?
2. (Answered 2026-10-08: any from all bosses, once in ten runs) **Which boss drops which:** for example Sulfuras and Thunderfury's
   parts staying as they are in Molten Core, Atiesh from Kel'Thuzad, the
   Warglaives from Nefarian, Thori'dal from C'Thun, Val'anyr and
   Shadowmourne from Kel'Thuzad or Ragnaros? And "1 in 10 per raid": one
   roll at the raid's last boss, or spread over its bosses?
3. (Answered 2026-10-08: new rows, originals untouched) **New rows or the originals changed:** new level-60 copies (the
   originals untouched, as the patch system prefers) or the original
   entries edited?
4. (Answered 2026-10-08: left out) **The lent weapons:** Andonisus and Kael'thas's eight vanish outside
   their fights in the stock game. Include them as real legendaries, or
   leave them out?
5. (Answered 2026-10-08: one dummy drop, turned into the looter's
   class's version on loot) **Atiesh's four versions.**
6. (Answered 2026-10-23: never offered to them) "never appear to them at all. Legends only come to those who will use them." So a class Atiesh has no version for is left out of its loot roll entirely; only mages, priests, warlocks and druids are offered it. **Atiesh looted by a class it doesn't fit:** a warrior, rogue, hunter,
   paladin, shaman or death knight loots the dummy. It stays a dummy that
   can be traded to a caster (and turns when that caster takes it), or
   it turns into one of the four at random, or it isn't offered to them in
   the loot roll at all?

## Set aside: six designs for this server

Drawn up 2026-10-08 before the owner chose the game's own legendaries;
kept for later. Level 60, legendary, each tied to something only this
server has.

1. **Everland Ghostsong** (staff, two hands): each kill of a monster above
   your level stores a verse (at most five); talking to a townsperson
   sings them, each giving the whole clan a bar of rested experience.
2. **Hauberk of the Last Stand** (plate, chest): below 20% health, damage
   taken halved and attacks heal for a share of their damage, 10 seconds,
   once every two minutes.
3. **Sargobras's Ledger** (off-hand tome): monsters five or more levels
   above you killed are written in as souls; ten souls call a stand-in to
   fight beside you for two minutes.
4. **The Red Notebook** (trinket), after the owner's "distance spectrum
   wheel iron isotope in red notebook" (617e12): for 20 seconds you and
   your buddies take the nearest thing, and each new target within 10
   yards adds 5% haste, stacking to five.
5. **Hearthstone of Every Home**: network stones (179) free, cooldown 15
   minutes.
6. **Banner of the Unbroken Clan** (cloak): three or more clanmates within
   30 yards each take 5% less damage; a buddy dying in that ring returns
   after 30 seconds at half health, once every five minutes.
7. **Scaling with gear (80 to 120):** answered in part 2026-10-08: stats,
   weapon damage and effects all follow ("both"); the legendary itself and
   other legendaries are left out of "highest item level equipped"
   ("yes"); recalculated when an item is equipped ("we can check for
   scaling the legendary upon equipping an item. Or maybe when equipping a
   legendary item?": equipping any item covers both). Still open: the step
   (each item level, or every 5 or 10), and whether the level-60 versions
   built today are replaced by item-level-80 ones that rise.
