--------------------------------------------------------------------------------
-- main.lua (issue 173a) - first light: a night elf in Ashenvale
--
-- For a general audience: the first step of the project's own game client.
-- It opens a window on the ground of Ashenvale near Astranaar, read from
-- the very files the game server uses for heights (lib/maps.lua), and puts
-- a night elf there (a stand-in shape until real models, 173d) whom you
-- move with the game's own controls at 120% of the base speeds
-- (lib/mover.lua). No interface, no server connection yet.
--
-- Controls (the game's, except q):
--   W / S      forward / back            A / D     turn (strafe with the right mouse button held)
--   E          strafe right              space     jump
--   left mouse drag   turn the camera    right mouse drag   turn her and the camera
--   mouse wheel       zoom               q                  quit
--
-- Run: scripts/custom-client [PROJECT_DIR]
-- Check: scripts/custom-client [PROJECT_DIR] --shot   draws a few frames,
-- saves a picture to tmp/shared-memory/custom-client-shot.png and quits.
--------------------------------------------------------------------------------

local Maps   = require("lib.maps")
local Mover  = require("lib.mover")
local Mat4   = require("lib.mat4")
local Ground = require("lib.ground-mesh")
local NavmeshSlope = require("lib.navmesh-slope")

-- {{{ settings
local MAP_ID      = 1                                 -- Kalimdor
local START       = { x = 2717.0, y = -400.0, o = 3.6 } -- Astranaar, Ashenvale, facing the town's west side
local SPEED       = 1.2                               -- 120% of the base speeds (owner, 2026-10-04)
local TILE_REACH  = 1                                  -- tiles drawn round her own: 3 x 3
local SKY         = { 0.52, 0.66, 0.78 }
local ELF_HEIGHT  = 2.3                                -- yards, a night elf's height
local ELF_WIDTH   = 0.7
local ZOOM_MIN, ZOOM_MAX = 2.0, 40.0
-- }}}

local world, elf, origin
local tiles_drawn = {}                                 -- tile key -> mesh (or false)
local cam = { yaw = START.o, pitch = 0.35, dist = 12.0 }
local shader, elf_mesh
local dragging = { left = false, right = false }
local shot = { path = nil, frames = 0 }                 -- --shot: picture after a few frames, then quit

-- {{{ local function data_dir
-- The server's maps folder: given on the command line (--maps DIR), or
-- found from where this program sits (src/custom-client -> project root).
local function data_dir()
    for i, a in ipairs(arg or {}) do
        if a == "--maps" and arg[i + 1] then return arg[i + 1] end
    end
    local src = love.filesystem.getSource()
    return src:gsub("/src/custom%-client/?$", "") .. "/data-files/maps"
end
-- }}}

-- {{{ local function make_elf_mesh
-- The stand-in: an upright box her height, a pale point on her front so
-- her facing shows. Built at the origin, facing +x; moved each frame.
local function make_elf_mesh()
    local w, h = ELF_WIDTH / 2, ELF_HEIGHT
    local verts = {}
    local function quad(a, b, c, d, n, col)
        for _, p in ipairs({ a, b, c, a, c, d }) do
            verts[#verts + 1] = { p[1], p[2], p[3], n[1], n[2], n[3], col[1], col[2], col[3], 1 }
        end
    end
    local body = { 0.45, 0.30, 0.62 }                  -- night-elf violet
    local p = { {-w,-w,0},{w,-w,0},{w,w,0},{-w,w,0},{-w,-w,h},{w,-w,h},{w,w,h},{-w,w,h} }
    quad(p[1],p[2],p[6],p[5], {0,-1,0}, body)
    quad(p[2],p[3],p[7],p[6], {1,0,0},  body)
    quad(p[3],p[4],p[8],p[7], {0,1,0},  body)
    quad(p[4],p[1],p[5],p[8], {-1,0,0}, body)
    quad(p[5],p[6],p[7],p[8], {0,0,1},  body)
    -- her front: a pale patch where her face is
    local f = { 0.92, 0.88, 0.95 }
    quad({w+0.01,-0.15,h-0.45},{w+0.01,0.15,h-0.45},{w+0.01,0.15,h-0.15},{w+0.01,-0.15,h-0.15}, {1,0,0}, f)
    return love.graphics.newMesh(Ground.FORMAT, verts, "triangles", "static")
end
-- }}}

-- {{{ local function refresh_tiles
-- Keeps the 3 x 3 tiles round her loaded and turned into meshes.
local function refresh_tiles()
    local tx, ty = Maps.tile_of(elf.x, elf.y)
    for dx = -TILE_REACH, TILE_REACH do
        for dy = -TILE_REACH, TILE_REACH do
            local key = (tx + dx) * 64 + (ty + dy)
            if tiles_drawn[key] == nil then
                local t = world:tile(tx + dx, ty + dy)
                tiles_drawn[key] = t and Ground.build(t, origin.x, origin.y) or false
            end
        end
    end
end
-- }}}

-- {{{ love.load
function love.load()
    local dir = data_dir()
    world = Maps.world(dir, MAP_ID)
    local z = world:height(START.x, START.y)
    if z < -10000 then
        error(string.format("no ground at the start (%.1f, %.1f) in map %d from %s: is the maps folder right?",
            START.x, START.y, MAP_ID, dir))
    end
    -- the steepest walkable ground, from the server's navigation tiles
    -- (data-files/mmaps sits beside data-files/maps)
    local max_slope = NavmeshSlope.read(dir:gsub("/maps/?$", "/mmaps"), MAP_ID)
    elf = Mover.new(START.x, START.y, z, START.o, SPEED, max_slope)
    origin = { x = math.floor(START.x), y = math.floor(START.y) }
    shader = love.graphics.newShader([[
        uniform mat4 u_proj;
        uniform mat4 u_view;
        uniform mat4 u_model;
        attribute vec3 VertexNormal;
        varying vec3 v_normal;
        varying float v_dist;
        vec4 position(mat4 transform_projection, vec4 vertex_position) {
            vec4 world = u_model * vertex_position;
            v_normal = mat3(u_model) * VertexNormal;
            vec4 eye = u_view * world;
            v_dist = length(eye.xyz);
            return u_proj * eye;
        }
    ]], [[
        uniform vec3 u_sky;
        varying vec3 v_normal;
        varying float v_dist;
        vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
            vec3 sun = normalize(vec3(0.45, 0.30, 0.84));
            float light = max(dot(normalize(v_normal), sun), 0.0) * 0.75 + 0.30;
            vec3 c = color.rgb * light;
            float fog = clamp((v_dist - 120.0) / 520.0, 0.0, 1.0);
            return vec4(mix(c, u_sky, fog), 1.0);
        }
    ]])
    elf_mesh = make_elf_mesh()
    refresh_tiles()
    for i, a in ipairs(arg or {}) do
        if a == "--shot" then shot.path = arg[i + 1] end
    end
end
-- }}}

-- {{{ local function input_now
local function input_now()
    local k = love.keyboard.isDown
    return {
        forward      = k("w") or k("up") or (dragging.left and dragging.right),
        back         = k("s") or k("down"),
        left         = k("a") or k("left"),
        right        = k("d") or k("right"),
        strafe_right = k("e"),
        strafe_turns = dragging.right,
        jump         = k("space"),
    }
end
-- }}}

-- {{{ love.update
function love.update(dt)
    dt = math.min(dt, 0.1)                             -- a stalled frame doesn't fling her
    local before = elf.o
    Mover.step(elf, input_now(), dt, function(x, y) return world:height(x, y) end)
    -- the camera follows her turns (as the game's does) unless it is held
    if not dragging.left then cam.yaw = cam.yaw + (elf.o - before) end
    refresh_tiles()
    love.window.setTitle(string.format("Everland Ghostsong  -  Ashenvale  x %.1f  y %.1f  z %.1f", elf.x, elf.y, elf.z))
end
-- }}}

-- {{{ input: mouse and keys
function love.mousepressed(_, _, button)
    if button == 1 then dragging.left = true end
    if button == 2 then dragging.right = true; cam.yaw = elf.o end
    love.mouse.setRelativeMode(dragging.left or dragging.right)
end
function love.mousereleased(_, _, button)
    if button == 1 then dragging.left = false end
    if button == 2 then dragging.right = false end
    love.mouse.setRelativeMode(dragging.left or dragging.right)
end
function love.mousemoved(_, _, dx, dy)
    if not (dragging.left or dragging.right) then return end
    cam.yaw = cam.yaw - dx * 0.006
    cam.pitch = math.max(-0.4, math.min(1.45, cam.pitch + dy * 0.006))
    if dragging.right then elf.o = cam.yaw % (2 * math.pi) end   -- the right button turns her with the camera
end
function love.wheelmoved(_, wy)
    cam.dist = math.max(ZOOM_MIN, math.min(ZOOM_MAX, cam.dist * (wy > 0 and 0.85 or 1.18)))
end
function love.keypressed(key)
    if key == "q" then love.event.quit() end
end
-- }}}

-- {{{ love.draw
function love.draw()
    love.graphics.clear(SKY[1], SKY[2], SKY[3], 1, false, true)
    love.graphics.setDepthMode("lequal", true)
    love.graphics.setMeshCullMode("none")
    love.graphics.setShader(shader)

    -- the camera: behind her by the camera's own heading, raised by its pitch
    local hx, hy, hz = elf.x - origin.x, elf.y - origin.y, elf.z + ELF_HEIGHT * 0.85
    local cx = hx - math.cos(cam.yaw) * math.cos(cam.pitch) * cam.dist
    local cy = hy - math.sin(cam.yaw) * math.cos(cam.pitch) * cam.dist
    local cz = hz + math.sin(cam.pitch) * cam.dist
    -- don't let the camera sink into the ground
    local floor = world:height(cx + origin.x, cy + origin.y)
    if floor > -10000 then cz = math.max(cz, floor + 0.6) end
    local w, h = love.graphics.getDimensions()
    shader:send("u_proj", "row", Mat4.perspective(math.rad(60), w / h, 0.3, 1600))
    shader:send("u_view", "row", Mat4.look_at({ cx, cy, cz }, { hx, hy, hz }, { 0, 0, 1 }))
    shader:send("u_sky", SKY)

    shader:send("u_model", "row", { {1,0,0,0}, {0,1,0,0}, {0,0,1,0}, {0,0,0,1} })
    for _, mesh in pairs(tiles_drawn) do
        if mesh then love.graphics.draw(mesh) end
    end
    local c, s = math.cos(elf.o), math.sin(elf.o)
    shader:send("u_model", "row", { {c,-s,0,hx}, {s,c,0,hy}, {0,0,1,elf.z}, {0,0,0,1} })
    love.graphics.draw(elf_mesh)

    love.graphics.setShader()
    love.graphics.setDepthMode()

    -- --shot: after a few frames, the picture, then quit
    if shot.path then
        shot.frames = shot.frames + 1
        if shot.frames == 5 then
            love.graphics.captureScreenshot(function(img)
                local f = assert(io.open(shot.path, "wb"))
                f:write(img:encode("png"):getString())
                f:close()
                print("picture saved: " .. shot.path)
                love.event.quit()
            end)
        end
    end
end
-- }}}
