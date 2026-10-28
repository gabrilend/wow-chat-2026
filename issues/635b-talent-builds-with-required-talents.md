# 635b - Talent Builds with Required Talents

## Status
- Created: 2026-10-27
- Phase: 6
- Parent: 635
- Blocked by: none
- Related: the buddy talent spender and its plan table (`buddies_loot.cpp`),
  `scripts/generate-basic-talent-data`, `scripts/test-buddy-talents`
- Priority: High
- State: in progress (the planner and its test built 2026-10-27; the
  player tool and the buddies' use of a build are not)

## Current Behavior

A buddy's talents follow one of ten plans: how many thirds of its points go
to each tree. Which talents inside a tree is the spender's choice.

**Built 2026-10-27** (not yet in game):
- The talent spender (`src/lua-basic/lib/buddy-talent-spender.lua`) has a
  build planner: its cost (the fewest points that max the required
  talents) and its point-by-point plan, required talents first, then the
  thirds; forbidden talents never taken; impossible builds refused with
  their shortfall. The ten buddy shapes are spent exactly as before (its
  old test passes unchanged).
- The builds are data, `src/lua-basic/data/talent-builds.lua`: the
  Botanica party's five, held to what basic opens.
- `scripts/test-talent-builds` (a quick test) spends 51 points on every
  build with 200 sets of dice, checks each point with its own referee,
  and checks the four refusals. On the five, at 60: the druid healer
  26/0/25 (Restoration takes 25, not a third, for Gift of Nature), the
  Renew priest 0/30/21 (Holy 30, for Spiritual Healing), the shaman
  0/51/0, the paladin 9/0/42 (Retribution holds only 42 under basic's
  cap; the rest overflows to Holy), the bear 1/50/0.
- Not built: the tool writing a build's talents for a player character
  (with 635a's checkpoint), and buddies reading a build instead of a
  shape.

## Intended Behavior

The owner, 2026-10-27: "the idea of having a build target "favor this
talent tree, but spend as much as you need to get to these select talents,
and max them out. build requirements"".

- **A build** is: the trees' thirds as today, plus a list of **required
  talents**, each to be maxed.
- **Required first**: the points go first to the required talents and to
  whatever opens them (the points a tier needs in its tree, and a talent's
  prerequisite talent), the cheapest way, "no matter how far down the tree
  she has to go". Then what is left follows the thirds, favouring the
  favoured tree.
- **Impossible builds are an error**, not a fallback: if the required
  talents cost more points than the character has at that level, the
  build is refused with the count it is short, and which talents it could
  afford.
- **Named builds** in a data file (`src/lua-basic/data/talent-builds.lua`),
  each with its required talents by name, checked against the client's
  talent table when the file is generated. The party's five (635) are the
  first.
- **For any character**: the spender runs for buddies at level-up; the same
  plan, written out as SQL by a tool, sets a player's talents.

## Suggested Implementation Steps

1. The planner as a pure function (a level's points, the talent table, the
   build → the talents and ranks), with tests: the Renew priest's build,
   an impossible build, a build with a prerequisite chain.
2. The data file, and its generator check.
3. The spender reads a build when a buddy has one; the SQL tool for a
   player.

## Open Questions

1. **The Renew priest and basic's talent cap.** Basic opens the first six
   rows of a tree and, in the seventh, only one-point talents (155g; the
   generated talent data marks the rest "not allowed"). Holy's Renew
   talents: Improved Renew (row 1, open), then Body and Soul (row 8),
   Empowered Renew (row 9) and Divine Providence (row 10), all shut on
   basic. "No matter how far down the tree she has to go" reaches past the
   cap. Choices: (a) the cap holds, and "required" means everything open
   that empowers Renew (Improved Renew, Spiritual Healing, Holy Reach and
   the like); (b) a checkpoint character may pass the cap (a test party,
   not a player's); (c) this party lives on the advanced profile, whose
   cap is deeper (1101).
2. **When required talents cost more than the thirds allow**: required
   talents win, and the favoured tree's share grows. Is that the intent?
