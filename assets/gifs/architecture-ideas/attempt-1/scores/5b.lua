-- idea: Rain freezing into snow mid-fall over a mountain valley, flickering between the two: slush.
-- page: 5
-- attempt: 1
-- written by scripts/compose-architecture-gifs, for the five architecture pages' pictures

canvas{ size = 256, fps = 25, length = 5.0, seed = 1001 }

stroke{ at = 0.0, lasts = 5.0, color = "violet", fade = "in", ease = "linear",
        shape = fill{ vertices = { {0, 256}, {70, 170}, {128, 210}, {190, 150}, {256, 256} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 2.8, lasts = 1.2, color = "ice", fade = "hold", ease = "linear",
        shape = line{ from = {107, 0}, to = {99, 170} },
        emit = { rate = 400, spread = 4, speed = 6, aim = 0.3, drag = 2, jitter = 40, life = 1.2 } }

stroke{ at = 3.7, lasts = 1.2, color = "ice", fade = "hold", ease = "linear",
        shape = line{ from = {89, 0}, to = {88, 170} },
        emit = { rate = 400, spread = 4, speed = 6, aim = 0.3, drag = 2, jitter = 40, life = 1.2 } }

stroke{ at = 2.6, lasts = 1.2, color = "ice", fade = "hold", ease = "linear",
        shape = line{ from = {179, 0}, to = {182, 170} },
        emit = { rate = 400, spread = 4, speed = 6, aim = 0.3, drag = 2, jitter = 40, life = 1.2 } }

stroke{ at = 2.3, lasts = 0.5, color = "teal", fade = "hold", ease = "linear",
        shape = line{ from = {68, 0}, to = {62, 170} },
        emit = { rate = 700, spread = 3, speed = 60, aim = 1, drag = 0.5, jitter = 4, life = 0.4 } }

stroke{ at = 3.1, lasts = 1.2, color = "ice", fade = "hold", ease = "linear",
        shape = line{ from = {208, 0}, to = {213, 170} },
        emit = { rate = 400, spread = 4, speed = 6, aim = 0.3, drag = 2, jitter = 40, life = 1.2 } }

stroke{ at = 3.6, lasts = 1.2, color = "ice", fade = "hold", ease = "linear",
        shape = line{ from = {191, 0}, to = {193, 170} },
        emit = { rate = 400, spread = 4, speed = 6, aim = 0.3, drag = 2, jitter = 40, life = 1.2 } }

stroke{ at = 3.8, lasts = 1.2, color = "ice", fade = "hold", ease = "linear",
        shape = line{ from = {31, 0}, to = {31, 170} },
        emit = { rate = 400, spread = 4, speed = 6, aim = 0.3, drag = 2, jitter = 40, life = 1.2 } }

stroke{ at = 1.6, lasts = 1.2, color = "ice", fade = "hold", ease = "linear",
        shape = line{ from = {135, 0}, to = {129, 170} },
        emit = { rate = 400, spread = 4, speed = 6, aim = 0.3, drag = 2, jitter = 40, life = 1.2 } }

stroke{ at = 2.1, lasts = 1.2, color = "ice", fade = "hold", ease = "linear",
        shape = line{ from = {241, 0}, to = {244, 170} },
        emit = { rate = 400, spread = 4, speed = 6, aim = 0.3, drag = 2, jitter = 40, life = 1.2 } }

stroke{ at = 2.0, lasts = 0.5, color = "teal", fade = "hold", ease = "linear",
        shape = line{ from = {165, 0}, to = {159, 170} },
        emit = { rate = 700, spread = 3, speed = 60, aim = 1, drag = 0.5, jitter = 4, life = 0.4 } }

stroke{ at = 3.4, lasts = 1.2, color = "ice", fade = "hold", ease = "linear",
        shape = line{ from = {244, 0}, to = {234, 170} },
        emit = { rate = 400, spread = 4, speed = 6, aim = 0.3, drag = 2, jitter = 40, life = 1.2 } }

stroke{ at = 3.8, lasts = 1.2, color = "ice", fade = "hold", ease = "linear",
        shape = line{ from = {161, 0}, to = {164, 170} },
        emit = { rate = 400, spread = 4, speed = 6, aim = 0.3, drag = 2, jitter = 40, life = 1.2 } }

stroke{ at = 0.4, lasts = 0.5, color = "teal", fade = "hold", ease = "linear",
        shape = line{ from = {148, 0}, to = {142, 170} },
        emit = { rate = 700, spread = 3, speed = 60, aim = 1, drag = 0.5, jitter = 4, life = 0.4 } }

stroke{ at = 1.1, lasts = 0.5, color = "teal", fade = "hold", ease = "linear",
        shape = line{ from = {80, 0}, to = {74, 170} },
        emit = { rate = 700, spread = 3, speed = 60, aim = 1, drag = 0.5, jitter = 4, life = 0.4 } }

stroke{ at = 1.3, lasts = 0.5, color = "teal", fade = "hold", ease = "linear",
        shape = line{ from = {83, 0}, to = {77, 170} },
        emit = { rate = 700, spread = 3, speed = 60, aim = 1, drag = 0.5, jitter = 4, life = 0.4 } }

stroke{ at = 2.2, lasts = 1.2, color = "ice", fade = "hold", ease = "linear",
        shape = line{ from = {50, 0}, to = {46, 170} },
        emit = { rate = 400, spread = 4, speed = 6, aim = 0.3, drag = 2, jitter = 40, life = 1.2 } }

stroke{ at = 0.6, lasts = 0.5, color = "teal", fade = "hold", ease = "linear",
        shape = line{ from = {133, 0}, to = {127, 170} },
        emit = { rate = 700, spread = 3, speed = 60, aim = 1, drag = 0.5, jitter = 4, life = 0.4 } }

stroke{ at = 4.1, lasts = 0.9, color = "ice", fade = "hold", ease = "linear",
        shape = line{ from = {205, 0}, to = {194, 170} },
        emit = { rate = 400, spread = 4, speed = 6, aim = 0.3, drag = 2, jitter = 40, life = 1.2 } }
