--------------------------------------------------------------------------------
-- lib/mat4.lua (issue 173a) - the two camera matrices
--
-- For a general audience: drawing 3D on a flat screen takes two
-- transforms: the view (where the camera stands and looks) and the
-- projection (how much it sees, and perspective). Each is a 4 x 4 grid of
-- numbers; these build them, as rows, for the shader (sent with "row").
--------------------------------------------------------------------------------

local Mat4 = {}

-- {{{ function Mat4.perspective
-- Field of view `fovy` (radians, top to bottom), width / height `aspect`,
-- near and far clipping distances.
function Mat4.perspective(fovy, aspect, near, far)
    local f = 1 / math.tan(fovy / 2)
    return {
        { f / aspect, 0, 0, 0 },
        { 0, f, 0, 0 },
        { 0, 0, (far + near) / (near - far), (2 * far * near) / (near - far) },
        { 0, 0, -1, 0 },
    }
end
-- }}}

-- {{{ function Mat4.look_at
-- A camera at `eye` looking at `at`, with `up` the world's up (z, here).
function Mat4.look_at(eye, at, up)
    local fx, fy, fz = at[1] - eye[1], at[2] - eye[2], at[3] - eye[3]
    local fl = math.sqrt(fx * fx + fy * fy + fz * fz)
    fx, fy, fz = fx / fl, fy / fl, fz / fl
    -- side = forward x up
    local sx, sy, sz = fy * up[3] - fz * up[2], fz * up[1] - fx * up[3], fx * up[2] - fy * up[1]
    local sl = math.sqrt(sx * sx + sy * sy + sz * sz)
    sx, sy, sz = sx / sl, sy / sl, sz / sl
    -- true up = side x forward
    local ux, uy, uz = sy * fz - sz * fy, sz * fx - sx * fz, sx * fy - sy * fx
    return {
        { sx, sy, sz, -(sx * eye[1] + sy * eye[2] + sz * eye[3]) },
        { ux, uy, uz, -(ux * eye[1] + uy * eye[2] + uz * eye[3]) },
        { -fx, -fy, -fz, (fx * eye[1] + fy * eye[2] + fz * eye[3]) },
        { 0, 0, 0, 1 },
    }
end
-- }}}

return Mat4
