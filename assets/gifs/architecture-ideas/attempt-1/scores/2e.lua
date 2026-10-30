-- idea: A sun and moon cycling over a map as its paint thickens and the routes grow smoother, day after day.
-- page: 2
-- attempt: 1
-- written by scripts/compose-architecture-gifs, for the five architecture pages' pictures

canvas{ size = 256, fps = 25, length = 6.0, seed = 1001 }

stroke{ at = 0.0, lasts = 1.0, color = "gold", fade = "hold", ease = "linear",
        shape = arc{ center = {128, 110}, radius = 96, from = 9.0, to = 3.0, turn = "clockwise" },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 1.0, lasts = 1.0, color = "ice", fade = "hold", ease = "linear",
        shape = arc{ center = {128, 110}, radius = 96, from = 9.0, to = 3.0, turn = "clockwise" },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 0.2, lasts = 1.6, color = "jade", fade = "in-out", ease = "linear",
        shape = line{ from = {24, 220}, to = {59, 182} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.2, lasts = 1.6, color = "jade", fade = "in-out", ease = "linear",
        shape = line{ from = {59, 182}, to = {94, 202} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.2, lasts = 1.6, color = "jade", fade = "in-out", ease = "linear",
        shape = line{ from = {94, 202}, to = {129, 169} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.2, lasts = 1.6, color = "jade", fade = "in-out", ease = "linear",
        shape = line{ from = {129, 169}, to = {164, 148} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.2, lasts = 1.6, color = "jade", fade = "in-out", ease = "linear",
        shape = line{ from = {164, 148}, to = {199, 179} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.2, lasts = 1.6, color = "jade", fade = "in-out", ease = "linear",
        shape = line{ from = {199, 179}, to = {234, 130} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.0, lasts = 2.0, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {20, 150}, {236, 150}, {236, 240}, {20, 240} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 2.0, lasts = 1.0, color = "gold", fade = "hold", ease = "linear",
        shape = arc{ center = {128, 110}, radius = 96, from = 9.0, to = 3.0, turn = "clockwise" },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 3.0, lasts = 1.0, color = "ice", fade = "hold", ease = "linear",
        shape = arc{ center = {128, 110}, radius = 96, from = 9.0, to = 3.0, turn = "clockwise" },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 2.2, lasts = 1.6, color = "jade", fade = "in-out", ease = "linear",
        shape = line{ from = {24, 220}, to = {59, 209} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.2, lasts = 1.6, color = "jade", fade = "in-out", ease = "linear",
        shape = line{ from = {59, 209}, to = {94, 206} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.2, lasts = 1.6, color = "jade", fade = "in-out", ease = "linear",
        shape = line{ from = {94, 206}, to = {129, 186} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.2, lasts = 1.6, color = "jade", fade = "in-out", ease = "linear",
        shape = line{ from = {129, 186}, to = {164, 179} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.2, lasts = 1.6, color = "jade", fade = "in-out", ease = "linear",
        shape = line{ from = {164, 179}, to = {199, 160} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.2, lasts = 1.6, color = "jade", fade = "in-out", ease = "linear",
        shape = line{ from = {199, 160}, to = {234, 147} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.0, lasts = 2.0, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {20, 154}, {236, 154}, {236, 240}, {20, 240} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 4.0, lasts = 1.0, color = "gold", fade = "hold", ease = "linear",
        shape = arc{ center = {128, 110}, radius = 96, from = 9.0, to = 3.0, turn = "clockwise" },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 5.0, lasts = 1.0, color = "ice", fade = "hold", ease = "linear",
        shape = arc{ center = {128, 110}, radius = 96, from = 9.0, to = 3.0, turn = "clockwise" },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 4.2, lasts = 1.6, color = "gold", fade = "in-out", ease = "linear",
        shape = line{ from = {24, 220}, to = {59, 201} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 4.2, lasts = 1.6, color = "gold", fade = "in-out", ease = "linear",
        shape = line{ from = {59, 201}, to = {94, 189} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 4.2, lasts = 1.6, color = "gold", fade = "in-out", ease = "linear",
        shape = line{ from = {94, 189}, to = {129, 183} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 4.2, lasts = 1.6, color = "gold", fade = "in-out", ease = "linear",
        shape = line{ from = {129, 183}, to = {164, 166} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 4.2, lasts = 1.6, color = "gold", fade = "in-out", ease = "linear",
        shape = line{ from = {164, 166}, to = {199, 163} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 4.2, lasts = 1.6, color = "gold", fade = "in-out", ease = "linear",
        shape = line{ from = {199, 163}, to = {234, 153} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 4.0, lasts = 2.0, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {20, 158}, {236, 158}, {236, 240}, {20, 240} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }
