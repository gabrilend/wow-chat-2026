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
Then, beyond the original: **real-time shadows from the sun** (owner,
2026-10-07). Trees, buildings, creatures and she herself cast shadows that
move as the sun moves through the day. The original's baked map is a
picture made once, offline, by Blizzard's tools from one fixed sun. It
does not move with the time of day, and it has no shadows from creatures
or from anything not placed in the map. Everything a live shadow needs is
already loaded: every shape's points (ground, doodads, buildings,
figures), and the direction toward the sun from the zone's light tables
(173n, the light's `sun_dir`).

How a live shadow works: before each frame, the scene is drawn a second
time from the sun's side, keeping only how far away each surface is (a
"depth picture"). When the real frame is drawn, each pixel asks the depth
picture whether something stood between it and the sun. If so, it
darkens. This runs on the graphics card (the 173u rule).

## Suggested Implementation Steps

1. Read MCSH per chunk; darken the painted ground by it in the shader.
2. A round soft shadow under each character and creature.
3. A picture next to the original client's at the same spot.
4. The sun's depth picture: the world drawn once more from `sun_dir`,
   depth only, covering the area around her. Several pictures at
   growing distances ("cascades") keep near shadows sharp and still
   reach the far trees.
5. Every shader that draws the world (ground, doodads, buildings,
   figures, water) reads the depth picture and darkens what it hides.
6. Pictures at morning, noon and evening at the same spot, showing the
   shadows turning with the sun.

## Open Questions

1. (Answered 2026-10-07) Should the client also cast real-time shadows
   from the sun, or stay exactly the original? The owner asked first
   whether the baked map is real-time shadows recorded and played back.
   It is not: it is one still picture per patch of ground, made once from
   one sun. And do we have the data for live ones? Yes: the shapes and
   the sun's direction (above). The answer: "If so, then I am totally
   excited about that idea, and we should absolutely invent real-time
   shadows."
2. (Answered 2026-10-07) Always on, or a setting? A setting: "sure let's
   keep it as a setting to be cheaper on user's hardware demands." With
   it off, the client draws the original's look, and the pixel-for-pixel
   comparisons run with it off. Still open: built now, or after the
   original is rebuilt?
3. Shadows from characters, and light from torches (the owner asked,
   2026-10-07). Characters: yes. They are drawn into the sun's depth
   picture like everything else, so they cast shadows. Torches: the
   models carry their own light (each model file can hold point lights,
   with a colour, a reach and the bone they ride on, and the buildings
   hold lights for their rooms). The buildings' room lights were baked
   into the colour of each point when the map was made, so they don't
   change live. As far as I know (not yet checked against the original), a
   model's own lights light only that model, not the ground and walls
   around it. Live torch light means the shaders add up the nearest few
   lights for each pixel, which costs little. Shadows *from* torch light
   cost more: each torch needs depth pictures in six directions, because
   it shines every way. Should live torch light be part of this setting,
   and should torches cast shadows too (perhaps only the nearest one or
   two)?
