-- judge-variants.lua - the named runs of the fish-school sandbox that the
-- judging machinery photographs and judges (issue 617e16b). Written by
-- hand: which situations a change to the flock is tried in ("We can try
-- multiple attempts each round of code iteration, like pushing all of them
-- into the same sub-zone or whatever", the owner, 2026-10-28).
-- Each run: name; continent (0 Eastern Kingdoms, 1 Kalimdor); zone (its
-- name); fence (its rank in the zone, 0 the largest); bots; turn (1
-- clockwise, -1 anticlockwise, 0 each its own: clockwise for now, "Right now
-- we're isolating one direction until we get the pattern right, then we do
-- both"); moments: seconds of play at which a frame is taken.
return {
    { name = "barrens-largest-clockwise",   continent = 1, zone = "The Barrens", fence = 0, bots = 36, turn = 1, moments = { 60, 120, 240 } },
    { name = "barrens-third-clockwise",     continent = 1, zone = "The Barrens", fence = 2, bots = 36, turn = 1, moments = { 60, 120, 240 } },
    { name = "dun-morogh-largest-clockwise", continent = 0, zone = "Dun Morogh", fence = 0, bots = 36, turn = 1, moments = { 60, 120, 240 } },
    { name = "elwynn-largest-clockwise",    continent = 0, zone = "Elwynn Forest", fence = 0, bots = 36, turn = 1, moments = { 60, 120, 240 } },
}
