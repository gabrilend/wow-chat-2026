--------------------------------------------------------------------------------
-- gltf.lua - read and write binary glTF (.glb) meshes (issue 506h)
--
-- For a general audience: glTF is the open 3D format the gear pipeline
-- keeps its models in (the image-to-3D stage, Hunyuan3D-2, writes .glb
-- files). This reads one into a plain list of triangles (positions,
-- normals, texture coordinates), which the converter to the game's model
-- format (m2.lua) then writes out; and writes such a list back to .glb, so
-- the tests can make a known model, read it back, and compare.
--
-- What it handles, and why only that: triangle meshes (mode 4) with float
-- positions, optional float normals and float texture coordinates, and
-- 8/16/32-bit indices, across every mesh node of the default scene with the
-- node transforms applied. That is what a generated item model is. Skins,
-- morph targets, animations and materials are not read here: animation
-- comes from a borrowed skeleton (issue 506g), and the item's texture is a
-- separate file the game names by itself (texture type 2, see m2.lua).
-- Anything outside that is an error naming what was met, never skipped.
--
-- A mesh is { positions = { x,y,z, x,y,z, ... }, normals = {...} or nil,
--             uvs = { u,v, ... } or nil, indices = { 0-based, 3 per tri } }
-- (flat arrays of numbers: a million-vertex mesh is then three big Lua
-- arrays, not a million tables).
--------------------------------------------------------------------------------

local ffi = require("ffi")

local Gltf = {}

-- {{{ local function json
-- dkjson from the shared libraries (the same one the gear-design tools use).
local json_lib
local function json()
    if not json_lib then
        package.path = "/home/ritz/programming/ai-stuff/libs/lua/?.lua;" .. package.path
        json_lib = require("dkjson")
    end
    return json_lib
end
-- }}}

-- {{{ component types
-- glTF's numbers for element types: 5121 unsigned byte, 5123 unsigned short,
-- 5125 unsigned int, 5126 float. Each maps to its C type and size.
local COMPONENT = {
    [5121] = { ctype = "const uint8_t*",  size = 1 },
    [5123] = { ctype = "const uint16_t*", size = 2 },
    [5125] = { ctype = "const uint32_t*", size = 4 },
    [5126] = { ctype = "const float*",    size = 4 },
}
local WIDTH = { SCALAR = 1, VEC2 = 2, VEC3 = 3, VEC4 = 4 }
-- }}}

-- {{{ local function matrix_of
-- A node's local transform as a 4x4 column-major matrix (glTF's order):
-- its "matrix", or built from translation, rotation (a quaternion x,y,z,w)
-- and scale.
local function matrix_of(node)
    if node.matrix then return node.matrix end
    local t = node.translation or { 0, 0, 0 }
    local r = node.rotation or { 0, 0, 0, 1 }
    local s = node.scale or { 1, 1, 1 }
    local x, y, z, w = r[1], r[2], r[3], r[4]
    local m = {
        (1 - 2 * (y * y + z * z)) * s[1], (2 * (x * y + z * w)) * s[1], (2 * (x * z - y * w)) * s[1], 0,
        (2 * (x * y - z * w)) * s[2], (1 - 2 * (x * x + z * z)) * s[2], (2 * (y * z + x * w)) * s[2], 0,
        (2 * (x * z + y * w)) * s[3], (2 * (y * z - x * w)) * s[3], (1 - 2 * (x * x + y * y)) * s[3], 0,
        t[1], t[2], t[3], 1,
    }
    return m
end

local function mul(a, b)
    local r = {}
    for c = 0, 3 do
        for row = 0, 3 do
            local v = 0
            for k = 0, 3 do v = v + a[k * 4 + row + 1] * b[c * 4 + k + 1] end
            r[c * 4 + row + 1] = v
        end
    end
    return r
end
-- }}}

-- {{{ local function accessor
-- The elements of an accessor as a flat Lua array of numbers.
local function accessor(doc, bin, index, path)
    local a = doc.accessors[index + 1] or error(string.format("gltf: %s names accessor %d, which doesn't exist", path, index))
    local comp = COMPONENT[a.componentType] or error(string.format("gltf: %s accessor %d has component type %s, not one this reader takes (5121, 5123, 5125, 5126)", path, index, tostring(a.componentType)))
    local width = WIDTH[a.type] or error(string.format("gltf: %s accessor %d is a %s, not SCALAR/VEC2/VEC3/VEC4", path, index, tostring(a.type)))
    if a.sparse then error(string.format("gltf: %s accessor %d is sparse; this reader doesn't take sparse accessors", path, index)) end
    local view = doc.bufferViews[a.bufferView + 1] or error(string.format("gltf: %s accessor %d has no buffer view", path, index))
    if (view.buffer or 0) ~= 0 then error(string.format("gltf: %s uses buffer %d; a .glb keeps everything in buffer 0", path, view.buffer)) end
    local stride = view.byteStride or (comp.size * width)
    local base = (view.byteOffset or 0) + (a.byteOffset or 0)
    local out = {}
    local n = 0
    for i = 0, a.count - 1 do
        local p = ffi.cast(comp.ctype, bin + base + i * stride)
        for k = 0, width - 1 do n = n + 1; out[n] = tonumber(p[k]) end
    end
    return out, width
end
-- }}}

-- {{{ function Gltf.read_glb
-- Read a .glb file into one merged triangle mesh (see the file's header for
-- the shape of the result). Every mesh node of the default scene (or of
-- scene 0) is placed with its full transform; normals are turned by the
-- same transform and renormalised.
function Gltf.read_glb(path)
    local f = io.open(path, "rb") or error("gltf: can't open " .. path)
    local data = f:read("*a"); f:close()
    local p = ffi.cast("const uint8_t*", data)
    if #data < 20 or ffi.string(p, 4) ~= "glTF" then error("gltf: " .. path .. " is not a binary glTF (no 'glTF' magic)") end
    local u = ffi.cast("const uint32_t*", p)
    if u[1] ~= 2 then error("gltf: " .. path .. " is glTF version " .. u[1] .. ", this reader takes version 2") end
    -- chunks: JSON first, then BIN
    local jlen, jtype = u[3], u[4]
    if jtype ~= 0x4E4F534A then error("gltf: " .. path .. ": the first chunk is not JSON") end
    local doc = json().decode(ffi.string(p + 20, jlen)) or error("gltf: " .. path .. ": the JSON chunk doesn't parse")
    local boff = 20 + jlen
    local bin
    if boff + 8 <= #data then
        local bu = ffi.cast("const uint32_t*", p + boff)
        if bu[1] ~= 0x004E4942 then error("gltf: " .. path .. ": the second chunk is not BIN") end
        bin = p + boff + 8
    else
        error("gltf: " .. path .. " has no BIN chunk (external buffers aren't read)")
    end

    local mesh = { positions = {}, normals = {}, uvs = {}, indices = {} }
    local has_normals, has_uvs = true, true
    local ident = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 }
    local scene = doc.scenes and doc.scenes[(doc.scene or 0) + 1]
    local roots = scene and scene.nodes or {}
    if #roots == 0 then error("gltf: " .. path .. " has no scene nodes") end

    local function visit(ni, parent)
        local node = doc.nodes[ni + 1]
        local m = mul(parent, matrix_of(node))
        if node.mesh then
            local gm = doc.meshes[node.mesh + 1]
            for pi, prim in ipairs(gm.primitives) do
                local where = string.format("mesh %d primitive %d", node.mesh, pi - 1)
                if (prim.mode or 4) ~= 4 then error("gltf: " .. path .. ": " .. where .. " is not triangles (mode " .. prim.mode .. ")") end
                local attr = prim.attributes
                if not attr.POSITION then error("gltf: " .. path .. ": " .. where .. " has no POSITION") end
                local pos = accessor(doc, bin, attr.POSITION, where .. " POSITION")
                local nor = attr.NORMAL and accessor(doc, bin, attr.NORMAL, where .. " NORMAL")
                local uv = attr.TEXCOORD_0 and accessor(doc, bin, attr.TEXCOORD_0, where .. " TEXCOORD_0")
                if not nor then has_normals = false end
                if not uv then has_uvs = false end
                local first = #mesh.positions / 3
                local vcount = #pos / 3
                for v = 0, vcount - 1 do
                    local x, y, z = pos[v * 3 + 1], pos[v * 3 + 2], pos[v * 3 + 3]
                    local n = #mesh.positions
                    mesh.positions[n + 1] = m[1] * x + m[5] * y + m[9] * z + m[13]
                    mesh.positions[n + 2] = m[2] * x + m[6] * y + m[10] * z + m[14]
                    mesh.positions[n + 3] = m[3] * x + m[7] * y + m[11] * z + m[15]
                    if nor then
                        local a, b, c = nor[v * 3 + 1], nor[v * 3 + 2], nor[v * 3 + 3]
                        local nx = m[1] * a + m[5] * b + m[9] * c
                        local ny = m[2] * a + m[6] * b + m[10] * c
                        local nz = m[3] * a + m[7] * b + m[11] * c
                        local l = math.sqrt(nx * nx + ny * ny + nz * nz)
                        if l < 1e-12 then l = 1 end
                        local k = #mesh.normals
                        mesh.normals[k + 1], mesh.normals[k + 2], mesh.normals[k + 3] = nx / l, ny / l, nz / l
                    end
                    if uv then
                        local k = #mesh.uvs
                        mesh.uvs[k + 1], mesh.uvs[k + 2] = uv[v * 2 + 1], uv[v * 2 + 2]
                    end
                end
                -- indices: given, or 0..n-1 in order
                local idx = prim.indices and accessor(doc, bin, prim.indices, where .. " indices")
                local ni2 = #mesh.indices
                if idx then
                    for i = 1, #idx do mesh.indices[ni2 + i] = idx[i] + first end
                else
                    for i = 0, vcount - 1 do mesh.indices[ni2 + i + 1] = first + i end
                end
            end
        end
        for _, c in ipairs(node.children or {}) do visit(c, m) end
    end
    for _, r in ipairs(roots) do visit(r, ident) end

    if #mesh.indices % 3 ~= 0 then error("gltf: " .. path .. ": index count " .. #mesh.indices .. " is not a multiple of 3") end
    if not has_normals then mesh.normals = nil end
    if not has_uvs then mesh.uvs = nil end
    return mesh
end
-- }}}

-- {{{ function Gltf.write_glb
-- Write a mesh (the shape read_glb returns) as a one-node .glb: positions,
-- normals and texture coordinates if present, 32-bit indices. Used by the
-- tests to make known models; not the pipeline's main output.
function Gltf.write_glb(path, mesh)
    local nv = #mesh.positions / 3
    local parts, views, accessors = {}, {}, {}
    local offset = 0
    local function add(values, ctype, size, comp, typ, count, extra)
        local bytes = #values * size
        local buf = ffi.new(ctype .. "[?]", #values)
        for i = 1, #values do buf[i - 1] = values[i] end
        parts[#parts + 1] = ffi.string(buf, bytes)
        views[#views + 1] = { buffer = 0, byteOffset = offset, byteLength = bytes }
        local a = { bufferView = #views - 1, componentType = comp, count = count, type = typ }
        for k, v in pairs(extra or {}) do a[k] = v end
        accessors[#accessors + 1] = a
        offset = offset + bytes
        local pad = (4 - bytes % 4) % 4
        if pad > 0 then parts[#parts + 1] = string.rep("\0", pad); offset = offset + pad end
        return #accessors - 1
    end
    local mn, mx = { math.huge, math.huge, math.huge }, { -math.huge, -math.huge, -math.huge }
    for i = 0, nv - 1 do
        for k = 1, 3 do
            local v = mesh.positions[i * 3 + k]
            if v < mn[k] then mn[k] = v end
            if v > mx[k] then mx[k] = v end
        end
    end
    local attrs = { POSITION = add(mesh.positions, "float", 4, 5126, "VEC3", nv, { min = mn, max = mx }) }
    if mesh.normals then attrs.NORMAL = add(mesh.normals, "float", 4, 5126, "VEC3", nv) end
    if mesh.uvs then attrs.TEXCOORD_0 = add(mesh.uvs, "float", 4, 5126, "VEC2", nv) end
    local ind = add(mesh.indices, "uint32_t", 4, 5125, "SCALAR", #mesh.indices)
    local binary = table.concat(parts)
    local doc = {
        asset = { version = "2.0", generator = "wow-chat-2026 gltf.lua" },
        scene = 0, scenes = { { nodes = { 0 } } }, nodes = { { mesh = 0 } },
        meshes = { { primitives = { { attributes = attrs, indices = ind, mode = 4 } } } },
        buffers = { { byteLength = #binary } }, bufferViews = views, accessors = accessors,
    }
    local js = json().encode(doc)
    js = js .. string.rep(" ", (4 - #js % 4) % 4)
    local total = 12 + 8 + #js + 8 + #binary
    local head = ffi.new("uint32_t[5]", { 0x46546C67, 2, total, #js, 0x4E4F534A })
    local bhead = ffi.new("uint32_t[2]", { #binary, 0x004E4942 })
    local f = io.open(path, "wb") or error("gltf: can't write " .. path)
    f:write(ffi.string(head, 20), js, ffi.string(bhead, 8), binary)
    f:close()
end
-- }}}

return Gltf
