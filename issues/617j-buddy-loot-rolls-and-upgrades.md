# 617j - Buddy Loot Rolls and Upgrades

## Status
- Created: 2026-09-24
- Phase: 6
- Parent: 617
- Blocked by: 617a (roster), 617g (talent plans: the three-way-split
  buddies)
- Related: 617h (what buddies sell or mail)
- Priority: Medium

## Origin

Verbatim, 2026-09-24, asked what a buddy does with a bind-on-pickup epic it
can't mail to its owner:

> bind-on-pickup epics are all gained from dungeons or raids, I think. If
> so, they should be tradeable to anyone that was there. Bots should need or
> greed appropriately. Players and their bots essentially share a gear
> pool, with a slight priority given to players for their BoE epics. Bots
> who have the profile that splits their talent picks across all three
> tiers will always greed every item they can equip (and which would be an
> upgrade) unless the average of their clan (the player and their buddy
> bots) is above them - then they will need any item that would be an
> upgrade, no matter which spec, until they are above the average, then
> they greed again till they are below.

> if it's an upgrade, they probably rolled need for it. If so, yeah, they
> should equip it of course. If it's one of the rare 3 spec characters, then
> if it's an upgrade to any of the three specs that they are, they should
> equip it. This goes for any item that enters their inventory - always
> equip upgrades.

## Current Behavior

Buddies do not exist yet. The bot module already rolls on loot (its loot
roll action): need when the item is usable by the bot and an upgrade, greed
otherwise, disenchant when its config allows; recipes it can learn get
need. The stock server already lets bind-on-pickup loot be traded for 2
hours to the players who were eligible for it (the item's "tradeable
bind-on-pickup" flag).

## Intended Behavior

- **Shared gear pool.** A player and their buddies (the "clan") are one
  pool: bind-on-pickup loot from dungeons and raids stays tradeable for 2
  hours to everyone who was there (stock), and buddies roll need or greed
  like the bot module does, with a slight priority to players (see Open
  Questions for what that means in practice).
- **Three-way-split buddies** (617g's thirds talent plan) roll by their
  clan's average:
  - normally they **greed** every item they can equip that would be an
    upgrade;
  - when the clan's average is above theirs, they **need** any upgrade, for
    any of their three specs, until they are above the average; then they
    go back to greed.
- **Always equip upgrades**, from any source (rolls, drops, mail, trades).
  For a three-way-split buddy, an upgrade to any one of its three specs
  counts.
- **"Upgrade" is decided by stat weights per spec** (Ritz, 2026-09-24):
  how much each stat is worth to a spec, from theorycrafting. The bot
  module already has such a table (its stats-weight calculator picks
  weights by class and main talent tree, e.g. holy paladin values
  intellect and spell power); it is tuned for level 80 and **used as is**
  (no level-60 theorycraft exists for this client's abilities). **Split-spec buddies blend
  their specs' weights by their talent split**: a holy/protection paladin
  on the 2/3–1/3 plan scores items with holy's weights at 2/3 and
  protection's at 1/3; a thirds buddy uses a third of each.
- **Clan average = average equipped item level** of the owner and all
  their buddies (Ritz, 2026-09-24).
- **Bind-on-equip epics go to the owner**: one that isn't an upgrade for
  the buddy is held until a mailbox and mailed to the owner; never sold,
  never vendored. That is what "a slight priority given to players for
  their BoE epics" means (Ritz, 2026-09-24: "No and no. It means if they
  get a BoE epic that isn't an upgrade, they give it to their player
  instead of auctioning it. They should never vendor a BoE epic item. They
  will hold onto it until they can mail it to the player.").
- **Giving within the clan** (Ritz, 2026-09-24, for Outland blues, which
  bind on pickup and stay tradeable in the clan for 2 hours, 155k): a
  buddy holding an item it can't use scores it for every clan member by
  their stat weights and trades it to the one it upgrades most. The owner
  is scored once per talent tree of the owner's class (the buddy can't
  know the owner's spec), best result counts. Verbatim: "If the buddy
  can't use it, they'll try to guess who among their number could benefit
  from it most. Then they'll give it to that player. Otherwise, if nobody
  views it as an upgrade, they'll vendor it. They should guess once for
  each potential stat profile their owner might possess, according to
  their class."
- When a buddy gives an item to its owner and another buddy also counts
  it as an upgrade, it says so in chat, so the owner can pass it on:
  "hey, so-and-so was also interested in this item..." (Ritz, 2026-09-24).
- A soulbound item that isn't an upgrade for anyone in the clan is
  vendored (617h).

## Suggested Implementation Steps

1. A clan gear score: the average of the equipped gear of the owner and
   each buddy, by the measure chosen below.
2. A roll-decision hook in the bot module's loot roll action for buddies:
   stock need/greed, plus the three-way-split rule.
3. Upgrade check on every item entering a buddy's bags; equip if better
   (for three-way buddies, better for any of the three specs).
4. Tests: a three-way buddy below the clan average needs an upgrade; above
   it, greeds; a looted upgrade is equipped at once.

## Related Issues

- **617** parent; **617g** talent plans (three-way-split buddies);
  **617h** selling and mailing

## Open Questions

- (Answered 2026-09-24) Stat weights: the bot module's level-80 table, as
  is. Verbatim: "level 80 weights are fine. There are no WotLK weights
  (WotLK abilities and such) tuned for level 60 characters. So I don't
  think the information we need exists. Let's use the level 80 versions,
  even though for example a class that gets an ability that really
  empowers, say, haste rating, might not have access to it because they
  learn it at level 61 or it's at the bottom of their talent tree. The
  miscalibration of buddy stat weights is the symptom of this and
  unfortunately we'll have to bear it for now." Known cost: a spec whose
  weight for a stat comes from an ability learned after 60, or from a
  talent past basic's 30-point cap (155g), overvalues that stat.
- (Answered 2026-09-24) Single-spec buddies: need/greed by their spec's
  stat weights (the Ritz's answer covers both kinds: weights per spec,
  blended for split specs).
- (Closed 2026-09-24) Mixed groups: the question confused more than it
  helped. Settled as the plain reading: each buddy's "clan" is its own
  owner and that owner's buddies.
- (Answered 2026-09-24) Clan average: average equipped item level.
  Bind-on-equip epics that aren't upgrades are mailed to the owner.
