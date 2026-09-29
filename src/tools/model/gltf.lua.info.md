# gltf.lua

Read and write binary glTF (.glb) triangle meshes (issue 506h).

- `Gltf.read_glb(path) -> mesh` — every mesh node of the default scene,
  transforms applied, merged into one mesh:
  `{ positions = {x,y,z,...}, normals = {...} or nil, uvs = {u,v,...} or nil,
  indices = {0-based, 3 per triangle} }` (flat number arrays). Errors,
  naming what was met, on non-triangle primitives, sparse accessors,
  external buffers, or a file that isn't glTF 2 binary.
- `Gltf.write_glb(path, mesh)` — one node, float positions/normals/uvs,
  32-bit indices. Used by the tests to make known models.
