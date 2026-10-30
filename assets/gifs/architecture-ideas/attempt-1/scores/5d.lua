-- idea: Two battleground windows side by side, the same sky changing in both at the same moment.
-- page: 5
-- attempt: 1
-- written by scripts/compose-architecture-gifs, for the five architecture pages' pictures

canvas{ size = 256, fps = 25, length = 5.0, seed = 1001 }

stroke{ at = 0.0, lasts = 5.0, color = "ice", fade = "in", ease = "linear",
        shape = line{ from = {14, 70}, to = {120, 70} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.0, lasts = 5.0, color = "ice", fade = "in", ease = "linear",
        shape = line{ from = {14, 186}, to = {120, 186} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.0, lasts = 1.3, color = "gold", fade = "in-out", ease = "linear",
        shape = fill{ vertices = { {14, 72}, {120, 72}, {120, 184}, {14, 184} }, sweep = "at-once" },
        emit = { rate = 700, spread = 1.5, speed = 4, aim = 0, drag = 2.5, jitter = 8, life = 0.8 } }

stroke{ at = 1.2, lasts = 1.3, color = "violet", fade = "in-out", ease = "linear",
        shape = fill{ vertices = { {14, 72}, {120, 72}, {120, 184}, {14, 184} }, sweep = "at-once" },
        emit = { rate = 700, spread = 1.5, speed = 4, aim = 0, drag = 2.5, jitter = 8, life = 0.8 } }

stroke{ at = 2.4, lasts = 1.3, color = "teal", fade = "in-out", ease = "linear",
        shape = fill{ vertices = { {14, 72}, {120, 72}, {120, 184}, {14, 184} }, sweep = "at-once" },
        emit = { rate = 700, spread = 1.5, speed = 4, aim = 0, drag = 2.5, jitter = 8, life = 0.8 } }

stroke{ at = 3.6, lasts = 1.3, color = "ice", fade = "in-out", ease = "linear",
        shape = fill{ vertices = { {14, 72}, {120, 72}, {120, 184}, {14, 184} }, sweep = "at-once" },
        emit = { rate = 700, spread = 1.5, speed = 4, aim = 0, drag = 2.5, jitter = 8, life = 0.8 } }

stroke{ at = 0.0, lasts = 5.0, color = "ice", fade = "in", ease = "linear",
        shape = line{ from = {136, 70}, to = {242, 70} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.0, lasts = 5.0, color = "ice", fade = "in", ease = "linear",
        shape = line{ from = {136, 186}, to = {242, 186} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.0, lasts = 1.3, color = "gold", fade = "in-out", ease = "linear",
        shape = fill{ vertices = { {136, 72}, {242, 72}, {242, 184}, {136, 184} }, sweep = "at-once" },
        emit = { rate = 700, spread = 1.5, speed = 4, aim = 0, drag = 2.5, jitter = 8, life = 0.8 } }

stroke{ at = 1.2, lasts = 1.3, color = "violet", fade = "in-out", ease = "linear",
        shape = fill{ vertices = { {136, 72}, {242, 72}, {242, 184}, {136, 184} }, sweep = "at-once" },
        emit = { rate = 700, spread = 1.5, speed = 4, aim = 0, drag = 2.5, jitter = 8, life = 0.8 } }

stroke{ at = 2.4, lasts = 1.3, color = "teal", fade = "in-out", ease = "linear",
        shape = fill{ vertices = { {136, 72}, {242, 72}, {242, 184}, {136, 184} }, sweep = "at-once" },
        emit = { rate = 700, spread = 1.5, speed = 4, aim = 0, drag = 2.5, jitter = 8, life = 0.8 } }

stroke{ at = 3.6, lasts = 1.3, color = "ice", fade = "in-out", ease = "linear",
        shape = fill{ vertices = { {136, 72}, {242, 72}, {242, 184}, {136, 184} }, sweep = "at-once" },
        emit = { rate = 700, spread = 1.5, speed = 4, aim = 0, drag = 2.5, jitter = 8, life = 0.8 } }
