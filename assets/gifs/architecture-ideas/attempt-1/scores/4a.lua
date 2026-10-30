-- idea: A deck dealing 64 figures onto a field, each flipping to show its class colour and a sword, shield or cross for its role.
-- page: 4
-- attempt: 1
-- written by scripts/compose-architecture-gifs, for the five architecture pages' pictures

canvas{ size = 256, fps = 25, length = 6.0, seed = 1001 }

stroke{ at = 0.2, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {24, 20} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.7, lasts = 5.3, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {24, 20} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 0.3, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {54, 20} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.8, lasts = 5.2, color = "jade", fade = "in", ease = "linear",
        shape = point{ at = {54, 20} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 0.3, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {84, 20} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.8, lasts = 5.2, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {84, 20} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 0.4, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {114, 20} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.9, lasts = 5.1, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {114, 20} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 0.5, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {144, 20} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.0, lasts = 5.0, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {144, 20} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 0.6, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {174, 20} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.1, lasts = 4.9, color = "jade", fade = "in", ease = "linear",
        shape = point{ at = {174, 20} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 0.6, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {204, 20} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.1, lasts = 4.9, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {204, 20} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 0.7, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {234, 20} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.2, lasts = 4.8, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {234, 20} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 0.8, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {24, 46} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.3, lasts = 4.7, color = "ice", fade = "in", ease = "linear",
        shape = point{ at = {24, 46} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 0.8, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {54, 46} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.3, lasts = 4.7, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {54, 46} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 0.9, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {84, 46} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.4, lasts = 4.6, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {84, 46} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 1.0, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {114, 46} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.5, lasts = 4.5, color = "jade", fade = "in", ease = "linear",
        shape = point{ at = {114, 46} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 1.0, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {144, 46} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.5, lasts = 4.5, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {144, 46} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 1.1, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {174, 46} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.6, lasts = 4.4, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {174, 46} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 1.2, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {204, 46} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.7, lasts = 4.3, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {204, 46} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 1.3, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {234, 46} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.8, lasts = 4.2, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {234, 46} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 1.3, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {24, 72} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.8, lasts = 4.2, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {24, 72} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 1.4, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {54, 72} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.9, lasts = 4.1, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {54, 72} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 1.5, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {84, 72} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.0, lasts = 4.0, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {84, 72} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 1.5, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {114, 72} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.0, lasts = 4.0, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {114, 72} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 1.6, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {144, 72} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.1, lasts = 3.9, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {144, 72} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 1.7, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {174, 72} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.2, lasts = 3.8, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {174, 72} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 1.7, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {204, 72} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.2, lasts = 3.8, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {204, 72} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 1.8, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {234, 72} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.3, lasts = 3.7, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {234, 72} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 1.9, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {24, 98} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.4, lasts = 3.6, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {24, 98} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 2.0, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {54, 98} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.5, lasts = 3.5, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {54, 98} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 2.0, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {84, 98} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.5, lasts = 3.5, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {84, 98} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 2.1, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {114, 98} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.6, lasts = 3.4, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {114, 98} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 2.2, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {144, 98} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.7, lasts = 3.3, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {144, 98} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 2.2, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {174, 98} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.7, lasts = 3.3, color = "jade", fade = "in", ease = "linear",
        shape = point{ at = {174, 98} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 2.3, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {204, 98} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.8, lasts = 3.2, color = "jade", fade = "in", ease = "linear",
        shape = point{ at = {204, 98} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 2.4, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {234, 98} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.9, lasts = 3.1, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {234, 98} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 2.4, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {24, 124} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.9, lasts = 3.1, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {24, 124} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 2.5, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {54, 124} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.0, lasts = 3.0, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {54, 124} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 2.6, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {84, 124} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.1, lasts = 2.9, color = "jade", fade = "in", ease = "linear",
        shape = point{ at = {84, 124} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 2.7, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {114, 124} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.2, lasts = 2.8, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {114, 124} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 2.7, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {144, 124} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.2, lasts = 2.8, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {144, 124} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 2.8, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {174, 124} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.3, lasts = 2.7, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {174, 124} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 2.9, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {204, 124} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.4, lasts = 2.6, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {204, 124} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 2.9, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {234, 124} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.4, lasts = 2.6, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {234, 124} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 3.0, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {24, 150} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.5, lasts = 2.5, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {24, 150} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 3.1, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {54, 150} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.6, lasts = 2.4, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {54, 150} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 3.1, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {84, 150} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.6, lasts = 2.4, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {84, 150} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 3.2, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {114, 150} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.7, lasts = 2.3, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {114, 150} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 3.3, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {144, 150} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.8, lasts = 2.2, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {144, 150} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 3.4, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {174, 150} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.9, lasts = 2.1, color = "jade", fade = "in", ease = "linear",
        shape = point{ at = {174, 150} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 3.4, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {204, 150} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.9, lasts = 2.1, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {204, 150} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 3.5, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {234, 150} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 4.0, lasts = 2.0, color = "jade", fade = "in", ease = "linear",
        shape = point{ at = {234, 150} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 3.6, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {24, 176} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 4.1, lasts = 1.9, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {24, 176} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 3.6, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {54, 176} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 4.1, lasts = 1.9, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {54, 176} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 3.7, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {84, 176} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 4.2, lasts = 1.8, color = "jade", fade = "in", ease = "linear",
        shape = point{ at = {84, 176} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 3.8, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {114, 176} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 4.3, lasts = 1.7, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {114, 176} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 3.8, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {144, 176} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 4.3, lasts = 1.7, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {144, 176} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 3.9, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {174, 176} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 4.4, lasts = 1.6, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {174, 176} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 4.0, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {204, 176} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 4.5, lasts = 1.5, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {204, 176} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 4.1, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {234, 176} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 4.6, lasts = 1.4, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {234, 176} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 4.1, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {24, 202} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 4.6, lasts = 1.4, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {24, 202} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 4.2, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {54, 202} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 4.7, lasts = 1.3, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {54, 202} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 4.3, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {84, 202} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 4.8, lasts = 1.2, color = "ice", fade = "in", ease = "linear",
        shape = point{ at = {84, 202} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 4.3, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {114, 202} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 4.8, lasts = 1.2, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {114, 202} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 4.4, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {144, 202} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 4.9, lasts = 1.1, color = "ice", fade = "in", ease = "linear",
        shape = point{ at = {144, 202} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 4.5, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {174, 202} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 5.0, lasts = 1.0, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {174, 202} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 4.5, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {204, 202} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 5.0, lasts = 1.0, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {204, 202} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }

stroke{ at = 4.6, lasts = 0.5, color = "gold", fade = "out", ease = "ease-out",
        shape = line{ from = {128, 246}, to = {234, 202} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 5.1, lasts = 0.9, color = "ember", fade = "in", ease = "linear",
        shape = point{ at = {234, 202} },
        emit = { rate = 500, spread = 1.5, speed = 20, aim = 0, drag = 3, jitter = 10, life = 0.35 } }
