# 155z18 - Shields Give Armour, Not Stamina

## Status
- Created: 2026-10-27
- Phase: 1
- Parent: 155
- Related: 155k2 (spirit on gear: the stat-swapping step this follows),
  155k (the stat budget: what "commensurate" is measured in), 635 (the
  Botanica party's paladin, who prompted it)
- Priority: Medium
- State: plan; open questions below

## Origin

The owner, 2026-10-27:

> the paladin uses 1h sword and off-hand item, because they have stamina
> while shields have armor - can we remove all +stamina stats from shields
> and give them a commesurately valuable +armor or +defence (light shield)
> bonus? Could also give spirit for holy shields, or sacred ones. magic
> shields can give mp5 for paladins and elemental shamans though sometimes
> those use a staff.

## Current Behavior

Stock shields carry stamina like any armour. On basic's world database
(read 2026-10-27), of the 301 green, blue and purple shields wearable at
60 or below, 144 carry stamina, 53 spirit, and 16 defence or mana every 5
seconds. So a shield's stamina competes with an off-hand item's, and a
paladin who wants stamina need not carry a shield.

## Intended Behavior

- **No shield carries stamina.** Its stamina is taken off and its worth
  given back, by the stat budget (the same weights 155k uses), as one of:
  - **plain shields**: bonus armour, or defence for a light shield;
  - **holy or sacred shields**: spirit;
  - **magic shields**: mana every 5 seconds (for paladins and elemental
    shamans).
- **Which kind a shield is** comes from what it already carries, by a
  rule a tool applies (open question 1).
- **Same item, same look, new numbers**, as 155k2 does; logged in
  `docs/balance-updates.md` with the rule and the count changed.
- **Made by a generator** beside 155k2's spirit step, from the stock item
  table, gated on basic, with a reverse.

## Suggested Implementation Steps

1. The rule as a pure function (a shield's stats → its kind and new
   stats), with tests on a plain, a holy and a magic shield.
2. The generator writes the SQL; a quick test that no shield on basic has
   stamina afterward, and that each changed shield's budget is within a
   point of its old one.
3. Its order against 155k2 (which already moves some stamina to spirit).

## Open Questions

1. **Which shield is which**: proposed, by its other stats: intellect or
   spell power → magic (mana every 5 seconds); spirit or healing → holy
   (spirit); otherwise plain (bonus armour, or defence when the shield is
   light: what makes a shield "light"? its armour below its item level's
   usual, or its name?). **Answered 2026-10-30:** "sounds good. let's
   worry about the "light" shields later." The sorting stands; every
   plain shield gets bonus armour for now, and light shields (defence)
   wait.
2. **Order with the spirit step**: the spirit step (155k2) turns stamina
   into spirit on two fifths of leather, plate, mail and jewellery, not
   shields. Run this after it, so shields are judged on stock stats?
   **Answered 2026-10-30:** asked with the agent's call, after it, the
   owner: "this one".
