# 179 - The Hearthstone Network

## Status
- Created: 2026-10-08
- Phase: 1
- Profile: basic
- Related: 617 (buddies), 617e (buddies following the owner across
  areas), 155 (the basic profile), 178 (experience; rested experience
  sets the price)
- Priority: Medium

## Origin

The owner, 2026-10-08:

> how hard would it be to make it so that every innkeeper we've visited,
> we can talk to them and they'll let us use a hearthstone from the
> hearthstone network to teleport to anywhere we've known by hearthstone
> before?

Told the Lua engine can't add one line to an innkeeper's stock menu (it
replaces the whole menu):

> how about each innkeeper sells a one-time-use hearthstone with a 60
> second disappearing countdown? and they will only sell you the
> hearthstone to a particular place if you've been there. They can have
> several nested menus as they sort through their organization patterns -
> it's a lot of stones to know the codes to translate the hearthstone to.
> but, lucky for the player, maybe only ones they've visited show up in
> the list, meaning there's no need for needless directory traversal.

On the price: "maybe... it costs more gold per bar of rested exp you have,
multiplied by your level. this encourages you to go where you want before
resting, rather than resting, then going... somewhere." Which inns:
"inns you've set as your home." Buddies: "they cast their hearthstone
whenever you do. Including temporary hearthstones. If theirs is on
cooldown, then they'll use the temporary one by walking to a nearby
innkeeper and asking for one. They know all of your hearthstone
locations."

## Current Behavior

Not built. A character has one hearthstone, bound to one inn at a time
("make this inn your home"), with a 30-minute cooldown. Innkeepers offer
binding and their goods.

## Intended Behavior

**The inns a character knows.** Every inn a character has set as its
home is remembered, for good: the network's destinations.

**Hearthstones to anywhere known, sold by any innkeeper.** Talking to an
innkeeper offers a hearthstone to each inn the character knows, and only
those: no list of inns it has never been to. The list is sorted the way
the innkeeper keeps it ("nested menus as they sort through their
organization patterns": by continent, then zone, then inn), and a branch
with nothing known in it doesn't appear.

**One use, gone in 60 seconds.** The stone bought is good for one trip,
to its one inn, and disappears 60 seconds after it is bought if not used.

**The price: rested experience times level.** A stone costs a sum of gold
for each bar of rested experience the character has (the experience bar
has 20 bars; rested experience shows as how many bars it covers),
multiplied by the character's level. With no rested experience it is
cheap; having rested first makes it dear. So: travel, then rest.

**Buddies come along.** When the owner uses a hearthstone, its own or a
network stone, each buddy uses its hearthstone too, to the same inn
(buddies know every inn the owner knows). A buddy whose hearthstone is on
cooldown walks to a nearby innkeeper, buys a network stone, and uses it.

## Suggested Implementation Steps

1. A characters-database table of known inns (character, inn: the
   innkeeper's spawn and the bind position), written when a character
   binds at an inn.
2. The network stone: an item that disappears 60 seconds after it is
   made (the item's duration), and that teleports to the inn stored with
   it when used, through a Lua item-use event.
3. The innkeeper's menu: Lua takes over every innkeeper's conversation
   (all creatures with the innkeeper flag, found at startup), rebuilds its
   stock options (bind here, browse goods), and adds "Buy a hearthstone
   to..." with the nested list of known inns.
4. The price, from the character's rested experience and level.
5. Buddies: on the owner's hearthstone or network stone, each buddy
   casts its own; on cooldown, it walks to the nearest innkeeper, buys a
   stone, and uses it.
6. Tests without a server: the price arithmetic; the nested list for a
   set of known inns, empty branches left out.

## Open Questions

1. **The gold per bar:** how much? For example 1 silver per bar per
   level would make a full 30-bar rest at level 40 cost 12 gold.
2. **No rested experience:** free, or a small floor price?
3. **Buddies' cooldown:** a buddy's own hearthstone shares the owner's 30
   minutes, or buddies have none (so they always come straight with the
   owner, and the walk to an innkeeper never happens)?
4. **The owner's own hearthstone:** unchanged (bound to the last inn,
   30 minutes), the network stones beside it?
5. **Inns across factions and neutral inns** (Booty Bay, Gadgetzan): in
   the network for both sides, once set as home?
