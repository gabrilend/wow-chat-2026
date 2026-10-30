-- idea: A heat map of the valley filling in evenly over a long time-lapse as the storm seeks the corners it has visited least.
-- page: 5
-- attempt: 1
-- written by scripts/compose-architecture-gifs, for the five architecture pages' pictures

canvas{ size = 256, fps = 25, length = 6.0, seed = 1001 }

stroke{ at = 0.0, lasts = 6.0, color = "ice", fade = "in", ease = "linear",
        shape = fill{ vertices = { {96, 10}, {150, 14}, {170, 70}, {160, 140}, {176, 200}, {150, 246}, {100, 244}, {84, 180}, {98, 110}, {80, 50} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.3, lasts = 5.7, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {110, 129}, {126, 129}, {126, 149}, {110, 149} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.5, lasts = 5.5, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {110, 106}, {126, 106}, {126, 126}, {110, 126} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.6, lasts = 5.4, color = "ember", fade = "in", ease = "linear",
        shape = fill{ vertices = { {110, 37}, {126, 37}, {126, 57}, {110, 57} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.7, lasts = 5.3, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {146, 60}, {162, 60}, {162, 80}, {146, 80} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.9, lasts = 5.1, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {146, 152}, {162, 152}, {162, 172}, {146, 172} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 1.0, lasts = 5.0, color = "ember", fade = "in", ease = "linear",
        shape = fill{ vertices = { {128, 106}, {144, 106}, {144, 126}, {128, 126} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 1.1, lasts = 4.9, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {146, 221}, {162, 221}, {162, 241}, {146, 241} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 1.2, lasts = 4.8, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {146, 198}, {162, 198}, {162, 218}, {146, 218} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 1.4, lasts = 4.6, color = "ember", fade = "in", ease = "linear",
        shape = fill{ vertices = { {146, 106}, {162, 106}, {162, 126}, {146, 126} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 1.5, lasts = 4.5, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {92, 175}, {108, 175}, {108, 195}, {92, 195} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 1.6, lasts = 4.4, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {146, 175}, {162, 175}, {162, 195}, {146, 195} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 1.8, lasts = 4.2, color = "ember", fade = "in", ease = "linear",
        shape = fill{ vertices = { {110, 14}, {126, 14}, {126, 34}, {110, 34} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 1.9, lasts = 4.1, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {92, 221}, {108, 221}, {108, 241}, {92, 241} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 2.0, lasts = 4.0, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {128, 60}, {144, 60}, {144, 80}, {128, 80} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 2.2, lasts = 3.8, color = "ember", fade = "in", ease = "linear",
        shape = fill{ vertices = { {110, 60}, {126, 60}, {126, 80}, {110, 80} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 2.3, lasts = 3.7, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {92, 37}, {108, 37}, {108, 57}, {92, 57} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 2.4, lasts = 3.6, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {92, 83}, {108, 83}, {108, 103}, {92, 103} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 2.5, lasts = 3.5, color = "ember", fade = "in", ease = "linear",
        shape = fill{ vertices = { {92, 198}, {108, 198}, {108, 218}, {92, 218} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 2.7, lasts = 3.3, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {110, 83}, {126, 83}, {126, 103}, {110, 103} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 2.8, lasts = 3.2, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {146, 129}, {162, 129}, {162, 149}, {146, 149} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 2.9, lasts = 3.1, color = "ember", fade = "in", ease = "linear",
        shape = fill{ vertices = { {128, 152}, {144, 152}, {144, 172}, {128, 172} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 3.1, lasts = 2.9, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {110, 175}, {126, 175}, {126, 195}, {110, 195} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 3.2, lasts = 2.8, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {128, 37}, {144, 37}, {144, 57}, {128, 57} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 3.3, lasts = 2.7, color = "ember", fade = "in", ease = "linear",
        shape = fill{ vertices = { {92, 106}, {108, 106}, {108, 126}, {92, 126} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 3.5, lasts = 2.5, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {92, 60}, {108, 60}, {108, 80}, {92, 80} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 3.6, lasts = 2.4, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {110, 221}, {126, 221}, {126, 241}, {110, 241} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 3.7, lasts = 2.3, color = "ember", fade = "in", ease = "linear",
        shape = fill{ vertices = { {128, 198}, {144, 198}, {144, 218}, {128, 218} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 3.8, lasts = 2.2, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {128, 175}, {144, 175}, {144, 195}, {128, 195} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 4.0, lasts = 2.0, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {146, 83}, {162, 83}, {162, 103}, {146, 103} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 4.1, lasts = 1.9, color = "ember", fade = "in", ease = "linear",
        shape = fill{ vertices = { {92, 152}, {108, 152}, {108, 172}, {92, 172} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 4.2, lasts = 1.8, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {128, 83}, {144, 83}, {144, 103}, {128, 103} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 4.4, lasts = 1.6, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {92, 129}, {108, 129}, {108, 149}, {92, 149} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 4.5, lasts = 1.5, color = "ember", fade = "in", ease = "linear",
        shape = fill{ vertices = { {128, 129}, {144, 129}, {144, 149}, {128, 149} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 4.6, lasts = 1.4, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {92, 14}, {108, 14}, {108, 34}, {92, 34} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 4.8, lasts = 1.2, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {128, 14}, {144, 14}, {144, 34}, {128, 34} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 4.9, lasts = 1.1, color = "ember", fade = "in", ease = "linear",
        shape = fill{ vertices = { {110, 152}, {126, 152}, {126, 172}, {110, 172} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 5.0, lasts = 1.0, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {146, 14}, {162, 14}, {162, 34}, {146, 34} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 5.1, lasts = 0.9, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {110, 198}, {126, 198}, {126, 218}, {110, 218} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 5.3, lasts = 0.7, color = "ember", fade = "in", ease = "linear",
        shape = fill{ vertices = { {146, 37}, {162, 37}, {162, 57}, {146, 57} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 5.4, lasts = 0.6, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {128, 221}, {144, 221}, {144, 241}, {128, 241} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }
