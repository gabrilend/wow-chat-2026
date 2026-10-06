# 173n - Zone Light and Sky

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173 (the custom client)
- Blocked by: 173f (painted ground), 173g (doodads)
- Related: 173h (shadows), 173b6 (video effects: view distance)
- Priority: High (owner, 2026-10-06: "can we work on doodad animations /
  lighting next?")

## Origin

Verbatim, 2026-10-06: "can we work on doodad animations / lighting next?"

## Current Behavior

Not built. Everything is lit by one fixed sun direction with fixed
strengths (ground: 0.30 + 0.75 x facing; models: 0.45 + 0.6 x facing),
fogged into one fixed sky colour from 120 to 640 yards.

## Intended Behavior

The world is lit as the original lights it, from the client's own light
tables:
- **Which light:** `Light.dbc` lists light spheres per map: a position, an
  inner and outer radius (blending between overlapping lights), and the
  light parameters to use. Each map has a default light for anywhere no
  sphere covers. Ashenvale's own lights are found by her position.
- **What it says:** `LightParams.dbc` and its bands. `LightIntBand.dbc`
  holds 18 colours per light, each a list of up to 16 (time of day,
  colour) pairs: the sun's light, the ambient light, five sky colours
  from top to horizon, the fog colour, and others. `LightFloatBand.dbc`
  holds fog distances by time of day.
- **Time of day:** the colours are blended for the current time of day.
  For now that is a fixed time chosen at start; later it comes from the
  server's game time.
- **The sun's direction** follows the time of day, as the original moves
  it.
- **Drawing:** the ground, doodads, buildings' outdoor parts and
  characters all use the zone's sun and ambient colours. Fog uses the
  zone's fog colour and distances. The sky is a dome coloured by the five
  sky bands instead of one flat colour.
- **Settings:** the time of day for pictures (a picture option), and the
  view distance (173b6, `farclip`), which bounds the fog.

## Suggested Implementation Steps

1. Read Light, LightParams, LightIntBand and LightFloatBand (`dbc.c`).
   Test: Ashenvale's light at Astranaar is found; its colours at noon and
   midnight differ as day and night do.
2. Blend lights by distance, and colours by time, into one "light now"
   structure: sun direction and colour, ambient colour, fog colour and
   distances, sky colours.
3. Hand that structure to every shader (ground, doodads, figures).
4. The sky dome.
5. Pictures at noon, dusk and midnight.

## Open Questions

None yet.
