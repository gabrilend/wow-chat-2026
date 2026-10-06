# 173h - Shadow Maps

## Status
- Created: 2026-10-05
- Phase: 1
- Parent: 173 (the custom client)
- Blocked by: 173f, 173g
- Priority: Medium (third of the owner's next five)

## Origin

See 173f (the owner's order, 2026-10-05).

## Current Behavior

Not built. Nothing casts a shadow. The ground's baked shadows are
already read (`adt.c`, MCSH) and packed into each chunk's blend picture's
alpha channel (`ground.c`: 255 lit, 0 shadowed); the shader doesn't use
them yet.

## Intended Behavior

Shadows as the original client has them: the ground's baked shadow map
(each ADT chunk's MCSH, a 64 x 64 one-bit map darkening the ground where
the world's objects shade it), and soft blob shadows under characters.
Shadows the original client does not draw are left out, so the picture
matches it.

## Suggested Implementation Steps

1. Read MCSH per chunk; darken the painted ground by it in the shader.
2. A round soft shadow under each character and creature.
3. A picture next to the original client's at the same spot.

## Open Questions

1. Should the client also cast real-time shadows from the sun (which the
   original 3.3.5a client did not draw), or stay exactly the original?
