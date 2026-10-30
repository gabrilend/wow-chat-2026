-- idea: Bots keeping a gap from a wall, the gap narrowing as they near a doorway they need.
-- page: 2
-- attempt: 1
-- written by scripts/compose-architecture-gifs, for the five architecture pages' pictures

canvas{ size = 256, fps = 25, length = 5.0, seed = 1001 }

stroke{ at = 0.0, lasts = 5.0, color = "ember", fade = "in", ease = "linear",
        shape = line{ from = {128, 10}, to = {128, 116} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 0.0, lasts = 5.0, color = "ember", fade = "in", ease = "linear",
        shape = line{ from = {128, 144}, to = {128, 246} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 0.3, lasts = 2.4, color = "jade", fade = "hold", ease = "ease-out",
        shape = line{ from = {97, 30}, to = {112, 130} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.7, lasts = 1.6, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {112, 130}, to = {220, 130} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.6, lasts = 2.4, color = "jade", fade = "hold", ease = "ease-out",
        shape = line{ from = {93, 40}, to = {112, 130} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.0, lasts = 1.6, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {112, 130}, to = {220, 149} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.9, lasts = 2.4, color = "jade", fade = "hold", ease = "ease-out",
        shape = line{ from = {95, 226}, to = {112, 130} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.3, lasts = 1.6, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {112, 130}, to = {220, 144} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.2, lasts = 2.4, color = "jade", fade = "hold", ease = "ease-out",
        shape = line{ from = {96, 216}, to = {112, 130} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.6, lasts = 1.4, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {112, 130}, to = {220, 122} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.6, lasts = 1.0, color = "gold", fade = "flash", ease = "linear",
        shape = point{ at = {128, 130} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }
