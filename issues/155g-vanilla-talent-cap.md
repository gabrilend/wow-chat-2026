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

## Current Behavior

Talent trees are the stock WotLK ones: eleven rows (tiers 0–10), where row
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
needs 30 points. The owner's examples are therefore the first talents cut:
tier 6 and everything below it in the tree.

## Intended Behavior

On basic, no talent in tier 6 or deeper (30+ points in the tree) can be
learned: the tier-6 "capstones" such as Combustion and Repentance, the
talents beside them, and every deeper row. Every talent in tiers 0–5 works
as stock.

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
   `OnPlayerCanLearnTalent` refuses `talent->Row >= 6`, with a system
   message.
2. B030: copy the file in, register `AddSC_basic_rules()` in
   `custom_script_loader.cpp`, revert both.
3. Add B030 to basic's list; `scripts/test-source-patches basic` and
   `scripts/test-patched-syntax basic`.
4. After the owner's build: on a level-60 fire mage, spend 30 points in
   fire and try Combustion: refused with the message; tier-5 talents learn
   fine.

## Related Issues

- **155** parent; **710** (resources: the same rules file will host those
  hooks)

## Open Questions

- **Bots' unspent points**: capped bots at 60 keep their deep-row points
  unspent. Should their talent plans be taught to spend them in tiers 0–5
  instead (a module patch)?
- **Where the cut falls**: vanilla's trees had their 31-point talent in
  tier 6, so vanilla let you take it. This cut removes tier 6 too, as the
  examples ask. Confirm tier 6 is out, not in.
