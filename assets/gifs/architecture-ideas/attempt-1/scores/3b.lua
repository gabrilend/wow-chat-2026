-- idea: A tooltip sentence lighting up word by word, with threads running from "Rejuvenation" to the ability.
-- page: 3
-- attempt: 1
-- written by scripts/compose-architecture-gifs, for the five architecture pages' pictures

canvas{ size = 256, fps = 25, length = 5.0, seed = 1001 }

stroke{ at = 0.3, lasts = 4.7, color = "ice", fade = "in", ease = "linear",
        shape = line{ from = {20, 70}, to = {38, 70} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.6, lasts = 4.4, color = "ice", fade = "in", ease = "linear",
        shape = line{ from = {46, 70}, to = {73, 70} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.9, lasts = 4.1, color = "ice", fade = "in", ease = "linear",
        shape = line{ from = {81, 70}, to = {104, 70} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.2, lasts = 3.8, color = "ice", fade = "in", ease = "linear",
        shape = line{ from = {112, 70}, to = {128, 70} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.5, lasts = 3.5, color = "gold", fade = "in", ease = "linear",
        shape = line{ from = {136, 70}, to = {162, 70} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.8, lasts = 3.2, color = "ice", fade = "in", ease = "linear",
        shape = line{ from = {170, 70}, to = {188, 70} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.1, lasts = 2.9, color = "ice", fade = "in", ease = "linear",
        shape = line{ from = {196, 70}, to = {211, 70} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.6, lasts = 1.2, color = "gold", fade = "hold", ease = "stroke",
        shape = line{ from = {149, 74}, to = {128, 190} },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 3.8, lasts = 1.2, color = "jade", fade = "in", ease = "linear",
        shape = fill{ vertices = { {110, 172}, {146, 172}, {146, 208}, {110, 208} }, sweep = "at-once" },
        emit = { rate = 700, spread = 1.5, speed = 4, aim = 0, drag = 2.5, jitter = 8, life = 0.8 } }
