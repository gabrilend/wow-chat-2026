-- camera-plan.lua - where the "webcams" stand round a subject (issue 506e)
--
-- For a general audience: to build a 3D model (and later its animations)
-- from pictures, the subject is seen from all round. The owner's rig
-- (2026-09-27): "compass orientated webcams facing in"; "eight x (1 or 3 or
-- 5) webcam interially focused radially spread"; "a ring above and below
-- the middle ring. that's the 5 I mentioned. Each with 8 perspectives of
-- them on the subject, whatever kind of model it is that we're trying to
-- generatee." So: eight cameras on a circle, all facing the middle, one
-- every 45 degrees of the compass; the circle repeated at up to five
-- heights. The same plan at three levels: 1 ring (8 views), 3 rings (24),
-- 5 rings (40). Every stage that works from views uses this one plan: the
-- multi-view pictures (506e), texturing the mesh (506f), and later posing
-- and animating (506g, 506i), so a view's name always means the same
-- camera.
--
-- Elevation is the camera's angle above the subject's middle (negative:
-- below), in degrees; azimuth the compass bearing, 0 = the subject's front
-- (north), counting the way the multi-view model counts (to be checked on
-- the first run: issue 506e, "which way azimuth turns").
--
-- The heights are first choices (20 and 40 degrees apart), to tune once
-- views can be looked at; the multi-view model (Stable Zero123) was trained
-- on views within about 30 degrees above or below, so the 5-ring level's
-- outer rings (40) are at the edge of what it has seen.

return {
    -- the compass: eight views per ring, index 0..7 in the order the
    -- multi-view model produces them (one batch of eight, 45 degrees apart)
    azimuths = {
        { name = "n",  degrees = 0 },   { name = "ne", degrees = 45 },
        { name = "e",  degrees = 90 },  { name = "se", degrees = 135 },
        { name = "s",  degrees = 180 }, { name = "sw", degrees = 225 },
        { name = "w",  degrees = 270 }, { name = "nw", degrees = 315 },
    },
    -- the rings, middle first; a level of N rings takes the first N
    rings = {
        { name = "middle", elevation = 0 },
        { name = "above",  elevation = 20 },
        { name = "below",  elevation = -20 },
        { name = "higher", elevation = 40 },
        { name = "lower",  elevation = -40 },
    },
    levels = { 1, 3, 5 },
    -- the four views Hunyuan3D-2's multi-view input takes (front, left,
    -- back, right), as indexes into azimuths: the subject's left is seen
    -- from the camera on its left. Which compass index that is depends on
    -- which way the multi-view model turns (the check in 506e); these are
    -- the guesses for counter-clockwise azimuth seen from above.
    mesh_inputs = { front = 0, left = 2, back = 4, right = 6 },
    -- the view files: <prefix>_<ring>_NNNNN_.png as ComfyUI saves a batch,
    -- NNNNN counting 1..8 in azimuth order within one run
    view_prefix = "mv",
}
