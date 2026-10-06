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

**Built 2026-10-06**, in C:
- **`light.h` / `light.c` read the light tables** (Light,
  LightIntBand, LightFloatBand; the parameter set's id is used directly,
  so LightParams itself isn't needed yet).
- **`light_at` answers "the light here, now".** Lights are blended by
  place: the map's default first, then every sphere that reaches, the
  larger first, each blended from its outer to its inner radius.
  Colours and fog are blended by time of day (half-minutes, wrapping
  round midnight).
- **The sun's direction** comes from the hour: it rises in the east at 6,
  stands high in the south at noon, and sets in the west at 18, staying
  a little above the horizon at night, as moonlight. This is this
  client's reading; the original's own path is not read.
- **Every world shader** (ground, doodads and buildings' outdoor parts,
  figures) lights by shade + sun x facing, and fogs into the zone's fog
  colour between its fog distances. `sky_light_shader` hands each one
  the light.
- **`sky.h` / `sky.c`** draw a dome of five rings, coloured by the five
  sky bands, behind everything. The window clears to the fog colour.
- **The time of day** is this machine's clock (the realm's clock is real
  time too), running on as the game runs. `--hour H` sets it for
  pictures.
- **At Astranaar** the light is Ashenvale's own (light 192): fog from 36
  to 361 yards at noon. Pictures at noon, 19:00 and 01:00 show
  Ashenvale's blue-green light.
- **Tests:** 5 checks.
  - At Astranaar the light is Ashenvale's own, not Kalimdor's default.
  - Noon's sun is brighter than half past midnight's.
  - The fog ends between 100 and 1600 yards.
  - Durotar, across the continent, gets another light.
  - The sun is high at noon and low at night.

**Skyboxes (2026-10-06): loaded, drawn only when simple.**
- **Where they are:** a light's parameter set names a skybox (LightParams
  field 3, then LightSkybox's model). Ashenvale's names none, and a
  search of maps 0 and 1 found none at all. The skyboxes on the main
  maps are Northrend's auroras (AuroraYellowGreen, AuroraOrange).
- **What's built:**
  - `light.c` reads LightParams and LightSkybox and gives the strongest
    light's skybox model with the light.
  - `sky.c` loads it as a figure (`figure_from_model`), sizes it to 800
    yards, plays its standing animation, draws it round the camera
    after the dome, and tints each piece by its animated colour and
    transparency (`figure_tint`; `m2.c` now reads each unit's colour and
    transparency tracks).
- **Layered pictures, now drawn (the same day):** an aurora lays two
  pictures on each piece (the light under a mask) and scrolls the mask.
  Drawn first with its first picture alone, it filled the sky as a solid
  yellow wall, so it was left out until the drawer could layer.
  - **The reader:** `m2.c` now reads, per piece, each layer's picture,
    which set of picture positions it uses (models carry two), its
    picture-position animation, and the combine code.
  - **The animations:** `anim_uv` reads picture-position animations,
    sliding and stretching (turning is read but not applied).
  - **The shader:** `doodads.c`'s shader lays a second layer over the
    first by the combine code (this client's reading: the code's low 3
    bits name how), each layer with its own positions and animation,
    tinted by the piece's animated colour and transparency.
  - **The skybox** is drawn by the doodad drawer (`doodads_skybox`,
    `doodads_draw_skybox`): round the camera, unlit, unfogged, behind
    everything. `sky.c` hands it the light's choice. The figure-based
    skybox code is gone.
  - **Seen:** Northrend's aurora now shows as a faint glow over the
    glacier cliffs. Its colours are to be checked against the original.
- **Also:**
  - `--map ID X Y` starts the client on any map (Map.dbc gives the folder
    name). Northrend at (3694, 3440) shows snow, a frozen lake and glacier
    cliffs.
  - Fog no longer starts behind the camera: Northrend's light 1386 gives
    a negative start share at night, now held at 0.

**Night light:** the owner (2026-10-06) on Ashenvale at night: "that's
approximately how it looks, but we can adjust it later if we need to."

**Left:**
- The combine code's reading, and turning picture animations, checked
  against the original.
- Weather lights (storms), underwater light, and the ghost world's
  light after death.
- The skybox (owner, 2026-10-06: "and skybox!"): many lights name a
  skybox model (LightParams' skybox, through LightSkybox.dbc: an M2 drawn
  round the camera, such as Ashenvale's tall trees against the sky). The
  clouds, the sun and moon, and the stars come with it.
- Comparing against the original side by side.
- Indoor parts of buildings still use their baked colours (173g).

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
