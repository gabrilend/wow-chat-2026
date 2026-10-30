-- idea: A broad talent, "all your Shadow spells", casting a wide net that catches several spell icons at once.
-- page: 3
-- attempt: 1
-- written by scripts/compose-architecture-gifs, for the five architecture pages' pictures

canvas{ size = 256, fps = 25, length = 5.0, seed = 1001 }

stroke{ at = 0.0, lasts = 5.0, color = "violet", fade = "in", ease = "linear",
        shape = point{ at = {128, 40} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 0.0, lasts = 5.0, color = "ice", fade = "in", ease = "linear",
        shape = fill{ vertices = { {18, 186}, {38, 186}, {38, 206}, {18, 206} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 1.0, lasts = 1.2, color = "violet", fade = "hold", ease = "ease-out",
        shape = line{ from = {128, 40}, to = {28, 196} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.7, lasts = 0.6, color = "violet", fade = "flash", ease = "linear",
        shape = point{ at = {28, 196} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 0.0, lasts = 5.0, color = "ice", fade = "in", ease = "linear",
        shape = fill{ vertices = { {68, 195}, {88, 195}, {88, 215}, {68, 215} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 1.0, lasts = 1.2, color = "violet", fade = "hold", ease = "ease-out",
        shape = line{ from = {128, 40}, to = {78, 205} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.8, lasts = 0.6, color = "violet", fade = "flash", ease = "linear",
        shape = point{ at = {78, 205} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 0.0, lasts = 5.0, color = "ice", fade = "in", ease = "linear",
        shape = fill{ vertices = { {118, 197}, {138, 197}, {138, 217}, {118, 217} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 1.0, lasts = 1.2, color = "violet", fade = "hold", ease = "ease-out",
        shape = line{ from = {128, 40}, to = {128, 207} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.9, lasts = 0.6, color = "violet", fade = "flash", ease = "linear",
        shape = point{ at = {128, 207} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 0.0, lasts = 5.0, color = "ice", fade = "in", ease = "linear",
        shape = fill{ vertices = { {168, 195}, {188, 195}, {188, 215}, {168, 215} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 1.0, lasts = 1.2, color = "violet", fade = "hold", ease = "ease-out",
        shape = line{ from = {128, 40}, to = {178, 205} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.0, lasts = 0.6, color = "violet", fade = "flash", ease = "linear",
        shape = point{ at = {178, 205} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 0.0, lasts = 5.0, color = "ice", fade = "in", ease = "linear",
        shape = fill{ vertices = { {218, 191}, {238, 191}, {238, 211}, {218, 211} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 1.0, lasts = 1.2, color = "violet", fade = "hold", ease = "ease-out",
        shape = line{ from = {128, 40}, to = {228, 201} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.1, lasts = 0.6, color = "violet", fade = "flash", ease = "linear",
        shape = point{ at = {228, 201} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 2.2, lasts = 1.0, color = "violet", fade = "hold", ease = "smoothstep",
        shape = arc{ center = {128, 120}, radius = 110, from = 7.5, to = 4.5, turn = "counterclockwise" },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }
