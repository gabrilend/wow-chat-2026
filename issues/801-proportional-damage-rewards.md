# 801 - Proportional Damage Rewards (No Tagging)

## Status
- Created: 2026-04-02
- Phase: 2
- Priority: Medium

## Current Behavior
- First player to damage a mob "tags" it (mob's nameplate turns grey for others)
- Only the tagging player (or their group) receives XP and loot
- Other players who help kill receive nothing
- Discourages cooperation between strangers

## Intended Behavior
- Remove tagging system entirely
- All players who deal damage receive rewards proportionally
- Healers receive contribution credit for nearby monsters
- XP awarded proportionally based on contribution
- Loot assigned via "reward-differential" system (see below)
- Currency split proportionally among contributors

## Contribution Tracking

### Damage Contribution
- Track damage dealt per player on each creature
- Pet damage credits the pet's owner
- DoTs work automatically (each tick is a damage event)
- Reflected damage: ignored for now (note: may need handling later)

### Healing Contribution
- When a player casts a heal, all hostile creatures within 60 yards get contribution credited to that player
- This allows healers to earn credit without dealing damage

### Reward Range
- ALL players must be within 60 yards of creature at death to receive loot
- Players farther away still get differential added, just no loot chance
- This prevents distant players from "sniping" loot while focused elsewhere

### Cleanup
- On player logout: remove player from all creature contribution lists
- On creature evade/reset: clear all contribution data, award nothing

## XP Distribution

On creature death:
1. Calculate total contribution (damage + healing credit)
2. For each contributor within reward range:
   - proportion = their_contribution / total_contribution
   - If proportion >= 0.05 (5% minimum), award XP
   - xpAward = baseXP * proportion

## Currency Distribution

- Sum creature's gold drop
- Divide proportionally among contributors (5% minimum)
- Each player receives: goldDrop * (their_contribution / total_contribution)

## Loot Distribution (Reward-Differential System)

### Concept
Players accumulate a "reward-differential" value (in copper) representing how much loot value they're "owed" from combat. The player with the highest differential gets the next loot drop.

### On Creature Death
1. Calculate total vendor value of all dropped items (sum as one value)
2. For each contributor (5% minimum):
   - Add to their reward-differential: vendorValue * proportion
3. Actual loot goes to contributor with HIGHEST reward-differential who is:
   - Within 60 yards of creature
   - In combat with the creature
4. Subtract loot's total vendor value from winner's reward-differential
5. Winner loots entire corpse (all items go to one player)
6. If no one qualifies: destroy loot (e.g., NPC vs NPC fight)

### Tie-Breaking
If multiple players have same reward-differential, highest contribution this kill wins.

### Persistence
- Save reward-differential to database on logout
- Load on login
- Value can go negative (player "owes" the system)

### Need Before Greed
- Triggers for all nearby players with 5%+ contribution
- Works even if players aren't grouped
- Normal Need > Greed rules apply

## Example Scenario

Monster has 1000 HP, drops item worth 100 copper:

| Player | Contribution | Proportion | XP Share | Differential +  |
|--------|-------------|------------|----------|-----------------|
| A      | 600 dmg     | 50%        | 50%      | +50 copper      |
| B      | 400 dmg     | 33%        | 33%      | +33 copper      |
| C      | 200 heal    | 17%        | 17%      | +17 copper      |

Before kill:
- Player A differential: 20 copper
- Player B differential: 80 copper
- Player C differential: 45 copper

After differential added:
- Player A: 70 copper
- Player B: 113 copper (HIGHEST, gets loot)
- Player C: 62 copper

After loot awarded to B:
- Player A: 70 copper
- Player B: 13 copper (113 - 100)
- Player C: 62 copper

## Implementation Steps

1. Create contribution tracking system
   - Hook CREATURE_EVENT_ON_DAMAGE_TAKEN for damage
   - Hook player heal events, apply to creatures within 60 yards
   - Store on creature via SetData()

2. Handle cleanup events
   - Player logout: remove from all contribution lists
   - Creature evade/reset: clear contribution data

3. Implement XP distribution
   - Hook CREATURE_EVENT_ON_DIED
   - Calculate proportions, award XP to eligible players

4. Implement currency distribution
   - Split gold proportionally on creature death

5. Implement reward-differential system
   - Create database table for player differential values
   - Load/save on login/logout
   - Award loot to highest differential player in combat

6. Modify Need Before Greed
   - Trigger for all nearby contributors (5%+)
   - Remove group requirement

## Technical Notes
- Healing range check: 60 yards (healing spells ~40 yard range + buffer)
- Minimum contribution threshold: 5%
- Reward-differential persisted in database
- All items freely tradeable (soulbound removal in separate issue)

## Related Issues
- 121 - bounty board currency system
- (soulbound removal issue - find number)
- 142 - symmetric aggro radius (the bystander-aggro scenario uses
  this system as the reward-routing layer; see 142 for the full
  composition story)
- 806 - proximity raid system (auto-grouping by location; tightens
  the conditions under which this reward system fires)

## Reward Curve Shape (added 2026-06-02)

**Design intent:** the per-creature XP and currency reward values
should scale **non-linearly with creature level** — either
logarithmically or exponentially, with the exact curve to be tuned —
so that a small proportional share of a high-level kill is still
meaningful in absolute terms.

**Why:** the proportional-distribution rules above are fair but flat.
Under linear creature-reward scaling (vanilla's near-default), a 1%
contribution to a level-40 kill earns roughly 1% of a level-40 kill's
reward, which is only a few times the absolute value of a 100%
contribution to a level-1 kill. The result: low-level players have no
strong incentive to *hang around* high-level encounters, because the
absolute payoff is unimpressive.

Under non-linear scaling (exponential is the stronger candidate;
logarithmic is the conservative one), the level-40 kill drops a
disproportionately large XP/currency pile. A 1% share of that pile
is meaningful even to a low-level. The behavioural pull is: stick
near the high-level player, contribute what you can, and the
absolute rewards make the proximity worthwhile.

**Composition with related systems:**
- **142-option-3** (target-change damage rescale) keeps low-level
  bystanders alive near high-level encounters.
- **This reward curve** makes sure the rewards from those encounters
  arrive in meaningful absolute amounts even when proportional shares
  are small.
- **806** (proximity raid) makes sure the grouping that triggers
  proportional rewards happens automatically rather than depending on
  manual invites.

The three pieces are facets of the same design: cross-level proximity
should be a meaningful experience, in danger and in reward, without
requiring social ceremony to activate.

**Tuning:** the exact curve (which exponent? which log base? plateau
where?) is a play-testing question. Open question pending data.

## Design Observation — High-Level Grouping Is Self-Incentivising

High-level players are already incentivised to group up among
themselves without any special system, by the natural mechanics of
this ruleset:

- AoE loot (mod-aoe-loot on vanilla, equivalent elsewhere) means
  large piles of corpses can be cleared with one keypress.
- Multiple high-level allies can hold a position while monsters
  approach them, fight efficiently, and gather materials at scale —
  the stand-and-deliver pattern.
- The proportional reward system means co-fighting high-levels each
  get their share without needing a tagging dance.

No mechanic needs to be added to make high-levels want to group;
the existing ones already produce the pull. The systems described
above (target-change damage rescale, reward curve, proximity raid)
are about pulling **low-levels into proximity with those groups**,
not about getting high-levels together in the first place.

