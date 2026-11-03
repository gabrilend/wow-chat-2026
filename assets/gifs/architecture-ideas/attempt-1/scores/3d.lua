
canvas{ size = 256, fps = 25, length = 5.0, seed = 1001 }

stroke{ at = 0.8, lasts = 4.0, color = "ice", fade = "in", ease = "linear",
        shape = arc{ center = {88, 142}, radius = 46, from = 12.0, to = 11.9, turn = "clockwise" },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.3, lasts = 3.7, color = "violet", fade = "in", ease = "linear",
        shape = arc{ center = {76, 129}, radius = 46, from = 12.0, to = 11.9, turn = "clockwise" },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.8, lasts = 3.2, color = "teal", fade = "in", ease = "linear",
        shape = arc{ center = {90, 114}, radius = 46, from = 12.0, to = 11.9, turn = "clockwise" },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.3, lasts = 2.7, color = "rose", fade = "in", ease = "linear",
        shape = arc{ center = {104, 126}, radius = 46, from = 12.0, to = 11.9, turn = "clockwise" },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.8, lasts = 2.2, color = "gold", fade = "hold", ease = "stroke",
        shape = line{ from = {90, 128}, to = {220, 128} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 4.0, lasts = 1.0, color = "jade", fade = "flash", ease = "linear",
        shape = point{ at = {220, 128} },
        emit = { rate = 1600, spread = 2, speed = 45, aim = 0, drag = 3, jitter = 10, life = 0.4 } }
