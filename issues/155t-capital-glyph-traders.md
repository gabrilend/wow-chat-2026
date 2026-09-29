# 155t - Capital Glyph Traders

## Status
- Created: 2026-09-26
- Phase: 1
- Parent: 155
- Blocked by: 155o (glyphs removed from Inscription), 155p (the gem supply
  that pays for them)
- Priority: Medium
- Planned only: not to be built yet (owner, 2026-09-26: "We can just plan
  issue files for these, we don't have to build them yet").

## Origin

Verbatim, 2026-09-26:

> Can we add a vendor in the capital cities near the leaders of that town
> that sells glyphs in exchange for gems? [...] Minor gems for minor glyphs.

Answers, verbatim, 2026-09-26:

> how about we pick TBC and WotLK badges and make a second NPC that trades
> gems for badges? We should have one badge type per faction, and it should
> be more faction themed than "Badge of Valor" or whatever. But not the PvP
> badges. Anyway low level gems give fewer badges, and the badges can be
> used for the glyphs.

> [glyphs above 60:] Can we change the level requirement?

> [what is a minor gem:] No, do it by level. So tigerseye and malachite
> might give 1 gem each, while an arcane crystal might be 15. A glyph might
> cost a thousand badges. Only do the Azeroth gems, the ones that aren't
> used for jewelcrafting into cut gems.

> [major glyphs too:] yes.

> [price:] let's say 1000 for minor, 2000 for major?

> [battleground marks as a second price:] nah just gems.

Second round, verbatim, 2026-09-26:

> Also, can we make it so that players have 3 minor and 3 major glyph slots
> from the start?

> [Badge of Justice leaking in from Outland heroics:] we can't do any
> Outland heroic dungeons so that's alright. Can you give me a
> categorization of the potential currencies? Maybe an HTML document that
> shows their icons and name?

> [renaming:] oh, can we rename them? That helps a lot. I'm assuming we
> can't change the picture though, right?

> [the gem curve:] yeah that's fine I think.

> [glyph levels:] set the required level to 1, or just remove the
> requirement. Make them BoP too. Buddybots should ignore glyphs for now,
> we can swing back around later for them.

Third round, verbatim, 2026-09-26:

> [glyphs priced in honor, which a normal vendor window can show:] I don't
> think we should exchange honor for gems. I think gems should give you
> honor, because you brought them to a safe place.

Read: gems are turned into **honor**, and the glyph trader becomes an
ordinary vendor selling glyphs for honor. The client's price list holds an
honor-only price of exactly 1000 (a minor glyph) but not 2000; the nearest
for a major glyph are 1600, 2400 and 2500 (read 2026-09-26 from
ItemExtendedCost.dbc). With honor as the price, the two faction badges
are no longer needed.

Fourth round, verbatim, 2026-09-26:

> [where gems become honor:] what if we get them for selling to the goblin
> auction houses? Whenever gems are put on the AH they're instantly bought
> (from the goblin auction houses) and you get a lua script to deliver them
> some honor. It's always different each time, +/- about 5-15%. that's
> plus or minus 5 to fifteen percent, which provides two oscillating
> points, just above and around the true value of the item. It's chosen
> randomly, but some say the goblins keep a secret hidden honor score, and
> they request the warchiefs of the horde reward you more.

> the reason you get honor for selling to the goblins is because they help
> everyone, and the more gems you sell them, the more they'll help your
> faction. Practical business. Hence, honor points from the kingdom and
> warband, used for ceremonial armor for the sportiest of fights. PvP and
> it's gear. They are honors.

Fifth round, verbatim, 2026-09-26:

> [the hidden honor score:] it's just honor points.
> [a gem's honor, the badge curve?] no honor stacks up to 2400 - it should
> be about 10x that amount.
> [which gems:] Azeroth gems. For now.
> [honor replaces the badges, 2400 or 2500?] What was the number I said
> before? Can you print the table and the target number(s)?

Sixth round, verbatim, 2026-09-26:

> the fractional amount we should round down to 1 decimal point, store it
> in a single byte integer in sql, and add it to the player's price next
> time they sell a gemstone. Essentially, keeping the remainder between
> frames.
>
> also it should return the deposit price because that way the user
> doesn't have to type 1c each time.

> [a major glyph at 2000 honor:] that seems really really low to me.

Seventh round, verbatim, 2026-09-26:

> I think those prices are still pretty low. Maybe 33,333 for a minor and
> 77,777 for a major?

> [the honor cap:] can we make that cap unlimited? it exists because of the
> patch cycle, which we don't really have.

## Current Behavior

Nothing built. On basic, glyphs have no source:

- **155o** removed every glyph and glyph-research recipe from Inscription,
  which is now a buff-scroll profession. The glyph items themselves are
  untouched in the world database (item class 16), and the client still
  has its glyph slots and glyph window.
- **Glyph slots at basic's cap of 60** (stock 3.3.5 unlock levels): major
  at 15 and 30, minor at 15 and 50. The other two (minor 70, major 80) are
  out of reach.
- **Glyph items**, counted 2026-09-26 from the world database and the
  client's Spell.dbc / GlyphProperties.dbc: every class has 6 to 8 minor
  glyphs and 27 to 31 major ones. Some need a level above 60 (the level on
  the item), which basic can't use; death-knight glyphs all need 55.
- **Gems** on basic are 155p's supply (gems below skill 300, socket bonuses
  of our choosing).
- **Badges**, read 2026-09-26: the Burning Crusade Badge of Justice and
  the Wrath emblems (Heroism, Valor, Conquest, Triumph, Frost) are
  currencies: they sit in the currency tab, not in bags, and stack without
  limit. The tab is a client list of item ids, so a brand-new item would
  take bag space; reusing a stock badge keeps the tab. On basic, Badges of
  Justice drop in Outland's heroic dungeons (155f leaves heroics stock);
  Conquest, Triumph and Frost come only from Northrend raids, which basic
  keeps closed (155s).
- **Glyph slots** are switched on by level in the server
  (`Player::InitGlyphsForLevel`: two at 15, one at 30, one at 50, one at
  70, one at 80), written into a player field the client reads to enable
  its sockets. Applying a glyph checks only that the slot is switched on,
  not the level, so switching all six on from level 1 needs one small
  source patch and no client change (read 2026-09-26).
- **The currency tab's items**, catalogued 2026-09-26 with their icons in
  the "Badge Quartermaster" page (https://claude.ai/artifact/AgiUR5wLjZKq9BTHDjBfYF,
  built from the client's CurrencyTypes.dbc, CurrencyCategory.dbc and
  ItemDisplayInfo.dbc and the world database): 26 entries in four client
  categories (Dungeon and Raid, Miscellaneous, Player vs. Player, Unused).
  Six are unused test or placeholder entries (three "Currency Token Test
  Token"s, a test item, a retired daily token, a placeholder) with no
  source anywhere in the game.
- **Renaming and re-picturing**: an item's name and its picture (the
  display id, which names an icon) are both fields on the item in the
  world database, and the client takes them from the server. So a badge
  can be renamed and can wear **any icon the client already holds**; only
  a picture the client doesn't have is impossible without a client patch.
- **Vendors can't charge gems the stock way.** A vendor price in items
  (honor, marks, badges) is an "extended cost" row in ItemExtendedCost.dbc,
  a client file; basic makes no client patches, and none of the stock rows
  charges gems. The project's answer to this already exists: the titan
  jewelers of 155p trade through a talk menu in a Lua script (hand over the
  gem, receive the item; `src/lua-basic/titan-jewelers.lua`).

## Intended Behavior

Two NPCs beside each of the eight capitals' leaders: Stormwind (King Varian
Wrynn's throne room), Ironforge (King Magni Bronzebeard, the High Seat),
Darnassus (Tyrande Whisperwind, the Temple of the Moon), the Exodar
(Prophet Velen, the Vault of Lights), Orgrimmar (Thrall, Grommash Hold),
Undercity (Lady Sylvanas Windrunner, the Royal Quarter), Thunder Bluff
(Cairne Bloodhoof, his lodge on the central rise), Silvermoon (Lor'themar
Theron, Sunfury Spire).

- **Honor per gem is ten times the badge curve** (2026-09-26), Azeroth gems
  only for now; the "secret honor score" is simply honor points:

  | Item level | Gems | Honor |
  |---|---|---|
  | 7, 15 | Malachite, Tigerseye, Small Lustrous Pearl | 10 |
  | 20 | Shadowgem | 30 |
  | 25 | Moss Agate, Iridescent Pearl | 40 |
  | 30 | Lesser Moonstone | 60 |
  | 35 | Jade | 70 |
  | 40 | Citrine, Black Pearl, Golden Pearl | 90 |
  | 45 | Aquamarine | 100 |
  | 50 | Star Ruby, Souldarite, Blood of the Mountain | 120 |
  | 55 | Blue Sapphire, Large Opal | 130 |
  | 60 | Arcane Crystal, Huge Emerald, Azerothian Diamond | 150 |

  Each sale is moved 5-15% up or down at random.
- **The remainder carries over** (owner, 2026-09-26): honor is paid in
  whole points; the fraction left from a sale, rounded down to tenths, is
  kept per player in the characters database as one byte (0-9 tenths) and
  added to that player's next gem sale.
- **The auction deposit is refunded** with the sale, so a seller needn't
  set a starting price of 1 copper each time.
- **Glyph prices, the owner's numbers** (2026-09-26, first given in
  badges): 1000 a minor glyph, 2000 a major. In honor: a minor glyph is
  about 100 Tigerseyes or 7 Arcane Crystals; a major, 200 or 14. The
  client's honor-only prices include 1000 exactly but not 2000 (the
  nearest are 1600, 2400 and 2500).
- **Gems become honor at the goblin auction houses** (owner, 2026-09-26,
  replacing the badge exchanger below): a gem listed on a neutral (goblin)
  auction house is bought at once, and the seller receives honor, the
  gem's value moved up or down by a random 5 to 15 percent each sale ("two
  oscillating points, just above and around the true value"). The honor
  comes "from the kingdom and warband": the goblins help everyone, and the
  more gems a faction sells them, the more they help it.
- *(Superseded 2026-09-26, kept for the record)* **The badge exchanger**
  takes Azeroth gems and pays the city's faction badge. Only the raw Azeroth gems basic's Jewelcrafting doesn't cut (155p
  makes cut gems come pre-cut from prospecting, and cuts only Outland and
  Wrath raws): Malachite, Tigerseye, Shadowgem, Moss Agate, Lesser
  Moonstone, Jade, Citrine, Aquamarine, Star Ruby, Blue Sapphire, Large
  Opal, Huge Emerald, Azerothian Diamond, Arcane Crystal, the pearls
  (Small Lustrous, Iridescent, Black, Golden), Souldarite and Blood of the
  Mountain; the exact list is drawn by a generator from what basic's cutting
  recipes don't use.
- **Badges per gem go by the gem's level**: 1 for Malachite (item level 7)
  and Tigerseye (15), up to 15 for Arcane Crystal (60). Proposed curve, one
  straight line through the owner's two examples: badges = 1 + (item level
  - 15) x 14/45, rounded, at least 1:

  | Item level | Gems | Badges |
  |---|---|---|
  | 7, 15 | Malachite, Tigerseye, Small Lustrous Pearl | 1 |
  | 20 | Shadowgem | 3 |
  | 25 | Moss Agate, Iridescent Pearl | 4 |
  | 30 | Lesser Moonstone | 6 |
  | 35 | Jade | 7 |
  | 40 | Citrine, Black Pearl, Golden Pearl | 9 |
  | 45 | Aquamarine | 10 |
  | 50 | Star Ruby, Souldarite, Blood of the Mountain | 12 |
  | 55 | Blue Sapphire, Large Opal | 13 |
  | 60 | Arcane Crystal, Huge Emerald, Azerothian Diamond | 15 |

- **One badge per faction**, a renamed currency-tab item wearing a
  faction icon of the owner's choosing (both picked on the Badge
  Quartermaster page; open question below).
- **The glyph trader** sells every glyph of the player's class, minor and
  major, for the faction badge: **1000 badges a minor glyph, 2000 a
  major**. Gems only reach it through badges (no battleground marks).
  At the table above that is, for a minor glyph, 1000 Tigerseyes or about
  67 Arcane Crystals.
- **Every glyph: required level 1, and bind on pickup** (owner, 2026-09-26:
  "set the required level to 1, or just remove the requirement. Make them
  BoP too"). The level and binding are fields on the item in the world
  database; the client learns the new values once its item cache is
  renewed, which C025 does on every install. A glyph for an ability a
  character doesn't have does nothing, harmlessly.
- **All six glyph slots, three major and three minor, open from level 1**
  (owner, 2026-09-26), by a source patch to the server's slot switch (see
  Current Behavior).
- **Buddies ignore glyphs** for now (owner, 2026-09-26: "we can swing back
  around later for them").
- Both NPCs trade through a talk menu (as the titan jewelers do): the
  exchanger takes every gem of one kind from the bags at once; the glyph
  trader's menu is paged, since a class has up to 31 major glyphs.
- Inscription still makes no glyphs (155o stands).

## Suggested Implementation Steps

1. A generator (LuaJIT, `scripts/generate-basic-glyph-trader-data`):
   glyphs per class with their minor/major type (item spell -> the spell's
   glyph effect -> GlyphProperties.dbc) and level; the exchange gems (raw
   gems of Azeroth item level 60 and below that no basic cutting recipe
   uses) with their badge price from the curve above. Writes
   `src/lua-basic/data/glyph-trader-data.lua` and the glyph level SQL.
2. SQL for basic (`sql/basic/db_world.src/`, a new install step, apply and
   revert): two creature templates, sixteen spawns beside the leaders;
   the two faction badges (two currency-tab items renamed and given the
   chosen icons); every glyph's level set to 1 and its binding to bind on
   pickup. Checked by
   `scripts/test-basic-sql-in-ram` and `scripts/validate-basic-state`.
3. `src/lua-basic/glyph-traders.lua`: both talk menus, prices in one table
   at the top, full-bag refunds.
4. A source patch (B-patch, basic's list) making the glyph-slot switch
   turn on all six slots at every level; `scripts/test-source-patches`
   and `scripts/test-patched-syntax`.
5. A test: every class has at least three minor and three major glyphs;
   every exchange gem has a price; no cut gem is on the list.

## Related Issues

- **155** parent
- **155o** inscription without glyphs (why glyphs need a new source)
- **155p** sockets and the gem supply (the price)
- **155u** battleground rewards (the owner chose gems only here, not
  battleground marks)

## Open Questions

- (Answered 2026-09-26) Minor/major gems: neither; badges by gem level,
  Azeroth uncut gems only. Major glyphs: sold too. Price: 1000 badges a
  minor glyph, 2000 a major. Marks: no, gems only. The gem curve: fine.
  Glyph level: 1, bind on pickup. Slots: three and three from level 1.
  Buddies: ignore glyphs. Badge of Justice leaking from Outland heroics:
  not a concern (no Outland heroics on basic).
- **Which item and icon for each faction's badge, and their names**: the
  Badge Quartermaster page lists the candidates and lets the owner pick
  both icons and names, with a button that copies the choice. The page
  recommends the unused currency-tab entries (no source anywhere), which
  also keeps the Badge of Justice and the emblems free for anything later.
- (Answered 2026-09-26) Where gems become honor: sold on the goblin
  auction houses, bought at once, paid in honor.
- (Answered 2026-09-26) The goblins' score is just honor; honor per gem is
  ten times the badge curve (table above); Azeroth gems only, for now.
- **Glyph prices: 33,333 honor a minor glyph, 77,777 a major** (owner,
  2026-09-26, replacing the 10,000 / 20,000 below). Neither is an honor
  price the client's vendor window holds, so the glyph trader sells
  through a talk menu (as the titan jewelers trade), taking the exact
  amount. A minor glyph is then about 222 Arcane Crystals' worth of honor,
  a major about 519. Honor has no cap on basic (C028, built 2026-09-26:
  `MaxHonorPoints` raised to 2,147,483,647, checked by
  `scripts/test-profile-config-gates`).
- *(Superseded 2026-09-26)* **Glyph prices, raised** (owner: 2000 "seems really really low"):
  proposed ten times the badge prices, in step with honor per gem being
  ten times the badge curve: **10,000 honor a minor glyph, 20,000 a
  major**, the original badge plan's ratio (a minor glyph for 1000
  Tigerseyes or about 67 Arcane Crystals). Both are honor-only prices the
  client's vendor window already holds (read 2026-09-26), so the glyph
  trader can be an ordinary vendor. Honor's cap is 75,000 (a config
  setting). **Agreed 2026-09-26 ("okay").**
