-- idea: A deck of weather cards (sun, fog, snow, slush) shuffled and dealt onto a timeline, each swelling and fading in turn.
-- page: 5
-- attempt: 1
-- written by scripts/compose-architecture-gifs, for the five architecture pages' pictures

canvas{ size = 256, fps = 25, length = 6.0, seed = 1001 }

stroke{ at = 0.0, lasts = 6.0, color = "ice", fade = "in", ease = "linear",
        shape = line{ from = {10, 200}, to = {246, 200} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.2, lasts = 0.9, color = "violet", fade = "in-out", ease = "smoothstep",
        shape = fill{ vertices = { {12, 120}, {42, 120}, {42, 190}, {12, 190} }, sweep = "radial" },
        emit = { rate = 700, spread = 1.5, speed = 4, aim = 0, drag = 2.5, jitter = 8, life = 0.8 } }

stroke{ at = 1.0, lasts = 0.9, color = "ice", fade = "in-out", ease = "smoothstep",
        shape = fill{ vertices = { {45, 120}, {75, 120}, {75, 190}, {45, 190} }, sweep = "radial" },
        emit = { rate = 700, spread = 1.5, speed = 4, aim = 0, drag = 2.5, jitter = 8, life = 0.8 } }

stroke{ at = 1.8, lasts = 0.9, color = "teal", fade = "in-out", ease = "smoothstep",
        shape = fill{ vertices = { {78, 120}, {108, 120}, {108, 190}, {78, 190} }, sweep = "radial" },
        emit = { rate = 700, spread = 1.5, speed = 4, aim = 0, drag = 2.5, jitter = 8, life = 0.8 } }

stroke{ at = 2.6, lasts = 0.9, color = "rose", fade = "in-out", ease = "smoothstep",
        shape = fill{ vertices = { {111, 120}, {141, 120}, {141, 190}, {111, 190} }, sweep = "radial" },
        emit = { rate = 700, spread = 1.5, speed = 4, aim = 0, drag = 2.5, jitter = 8, life = 0.8 } }

stroke{ at = 3.4, lasts = 0.9, color = "jade", fade = "in-out", ease = "smoothstep",
        shape = fill{ vertices = { {144, 120}, {174, 120}, {174, 190}, {144, 190} }, sweep = "radial" },
        emit = { rate = 700, spread = 1.5, speed = 4, aim = 0, drag = 2.5, jitter = 8, life = 0.8 } }

stroke{ at = 4.2, lasts = 0.9, color = "gold", fade = "in-out", ease = "smoothstep",
        shape = fill{ vertices = { {177, 120}, {207, 120}, {207, 190}, {177, 190} }, sweep = "radial" },
        emit = { rate = 700, spread = 1.5, speed = 4, aim = 0, drag = 2.5, jitter = 8, life = 0.8 } }

stroke{ at = 5.0, lasts = 0.9, color = "ember", fade = "in-out", ease = "smoothstep",
        shape = fill{ vertices = { {210, 120}, {240, 120}, {240, 190}, {210, 190} }, sweep = "radial" },
        emit = { rate = 700, spread = 1.5, speed = 4, aim = 0, drag = 2.5, jitter = 8, life = 0.8 } }
