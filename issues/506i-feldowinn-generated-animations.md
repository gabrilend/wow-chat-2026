# 506i - Feldowinn Generated Animations

## Status
- Created: 2026-09-27
- Phase: 5
- Parent: 506
- Blocked by: 506g (a rigged model), 506e (the camera plan's renders)
- Priority: Medium ("we're going to generate our own soon")

## Current Behavior

Not built. Designed in `docs/feldowinn-3d-pipeline.md`, "Generated
animations".

## Intended Behavior

The owner, 2026-09-27, verbatim:

> if we have the pictures from all dimensions, it's easy to paint a 3d
> model with animations. Just gotta stable-diffusion the animation frames.
> Show it the entire trajectory, ask it to "build-what's-next" to the next
> one. each for each type of unit in play. All their animations
> automatically built and filled out and attached to mechanics or
> abilities the unit may use in the game.

> we're going to generate our own soon. We need to be able to first pose a
> model, then interpret the 2d visual (taken from the same number of
> directions) in relation to the picture being shown. Then, see another 2d
> wireframe style visual (taken from one of the same eight x (1 or 3 or 5)
> webcam [...] points of the subject... of the next movement in the
> pattern to fulfill. And that can be any source, including our own later
> on

> once the model generation is complete, we can take pictures of the
> models and develop their animations by moving the "conception
> wireframe" forward one step and providing a "before" and "after" with
> the picture advanced slightly is the guided destination.

Per keyframe: pose the rigged model; render it from the camera plan; take
the target (the next step of the movement, as wireframe or pose views from
the same cameras, from any source); with the before/after pair as the
guide, solve the bone rotations that make the model's views match the
target's; keyframe; advance. The keyframes become an animation named for
the game's animation table where one fits, so abilities use it; one set
per kind of unit.

## Suggested Implementation Steps

1. A renderer of a posed glTF model from the camera plan (silhouettes and
   joint positions per view): our own, the same one texturing (506f) and
   the custom client can share.
2. A pose solver: bone rotations fitted to a target's views (silhouette
   overlap and joint distances, view by view, bone limits kept), small
   steps from the current pose.
3. Target sources: first a stock animation rendered as wireframes (so the
   solver is tested against a known answer: re-solving a stock animation
   must come back to it), then drawn sketches, then generated frames.
4. Keyframes to glTF animations; to M2 tracks for the stock client
   (506h's skinned export).

## Related Issues

- **506** parent; **506g**; **506e**; **506h**
