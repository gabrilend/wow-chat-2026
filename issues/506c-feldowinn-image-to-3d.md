# 506c - Feldowinn Image to 3D

## Status
- Created: 2026-09-27
- Phase: 5
- Parent: 506
- Blocked by: 506b; image-to-3D weights installed; the 1080 Ti proven able
  to run them
- Priority: High

## Current Behavior

**Written 2026-09-27, untested**: `assets/feldowinn/comfyui/to-3d.json`
(checked against the checkout's node definitions like 506b's); the
client takes `--workflow to-3d`, defaulting to the design's newest view,
and the mesh lands beside its views as `output/feldowinn/<design
id>/model_*.glb`. The installation's ComfyUI checkout
already has native Hunyuan3D-2 nodes (conditioning, latent, decode to
voxels, voxels to mesh) and a GLB saver, and TRELLIS.2 nodes; no custom
nodes are needed. No image-to-3D weights are installed.

## Intended Behavior

- A workflow (`assets/feldowinn/comfyui/to-3d.json`): the
  image-only checkpoint loader (Hunyuan3D-2 DiT, its CLIP vision and
  VAE), the concept image, CLIP-vision encoding, Hunyuan3D-2
  conditioning, the 3D latent, a seeded sampler, decode to voxels,
  voxels to mesh (surface net), save as GLB under
  `feldowinn-3d/<profile id>`. Placeholders `__IMAGE__`, `__SEED__`,
  `__PREFIX__`, `__CKPT__`.
- The same client as 506b, with `--workflow to-3d`, saving the GLB.

**The graphics card risk.** The GTX 1080 Ti (Pascal, compute 6.1, 11 GB,
no cuDNN on this build) has no bfloat16 and runs half precision very
slowly, so ComfyUI will run these models in full precision: twice the
memory. The full Hunyuan3D-2 DiT may not fit in 11 GB at full precision;
the mini model should. TRELLIS.2 is larger still. How to check, in
order: (1) with ComfyUI running, load the mini checkpoint in a one-node
workflow and read the reported memory; (2) run `to-3d` at octree
resolution 128 and 1000 chunks; (3) raise toward 256 while it fits.

## Suggested Implementation Steps

1. Download the Hunyuan3D-2 mini checkpoint (ComfyUI's repackaged file)
   into the installation's models (checkpoints), import with its
   `import-models`.
2. The checks above, then one concept image through `to-3d`. Pass: a
   GLB that opens in a viewer and looks like the image's piece.

## Related Issues

- **506** parent; world-edit-to-execute W05 (fit, score, keep)
