
canvas{ size = 256, fps = 25, length = 6.0, seed = 1001 }

stroke{ at = 0.0, lasts = 6.0, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {119, 29}, {137, 29}, {137, 47}, {119, 47} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 6.0, color = "violet", fade = "in", ease = "linear",
        shape = fill{ vertices = { {209, 119}, {227, 119}, {227, 137}, {209, 137} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 6.0, color = "ice", fade = "in", ease = "linear",
        shape = fill{ vertices = { {119, 209}, {137, 209}, {137, 227}, {119, 227} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 6.0, color = "jade", fade = "in", ease = "linear",
        shape = fill{ vertices = { {29, 119}, {47, 119}, {47, 137}, {29, 137} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.2, lasts = 2.6, color = "teal", fade = "hold", ease = "linear",
        shape = arc{ center = {128, 128}, radius = 90, from = 12.0, to = 11.9, turn = "clockwise" },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 2.6, lasts = 0.4, color = "gold", fade = "flash", ease = "linear",
        shape = point{ at = {128, 128} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 2.6, lasts = 3.4, color = "gold", fade = "in", ease = "linear",
        shape = line{ from = {118, 134}, to = {138, 134} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.0, lasts = 2.6, color = "teal", fade = "hold", ease = "linear",
        shape = arc{ center = {128, 128}, radius = 90, from = 12.0, to = 11.9, turn = "clockwise" },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 5.4, lasts = 0.4, color = "gold", fade = "flash", ease = "linear",
        shape = point{ at = {128, 114} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 5.4, lasts = 0.6, color = "gold", fade = "in", ease = "linear",
        shape = line{ from = {118, 120}, to = {138, 120} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }
