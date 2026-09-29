# 155u - Battleground Rewards

## Status
- Created: 2026-09-26
- Phase: 1
- Parent: 155
- Blocked by: none for the planning; the chosen rewards decide the rest
- Priority: Medium
- Planned only: not to be built yet (owner, 2026-09-26).

## Origin

Verbatim, 2026-09-26:

> Also, what options do we have for giving rewards to players who
> participate in battlegrounds? [...] We can just plan issue files for
> these, we don't have to build them yet.

Answers, verbatim, 2026-09-26:

> [marks at the glyph traders:] nah just gems.

> [buddy share:] buddies keep their rewards, but when a clanmember
> prospers, they all prosper.

> [loot bags:] we shouldn't have loot bags, instead preferring vendors that
> sell the same items. My recollection is that these items have random
> enchantment suffixes, so when they're bought we should (with a script)
> apply a random enchantment to them.

> [PvP rank ladder:] I don't think we should use this system for now. We
> can return to it later, but it mostly focused power at the top and
> required a lot of time commitment consistently. That's not really what I
> want to emphasize with this project, I want to build something you can
> return to when you have time. Your clan will be there for you.

> [experience:] how about experience for kills, and we remove experience
> every time you die? One death = one experience. To encourage people to
> try. Also, we should give like... 10x the amount that they give stock.
> Buddy bot kills are worth 5x, both positive and negative.

Second round, verbatim, 2026-09-26:

> [does a death cost what the killing blow paid, and can it de-level:]
> stops at the start of the level, but you don't give experience when
> slain. And yes the killing blow is the cost. Direct experience point
> transfer, mwahahaha
>
> (that won't get abused at all...) hey it's a zero sum game so someone's
> gotta level up somewhen anyway.
>
> "they'll just transfer from buddy bots" maybe that's true, idk.

> [buddy kills 5x:] (b) a buddy's own kills pay the buddy 5x, and its
> deaths cost it 5x.

> [clan prosperity:] that's more of a meta observation.

> [bracket vendors, which items:] just the ones from the loot bags that
> drop already.

Third round, verbatim, 2026-09-26:

> can we make it so if you wanna join a battleground you gotta go to the
> battleground and talk to the battlemasters? We shouldn't have them at the
> capital cities, just out in the world. This means buddy-bots will have
> to walk to them when the player does, almost ensuring they won't be in
> the same battleground. But sometimes it'll happen, especially if they all
> gather for it.

> the horde should pay you in gold bars. Nothing else. Just gold bars. So
> the reward for battlegrounds, instead of an item, it's gold bars. These
> can be exchanged with just about anyone for gold from a vendor, but
> they're primarily used for turning in for [something I haven't decided
> yet].

> [2026-09-26, later:] oh fighting in a battleground, the kingdom pays you
> in gold bars as well.

Fourth round, verbatim, 2026-09-26:

> [gold bars per match:] I think 1 gold coin is about 6000$, and I think
> gold is more plentiful in Azeroth than here. So let's say that you get as
> many as are on the icon (how many it stacks to) let's say 3 for now.
> Maybe 6, for 6 thousand. but, since gold is cheap in Azeroth, and they
> use it as coins... Maybe their coins are the size of dimes? OH THAT MAKES
> SENSE. right so a gold bar is worth about 1000$ in this game... wink

> [stock honor and marks:] players get honor from fighting in
> battlegrounds I think. The marks should be kept so we know where you were
> fighting, but we might lower the cost of the items they provide because
> there's more honor to compensate, from gems sold to goblins. Because the
> goblins are aiding and assisting. But, with no influx of marks of
> honor... might just need to double the honor cost of all equipment.
> HMMMM maybe terrible idea?

> [which battlemasters stay:] the ones outside of the battlegrounds

> [the gold bar's stack:] 6

Fifth round, verbatim, 2026-09-26:

> [3 gold bars a match:] it's determined by your participation - honor
> gained. If you're in the top 1/3rd, you get 3. Middle 2/3rd, you get 2,
> bottom 1/3rd you get one. Really it's for every third, you get a gold
> bar.

Sixth round, verbatim, 2026-09-26:

> [a gold bar's worth:] let's make it 4g for each gold bar. You can buy
> them for 6g from the shop, but only ever with limited quantity. These
> shops are like, the wandering goblins and such. Traders that travel the
> road might have them. Also they're sometimes found in chests.

## Current Behavior

Nothing custom. What the stock server gives, read 2026-09-26 from
`worldserver.conf.dist` and the world database:

- **Battlegrounds open on basic** (cap 60): Warsong Gulch (from 10),
  Arathi Basin (from 20), Alterac Valley (from 51). Eye of the Storm,
  Strand of the Ancients and Isle of Conquest start above 60.
- **Honor**: every match pays honor to both sides, more to the winner, with
  a bigger bonus for the first win of the day (config
  `Battleground.RewardWinnerHonorFirst` / `...Last`, `RewardLoserHonor...`,
  `Rate.Honor`). The capital honor vendors sell level 70 and 80 gear,
  unusable at 60.
- **Marks of Honor**: one item per battleground (Warsong Gulch, Arathi
  Basin, Alterac Valley Mark of Honor), given for matches.
- **Supply officers**: eight faction vendors (two per battleground side,
  such as Illiyana Moonblaze and Kelm Hargunth for Warsong Gulch) sell
  gear for levels 10 to 60 for honor or marks, some gated by the
  battleground faction's reputation. This is stock gear already sized to
  basic's levels.
- **Experience**: none for kills (`Battleground.GiveXPForKills = 0`).
- **Reputation** with each battleground's faction, from objectives.
- **Buddies** join their owner's queues (617i), so what a match pays
  matters for bots too.
- **Random suffixes are already rolled on purchase**: every newly made
  item gets a random enchantment when its template has random properties
  or suffixes (`Item::CreateItem`, which vendor purchases use, read
  2026-09-26), so a bought "of the Bear" green arrives with a random suffix
  with no script. The script the owner expected isn't needed.
- **Death costs no experience** in the stock game, and kills give none in
  battlegrounds (the switch above). The Lua engine's give-experience event
  can change an award's amount, including making it zero; taking
  experience away needs the character's experience set directly.

## Intended Behavior

Chosen 2026-09-26 from the options first listed here:

- **Battlegrounds pay in gold bars**, on both sides (owner, 2026-09-26:
  "Nothing else. Just gold bars." for the Horde, then "the kingdom pays
  you in gold bars as well"): the reward for a match is Gold Bars instead
  of items. Battlegrounds give no reputation (161). **Gold bars by
  participation**: at a match's end, its players are ranked by honor gained
  in it, **within their own team** (owner, 2026-09-26: "within a team. So
  if you're in the top 33% of your faction, you get 3 gold bars."); the
  top third get 3 gold bars, the middle third 2, the bottom third 1. A
  Gold Bar stacks to 6. (The owner's scale: a
  gold coin the size of a dime, a gold bar worth about a thousand dollars.)
- **Honor and marks stay**: matches still pay stock honor, and marks are
  kept as the record of where one fought.
- **What marks buy in this client** (read 2026-09-26): the supply
  officers' gear costs honor only, no marks. A mark's one use at basic's
  levels is the Alliance Brigadier General or Horde Warbringer, who trade
  one mark of any battleground for a Commendation of Service, which gives
  about 1,850 honor (its spell's honor amount in the client). So each mark
  is a large piece of honor.
- **A Gold Bar is worth 4 gold** to any vendor (stock: 6 silver). It can be
  bought for 6 gold, a few at a time, from travelling traders (wandering
  goblins and road traders), and is sometimes found in chests.
- **The battlemasters that stay** are the ones standing outside each
  battleground's entrance.
  Any vendor buys them for gold; their main use is still to be decided.
- **Queue only at the battlemasters in the world**: a battleground is
  joined by walking to its entrance and talking to its battlemaster. The
  capital battlemasters are removed, and queueing from the player's PvP
  window is refused. Buddies walk to the battlemaster when their owner
  does, so they will rarely land in the same match, sometimes when they
  gather first.
- *(Superseded 2026-09-26 by gold bars)* **Honor, marks and the eight
  supply officers stay** as the stock level 10-60 gear ladder.
- **Experience moves from the slain to the slayer.** A kill pays 10x the
  stock kill experience, and the slain character loses exactly what the
  killing blow earned: "Direct experience point transfer". The loss stops
  at the start of the victim's current level (no de-leveling).
- **Buddies at 5x**: a buddy's own kills pay it 5x, and its deaths cost it
  5x (answer (b), 2026-09-26).
- *(Superseded 2026-09-26 by gold bars)* **Bracket vendors instead of loot
  bags**: vendors that sell the items in
  the loot bags that already drop ("just the ones from the loot bags that
  drop already"). Their random suffixes are rolled by the server on
  purchase (see Current Behavior).
- **Buddies keep their own rewards.** "When a clanmember prospers, they
  all prosper" is an observation about clans, not a mechanic: no reward is
  shared out.
- **Not chosen**: marks at the glyph traders (155t takes gems only); loot
  bags; the vanilla PvP rank ladder, for the owner's reason quoted above
  (it concentrated power at the top and asked for steady time; this
  project is something to return to when there's time).

## Suggested Implementation Steps

Decided after the owner picks options. Whatever is chosen: config changes
as C patches gated to basic; anything new at the end of a match through
the Lua engine's battleground-end event (`src/lua-basic/`); any item
lists written by a generator, not by hand.

## Related Issues

- **155** parent
- **155t** capital glyph traders (they take gems only, not battleground
  marks)
- **155p** sockets and the gem supply
- **617i** buddy battlegrounds (buddies queue with their owner)
- **161** faction by reputation (a planned rule: battlegrounds pay no
  reputation there either)

## Open Questions

- (Answered 2026-09-26) Options: stock ladder kept; experience for kills at
  10x as a direct transfer from the slain, floored at the start of the
  level; buddies 5x on their own kills and deaths; bracket vendors selling
  the existing loot bags' items; buddies keep their rewards (clan
  prosperity is an observation, not a mechanic). Not: marks for glyphs,
  loot bags, the PvP rank ladder.
- **"You don't give experience when slain"**, read as: a victim already at
  the start of its level loses nothing, so the killer gains nothing from
  it (a strict transfer). Or should the killer still earn the kill's
  experience while the victim, at the floor, loses nothing?
- (Answered 2026-09-26) Rewards: gold bars only (bracket vendors and loot
  bags superseded). Queueing: only at the battlemasters in the world.
- **Travelling traders and chests**: which traders (the wandering NPCs of
  the travel system are beta's; basic has none yet), how many bars each
  holds and how often they restock, and which chests (a share of all
  world chests, or some)?
- (Answered 2026-09-26) Gold bars by thirds of honor gained in the match
  (3, 2, 1), stack of 6; honor and marks stay; the battlemasters outside
  the battlegrounds stay.
- **The price of mark-and-honor gear**, the owner's "HMMMM maybe terrible
  idea?": lower the mark costs, or double the honor costs, now that
  goblin gem sales add honor. Marks still come in from every match (the
  server keeps paying them), so a mark shortage isn't expected; the extra
  honor from gems argues for raising honor prices rather than lowering
  mark prices. Decide after seeing how much honor gem sales bring.
- (Answered 2026-09-26) The thirds are counted within each team.
- **The PvP window's queue button**: refused with a message pointing to the
  battlemaster in the world, or silently?
