# 506b - Feldowinn Concept Art

## Status
- Created: 2026-09-27
- Phase: 5
- Parent: 506
- Blocked by: 506a; the ComfyUI installation at /mnt/kaun/stable-diffusion/
  reaching a running server
- Priority: High

## Current Behavior

**Written 2026-09-27, untested** (ComfyUI can't run yet):
`assets/feldowinn/comfyui/concept.json`, `concept-scribble.json`, their
README, and `scripts/feldowinn-comfy-submit`. Checked without running
ComfyUI (`scripts/test-feldowinn`): every node type exists in the
installation's checkout, every input given belongs to its node, every
link points inside the graph, every placeholder is one the client fills;
Dreamshaper-8 and the scribble ControlNet are installed. Results land in
ComfyUI's output folder, `output/feldowinn/<design id>/view_*.png` (the
gallery reads them there), one line per file in
`assets/feldowinn/generated.tsv` (prompt, seed, workflow fingerprint).

## Intended Behavior

- A ComfyUI workflow in API format
  (`assets/feldowinn/comfyui/concept.json`): Dreamshaper-8 (the
  installation keeps it in diffusers form, so the deprecated but present
  diffusers loader node), the profile's prompt and a shared negative
  prompt, a portrait-shaped latent (512 by 768), a seeded sampler, decode,
  save under `feldowinn/<profile id>`. Placeholders `__PROMPT__`,
  `__NEGATIVE__`, `__SEED__`, `__PREFIX__`, the same convention as the
  installation's own `workflows/README.md`.
- A second workflow with a scribble ControlNet
  (`concept-scribble.json`, `__CONTROL_IMAGE__`), for when a silhouette
  sketch exists.
- IP-Adapter (a reference-image look, present among the weights) needs a
  custom node pack the installation doesn't have (stock ComfyUI has no
  IP-Adapter nodes): not used until installed.
- A client (`scripts/feldowinn-comfy-submit`): fills the placeholders
  from a profile, posts the graph to ComfyUI's `/prompt`, waits on
  `/history/<id>`, downloads the saved images through `/view` into
  `assets/feldowinn/images/<profile id>.png`, and records prompt, seed and
  workflow hash beside it (the asset forge's rule: a generated thing
  without them is refused).

## Suggested Implementation Steps

1. Once `./run` in the installation serves on 127.0.0.1:8188:
   `scripts/feldowinn-comfy-submit --profile <id> --workflow concept`.
   Pass: an image file appears, its record names prompt, seed and
   workflow hash. Run the same profile and seed twice: same image.

## Related Issues

- **506** parent; **506c** takes its images
