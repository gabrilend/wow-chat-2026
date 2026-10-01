# 506 - Gear Gallery

## Status
- Created: 2026-09-27
- Phase: 5 (Content Generation: it generates designs, it doesn't change the
  server)
- Priority: High (owner, 2026-09-27: the 3D model generation system is "our
  priority target, after all... Minimum Viable")
- Sub-issues: 506a (design profiles), 506b (concept art through ComfyUI),
  506c (image to 3D through ComfyUI), 506d (the gallery and its votes),
  506e (camera plan and multi-view rings), 506f (mesh and texture from
  views), 506g (skeleton borrowing), 506h (model formats: glTF kept, M2
  exported), 506i (generated animations)
- Related: 159 (equipment portrait grid: pictures of existing items);
  world-edit-to-execute W05 (the asset forge: find or generate a model),
  whose generate route this is the first real target for

## Origin

The owner, 2026-09-27 (the whole conversation is in the transcripts):

> I think first we generate profiles, display them in an HTML
> gallery, then let the developer vote them up or down over time. Higher
> priority given to various designs of questions that haven't been
> answered yet - and variability when persistence is downvoted.

> [where it lives:] wow-chat. world-edit-to-execute came later, but was
> built first.

> comfyUI stuff can be built, or at least maximally described, before the
> ability to test it is measured to completion. But testing is important
> for end-user results.

> can we hook up the stable-diffusion output directory .png storage
> location addresses with the gallery HTML presentation votationationing
> gatherer?

The 3D pipeline, verbatim (2026-09-27; the rest of the owner's answers are
in 506e, 506h and 506i):

> Then, if we still have work to do, we can hook up the stable-diffusion
> output directory to some potential 3d model generation comfy-UI map
> pattern we could impelement. We'd generate pictures at first one of 8
> angles (compass orientated webcams facing in) then we'd gather middle and
> lower shots too, then 5

> assume that there will be the potential requirement for a remote host.
> This can be arranged.

The whole pipeline: `docs/gear-3d-pipeline.md`.

## Current Behavior

**Started 2026-09-27.** The design profiles and the gallery run today;
the two ComfyUI stages are written and checked against the installation's
source, but untested (ComfyUI can't run yet: its Python packages are still
being installed at `/mnt/kaun/stable-diffusion/`).
- Round 1 (24 profiles) made: `assets/gear-designs/profiles/round-001.lua`.
- The gallery, published: https://claude.ai/artifact/4BuF6CdpRvtUqkPE1pQ1RF
  (votes kept in the page's own database; export to votes.tsv).
- **The seam for later stages**: every generated file for a design lives in
  one folder in ComfyUI's output, `output/gear-designs/<design id>/`
  (`view_*.png` concept views, `model_*.glb` meshes). The gallery reads
  that folder; a later multi-view, 3D, animation or game-model stage adds
  its files to the same folder, named by kind.
- `scripts/test-gear-designs`: 334 checks pass (the camera plan and the two
  multi-view workflows added 2026-09-27); planted faults fail it.
- **The 3D stages** (2026-09-27): the camera plan and both multi-view
  workflows written and checked against the installed ComfyUI's source,
  untested (506e, 506f); the model formats built and tested (506h:
  `scripts/test-model-formats`, 35 checks); skeleton and animations
  designed (506g, 506i). Built-in ComfyUI nodes only, by the owner's rule.

## Intended Behavior

The first design target is a set of Retribution Paladin gear. It is not
anyone's character: the design questions are neutral placeholders until a
theme is chosen on purpose (owner, 2026-10-01, taking a person out of the
design: "it's not a game about her, it's a game *for* her"). The subject
the prompts name is a field of the question bank. The loop:
1. **Profiles** (506a): design variations of each gear piece, each a
   structured record answering one or two open design questions, with a
   text prompt for image generation.
2. **Concept art** (506b): each profile's prompt through ComfyUI's
   text-to-image, one image per profile.
3. **Models** (506c): chosen concept images through ComfyUI's
   image-to-3D, one mesh per image.
4. **Votes** (506d): a gallery page shows every profile (its image once it
   exists); the developer votes each up or down, over days and weeks; the
   votes go back to step 1.

Generation favours design questions not yet answered; a design that keeps
winning is carried into new profiles ("persistence"), and when a carried
design gets voted down, the carrying loosens and variation widens.

## Suggested Implementation Steps

| ID | Name | Dependencies | Description |
|----|------|--------------|-------------|
| 506a | gear-design-profiles | None | The design questions and a generator of profiles weighted by votes |
| 506b | gear-concept-art | 506a | ComfyUI text-to-image workflow and a client that submits and saves |
| 506c | gear-image-to-3d | 506b | ComfyUI image-to-3D workflow (Hunyuan3D-2), same client |
| 506d | gear-gallery-and-votes | 506a | The gallery page, votes kept for the developer, read back by 506a |
| 506e | gear-camera-plan-and-multiview | 506b | The rig (8 views x 1, 3 or 5 rings) and Stable Zero123 rings |
| 506f | gear-mesh-and-texture-from-views | 506e | Hunyuan3D-2 multi-view mesh; texture projected from the rings |
| 506g | gear-skeleton-borrowing | 506f, 506h | A stock skeleton and its animations for a creature mesh |
| 506h | gear-model-formats | None | glTF kept, M2 + .skin exported (static items built) |
| 506i | gear-generated-animations | 506g, 506e | Pose, render, match the next frame's views, keyframe |

Rationale: four streams, each testable apart. The profiles and the gallery
run today; the two ComfyUI stages wait on the installation and on the
graphics card (a 1080 Ti) proving able to run them. Split so the parts
that run now can be finished and used while the others wait.

Order: `506a → (506d ∥ 506b) → 506c`; then `506b → 506e → 506f → 506g →
506i`, with `506h` alongside (built first, since it needs no generator).
Rationale for the second group: each stage has its own blocker (weights,
the graphics card, a stock reader with keyframes, a pose solver), so each
can finish or wait on its own; 506g stops short of 506i on purpose ("a
good partway stopping point because it has separate blockers from the
animations").

## Related Issues

- **159**; **155f**-era gear ladders for item levels when models become items
