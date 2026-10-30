-- idea: A player walking past a row of sleeping stand-ins; one wakes at random and rises to the player's level.
-- page: 4
-- attempt: 1
-- written by scripts/compose-architecture-gifs, for the five architecture pages' pictures

canvas{ size = 256, fps = 25, length = 5.0, seed = 1001 }

stroke{ at = 0.0, lasts = 5.0, color = "ice", fade = "out", ease = "linear",
        shape = point{ at = {40, 200} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 2.2, lasts = 1.2, color = "jade", fade = "hold", ease = "ease-out",
        shape = line{ from = {40, 200}, to = {40, 90} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 3.4, lasts = 1.6, color = "jade", fade = "flash", ease = "linear",
        shape = point{ at = {40, 90} },
        emit = { rate = 1600, spread = 2, speed = 45, aim = 0, drag = 3, jitter = 10, life = 0.4 } }

stroke{ at = 0.0, lasts = 5.0, color = "ice", fade = "in", ease = "linear",
        shape = point{ at = {66, 200} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 5.0, color = "ice", fade = "in", ease = "linear",
        shape = point{ at = {92, 200} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 5.0, color = "ice", fade = "in", ease = "linear",
        shape = point{ at = {118, 200} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 5.0, color = "ice", fade = "in", ease = "linear",
        shape = point{ at = {144, 200} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 5.0, color = "ice", fade = "in", ease = "linear",
        shape = point{ at = {170, 200} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 5.0, color = "ice", fade = "in", ease = "linear",
        shape = point{ at = {196, 200} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 5.0, color = "ice", fade = "in", ease = "linear",
        shape = point{ at = {222, 200} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 5.0, color = "gold", fade = "hold", ease = "linear",
        shape = line{ from = {10, 90}, to = {246, 90} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }
