--------------------------------------------------------------------------------
-- conf.lua (issue 173a) - the custom client's window
--
-- For a general audience: LÖVE reads this before anything else: the
-- window's title and size, and that it needs a depth buffer (so nearer
-- ground hides farther ground when drawn in 3D).
--------------------------------------------------------------------------------

function love.conf(t)
    t.identity      = "everland-custom-client"
    t.window.title  = "Everland Ghostsong"
    t.window.width  = 1280
    t.window.height = 720
    t.window.resizable = true
    t.window.depth  = 24          -- depth buffer bits: needed for 3D
    t.window.msaa   = 0           -- smoothing off: with it on, the --shot picture comes out black (seen 2026-10-04)
    t.window.vsync  = 1
    t.modules.audio = false
    t.modules.sound = false
    t.modules.joystick = false
    t.modules.physics = false
end
