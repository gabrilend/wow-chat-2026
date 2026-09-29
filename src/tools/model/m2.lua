--------------------------------------------------------------------------------
-- m2.lua - read the game's models (M2 + .skin, WotLK version 264) and write
-- static ones (issue 506h)
--
-- For a general audience: the 3.3.5 game client draws every creature, item
-- and doodad from an .m2 file (the model: vertices, bones, animations,
-- textures) and one or more .skin files beside it (how the vertices are
-- cut into triangles and draw calls). This reads both, and writes a
-- *static* model: one that stands still, like a helm, a shoulder pad, a
-- weapon or a shield, which is what the game's own item models are (one
-- root bone, one "Stand" animation that does nothing). Moving creatures
-- need a skeleton and animations borrowed from a stock model (issue 506g).
--
-- Where the layout comes from (the rubric strategem: read others' readers
-- for the rules, write our own): the server's own model extractor
-- (source-beta/src/tools/vmap4_extractor/modelheaders.h: the header, field
-- by field) and real client files, measured (docs/m2-format-wotlk.md: a
-- stock helm, shoulder and sword dumped record by record). Every record size
-- below was checked against those files: header 304 bytes, sequence 64,
-- bone 88, vertex 48, texture 16, track 20; skin header 48, submesh 48,
-- batch 24; every block aligned to 16 bytes, the model's name first after
-- the header.
--------------------------------------------------------------------------------

local ffi = require("ffi")

-- {{{ record layouts
-- M2Array: a count and an offset from the start of the file.
ffi.cdef[[
typedef struct { uint32_t n, ofs; } m2_array;
typedef struct {
    char magic[4]; uint32_t version;
    m2_array name; uint32_t flags;
    m2_array global_sequences, sequences, sequence_lookup, bones, key_bone_lookup, vertices;
    uint32_t views;
    m2_array colors, textures, transparency, texture_anims, texture_replace, materials,
             bone_lookup, texture_lookup, texture_unit_lookup, transparency_lookup, texture_anim_lookup;
    float bb_min[3], bb_max[3], bb_radius, cb_min[3], cb_max[3], cb_radius;
    m2_array collision_tris, collision_verts, collision_normals, attachments, attachment_lookup,
             events, lights, cameras, camera_lookup, ribbons, particles;
} m2_header;
typedef struct {
    uint16_t id, variation; uint32_t duration; float move_speed; uint32_t flags;
    int16_t frequency; uint16_t pad; uint32_t replay_min, replay_max, blend_time;
    float b_min[3], b_max[3], b_radius; int16_t next_variation; uint16_t alias_next;
} m2_sequence;
typedef struct { uint16_t interpolation; int16_t global_sequence; m2_array timestamps, values; } m2_track;
typedef struct {
    int32_t key_bone; uint32_t flags; int16_t parent; uint16_t submesh; uint16_t u1, u2;
    m2_track translation, rotation, scale; float pivot[3];
} m2_bone;
typedef struct { float pos[3]; uint8_t weights[4]; uint8_t bones[4]; float normal[3]; float uv[2]; float uv2[2]; } m2_vertex;
typedef struct { uint32_t type, flags; m2_array filename; } m2_texture;
typedef struct { uint16_t flags, blend; } m2_material;
typedef struct { char magic[4]; m2_array vertices, indices, bones, submeshes, batches; uint32_t bone_count_max; } m2_skin_header;
typedef struct {
    uint16_t id, level, vertex_start, vertex_count, index_start, index_count,
             bone_count, bone_combo, bone_influences, center_bone;
    float center[3], sort_center[3], sort_radius;
} m2_submesh;
typedef struct {
    uint8_t flags; int8_t priority; uint16_t shader, skin_section, geoset, color, material, layer,
             texture_count, texture_combo, uv_combo, weight_combo, transform_combo;
} m2_batch;
]]
local SIZE = {
    header = 304, sequence = 64, track = 20, bone = 88, vertex = 48, texture = 16, material = 4,
    skin_header = 48, submesh = 48, batch = 24,
}
for name, size in pairs(SIZE) do
    local ct = name == "header" and "m2_header" or ("m2_" .. name)
    assert(ffi.sizeof(ct) == size, "m2.lua: " .. ct .. " is " .. ffi.sizeof(ct) .. " bytes, the files say " .. size)
end
-- }}}

local M2 = {}
M2.VERSION = 264

-- {{{ reading
-- {{{ local function check_array
-- An array must lie inside the file: a model whose offsets point past its
-- end is broken, and is reported with which array and where.
local function check_array(len, arr, elem, what)
    if arr.n == 0 then return end
    if arr.ofs + arr.n * elem > len then
        error(string.format("m2: %s (%d x %d bytes at %d) runs past the end of the file (%d bytes)", what, arr.n, elem, arr.ofs, len))
    end
end
-- }}}

-- {{{ function M2.read
-- Read an .m2 and its first .skin (both as strings of bytes) into plain
-- tables: the header's counts and bounds, the sequences, bones (without
-- their keyframes), vertices, textures, materials, the lookups, and the
-- skin's vertex lookup, triangle indices, submeshes and batches. Errors,
-- naming what was wrong, on a file that isn't a version-264 model or whose
-- arrays leave the file.
function M2.read(m2, skin)
    local len = #m2
    if len < SIZE.header then error("m2: file is " .. len .. " bytes, shorter than a header") end
    local p = ffi.cast("const uint8_t*", m2)
    local h = ffi.cast("const m2_header*", p)
    if ffi.string(h.magic, 4) ~= "MD20" then error("m2: no MD20 magic (got " .. ffi.string(h.magic, 4) .. ")") end
    if h.version ~= M2.VERSION then error("m2: version " .. h.version .. ", this reader takes " .. M2.VERSION .. " (WotLK)") end
    local model = { version = h.version, flags = h.flags, views = h.views, counts = {} }
    for _, f in ipairs({ "global_sequences", "sequences", "sequence_lookup", "bones", "key_bone_lookup", "vertices",
        "colors", "textures", "transparency", "texture_anims", "texture_replace", "materials", "bone_lookup",
        "texture_lookup", "texture_unit_lookup", "transparency_lookup", "texture_anim_lookup", "attachments",
        "events", "lights", "cameras", "ribbons", "particles" }) do
        model.counts[f] = h[f].n
    end
    check_array(len, h.name, 1, "the name")
    model.name = ffi.string(p + h.name.ofs, math.max(0, h.name.n - 1))
    model.bounds = { min = { h.bb_min[0], h.bb_min[1], h.bb_min[2] }, max = { h.bb_max[0], h.bb_max[1], h.bb_max[2] }, radius = h.bb_radius }

    check_array(len, h.sequences, SIZE.sequence, "the sequences")
    model.sequences = {}
    for i = 0, h.sequences.n - 1 do
        local s = ffi.cast("const m2_sequence*", p + h.sequences.ofs + i * SIZE.sequence)
        model.sequences[i + 1] = { id = s.id, variation = s.variation, duration = s.duration, flags = s.flags,
            frequency = s.frequency, blend_time = s.blend_time, next_variation = s.next_variation, alias_next = s.alias_next,
            bounds = { min = { s.b_min[0], s.b_min[1], s.b_min[2] }, max = { s.b_max[0], s.b_max[1], s.b_max[2] }, radius = s.b_radius } }
    end
    check_array(len, h.bones, SIZE.bone, "the bones")
    model.bones = {}
    for i = 0, h.bones.n - 1 do
        local b = ffi.cast("const m2_bone*", p + h.bones.ofs + i * SIZE.bone)
        model.bones[i + 1] = { key_bone = b.key_bone, flags = b.flags, parent = b.parent, submesh = b.submesh,
            pivot = { b.pivot[0], b.pivot[1], b.pivot[2] },
            keyframed = b.translation.timestamps.n + b.rotation.timestamps.n + b.scale.timestamps.n > 0 }
    end
    check_array(len, h.vertices, SIZE.vertex, "the vertices")
    local pos, nor, uv, wts = {}, {}, {}, {}
    for i = 0, h.vertices.n - 1 do
        local v = ffi.cast("const m2_vertex*", p + h.vertices.ofs + i * SIZE.vertex)
        pos[i * 3 + 1], pos[i * 3 + 2], pos[i * 3 + 3] = v.pos[0], v.pos[1], v.pos[2]
        nor[i * 3 + 1], nor[i * 3 + 2], nor[i * 3 + 3] = v.normal[0], v.normal[1], v.normal[2]
        uv[i * 2 + 1], uv[i * 2 + 2] = v.uv[0], v.uv[1]
        wts[i + 1] = { v.weights[0], v.weights[1], v.weights[2], v.weights[3], v.bones[0], v.bones[1], v.bones[2], v.bones[3] }
    end
    model.vertices = { positions = pos, normals = nor, uvs = uv, weights = wts }
    check_array(len, h.textures, SIZE.texture, "the textures")
    model.textures = {}
    for i = 0, h.textures.n - 1 do
        local t = ffi.cast("const m2_texture*", p + h.textures.ofs + i * SIZE.texture)
        check_array(len, t.filename, 1, "texture " .. i .. "'s file name")
        model.textures[i + 1] = { type = t.type, flags = t.flags, filename = ffi.string(p + t.filename.ofs, math.max(0, t.filename.n - 1)) }
    end
    check_array(len, h.materials, SIZE.material, "the materials")
    model.materials = {}
    for i = 0, h.materials.n - 1 do
        local m = ffi.cast("const m2_material*", p + h.materials.ofs + i * SIZE.material)
        model.materials[i + 1] = { flags = m.flags, blend = m.blend }
    end
    local function i16s(arr, what)
        check_array(len, arr, 2, what)
        local out = {}
        local q = ffi.cast("const int16_t*", p + arr.ofs)
        for i = 0, arr.n - 1 do out[i + 1] = q[i] end
        return out
    end
    model.lookups = {
        key_bone = i16s(h.key_bone_lookup, "the key bone lookup"), texture_replace = i16s(h.texture_replace, "the texture replace lookup"),
        bone = i16s(h.bone_lookup, "the bone lookup"), texture = i16s(h.texture_lookup, "the texture lookup"),
        texture_unit = i16s(h.texture_unit_lookup, "the texture unit lookup"), transparency = i16s(h.transparency_lookup, "the transparency lookup"),
        texture_anim = i16s(h.texture_anim_lookup, "the texture animation lookup"),
    }

    if skin then
        local sl = #skin
        if sl < SIZE.skin_header then error("m2: skin is " .. sl .. " bytes, shorter than its header") end
        local sp = ffi.cast("const uint8_t*", skin)
        local sh = ffi.cast("const m2_skin_header*", sp)
        if ffi.string(sh.magic, 4) ~= "SKIN" then error("m2: the skin has no SKIN magic") end
        check_array(sl, sh.vertices, 2, "the skin's vertex lookup")
        check_array(sl, sh.indices, 2, "the skin's triangle indices")
        check_array(sl, sh.bones, 4, "the skin's vertex bones")
        check_array(sl, sh.submeshes, SIZE.submesh, "the skin's submeshes")
        check_array(sl, sh.batches, SIZE.batch, "the skin's batches")
        local s = { bone_count_max = sh.bone_count_max, lookup = {}, indices = {}, submeshes = {}, batches = {} }
        local lk = ffi.cast("const uint16_t*", sp + sh.vertices.ofs)
        for i = 0, sh.vertices.n - 1 do s.lookup[i + 1] = lk[i] end
        local ix = ffi.cast("const uint16_t*", sp + sh.indices.ofs)
        for i = 0, sh.indices.n - 1 do s.indices[i + 1] = ix[i] end
        for i = 0, sh.submeshes.n - 1 do
            local m = ffi.cast("const m2_submesh*", sp + sh.submeshes.ofs + i * SIZE.submesh)
            s.submeshes[i + 1] = { id = m.id, level = m.level, vertex_start = m.vertex_start, vertex_count = m.vertex_count,
                index_start = m.index_start, index_count = m.index_count, bone_count = m.bone_count, bone_combo = m.bone_combo,
                bone_influences = m.bone_influences, center_bone = m.center_bone, sort_radius = m.sort_radius }
        end
        for i = 0, sh.batches.n - 1 do
            local b = ffi.cast("const m2_batch*", sp + sh.batches.ofs + i * SIZE.batch)
            s.batches[i + 1] = { flags = b.flags, priority = b.priority, shader = b.shader, skin_section = b.skin_section,
                geoset = b.geoset, color = b.color, material = b.material, texture_count = b.texture_count,
                texture_combo = b.texture_combo, uv_combo = b.uv_combo, weight_combo = b.weight_combo, transform_combo = b.transform_combo }
        end
        model.skin = s
    end
    return model
end
-- }}}

-- {{{ function M2.validate
-- The rules a model must keep to be drawable: every skin index points into
-- the vertex lookup, every lookup entry at a model vertex, every submesh's
-- ranges inside the skin, every batch at a submesh and a material, the
-- header's box holding every vertex. Returns a list of problems (empty when
-- sound); the tests call it on stock files and on ours alike.
function M2.validate(model)
    local problems = {}
    local function bad(fmt, ...) problems[#problems + 1] = string.format(fmt, ...) end
    local nv = #model.vertices.positions / 3
    local b = model.bounds
    local eps = 1e-3
    for i = 0, nv - 1 do
        for k = 1, 3 do
            local v = model.vertices.positions[i * 3 + k]
            if v < b.min[k] - eps or v > b.max[k] + eps then bad("vertex %d lies outside the header's box on axis %d", i, k); break end
        end
        if #problems > 5 then break end
    end
    local s = model.skin
    if not s then return problems end
    for i, v in ipairs(s.lookup) do if v >= nv then bad("skin lookup %d points at vertex %d of %d", i - 1, v, nv) break end end
    for i, v in ipairs(s.indices) do if v >= #s.lookup then bad("skin index %d points at lookup %d of %d", i - 1, v, #s.lookup) break end end
    if #s.indices % 3 ~= 0 then bad("skin index count %d is not a multiple of 3", #s.indices) end
    for i, m in ipairs(s.submeshes) do
        if m.vertex_start + m.vertex_count > #s.lookup then bad("submesh %d's vertices run past the lookup", i - 1) end
        if m.index_start + m.index_count > #s.indices then bad("submesh %d's indices run past the index list", i - 1) end
    end
    for i, bt in ipairs(s.batches) do
        if bt.skin_section >= #s.submeshes then bad("batch %d names submesh %d of %d", i - 1, bt.skin_section, #s.submeshes) end
        if bt.material >= #model.materials then bad("batch %d names material %d of %d", i - 1, bt.material, #model.materials) end
    end
    return problems
end
-- }}}

-- {{{ function M2.mesh_of
-- A read model's triangles as a plain mesh (gltf.lua's shape), in the
-- skin's vertex order, so a stock model can be written back out by
-- write_static and compared.
function M2.mesh_of(model)
    local s = model.skin or error("m2: mesh_of needs the model read with its skin")
    local mesh = { positions = {}, normals = {}, uvs = {}, indices = {} }
    for i, v in ipairs(s.lookup) do
        for k = 1, 3 do
            mesh.positions[(i - 1) * 3 + k] = model.vertices.positions[v * 3 + k]
            mesh.normals[(i - 1) * 3 + k] = model.vertices.normals[v * 3 + k]
        end
        mesh.uvs[(i - 1) * 2 + 1], mesh.uvs[(i - 1) * 2 + 2] = model.vertices.uvs[v * 2 + 1], model.vertices.uvs[v * 2 + 2]
    end
    for i, v in ipairs(s.indices) do mesh.indices[i] = v end
    return mesh
end
-- }}}
-- }}}

-- {{{ writing
-- {{{ local function builder
-- A byte buffer that places blocks one after another, each starting on a
-- 16-byte boundary (as the client's own files do), and remembers where.
local function builder(start)
    local parts, size = {}, start
    local b = {}
    function b.add(bytes)
        local pad = (16 - size % 16) % 16
        if pad > 0 then parts[#parts + 1] = string.rep("\0", pad); size = size + pad end
        local at = size
        parts[#parts + 1] = bytes
        size = size + #bytes
        return at
    end
    function b.finish()
        local pad = (16 - size % 16) % 16
        if pad > 0 then parts[#parts + 1] = string.rep("\0", pad); size = size + pad end
        return table.concat(parts), size
    end
    return b
end
local function bytes_of(ctype, count, fill)
    local arr = ffi.new(ctype .. "[?]", count)
    fill(arr)
    return ffi.string(arr, ffi.sizeof(ctype) * count)
end
-- }}}

-- {{{ local function bounds_of
-- The box round the positions and the sphere radius: the farthest vertex
-- from the box's middle.
local function bounds_of(pos)
    local mn, mx = { math.huge, math.huge, math.huge }, { -math.huge, -math.huge, -math.huge }
    for i = 0, #pos / 3 - 1 do
        for k = 1, 3 do
            local v = pos[i * 3 + k]
            if v < mn[k] then mn[k] = v end
            if v > mx[k] then mx[k] = v end
        end
    end
    local c = { (mn[1] + mx[1]) / 2, (mn[2] + mx[2]) / 2, (mn[3] + mx[3]) / 2 }
    local r = 0
    for i = 0, #pos / 3 - 1 do
        local dx, dy, dz = pos[i * 3 + 1] - c[1], pos[i * 3 + 2] - c[2], pos[i * 3 + 3] - c[3]
        local d = math.sqrt(dx * dx + dy * dy + dz * dz)
        if d > r then r = d end
    end
    return mn, mx, r, c
end
-- }}}

-- {{{ function M2.write_static
-- Write a static model (an item: helm, shoulder, weapon, shield) from a mesh
-- already in the game's model space (see M2.from_gltf for the turn from
-- glTF's). Returns the .m2 bytes and the .skin bytes (the skin is the
-- "<name>00.skin" beside the model).
--
-- Everything but the geometry copies what the game's own item models carry
-- (measured on stock helms and shoulders, docs/m2-format-wotlk.md): one
-- root bone with no keyframes, one "Stand" sequence (id 0) kept in the
-- model (flag 0x20, no .anim file), one texture of type 2 (the item's own
-- texture, which the game names through its item display data, so the file
-- name here is empty), a one-key transparency track fully opaque, the
-- lookups those need, one submesh and one draw batch.
--
-- opts: two_sided (material flag 0x4, as stock helms have), duration (the
--       Stand sequence's length in ms; default 333333, the stock shoulder's)
-- Errors when the mesh has more vertices or indices than the format's
-- 16-bit counts allow (65,535): a generated mesh must be reduced first
-- (issue 506h's decimation step), never cut silently.
function M2.write_static(mesh, name, opts)
    opts = opts or {}
    local nv = #mesh.positions / 3
    local ni = #mesh.indices
    if nv > 65535 then error(string.format("m2: %d vertices; a skin addresses at most 65,535 (reduce the mesh first)", nv)) end
    if ni > 65535 then error(string.format("m2: %d indices; a submesh counts at most 65,535 (reduce the mesh first)", ni)) end
    if ni % 3 ~= 0 then error("m2: index count " .. ni .. " is not a multiple of 3") end
    if not mesh.normals then error("m2: the mesh has no normals (M2.from_gltf makes them)") end
    if not mesh.uvs then error("m2: the mesh has no texture coordinates (an item's texture needs them)") end
    for i = 1, ni do
        if mesh.indices[i] < 0 or mesh.indices[i] >= nv then error(string.format("m2: index %d points at vertex %d of %d", i - 1, mesh.indices[i], nv)) end
    end
    local mn, mx, radius, centre = bounds_of(mesh.positions)

    local b = builder(SIZE.header)
    local h = ffi.new("m2_header")
    ffi.copy(h.magic, "MD20", 4)
    h.version = M2.VERSION
    h.views = 1

    h.name.n = #name + 1
    h.name.ofs = b.add(name .. "\0")

    h.sequences.n = 1
    h.sequences.ofs = b.add(bytes_of("m2_sequence", 1, function(s)
        s[0].id, s[0].variation, s[0].duration = 0, 0, opts.duration or 333333
        s[0].flags, s[0].frequency, s[0].blend_time = 0x20, 32767, 150
        for k = 0, 2 do s[0].b_min[k], s[0].b_max[k] = mn[k + 1], mx[k + 1] end
        s[0].b_radius, s[0].next_variation, s[0].alias_next = radius, -1, 0
    end))

    h.bones.n = 1
    h.bones.ofs = b.add(bytes_of("m2_bone", 1, function(bn)
        bn[0].key_bone, bn[0].flags, bn[0].parent, bn[0].submesh = -1, 0, -1, 0
        for _, t in ipairs({ bn[0].translation, bn[0].rotation, bn[0].scale }) do t.interpolation, t.global_sequence = 0, -1 end
        for k = 0, 2 do bn[0].pivot[k] = centre[k + 1] end
    end))

    h.key_bone_lookup.n = 1
    h.key_bone_lookup.ofs = b.add(bytes_of("int16_t", 1, function(a) a[0] = -1 end))

    h.vertices.n = nv
    h.vertices.ofs = b.add(bytes_of("m2_vertex", nv, function(v)
        for i = 0, nv - 1 do
            for k = 0, 2 do v[i].pos[k] = mesh.positions[i * 3 + k + 1]; v[i].normal[k] = mesh.normals[i * 3 + k + 1] end
            v[i].weights[0] = 255
            v[i].uv[0], v[i].uv[1] = mesh.uvs[i * 2 + 1], mesh.uvs[i * 2 + 2]
        end
    end))

    h.textures.n = 1
    local tex = ffi.new("m2_texture[1]")
    tex[0].type = 2
    local tex_at = b.add(string.rep("\0", SIZE.texture))
    tex[0].filename.n = 1
    tex[0].filename.ofs = b.add("\0")
    h.textures.ofs = tex_at

    -- transparency: one track, one key at time 0, fully opaque (32767)
    local tr = ffi.new("m2_track[1]")
    tr[0].interpolation, tr[0].global_sequence = 0, -1
    local tr_at = b.add(string.rep("\0", SIZE.track))
    h.transparency.n, h.transparency.ofs = 1, tr_at

    h.texture_replace.n = 3
    h.texture_replace.ofs = b.add(bytes_of("int16_t", 3, function(a) a[0], a[1], a[2] = -1, -1, 0 end))
    h.materials.n = 1
    h.materials.ofs = b.add(bytes_of("m2_material", 1, function(m) m[0].flags, m[0].blend = opts.two_sided and 4 or 0, 0 end))
    h.bone_lookup.n = 1
    h.bone_lookup.ofs = b.add(bytes_of("int16_t", 1, function(a) a[0] = 0 end))
    h.texture_lookup.n = 1
    h.texture_lookup.ofs = b.add(bytes_of("int16_t", 1, function(a) a[0] = 0 end))
    h.texture_unit_lookup.n = 1
    h.texture_unit_lookup.ofs = b.add(bytes_of("int16_t", 1, function(a) a[0] = 0 end))
    h.transparency_lookup.n = 1
    h.transparency_lookup.ofs = b.add(bytes_of("int16_t", 1, function(a) a[0] = 0 end))
    h.texture_anim_lookup.n = 1
    h.texture_anim_lookup.ofs = b.add(bytes_of("int16_t", 1, function(a) a[0] = -1 end))

    -- the transparency track's per-sequence arrays: one timestamp list and
    -- one value list, each holding one entry
    local ts_values = b.add(bytes_of("uint32_t", 1, function(a) a[0] = 0 end))
    local vs_values = b.add(bytes_of("int16_t", 1, function(a) a[0] = 32767 end))
    local ts_list = b.add(bytes_of("m2_array", 1, function(a) a[0].n, a[0].ofs = 1, ts_values end))
    local vs_list = b.add(bytes_of("m2_array", 1, function(a) a[0].n, a[0].ofs = 1, vs_values end))
    tr[0].timestamps.n, tr[0].timestamps.ofs = 1, ts_list
    tr[0].values.n, tr[0].values.ofs = 1, vs_list

    for k = 0, 2 do h.bb_min[k], h.bb_max[k] = mn[k + 1], mx[k + 1] end
    h.bb_radius = radius

    local body = b.finish()
    -- patch the records that were placed before their contents existed
    local buf = ffi.new("uint8_t[?]", SIZE.header + #body)
    ffi.copy(buf + SIZE.header, body, #body)
    ffi.copy(buf, h, SIZE.header)
    ffi.copy(buf + tex_at, tex, SIZE.texture)
    ffi.copy(buf + tr_at, tr, SIZE.track)
    local m2 = ffi.string(buf, SIZE.header + #body)

    -- the skin: the identity vertex lookup, the triangles, all vertices on
    -- bone 0, one submesh, one batch
    local sb = builder(SIZE.skin_header)
    local sh = ffi.new("m2_skin_header")
    ffi.copy(sh.magic, "SKIN", 4)
    sh.vertices.n = nv
    sh.vertices.ofs = sb.add(bytes_of("uint16_t", nv, function(a) for i = 0, nv - 1 do a[i] = i end end))
    sh.indices.n = ni
    sh.indices.ofs = sb.add(bytes_of("uint16_t", ni, function(a) for i = 0, ni - 1 do a[i] = mesh.indices[i + 1] end end))
    sh.bones.n = nv
    sh.bones.ofs = sb.add(string.rep("\0", 4 * nv))
    sh.submeshes.n = 1
    sh.submeshes.ofs = sb.add(bytes_of("m2_submesh", 1, function(s)
        s[0].vertex_count, s[0].index_count = nv, ni
        s[0].bone_count, s[0].bone_influences = 1, 1
        for k = 0, 2 do s[0].center[k], s[0].sort_center[k] = centre[k + 1], centre[k + 1] end
        s[0].sort_radius = radius
    end))
    sh.batches.n = 1
    sh.batches.ofs = sb.add(bytes_of("m2_batch", 1, function(bt)
        bt[0].flags, bt[0].color, bt[0].texture_count = 16, 65535, 1
    end))
    sh.bone_count_max = 21
    local sbody = sb.finish()
    local sbuf = ffi.new("uint8_t[?]", SIZE.skin_header + #sbody)
    ffi.copy(sbuf + SIZE.skin_header, sbody, #sbody)
    ffi.copy(sbuf, sh, SIZE.skin_header)
    return m2, ffi.string(sbuf, SIZE.skin_header + #sbody)
end
-- }}}

-- {{{ function M2.from_gltf
-- Turn a glTF mesh (gltf.lua's read_glb) into the game's model space.
-- glTF: +Y up, +Z the front, metres. The game's models: +Z up, +X the
-- front, yards. A proper turn (no mirroring, so triangles keep their
-- winding): game (x, y, z) = glTF (z, x, y), times `scale`.
-- scale: glTF units to the game's (default 1/0.9144, metres to yards; an
--        item model is further scaled by the game where it attaches, so
--        the caller sets the size the piece should have)
-- Missing normals are made from the triangles (area-weighted); missing
-- texture coordinates are an error unless opts.allow_no_uv (then zeros:
-- the model draws, the texture won't sit right).
function M2.from_gltf(g, opts)
    opts = opts or {}
    local s = opts.scale or (1 / 0.9144)
    local nv = #g.positions / 3
    local out = { positions = {}, normals = {}, uvs = {}, indices = {} }
    for i = 0, nv - 1 do
        local x, y, z = g.positions[i * 3 + 1], g.positions[i * 3 + 2], g.positions[i * 3 + 3]
        out.positions[i * 3 + 1], out.positions[i * 3 + 2], out.positions[i * 3 + 3] = z * s, x * s, y * s
    end
    for i = 1, #g.indices do out.indices[i] = g.indices[i] end
    if g.normals then
        for i = 0, nv - 1 do
            local x, y, z = g.normals[i * 3 + 1], g.normals[i * 3 + 2], g.normals[i * 3 + 3]
            out.normals[i * 3 + 1], out.normals[i * 3 + 2], out.normals[i * 3 + 3] = z, x, y
        end
    else
        for i = 1, nv * 3 do out.normals[i] = 0 end
        local P = out.positions
        for t = 0, #out.indices / 3 - 1 do
            local a, b, c = out.indices[t * 3 + 1], out.indices[t * 3 + 2], out.indices[t * 3 + 3]
            local ux, uy, uz = P[b * 3 + 1] - P[a * 3 + 1], P[b * 3 + 2] - P[a * 3 + 2], P[b * 3 + 3] - P[a * 3 + 3]
            local vx, vy, vz = P[c * 3 + 1] - P[a * 3 + 1], P[c * 3 + 2] - P[a * 3 + 2], P[c * 3 + 3] - P[a * 3 + 3]
            local nx, ny, nz = uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx
            for _, v in ipairs({ a, b, c }) do
                out.normals[v * 3 + 1] = out.normals[v * 3 + 1] + nx
                out.normals[v * 3 + 2] = out.normals[v * 3 + 2] + ny
                out.normals[v * 3 + 3] = out.normals[v * 3 + 3] + nz
            end
        end
        for i = 0, nv - 1 do
            local x, y, z = out.normals[i * 3 + 1], out.normals[i * 3 + 2], out.normals[i * 3 + 3]
            local l = math.sqrt(x * x + y * y + z * z)
            if l < 1e-12 then x, y, z, l = 0, 0, 1, 1 end
            out.normals[i * 3 + 1], out.normals[i * 3 + 2], out.normals[i * 3 + 3] = x / l, y / l, z / l
        end
    end
    if g.uvs then
        for i = 1, #g.uvs do out.uvs[i] = g.uvs[i] end
    elseif opts.allow_no_uv then
        for i = 1, nv * 2 do out.uvs[i] = 0 end
    else
        error("m2: the glTF mesh has no texture coordinates (TEXCOORD_0); pass allow_no_uv to write it untextured")
    end
    return out
end
-- }}}
-- }}}

return M2
