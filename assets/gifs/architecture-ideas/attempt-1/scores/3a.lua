
canvas{ size = 256, fps = 25, length = 5.0, seed = 1001 }

stroke{ at = 0.0, lasts = 2.0, color = "jade", fade = "out", ease = "linear",
        shape = fill{ vertices = { {32, 79}, {68, 79}, {68, 115}, {32, 115} }, sweep = "at-once" },
        emit = { rate = 700, spread = 1.5, speed = 4, aim = 0, drag = 2.5, jitter = 8, life = 0.8 } }

stroke{ at = 0.0, lasts = 2.0, color = "teal", fade = "out", ease = "linear",
        shape = fill{ vertices = { {188, 144}, {224, 144}, {224, 180}, {188, 180} }, sweep = "at-once" },
        emit = { rate = 700, spread = 1.5, speed = 4, aim = 0, drag = 2.5, jitter = 8, life = 0.8 } }

stroke{ at = 0.8, lasts = 1.8, color = "jade", fade = "hold", ease = "ease-out",
        shape = line{ from = {50, 97}, to = {128, 128} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 0.8, lasts = 1.8, color = "teal", fade = "hold", ease = "ease-out",
        shape = line{ from = {206, 162}, to = {128, 128} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 2.6, lasts = 0.6, color = "gold", fade = "flash", ease = "linear",
        shape = point{ at = {128, 128} },
        emit = { rate = 1600, spread = 2, speed = 45, aim = 0, drag = 3, jitter = 10, life = 0.4 } }

stroke{ at = 2.8, lasts = 2.2, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {110, 110}, {146, 110}, {146, 146}, {110, 146} }, sweep = "at-once" },
        emit = { rate = 700, spread = 1.5, speed = 4, aim = 0, drag = 2.5, jitter = 8, life = 0.8 } }
