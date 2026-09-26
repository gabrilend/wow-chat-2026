# Respec Cost: No Cap, Weekly Drop Patch (B035)

## Overview

On the basic profile (issue 155r), resetting talents costs 1 gold, then 5,
then 10, then 10 gold more each time with no cap; for each weekly reset
since a character's last respec the price drops one step (10 gold), never
below 10 gold. Ritz, 2026-09-25: "Could we make it 1, 5, 10, then 20, 30,
40, 50, etc? Let's do a drop for everyone on the server's weekly reset day.
And yeah let's keep the floor."

Stock, for comparison: 1, 5, 10, then 5 gold more each time up to 50; a
5-gold drop per calendar month; floor 10.

Applied by `patches/B035-respec-cost-weekly.sh`. The other half of 155r,
no dual spec, is config patch `config/patches/C026-basic-no-dual-spec.sh`
(`MinDualSpecLevel = 255`).

## Files to Modify

### 1. `src/server/game/Entities/Player/Player.cpp`

At the top of `uint32 Player::resetTalentsCost() const`, right after its
opening brace, insert:

```cpp
    // >>> B035-respec-cost BEGIN
    {
        if (m_resetTalentsCost < 1 * GOLD)
            return 1 * GOLD;
        if (m_resetTalentsCost < 5 * GOLD)
            return 5 * GOLD;
        if (m_resetTalentsCost < 10 * GOLD)
            return 10 * GOLD;
        int64 lastWeeklyReset = int64(sWorld->GetNextWeeklyQuestsResetTime().count()) - int64(WEEK);
        int64 resets = 0;
        if (lastWeeklyReset > int64(m_resetTalentsTime))
            resets = (lastWeeklyReset - int64(m_resetTalentsTime)) / int64(WEEK) + 1;
        if (resets > 0)
        {
            int64 dropped = int64(m_resetTalentsCost) - int64(10 * GOLD) * resets;
            return dropped < int64(10 * GOLD) ? uint32(10 * GOLD) : uint32(dropped);
        }
        return m_resetTalentsCost + 10 * GOLD;
    }
    // <<< B035-respec-cost END
```

`m_resetTalentsCost` is what the last respec cost and `m_resetTalentsTime`
when it happened (both saved per character by the stock server). The weekly
reset is the server's weekly quest reset; the last one was a week before
the next scheduled one.

## Usage

In game: three respecs in a row cost 1, 5 and 10 gold; the seventh 50, the
eighth 60. After a weekly reset the next respec costs one step less.

## Build Instructions

Part of the basic profile's source patch list (`patches/patches.sh`),
applied before compiling and reverted after. Round trip:
`scripts/test-source-patches`.
