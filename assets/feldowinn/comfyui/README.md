# Feldowinn's ComfyUI workflows (issues 506b, 506c)

UNTESTED: written 2026-09-27 while the ComfyUI installation at
`/mnt/kaun/stable-diffusion/` could not yet run. Each file is a graph in
ComfyUI's API format (the shape its `/prompt` endpoint takes, not the
editor's layout format). `scripts/test-feldowinn` checks, without running
ComfyUI, that every node type exists in that installation's checkout and
every input a node requires is given.

Placeholders, filled by `scripts/feldowinn-comfy-submit` (the same
convention as the installation's own `workflows/README.md`):

| Placeholder | Filled with |
|---|---|
| `__PROMPT__` | the profile's prompt |
| `__NEGATIVE__` | the shared negative prompt (`src/tools/feldowinn/profiles.lua`) |
| `__SEED__` | a whole number (the quoted placeholder becomes a bare number) |
| `__PREFIX__` | `feldowinn/<profile id>/view` or `feldowinn/<profile id>/model` (one folder per profile in ComfyUI's output folder) |
| `__CONTROL_IMAGE__` | a sketch uploaded to ComfyUI's input folder |
| `__IMAGE__` | a concept image uploaded to ComfyUI's input folder |
| `__CKPT__` | the Hunyuan3D-2 checkpoint's file name |

- `concept.json`: text to image. Dreamshaper-8 is installed in diffusers
  form, so it loads through the diffusers loader node (marked deprecated
  in ComfyUI, still present). 512 by 768, 28 steps, DPM++ 2M Karras.
- `concept-scribble.json`: the same, steered by a silhouette sketch
  through the installed scribble ControlNet.
- `to-3d.json`: image to 3D with ComfyUI's own Hunyuan3D-2 nodes (no custom
  nodes needed): the image-only checkpoint loader, CLIP-vision encoding,
  Hunyuan3D-2 conditioning, the 3D latent, sampling, decode to voxels,
  voxels to mesh, saved as GLB. Needs the Hunyuan3D-2 checkpoint (none is
  installed): start with the mini model on the 1080 Ti (issue 506c).

Not used: IP-Adapter (the weights are installed, but stock ComfyUI has no
IP-Adapter nodes; it needs a custom node pack the installation lacks).
