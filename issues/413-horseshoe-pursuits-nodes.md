# 413 - Horseshoe Pursuits: Upside-Down Leather Nodes

## Status
- Created: 2026-10-12
- Phase: 4
- Related: 617e3 (buddies go to chests and nodes), 173d (the custom
  client's models and world objects)
- Priority: Low
- State: planned; open questions first

## Origin

Verbatim, 2026-10-12:

> also, can we add a certain number of new resource nodes to the game?
> They should be spawned like minerals and herbs. Rather, each mineral and
> herb has an increased spawn rate, and a proportional amount of them are
> now the new resource node. They should be... Upside-down, static,
> floating at the tip of their highest modelled point at the top of the
> ground, but the model itself is upside-down turned around, ideally
> perpendicular to the nearest downward slope. Follow the points until
> they next go up, then stop following that line of outward facing
> points. Pick a direction that stays going "down" the longest, the first
> time it does so. That's the one it should be oriented perpendicular
> around. The animation should be frozen. It should have glowing sparkles
> like mineral nodes and plants do. It should just be there. The names of
> the new nodes should be in japanese, and they should be named
> "horse-shoe pursuits" but named with the most transliterated
> pronunciation like "horushupurushuts'" like "ho ru shu, pu ru shu tsu"
> but with the tiny tsu like in "mi ka" three things like "mi tsu tsu" but
> the second tsu is tiny. and it should try and describe horses (the
> animal) wearing human shoes (like boots or galoshes) and business
> pursuits to provide them. And each one should be a different poetic
> device to explain such things. Just... absolutely deliverance wretched.

Answers, 2026-10-12 (verbatim):

> the tilt should always be rigid straight up and down.

> oh if we can't do japanese characters then we should just make them up.
> anyway they should have models that look like boars and bears and deer
> and other creatures that are in the real world and azeroth at roughly
> those sizes. their names can be something in english that roughly
> corresponds to the instructions I gave you - no need to do the "names in
> latin letters" that was just to describe which characters I was hoping
> for to display. BUT we shall make do with english, so if you could think
> of strange and silly names related to "horse-shoe-pursuits" please do,
> and name the appropriate resource nodes, which, when gathered by a
> skinner, give leather and hides, and slain enemies no longer do, because
> beasts aren't in wow-chat. For very rare leathers they spawn in the area
> where the rare mobs that used to give them are.

## Current Behavior

Herbs and mineral veins appear through spawn pools: each pool is a group
of possible places, of which a fixed number hold a node at a time (for
example "Copper Vein Durotar Skull Rock (3 spawns 12 locs)": 12 places, 3
in use). The basic world has 3,279 herb and mineral pools with 4,341
nodes up at once (2026-10-12: pools in `acore_world_basic.pool_template`
whose description names an herb, vein, mine or deposit). No other kind of
gathering node exists.

Leather and hides come only from skinning slain creatures (each creature
type names a skinning loot list; Light Leather alone is on 363 types in
the basic world). The stock client's list of models a world object may
use (GameObjectDisplayInfo.dbc) holds no animal models: only statues and
roasts of them (a Dire Maul bear and deer statue, a roast boar).

## Intended Behavior

**Leather comes from nodes, not corpses.** Skinners gather leather and
hides from a new kind of node; slain creatures no longer give any ("beasts
aren't in wow-chat").

**More nodes, a share of them new.** Each herb and mineral pool holds more
nodes at once than it does now; the extra ones are leather nodes, in
proportion to the increase. A node's leather follows its pool's tier
(the zone's level): a copper or peacebloom pool's leather node gives
light leather and hides, a thorium or dreamfoil pool's gives rugged.
**Rare leathers** (those that came from a few creatures only) come from
nodes placed where those creatures used to spawn.

**How a node looks and sits:**
- an animal of the real world and of Azeroth (boar, bear, deer, ...), at
  about its real size;
- upside down, held straight up and down (no tilt to the slope); its
  highest point, now its lowest, just touching the ground;
- turned to face along the ground's longest downhill run (open question
  2): from the node's place, lines run outward in many directions; each
  is followed while the ground keeps falling and stops where it first
  rises; the longest fall wins, the first found on a tie;
- its animation frozen, sparkling as herbs and ore do (a per-object flag
  the server can set), never moving.

**Names**: strange and silly English, about horses wearing human shoes
(boots, galoshes) and the businesses that supply them, each kind a
different poetic device. Drafts (one per kind, matched to tiers once the
count is settled):

| Device | Name |
|---|---|
| Spoonerism | Shorse Hoes |
| Chiasmus | Shoes for Horses, Horses for Shoes |
| Alliteration | Prancing Pony Pump Purveyors |
| Onomatopoeia | Squelch-Clop Galosh Concern |
| Zeugma | Took the Boots and the Market |
| Oxymoron | Barefoot Bootery |
| Hyperbole | Ten Thousand Wellingtons for One Mare |
| Litotes | Not Unshod Enterprises |
| Polyptoton | Shod Shoers Shoeing the Unshod |
| Personification | The Mare Who Haggled for Loafers |
| Apostrophe | O Boot, Fit Thou the Fetlock |
| Synecdoche | Four Hooves, Two Pairs, One Ledger |
| Hendiadys | Galoshes and Gumption |
| Anaphora | More Boots, More Hooves, More Margin |
| Pun | Mane Street Footwear |

**The placing is computed by a tool, not by hand**: a generator reads each
pool's places, the extracted ground heights and the model's height, works
out each node's height and facing, and writes the SQL that adds the
spawns.

## Suggested Implementation Steps

1. Answer the open questions (the model question first: it decides
   between a world object and a creature).
2. The node kinds, one per leather tier and rare leather, named from the
   table; their skinning loot.
3. Slain creatures' skinning loot removed (for the profiles chosen).
4. The facing walk over the extracted ground heights; a test of it on
   made-up ground (a cone, a plane, a valley).
5. The generator: for each herb and mineral pool, its raised count and
   the new spawns at its places; rare leathers' nodes at their old
   creatures' spawns. Writes the SQL.
6. An install step for the profiles that want it.
7. In game: walk Durotar, find one, skin it.

## Open Questions

1. **The animal model.** The stock client lets a world object use only
   models from its own list, and no animal is on it. Two ways:
   - **a client patch**: a file added to every player's client that puts
     boar, bear and deer models on the list. Then the node is a true
     world object: upside down, frozen, sparkling, anywhere. Each player
     installs it (the custom client could carry it built in);
   - **a creature lying dead and skinnable**, the way skinning works
     today: no client change, it sparkles and is skinned as any corpse
     is, frozen in its death pose. But a creature can't be turned upside
     down on the stock client; it lies on its side.
   Which?
2. Facing: with the tilt gone, should the node still turn to face along
   the longest downhill run, or face at random?
3. Which profiles lose leather from slain creatures: basic (which has
   beasts everywhere), or only the wow-chat profiles (beta, release)?
4. How much more: each pool's count up by how much (a quarter, half,
   double)?
5. Do the node kinds follow the leather tiers (light, medium, heavy,
   thick, rugged, knothide: about six, plus the rare ones), or more kinds
   than tiers, so more of the names get used?
6. Do herbalists and miners leave the leather nodes alone (only skinners
   can gather), and should buddy skinners go to them (617e3)?
