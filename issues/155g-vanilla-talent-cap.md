# 155g - Talents Capped as in Vanilla

## Status
- Created: 2026-09-23
- Phase: 1
- Parent: 155
- Blocked by: 155a
- Priority: Medium

## Origin

Verbatim, 2026-09-23:

> can we also make a patch to disable the talent picks above 30 talents
> required? For example, for fire mage, that's combustion. For ret paladin,
> it's repentance. This should include the talents to the left and right of
> the "capstone" - essentially, we're setting the max level to 60, and
> capping talents as they would be in vanilla. This should be applied to
> basic.

Refined, verbatim, 2026-09-23: "okay so tier 6 should have only the capstone
ability available." So tier 6 keeps its capstone (e.g. Combustion,
Repentance) and refuses the talents
beside it; tier 7 and deeper stay refused.

How the capstone is found, verbatim, 2026-09-26: "The talent cap can select
the capstone by looking for the talent that costs 1 talent point." Where a
tree has two one-point talents in tier 6, the owner chose (2026-09-26) to
open both.

On "Is there a reason this isn't applied with the patching system?": it is.
B030 is an ordinary source patch in `patches/patches.sh`, applied before
each compile and reverted after. The C++ is kept as a whole file in the
project (`src/cpp-basic/`) because it is a new file, not an edit to one;
B030 copies it into the server tree and registers it, and its revert
removes both.

## Current Behavior

**Built 2026-09-26 with the capstone rule; not yet compiled or tried in
game.** `src/cpp-basic/basic_rules.cpp` (copied in by B030) opens every
talent above tier 6, opens a tier-6 talent that has one rank, and refuses
the rest with a system message. `scripts/test-source-patches <dir> basic`
(round trip byte-identical) and `scripts/test-patched-syntax <dir> basic`
(the rules file and loader compile-check clean) both pass. The in-game
check, step 4 below, waits on the owner's build.

Stock, for reference: talent trees are the stock WotLK ones: eleven rows (tiers 0–10), where row
*n* needs *5n* points spent in the tree. The client's own data files hold
the trees (`Talent.dbc`), and those can't be changed (no client patches). A
level-60 character has 51 points, enough to reach the WotLK trees' tier 10
in one tree.

The server decides whether a talent is learned: `Player::LearnTalent`
(`src/server/game/Entities/Player/Player.cpp`) asks a stock script hook,
`OnPlayerCanLearnTalent(player, talent, rank)`, and refuses when any script
says no. The talent's row is `TalentEntry::Row`.

Checked in the client's talent table (2026-09-23): Combustion (fire mage)
and Repentance (retribution paladin) are both in **tier 6**, the row that
needs 30 points. The owner's examples are the capstones of the first
capped row.

## Intended Behavior

On basic, tiers 0–5 work as stock. In tier 6 (30 points in the tree) only
the capstone can be learned: the talent that costs one point, such as
Combustion or Repentance. The multi-rank talents beside it, and every row
deeper than tier 6, are refused.

Checked in Talent.dbc (2026-09-26): 27 of the 30 class trees have exactly
one one-point talent in tier 6. It is not always in the middle column
(affliction's Dark Pact sits right of centre), which is why rank count is
the test and not column. Three trees have two, and both are open:

| Tree | Tier-6 one-point talents |
|---|---|
| Restoration shaman | Mana Tide Totem, Cleanse Spirit |
| Enhancement shaman | Dual Wield, Stormstrike |
| Unholy death knight | Anti-Magic Zone, Ghoul Frenzy |

Hunter pet trees are untouched: pets learn talents through a separate
server path that does not ask this rule.

- The client still draws the full tree (its files are fixed). Clicking a
  capped talent is refused by the server, and the player gets a one-line
  system message saying why.
- Bots use the same learning path, so they are capped too. A refused
  talent leaves the point unspent; the bots' talent loops are bounded, so
  nothing spins (checked in `PlayerbotFactory.cpp`).

Mechanism: a project-owned C++ rules file for basic,
`src/cpp-basic/basic_rules.cpp`, holding a player script that answers the
stock hook. Source patch B030 copies it into the server's own
`src/server/scripts/Custom/` folder (stock, empty, meant for this) and
registers it in that folder's loader, bracketed so the revert removes it
exactly. The same file is the natural home for basic's later server rules
(the resource hooks in 710).

## Suggested Implementation Steps

1. `src/cpp-basic/basic_rules.cpp`: a `PlayerScript` whose
   `OnPlayerCanLearnTalent` allows rows below 6, allows row 6 when the
   talent has one rank (no second rank id), and refuses everything else
   with a system message.
2. B030: copy the file in, register `AddSC_basic_rules()` in
   `custom_script_loader.cpp`, revert both.
3. Add B030 to basic's list; `scripts/test-source-patches basic` and
   `scripts/test-patched-syntax basic`.
4. After the owner's build: on a level-60 fire mage, spend 30 points in
   fire: Combustion learns; the multi-rank talents beside it (Firestarter,
   Hot Streak) are refused with the message; tier 7 is refused; tier-5
   talents learn fine. On a restoration shaman, both Mana Tide Totem and
   Cleanse Spirit learn.

## Related Issues

- **155** parent; **710** (resources: the same rules file will host those
  hooks)

## Open Questions

- **Bots' unspent points**: capped bots at 60 keep their deep-row points
  unspent. Should their talent plans be taught to spend them in tiers 0–5
  instead (a module patch)?
- (Answered 2026-09-23 and 2026-09-26) **Where the cut falls**: tier 6
  keeps its one-point capstone; the rest of tier 6 and everything deeper
  are out. Trees with two one-point talents open both.
