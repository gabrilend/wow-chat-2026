-- idea: A dark storm cloud drifting across the Alterac Valley map, leaving a fading glow where it has been.
-- page: 5
-- attempt: 1
-- written by scripts/compose-architecture-gifs, for the five architecture pages' pictures

canvas{ size = 256, fps = 25, length = 6.0, seed = 1001 }

stroke{ at = 0.0, lasts = 6.0, color = "ice", fade = "in", ease = "linear",
        shape = fill{ vertices = { {96, 10}, {150, 14}, {170, 70}, {160, 140}, {176, 200}, {150, 246}, {100, 244}, {84, 180}, {98, 110}, {80, 50} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.5, lasts = 0.5, color = "violet", fade = "hold", ease = "linear",
        shape = line{ from = {128, 30}, to = {119, 50} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 1.0, lasts = 2.5, color = "gold", fade = "out", ease = "linear",
        shape = point{ at = {119, 50} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 1.0, lasts = 0.5, color = "violet", fade = "hold", ease = "linear",
        shape = line{ from = {119, 50}, to = {117, 72} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 1.5, lasts = 2.5, color = "gold", fade = "out", ease = "linear",
        shape = point{ at = {117, 72} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 1.5, lasts = 0.5, color = "violet", fade = "hold", ease = "linear",
        shape = line{ from = {117, 72}, to = {109, 93} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 2.0, lasts = 2.5, color = "gold", fade = "out", ease = "linear",
        shape = point{ at = {109, 93} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 2.0, lasts = 0.5, color = "violet", fade = "hold", ease = "linear",
        shape = line{ from = {109, 93}, to = {98, 111} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 2.5, lasts = 2.5, color = "gold", fade = "out", ease = "linear",
        shape = point{ at = {98, 111} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 2.5, lasts = 0.5, color = "violet", fade = "hold", ease = "linear",
        shape = line{ from = {98, 111}, to = {95, 125} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 3.0, lasts = 2.5, color = "gold", fade = "out", ease = "linear",
        shape = point{ at = {95, 125} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 3.0, lasts = 0.5, color = "violet", fade = "hold", ease = "linear",
        shape = line{ from = {95, 125}, to = {95, 141} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 3.5, lasts = 2.5, color = "gold", fade = "out", ease = "linear",
        shape = point{ at = {95, 141} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 3.5, lasts = 0.5, color = "violet", fade = "hold", ease = "linear",
        shape = line{ from = {95, 141}, to = {95, 153} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 4.0, lasts = 2.0, color = "gold", fade = "out", ease = "linear",
        shape = point{ at = {95, 153} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 4.0, lasts = 0.5, color = "violet", fade = "hold", ease = "linear",
        shape = line{ from = {95, 153}, to = {95, 169} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 4.5, lasts = 1.5, color = "gold", fade = "out", ease = "linear",
        shape = point{ at = {95, 169} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 4.5, lasts = 0.5, color = "violet", fade = "hold", ease = "linear",
        shape = line{ from = {95, 169}, to = {95, 190} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 5.0, lasts = 1.0, color = "gold", fade = "out", ease = "linear",
        shape = point{ at = {95, 190} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 5.0, lasts = 0.5, color = "violet", fade = "hold", ease = "linear",
        shape = line{ from = {95, 190}, to = {95, 208} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 5.5, lasts = 0.5, color = "gold", fade = "out", ease = "linear",
        shape = point{ at = {95, 208} },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }
