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

## Current Behavior

Not built. The world database's legendary (orange) weapons and pieces,
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
2. Their drops: one shared loot group (every legendary, equal chance) on
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
3. **New rows or the originals changed:** new level-60 copies (the
   originals untouched, as the patch system prefers) or the original
   entries edited?
4. (Answered 2026-10-08: left out) **The lent weapons:** Andonisus and Kael'thas's eight vanish outside
   their fights in the stock game. Include them as real legendaries, or
   leave them out?
5. **Atiesh's four versions:** all four drop (each for its classes), or
   one?

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
