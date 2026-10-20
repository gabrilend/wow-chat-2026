
return {
    azimuths = {
        { name = "n",  degrees = 0 },   { name = "ne", degrees = 45 },
        { name = "e",  degrees = 90 },  { name = "se", degrees = 135 },
        { name = "s",  degrees = 180 }, { name = "sw", degrees = 225 },
        { name = "w",  degrees = 270 }, { name = "nw", degrees = 315 },
    },
    rings = {
        { name = "middle", elevation = 0 },
        { name = "above",  elevation = 20 },
        { name = "below",  elevation = -20 },
        { name = "higher", elevation = 40 },
        { name = "lower",  elevation = -40 },
    },
    levels = { 1, 3, 5 },
    mesh_inputs = { front = 0, left = 2, back = 4, right = 6 },
    view_prefix = "mv",
}
