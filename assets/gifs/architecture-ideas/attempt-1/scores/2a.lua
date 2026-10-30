-- idea: 36 green dots exploring a dark map, painting gold cells as they walk, walls turning orange where they bump.
-- page: 2
-- attempt: 1
-- written by scripts/compose-architecture-gifs, for the five architecture pages' pictures

canvas{ size = 256, fps = 25, length = 5.0, seed = 1001 }

stroke{ at = 0.4, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {207, 133}, to = {234, 115} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.7, lasts = 4.3, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {229, 110}, {239, 110}, {239, 120}, {229, 120} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 1.1, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {234, 115}, to = {236, 138} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.4, lasts = 3.6, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {231, 133}, {241, 133}, {241, 143}, {231, 143} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 1.8, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {236, 138}, to = {207, 116} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.1, lasts = 2.9, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {202, 111}, {212, 111}, {212, 121}, {202, 121} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 2.5, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {207, 116}, to = {185, 104} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.8, lasts = 2.2, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {180, 99}, {190, 99}, {190, 109}, {180, 109} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 3.1, lasts = 1.9, color = "ember", fade = "in", ease = "linear",
        shape = line{ from = {177, 96}, to = {193, 112} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.2, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {185, 104}, to = {216, 85} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.5, lasts = 1.5, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {211, 80}, {221, 80}, {221, 90}, {211, 90} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 3.9, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {216, 85}, to = {184, 103} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 4.2, lasts = 0.8, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {179, 98}, {189, 98}, {189, 108}, {179, 108} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.2, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {149, 96}, to = {179, 94} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.5, lasts = 4.5, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {174, 89}, {184, 89}, {184, 99}, {174, 99} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.9, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {179, 94}, to = {218, 55} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.2, lasts = 3.8, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {213, 50}, {223, 50}, {223, 60}, {213, 60} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 1.6, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {218, 55}, to = {181, 41} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.9, lasts = 3.1, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {176, 36}, {186, 36}, {186, 46}, {176, 46} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 2.3, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {181, 41}, to = {217, 72} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.6, lasts = 2.4, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {212, 67}, {222, 67}, {222, 77}, {212, 77} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 3.0, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {217, 72}, to = {244, 90} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.3, lasts = 1.7, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {239, 85}, {249, 85}, {249, 95}, {239, 95} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 3.6, lasts = 1.4, color = "ember", fade = "in", ease = "linear",
        shape = line{ from = {236, 82}, to = {252, 98} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.7, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {244, 90}, to = {238, 107} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 4.0, lasts = 1.0, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {233, 102}, {243, 102}, {243, 112}, {233, 112} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.4, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {168, 40}, to = {154, 44} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.7, lasts = 4.3, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {149, 39}, {159, 39}, {159, 49}, {149, 49} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 1.1, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {154, 44}, to = {143, 81} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.4, lasts = 3.6, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {138, 76}, {148, 76}, {148, 86}, {138, 86} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 1.7, lasts = 3.3, color = "ember", fade = "in", ease = "linear",
        shape = line{ from = {135, 73}, to = {151, 89} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.8, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {143, 81}, to = {122, 85} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.1, lasts = 2.9, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {117, 80}, {127, 80}, {127, 90}, {117, 90} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 2.5, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {122, 85}, to = {88, 55} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.8, lasts = 2.2, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {83, 50}, {93, 50}, {93, 60}, {83, 60} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 3.2, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {88, 55}, to = {119, 29} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.5, lasts = 1.5, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {114, 24}, {124, 24}, {124, 34}, {114, 34} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 3.9, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {119, 29}, to = {151, 56} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 4.2, lasts = 0.8, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {146, 51}, {156, 51}, {156, 61}, {146, 61} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.2, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {51, 42}, to = {35, 77} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.5, lasts = 4.5, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {30, 72}, {40, 72}, {40, 82}, {30, 82} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.9, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {35, 77}, to = {47, 105} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.2, lasts = 3.8, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {42, 100}, {52, 100}, {52, 110}, {42, 110} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 1.6, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {47, 105}, to = {46, 81} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.9, lasts = 3.1, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {41, 76}, {51, 76}, {51, 86}, {41, 86} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 2.3, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {46, 81}, to = {12, 108} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.6, lasts = 2.4, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {7, 103}, {17, 103}, {17, 113}, {7, 113} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 2.9, lasts = 2.1, color = "ember", fade = "in", ease = "linear",
        shape = line{ from = {4, 100}, to = {20, 116} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.0, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {12, 108}, to = {12, 82} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.3, lasts = 1.7, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {7, 77}, {17, 77}, {17, 87}, {7, 87} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 3.6, lasts = 1.4, color = "ember", fade = "in", ease = "linear",
        shape = line{ from = {4, 74}, to = {20, 90} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.7, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {12, 82}, to = {12, 61} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 4.0, lasts = 1.0, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {7, 56}, {17, 56}, {17, 66}, {7, 66} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 4.3, lasts = 0.7, color = "ember", fade = "in", ease = "linear",
        shape = line{ from = {4, 53}, to = {20, 69} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.1, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {112, 192}, to = {123, 170} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.4, lasts = 4.6, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {118, 165}, {128, 165}, {128, 175}, {118, 175} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.8, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {123, 170}, to = {116, 149} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.1, lasts = 3.9, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {111, 144}, {121, 144}, {121, 154}, {111, 154} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 1.5, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {116, 149}, to = {111, 153} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.8, lasts = 3.2, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {106, 148}, {116, 148}, {116, 158}, {106, 158} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 2.2, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {111, 153}, to = {145, 126} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.5, lasts = 2.5, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {140, 121}, {150, 121}, {150, 131}, {140, 131} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 2.9, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {145, 126}, to = {160, 157} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.2, lasts = 1.8, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {155, 152}, {165, 152}, {165, 162}, {155, 162} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 3.6, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {160, 157}, to = {130, 162} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.9, lasts = 1.1, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {125, 157}, {135, 157}, {135, 167}, {125, 167} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.1, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {213, 132}, to = {226, 162} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.4, lasts = 4.6, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {221, 157}, {231, 157}, {231, 167}, {221, 167} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.8, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {226, 162}, to = {196, 196} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.1, lasts = 3.9, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {191, 191}, {201, 191}, {201, 201}, {191, 201} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 1.5, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {196, 196}, to = {202, 171} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.8, lasts = 3.2, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {197, 166}, {207, 166}, {207, 176}, {197, 176} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 2.1, lasts = 2.9, color = "ember", fade = "in", ease = "linear",
        shape = line{ from = {194, 163}, to = {210, 179} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.2, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {202, 171}, to = {187, 182} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.5, lasts = 2.5, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {182, 177}, {192, 177}, {192, 187}, {182, 187} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 2.9, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {187, 182}, to = {171, 177} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.2, lasts = 1.8, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {166, 172}, {176, 172}, {176, 182}, {166, 182} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 3.6, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {171, 177}, to = {199, 171} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.9, lasts = 1.1, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {194, 166}, {204, 166}, {204, 176}, {194, 176} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 4.2, lasts = 0.8, color = "ember", fade = "in", ease = "linear",
        shape = line{ from = {191, 163}, to = {207, 179} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.3, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {67, 73}, to = {81, 33} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.6, lasts = 4.4, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {76, 28}, {86, 28}, {86, 38}, {76, 38} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 1.0, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {81, 33}, to = {50, 48} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.3, lasts = 3.7, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {45, 43}, {55, 43}, {55, 53}, {45, 53} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 1.6, lasts = 3.4, color = "ember", fade = "in", ease = "linear",
        shape = line{ from = {42, 40}, to = {58, 56} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.7, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {50, 48}, to = {26, 37} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.0, lasts = 3.0, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {21, 32}, {31, 32}, {31, 42}, {21, 42} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 2.4, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {26, 37}, to = {12, 50} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.7, lasts = 2.3, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {7, 45}, {17, 45}, {17, 55}, {7, 55} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 3.0, lasts = 2.0, color = "ember", fade = "in", ease = "linear",
        shape = line{ from = {4, 42}, to = {20, 58} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.1, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {12, 50}, to = {47, 86} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.4, lasts = 1.6, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {42, 81}, {52, 81}, {52, 91}, {42, 91} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 3.8, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {47, 86}, to = {19, 124} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 4.1, lasts = 0.9, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {14, 119}, {24, 119}, {24, 129}, {14, 129} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.1, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {110, 50}, to = {89, 75} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 0.4, lasts = 4.6, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {84, 70}, {94, 70}, {94, 80}, {84, 80} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 0.8, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {89, 75}, to = {126, 56} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.1, lasts = 3.9, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {121, 51}, {131, 51}, {131, 61}, {121, 61} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 1.5, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {126, 56}, to = {91, 86} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 1.8, lasts = 3.2, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {86, 81}, {96, 81}, {96, 91}, {86, 91} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 2.2, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {91, 86}, to = {64, 54} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.5, lasts = 2.5, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {59, 49}, {69, 49}, {69, 59}, {59, 59} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 2.8, lasts = 2.2, color = "ember", fade = "in", ease = "linear",
        shape = line{ from = {56, 46}, to = {72, 62} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 2.9, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {64, 54}, to = {101, 28} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.2, lasts = 1.8, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {96, 23}, {106, 23}, {106, 33}, {96, 33} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 3.6, lasts = 0.7, color = "jade", fade = "hold", ease = "linear",
        shape = line{ from = {101, 28}, to = {110, 12} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }

stroke{ at = 3.9, lasts = 1.1, color = "gold", fade = "in", ease = "linear",
        shape = fill{ vertices = { {105, 7}, {115, 7}, {115, 17}, {105, 17} }, sweep = "at-once" },
        emit = { rate = 250, spread = 1.5, speed = 3, aim = 0, drag = 2.5, jitter = 6, life = 0.6 } }

stroke{ at = 4.2, lasts = 0.8, color = "ember", fade = "in", ease = "linear",
        shape = line{ from = {102, 4}, to = {118, 20} },
        emit = { rate = 500, spread = 1.2, speed = 10, aim = 0.9, drag = 2.5, jitter = 8, life = 0.5 } }
