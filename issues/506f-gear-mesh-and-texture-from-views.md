# 506f - Gear Mesh and Texture from Views

## Status
- Created: 2026-09-27
- Phase: 5
- Parent: 506
- Blocked by: 506e; Hunyuan3D-2 multi-view weights; the 1080 Ti (or a
  remote host) able to run them
- Priority: High

## Current Behavior

**Mesh written 2026-09-27, untested**: `assets/gear-designs/comfyui/
to-3d-multiview.json`: four views (front, left, back, right: the middle
ring's views named in `camera-plan.lua`'s `mesh_inputs`), each CLIP-vision
encoded, into ComfyUI's built-in `Hunyuan3Dv2ConditioningMultiView`, the
3D latent, a seeded sampler, decode to voxels, voxels to mesh, save GLB.
The client fills the four from the design's newest middle-ring run
(`--workflow to-3d-multiview`); nodes and inputs checked against the
installed source (`scripts/test-gear-designs`). **Texturing: not built.**

## Intended Behavior

- A mesh from four agreeing views, better than from one (the backs and
  sides are seen, not guessed).
- A texture from all the ring views: each part of the mesh takes its
  colour from the view that faces it most squarely, blended where views
  meet; our own tool, since Hunyuan3D-2's texture painter is not a
  built-in node (the owner's rule, 506e).
- Colour slots beside the texture, like WC3 team colour (owner,
  2026-10-01: "we could mix-and-match the colors later on as we go"): a
  mask per slot (one 8-bit channel, same size as the texture, 0 = painted
  texture shows, 255 = the slot's colour shows) and a palette (list of
  colours, three bytes each) that fills them when drawn. Recolouring a
  design is a palette swap, not a regeneration. Which areas become slots
  (the plate, the cloth, the trim) is decided per piece; the design
  question bank's palette answer becomes the default palette. Shared with
  world-edit-to-execute W05a, which defines the mask format.

## Suggested Implementation Steps

1. Download the Hunyuan3D-2 multi-view weights (safetensors, ComfyUI's
   repackaged file; the name is the client's `--ckpt` default
   `hunyuan3d-dit-v2-mv.safetensors`, change it to the file's real name).
2. **Test**: `scripts/gear-comfy-submit --profile <id> --workflow
   to-3d-multiview` after 506e's middle ring. Pass: a `model_*.glb` in the
   design's folder that opens in a viewer and reads with
   `src/tools/model/gltf.lua`; compare with 506c's single-view mesh of the
   same design. On the 1080 Ti, begin at octree resolution 128 (506c's
   memory check).
3. Texturing: a projector in Lua: for each triangle, the ring view whose
   camera faces it most squarely (the camera plan gives each view's
   direction), its pixels sampled through the camera's projection into a
   texture laid out by the mesh's texture coordinates (a mesh without them
   gets them first: an atlas unwrap); blends at seams; tested on a known
   shape rendered from the plan.

## Related Issues

- **506** parent; **506e**; **506c** the single-view route; **506h**
