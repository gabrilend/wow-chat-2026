-- idea: A tree of locked issues; answering one question at the root unlocks a chain of them, one after another downward.
-- page: 1
-- attempt: 1
-- written by scripts/compose-architecture-gifs, for the five architecture pages' pictures

canvas{ size = 256, fps = 25, length = 5.0, seed = 1001 }

stroke{ at = 0.0, lasts = 5.0, color = "violet", fade = "in", ease = "linear",
        shape = line{ from = {128, 30}, to = {64, 92} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 5.0, color = "violet", fade = "in", ease = "linear",
        shape = line{ from = {128, 30}, to = {192, 92} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 5.0, color = "violet", fade = "in", ease = "linear",
        shape = line{ from = {64, 92}, to = {36, 154} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 5.0, color = "violet", fade = "in", ease = "linear",
        shape = line{ from = {64, 92}, to = {99, 154} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 5.0, color = "violet", fade = "in", ease = "linear",
        shape = line{ from = {192, 92}, to = {161, 154} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 5.0, color = "violet", fade = "in", ease = "linear",
        shape = line{ from = {192, 92}, to = {217, 154} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 5.0, color = "violet", fade = "in", ease = "linear",
        shape = line{ from = {36, 154}, to = {13, 216} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 5.0, color = "violet", fade = "in", ease = "linear",
        shape = line{ from = {36, 154}, to = {50, 216} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 5.0, color = "violet", fade = "in", ease = "linear",
        shape = line{ from = {99, 154}, to = {84, 216} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 5.0, color = "violet", fade = "in", ease = "linear",
        shape = line{ from = {99, 154}, to = {122, 216} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 5.0, color = "violet", fade = "in", ease = "linear",
        shape = line{ from = {161, 154}, to = {136, 216} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 5.0, color = "violet", fade = "in", ease = "linear",
        shape = line{ from = {161, 154}, to = {175, 216} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 5.0, color = "violet", fade = "in", ease = "linear",
        shape = line{ from = {217, 154}, to = {200, 216} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 5.0, color = "violet", fade = "in", ease = "linear",
        shape = line{ from = {217, 154}, to = {232, 216} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 1.0, lasts = 0.6, color = "gold", fade = "flash", ease = "linear",
        shape = point{ at = {128, 30} },
        emit = { rate = 1600, spread = 2, speed = 45, aim = 0, drag = 3, jitter = 10, life = 0.4 } }

stroke{ at = 1.4, lasts = 0.7, color = "gold", fade = "hold", ease = "stroke",
        shape = line{ from = {128, 30}, to = {64, 92} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 2.1, lasts = 0.5, color = "jade", fade = "flash", ease = "linear",
        shape = point{ at = {64, 92} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 1.4, lasts = 0.7, color = "gold", fade = "hold", ease = "stroke",
        shape = line{ from = {128, 30}, to = {192, 92} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 2.1, lasts = 0.5, color = "jade", fade = "flash", ease = "linear",
        shape = point{ at = {192, 92} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 2.3, lasts = 0.7, color = "gold", fade = "hold", ease = "stroke",
        shape = line{ from = {64, 92}, to = {36, 154} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 3.0, lasts = 0.5, color = "jade", fade = "flash", ease = "linear",
        shape = point{ at = {36, 154} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 2.2, lasts = 0.7, color = "gold", fade = "hold", ease = "stroke",
        shape = line{ from = {64, 92}, to = {99, 154} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 2.9, lasts = 0.5, color = "jade", fade = "flash", ease = "linear",
        shape = point{ at = {99, 154} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 2.1, lasts = 0.7, color = "gold", fade = "hold", ease = "stroke",
        shape = line{ from = {192, 92}, to = {161, 154} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 2.8, lasts = 0.5, color = "jade", fade = "flash", ease = "linear",
        shape = point{ at = {161, 154} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 2.3, lasts = 0.7, color = "gold", fade = "hold", ease = "stroke",
        shape = line{ from = {192, 92}, to = {217, 154} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 3.0, lasts = 0.5, color = "jade", fade = "flash", ease = "linear",
        shape = point{ at = {217, 154} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 3.2, lasts = 0.7, color = "gold", fade = "hold", ease = "stroke",
        shape = line{ from = {36, 154}, to = {13, 216} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 3.9, lasts = 0.5, color = "jade", fade = "flash", ease = "linear",
        shape = point{ at = {13, 216} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 3.1, lasts = 0.7, color = "gold", fade = "hold", ease = "stroke",
        shape = line{ from = {36, 154}, to = {50, 216} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 3.8, lasts = 0.5, color = "jade", fade = "flash", ease = "linear",
        shape = point{ at = {50, 216} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 3.0, lasts = 0.7, color = "gold", fade = "hold", ease = "stroke",
        shape = line{ from = {99, 154}, to = {84, 216} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 3.7, lasts = 0.5, color = "jade", fade = "flash", ease = "linear",
        shape = point{ at = {84, 216} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 3.2, lasts = 0.7, color = "gold", fade = "hold", ease = "stroke",
        shape = line{ from = {99, 154}, to = {122, 216} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 3.9, lasts = 0.5, color = "jade", fade = "flash", ease = "linear",
        shape = point{ at = {122, 216} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 3.1, lasts = 0.7, color = "gold", fade = "hold", ease = "stroke",
        shape = line{ from = {161, 154}, to = {136, 216} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 3.8, lasts = 0.5, color = "jade", fade = "flash", ease = "linear",
        shape = point{ at = {136, 216} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 3.1, lasts = 0.7, color = "gold", fade = "hold", ease = "stroke",
        shape = line{ from = {161, 154}, to = {175, 216} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 3.8, lasts = 0.5, color = "jade", fade = "flash", ease = "linear",
        shape = point{ at = {175, 216} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 3.2, lasts = 0.7, color = "gold", fade = "hold", ease = "stroke",
        shape = line{ from = {217, 154}, to = {200, 216} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 3.9, lasts = 0.5, color = "jade", fade = "flash", ease = "linear",
        shape = point{ at = {200, 216} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 3.3, lasts = 0.7, color = "gold", fade = "hold", ease = "stroke",
        shape = line{ from = {217, 154}, to = {232, 216} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 4.0, lasts = 0.5, color = "jade", fade = "flash", ease = "linear",
        shape = point{ at = {232, 216} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }
