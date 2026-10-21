# 617j - Buddy Loot Rolls and Upgrades

## Status
- Created: 2026-09-24
- Phase: 6
- Parent: 617
- Blocked by: 617a (roster), 617g (talent plans: the three-way-split
  buddies)
- Related: 617h (what buddies sell or mail)
- Priority: Medium
- Sub-issues: 617j1 (loot turns: the group's loot rule, and who opens which corpse), 617j2 (gems and sockets by the talent plan)

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

**Steps 1–4 built 2026-10-02, syntax-checked, not yet compiled or run.**
In progress: the giving within the clan and the class-book hand-over are
not built (below), and nothing has been seen in game.

- **Source patch B046** (`patches/B046-playerbots-buddy-loot-judgement.sh`,
  bot module only): the stat-weight scorer (`StatsWeightCalculator`) asks
  the buddy module for a buddy's talent plan before scoring; for a buddy
  the item's score is each tree's score weighted by its share of the
  plan's points (the scorer gains "score as this tree" for the parts, each
  part keeping the caller's switches). The loot roll action hands the
  buddy module its own judgement before and after the config's need/greed
  switches and casts what comes back. Anyone not a buddy is untouched.
  Needs B036 (the module in the build): without it, a link error.
  Round trip in a RAM copy (apply, apply again, revert, revert again):
  apply idempotent, revert byte-identical. Every patched file and the new
  module file pass the compiler's syntax check with the last build's
  flags (a planted error in the same check was caught).
- **`patches/B036-mod-buddies/mod-buddies/src/buddies_loot.cpp` / `.h`**:
  - the plans: `buddy_roster.profile` 1–10 read as points per tree in
    thirds (the generator writes the ten shapes in one order for every
    class; checked 2026-10-02); each tree's kind of stats by the bot
    module's own per-class, per-tree rules, except a feral druid is a tank
    by its plan's role rather than by bear form;
  - the clan gear score: average equipped item level (the server's own
    formula) of the owner and every buddy of the owner; refreshed every 10
    seconds on the world thread; online characters as they stand, offline
    ones read once from the database (their gear can't change offline);
  - the roll: class books (155q, and the stock ones they copy) pass when
    the owner needs one and is in the group, need when the buddy itself
    needs it, otherwise greed; an upgrade is needed, except by a "third in
    each tree" buddy (plan 7), which needs it only while its own average is
    below the clan's and greeds otherwise; a unique item it already holds
    is passed; greed and disenchant as judged; else pass. This ignores
    basic's playerbots config for buddies (need-level 1 turns need into
    greed, greed off turns greed into pass), which applies to other bots.
- **Always equip upgrades** is the bot module's own: it equips upgrades
  when an item is pushed into a bot's bags (loot, roll won, trade) and on
  its periodic check (which is what catches mail; taking mail sends no
  push), with `AiPlayerbot.AutoEquipUpgradeLoot` on (basic: on). Scored
  by the plan through B046, that is this rule. Its threshold
  `AiPlayerbot.EquipUpgradeThreshold` is 1.1: an item must score 10%
  better to be worn.
- **A third in each tree, scored as a blend:** the owner's 2026-09-24
  stat-weight answer ("a thirds buddy uses a third of each") is what is
  built; the earlier "an upgrade to any of the three specs" reading is not,
  because scoring each item by its best tree lets two items each beat the
  other (each better for a different tree) and the buddy would swap them
  forever. See Open Questions.

**Not built:** giving within the clan (a buddy holding an item it can't
use trades it to the clan member it upgrades most, the owner scored once
per tree of their class; the "so-and-so was also interested" line), and a
buddy holding a class book handing it to the owner or a buddy who needs
it. Both need the trade window driven between two characters; nothing in
the module does that yet.

Before: buddies did not exist. The bot module already rolls on loot (its loot
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
- **Class books** (basic's level 61–80 ability books, 155q; unbound, so
  they can be traded): a book counts as an upgrade for a clan member of its
  class who doesn't yet know that rank or a higher one, and who knows the
  talent it may need. Ritz, 2026-09-25: "buddybots should consider them as
  upgrade potentials, preferring the player if they need it over a
  buddy-bot of the same class who also needs it." So the owner comes
  first: a buddy passes on a roll for a book its owner needs, and a buddy
  holding one hands it to the owner if the owner needs it, else to a buddy
  of that class who does. A book nobody in the clan needs goes to the
  auction house (617h), as it is unbound.

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
  talent past basic's cap (155g: no row deeper than tier 6, and only the
  capstone in tier 6), overvalues that stat.
- (Answered 2026-09-24) Single-spec buddies: need/greed by their spec's
  stat weights (the Ritz's answer covers both kinds: weights per spec,
  blended for split specs).
- (Closed 2026-09-24) Mixed groups: the question confused more than it
  helped. Settled as the plain reading: each buddy's "clan" is its own
  owner and that owner's buddies.
- (Answered 2026-09-24) Clan average: average equipped item level.
  Bind-on-equip epics that aren't upgrades are mailed to the owner.
- (Open, 2026-10-02) A buddy with a third in each tree: scored as a blend
  of a third of each tree (built), or "an upgrade to any one of its three
  specs" (the earlier wording)? The second makes the buddy swap two items
  back and forth when each is better for a different tree.
- (Open, 2026-10-02) Class book when the owner needs it but isn't in the
  group: the buddy greeds it now (to keep it in the clan), but nothing
  hands it over yet. Should it need instead?
- (Open, 2026-10-02) The bot module's 10% upgrade threshold
  (`AiPlayerbot.EquipUpgradeThreshold` 1.1) keeps "always equip upgrades"
  from equipping small ones. Keep, or lower it for basic?
