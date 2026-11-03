-- movement-benchmark-targets.lua - what the movement benchmark holds each
-- owner's buddies to (issue 617e14f). Written by hand: design. The owner's
-- picture, 2026-10-27: "We're looking for something that feels whirling,
-- but semi chaotic, like a maelstrom of swirls but in all directions at
-- once. the player-bot buddies should circle about, and sometimes dodge
-- through scenery. They should explore". The numbers are ours, first
-- guesses to be set by the owner or by runs she says look right (617e14f's
-- open question). Each: the measure (scripts/lib/movement-judges.lua), and
-- the least or most it may be.
return {
    -- they move: the share of samples a buddy moved more than a yard since
    -- the last (standing is sometimes right, "sometimes they stand still",
    -- so not all; most of the time, though)
    { measure = "moving",    least = 0.60,
      why = "\"circle about\": buddies are mostly on the move" },
    -- they circle: the share of minute-long stretches in which a buddy's
    -- path turned at least half a circle in one direction
    { measure = "circling",  least = 0.30,
      why = "\"whirling\", \"a maelstrom of swirls\"" },
    -- both ways: of the circling stretches, the smaller of clockwise and
    -- anticlockwise over the larger (1: as many each way). The end state;
    -- for now one direction is being got right first (the owner,
    -- 2026-10-28: "Right now we're isolating one direction until we get the
    -- pattern right, then we do both"), so a one-way flock misses this on
    -- purpose until then
    { measure = "both_ways", least = 0.40,
      why = "\"in all directions at once\"" },
    -- winding: path length over the straight distance, a minute at a time,
    -- the median; straight lines are 1, standing jitter is very high
    { measure = "winding",   least = 1.5, most = 8.0,
      why = "\"semi chaotic\": not straight lines, not shuffling on a spot" },
    -- covering: the share of the clan's sub-zone's squares a buddy came
    -- within 20 yards of, over the stretch
    { measure = "covering",  least = 0.25,
      why = "\"They should explore, paving exploration bricks onto each part of the floor\"" },
    -- the watcher's rule breaks (scripts/watch-buddy-spread's rules), per
    -- buddy per 10 minutes
    { measure = "still",     most = 0.5,
      why = "a buddy standing 30 s while its owner is over 10 yards off: nothing moving it" },
    { measure = "stacked",   most = 0.5,
      why = "two on one spot for 10 s" },
}
