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

**Built 2026-10-06** (`ground.c`'s shader):
- **The ground's baked shadows** (MCSH, read by `adt.c` and packed into
  each chunk's blend picture's alpha channel) darken the ground to 60%.
  The original's tree shadows now fall across Astranaar's road.
- **A soft round shadow under each character** ("blob"), worked out in
  the ground's shader, not drawn as a separate shape.
  - `ground_blob(x, y, z, radius)` adds one for this frame, up to 8.
  - It darkens to 40% at its centre and fades out over its outer 70%.
  - It fades over 3 yards of height, so a character high above the ground
    casts none.
  - Hers is 1.3 yards across.
- **Checked by pictures:** with a test radius of 5 yards it shows as a
  clear dark circle. At 1.3 her body covers most of it from above, as in
  the original.

**Left:** shadows on doodads and buildings (the original bakes none
onto them; its doodads are lit by the zone's light, which comes with the
zone-light step, not yet an issue), and the blob's darkness compared with
the original.

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
