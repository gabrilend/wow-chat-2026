-- idea: An answer typed into a message box folds into a paper plane and flies into a folder labelled "answers".
-- page: 1
-- attempt: 1
-- written by scripts/compose-architecture-gifs, for the five architecture pages' pictures

canvas{ size = 256, fps = 25, length = 5.0, seed = 1001 }

stroke{ at = 0.0, lasts = 5.0, color = "teal", fade = "in", ease = "linear",
        shape = fill{ vertices = { {30, 150}, {140, 150}, {140, 190}, {30, 190} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.4, lasts = 1.4, color = "gold", fade = "hold", ease = "linear",
        shape = line{ from = {38, 170}, to = {128, 170} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.0, lasts = 5.0, color = "jade", fade = "in", ease = "linear",
        shape = fill{ vertices = { {168, 53}, {212, 53}, {212, 83}, {168, 83} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 2.0, lasts = 1.6, color = "gold", fade = "hold", ease = "stroke",
        shape = arc{ center = {159, 170}, radius = 70, from = 9.0, to = 2.5, turn = "clockwise" },
        emit = { rate = 900, spread = 2, speed = 18, aim = 0.8, drag = 2.2, jitter = 18, life = 0.7 } }

stroke{ at = 3.7, lasts = 0.8, color = "gold", fade = "flash", ease = "linear",
        shape = point{ at = {190, 67} },
        emit = { rate = 1600, spread = 2, speed = 45, aim = 0, drag = 3, jitter = 10, life = 0.4 } }
