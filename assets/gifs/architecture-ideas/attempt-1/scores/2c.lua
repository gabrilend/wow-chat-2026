-- idea: Six small panels, each walking the same maze a different way: one stuck and jittering, the painted map gliding through.
-- page: 2
-- attempt: 1
-- written by scripts/compose-architecture-gifs, for the five architecture pages' pictures

canvas{ size = 256, fps = 25, length = 5.0, seed = 1001 }

stroke{ at = 0.0, lasts = 5.0, color = "ice", fade = "in", ease = "linear",
        shape = fill{ vertices = { {12, 40}, {84, 40}, {84, 120}, {12, 120} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 5.0, color = "ember", fade = "in", ease = "linear",
        shape = line{ from = {48, 40}, to = {48, 90} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.4, lasts = 2.0, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {22, 110}, to = {49, 103} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.4, lasts = 2.0, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {49, 103}, to = {74, 50} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.0, lasts = 5.0, color = "ice", fade = "in", ease = "linear",
        shape = fill{ vertices = { {92, 40}, {164, 40}, {164, 120}, {92, 120} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 5.0, color = "ember", fade = "in", ease = "linear",
        shape = line{ from = {128, 40}, to = {128, 90} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.4, lasts = 2.0, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {102, 110}, to = {128, 100} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.4, lasts = 2.0, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {128, 100}, to = {154, 50} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.0, lasts = 5.0, color = "ice", fade = "in", ease = "linear",
        shape = fill{ vertices = { {172, 40}, {244, 40}, {244, 120}, {172, 120} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 5.0, color = "ember", fade = "in", ease = "linear",
        shape = line{ from = {208, 40}, to = {208, 90} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.4, lasts = 2.0, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {182, 110}, to = {205, 104} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.4, lasts = 2.0, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {205, 104}, to = {234, 50} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.0, lasts = 5.0, color = "ice", fade = "in", ease = "linear",
        shape = fill{ vertices = { {12, 140}, {84, 140}, {84, 220}, {12, 220} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 5.0, color = "ember", fade = "in", ease = "linear",
        shape = line{ from = {48, 140}, to = {48, 190} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.4, lasts = 2.0, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {22, 210}, to = {48, 207} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.4, lasts = 2.0, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {48, 207}, to = {74, 150} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.0, lasts = 5.0, color = "ice", fade = "in", ease = "linear",
        shape = fill{ vertices = { {92, 140}, {164, 140}, {164, 220}, {92, 220} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 5.0, color = "ember", fade = "in", ease = "linear",
        shape = line{ from = {128, 140}, to = {128, 190} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.4, lasts = 2.0, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {102, 210}, to = {128, 209} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.4, lasts = 2.0, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {128, 209}, to = {154, 150} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.0, lasts = 5.0, color = "ice", fade = "in", ease = "linear",
        shape = fill{ vertices = { {172, 140}, {244, 140}, {244, 220}, {172, 220} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.0, lasts = 5.0, color = "ember", fade = "in", ease = "linear",
        shape = line{ from = {208, 140}, to = {208, 190} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.7, lasts = 0.4, color = "rose", fade = "hold", ease = "linear",
        shape = line{ from = {182, 210}, to = {197, 187} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.1, lasts = 0.4, color = "rose", fade = "hold", ease = "linear",
        shape = line{ from = {197, 187}, to = {198, 182} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.5, lasts = 0.4, color = "rose", fade = "hold", ease = "linear",
        shape = line{ from = {198, 182}, to = {191, 176} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.9, lasts = 0.4, color = "rose", fade = "hold", ease = "linear",
        shape = line{ from = {191, 176}, to = {198, 184} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.3, lasts = 0.4, color = "rose", fade = "hold", ease = "linear",
        shape = line{ from = {198, 184}, to = {198, 174} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.7, lasts = 0.4, color = "rose", fade = "hold", ease = "linear",
        shape = line{ from = {198, 174}, to = {197, 179} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.1, lasts = 0.4, color = "rose", fade = "hold", ease = "linear",
        shape = line{ from = {197, 179}, to = {199, 186} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.5, lasts = 0.4, color = "rose", fade = "hold", ease = "linear",
        shape = line{ from = {199, 186}, to = {198, 174} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.9, lasts = 0.4, color = "rose", fade = "hold", ease = "linear",
        shape = line{ from = {198, 174}, to = {199, 182} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 4.3, lasts = 0.4, color = "rose", fade = "hold", ease = "linear",
        shape = line{ from = {199, 182}, to = {195, 188} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }
