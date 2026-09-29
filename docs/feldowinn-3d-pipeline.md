# The Feldowinn 3D Pipeline

From a design profile to a model the game can show, and on to its
animations (issues 506, 506e-506i). What each stage takes and makes, where
its files go, what is built, and what waits on the generator running. The
owner's words (2026-09-27) are in the issues; the design here follows them.

## The shape of it

```
profile (506a)
  -> concept view         text-to-image, one front picture       (506b)
  -> multi-view rings     the camera plan: 8 views x 1, 3 or 5   (506e)
  -> mesh                 four views -> a 3D mesh (glTF)          (506f)
  -> texture              the views projected onto the mesh      (506f)
  -> kept format          glTF (the project's own later)          (506h)
       -> stock export    .m2 + .skin for the 3.3.5 client        (506h)
  -> skeleton             borrowed from a stock model             (506g)
  -> animations           generated, pose by pose                 (506i)
votes on every stage's pictures come back to the profiles (506d)
```

Every file for one design lives in one folder of the generator's output,
`output/feldowinn/<design id>/` (the seam 506d made): `view_*.png` the
concept, `mv_<ring>_*.png` the rings, `model_*.glb` meshes, `NAME.m2` and
`NAME00.skin` the stock export, later `pose_*` and `anim_*`.

## The camera plan (506e)

The owner's rig: "eight x (1 or 3 or 5) webcam interially focused radially
spread": eight cameras on a circle facing the subject, one every 45
degrees of the compass, the circle repeated at one, three or five heights
("a ring above and below the middle ring. that's the 5 I mentioned"). The
plan is data, `assets/feldowinn/camera-plan.lua`: the compass (n, ne, e ...
nw), the rings (middle 0 degrees, above 20, below -20, higher 40, lower
-40: first choices), the levels (1, 3, 5 rings: 8, 24, 40 views), and which
four views the mesh stage takes. Every later stage that works from views
(texturing, posing, animating) uses the same plan, so a view's name always
means the same camera.

## Security: built-in nodes, downloaded weights (the owner's rule)

"my friend was hacked when using someone else's utilities. I'll only use
their maps of the utilities that come with the software. I can do a model
though, because models do not determine behavior." So:
- **Nodes: only those that come with ComfyUI** (its `nodes.py` and
  `comfy_extras/`). No third-party node packs: their Python runs with full
  rights on the machine. The tests check every workflow node against the
  installed checkout's own source.
- **Weights may be downloaded.** Prefer `.safetensors`: a plain table of
  numbers that can't hold code. ComfyUI loads any other kind (`.ckpt`,
  `.pt`) with PyTorch's weights-only loader (`comfy/utils.py`,
  `load_torch_file`: `torch.load(..., weights_only=True)`), which refuses
  the code a pickled file can carry; still, convert to safetensors where a
  safetensors copy exists.
- **What the rule rules out**: Zero123++ and InstantMesh (node packs only),
  Hunyuan3D-2's texture painter (not among the built-in nodes), background
  removers from packs, TRELLIS node packs (though ComfyUI's own TRELLIS.2
  nodes are built in, and allowed).
- **What stays in**: Stable Zero123 (built-in conditioning, batched with
  elevation and azimuth steps), Stable Video 3D (built-in, an orbit of 21
  frames at one elevation), Hunyuan3D-2 single-image and multi-view (built
  in, with a GLB saver), TRELLIS.2 (built in).

## Multi-view rings (506e)

`assets/feldowinn/comfyui/multiview.json`: Stable Zero123 from the concept
view, one ring per run: a batch of eight, azimuth from 0 in steps of 45,
at the ring's elevation, 256x256 (the model's size). Client:
`scripts/feldowinn-comfy-submit --profile ID --workflow multiview --ring
middle` (then `above`, `below`, and for 5 rings `higher`, `lower`). Output
`mv_<ring>_00001_.png` .. `_00008_.png` in azimuth order.

Why a multi-view model rather than eight separate pictures: pictures drawn
one at a time don't agree on details (a strap's buckle is somewhere else
from each side), and a mesh built from them tears; a multi-view model draws
all views of one object from one understanding of it.

## Mesh and texture (506f)

`assets/feldowinn/comfyui/to-3d-multiview.json`: Hunyuan3D-2's built-in
multi-view conditioning takes four views (front, left, back, right: the
middle ring's n, e, s, w, mapped in the camera plan), then the 3D latent,
decode to voxels, voxels to mesh, save GLB. The single-image route
(`to-3d.json`, 506c) stays as the fallback-free alternative for a quick
look. Texturing (not built): project the ring views onto the mesh (each
triangle takes the view that faces it most squarely, blended at seams),
written as our own tool, since Hunyuan's painter isn't a built-in node.

## The kept format and the stock export (506h)

The owner: "Connect if we eventually intend to use this patternology,
convert if the blizzard format is superior", and "building this *is* the
custom client though, so plan accordingly." So:
- **glTF is the kept format** (mesh, skeleton, animations in one open
  file), and the project's own format can replace it when the custom
  client wants one. The pipeline's stages read and write glTF.
- **M2 + .skin is an export** for the stock 3.3.5 client, one way
  (`scripts/convert-gltf-to-m2`, `src/tools/model/m2.lua`): today static
  items (helms, shoulders, weapons, shields), shaped exactly like the
  game's own (`docs/m2-format-wotlk.md`). Seen in game only once the
  client's item data names it (no client changes until the custom client);
  checked here by reading back, and in a model viewer.
- Body armour (chest, legs, gloves, boots) is texture on the body in the
  stock client, not a model: the export for those is a texture in the
  body's layout.
- **Mesh size**: the format counts vertices and indices in 16 bits
  (65,535); generated meshes are far larger, so a reduction step
  (decimation to an item's budget, a few thousand triangles) comes before
  the export. The writer stops with an error on a mesh too big, never cuts.

## Skeleton (506g)

The owner: borrowing "a good partway stopping point because it has
separate blockers from the animations". A creature or character model
borrows a stock skeleton and animation set with the same body plan
(world-edit-to-execute W05b's design): the new mesh's vertices get weights
to the borrowed bones (nearest bones, smoothed), and every stock animation
then plays on it, already named by the game's animation table and so tied
to the abilities that use them. Items need none (one root bone).

## Generated animations (506i)

The owner: "We need to be able to first pose a model, then interpret the
2d visual (taken from the same number of directions) in relation to the
picture being shown. Then, see another 2d wireframe style visual [...] of
the next movement in the pattern to fulfill. And that can be any source,
including our own later on", and "take pictures of the models and develop
their animations by moving the 'conception wireframe' forward one step
and providing a 'before' and 'after' with the picture advanced slightly is
the guided destination." The loop, per keyframe:
1. **Pose**: the rigged model in its current pose.
2. **See it**: render it from the camera plan (the same 8, 24 or 40 views).
3. **The target**: the next step of the movement as views from the same
   cameras: a wireframe or pose picture ("any source": a reference, a
   drawn sketch, another model, later our own generator).
4. **Before and after**: the guide is the pair (this pose's views, the
   target's views), "the picture advanced slightly".
5. **Solve**: change the bone rotations until the model's views match the
   target's (compare silhouettes and joint positions view by view; small
   steps, the bones' limits kept).
6. **Keyframe** the solved pose, advance, repeat until the movement ends;
   the keyframes become the animation, named for the game's animation table
   where one fits (attack, cast, run), so abilities use it.

## What runs today, what waits

| Stage | Built | Tested here | Needs to test |
|---|---|---|---|
| Camera plan | yes | yes (`test-feldowinn` part 7) | seeing views |
| Multi-view workflow | yes | nodes and inputs against the installed source | ComfyUI running, Stable Zero123 weights |
| Mesh from four views | yes | nodes and inputs | ComfyUI, Hunyuan3D-2mv weights, the 1080 Ti's memory |
| Texturing | no | | |
| glTF read/write | yes | round trip (`test-model-formats`) | a real generated .glb |
| M2 + .skin export (static) | yes | read back; rewrites stock items exactly | a model viewer; in game needs the client's item data |
| Skeleton borrowing | no | | |
| Generated animations | no | | |

## Where the generator runs

The owner: "assume that there will be the potential requirement for a
remote host." The client already works against any ComfyUI address
(`--server http://HOST:8188`): the workflow and pictures go up over
ComfyUI's web interface; ComfyUI saves on its own machine; each output is
fetched back through its `/view` address into the same per-design folder
here, and logged with its prompt, seed and workflow fingerprint. Nothing
else needs the two machines to share a disk.
