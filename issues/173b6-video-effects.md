# 173b6 - Video: Effects

*Continues in the W client (`/mnt/mtwo/games/azeroth-core/custom-client/`), since the move on 2026-10-07 (173v): issue 1001. This issue stays as the record of how the client began; its paths are as they were then.*

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173b (the options menu)
- Blocked by: 173b1 (the settings store)
- Built with: 173f (painted ground), 173g (doodads), 173h (shadow maps),
  173i (animation)
- Priority: Medium

## Origin

See 173b (the owner's words, 2026-10-06).

## Current Behavior

**View Distance built (2026-10-06); the other rows wait for their
features.**
- `farclip` (177 to 1277 yards, step 110, the original's range; default
  507) is in the store.
- **What it controls:**
  - how many tiles load round her: enough to cover it, 3 x 3 up to 7 x 7;
  - the far plane: 1.25 times it, plus 100 yards;
  - where the fog ends, at the latest: a zone's fog reaching further is
    pulled in to it, its start in proportion.
- **The default** keeps the 3 x 3 the client had before. Set to 1057 in
  the settings file, she loads 5 x 5 (25 tiles, 14,967 placements around
  Astranaar).

**Particle Density built (2026-10-07):** `particleDensity` (0.1 to 1,
step 0.1; default 1) scales every emitter's birth rate
(`particles_step`'s density, passed from `main.c` through
`doodads_animate`, so the particle code reads no settings). Live. Tested:
at 0.3 a torch keeps about three in ten of its sparks.

**Texture Filtering built (2026-10-07):** `textureFilteringMode` (0 to
5, read at start as the original marks it; default 1, trilinear, what
every picture had before): 0 bilinear (the nearest smaller copy), 1
trilinear, 2 to 5 anisotropic 2x, 4x, 8x, 16x, held to the card's most
(and to trilinear, said once, on a card without the extension). Every
picture the client sends goes through one helper (`texture_filter` in
`texture.c`): model and building pictures, painted skins, water, and the
ground's picture array. Seen: the default gives the same picture as
before; 16x sharpens the ground seen at a slant.

## Intended Behavior

The original's Effects panel (reference page, *Video* → *Effects*), each
setting built with the feature it controls:

| Setting | Stored name | Range | Built with |
|---|---|---|---|
| Overall quality preset | `quality` | 1 to 6 | last: sets the others in one move |
| View Distance | `farclip` | 177 to 1277 yards, step 110 | now: the far plane, fog and how many tiles are loaded |
| Terrain Blending | `TerrainMip` | 0 or 1 | 173f: the ground's blend-layer resolution |
| Specular Lighting (terrain highlights) | `specular` | on/off | 173f |
| Environment Detail | `environmentDetail` | 0.5 to 1.5 | 173g: how far doodads are drawn |
| Ground Clutter Density | `groundEffectDensity` | 16 to 64 | 173g: grass and small plants |
| Ground Clutter Radius | `groundEffectDist` | 70 to 140 yards | 173g |
| Shadow Quality | `extShadowQuality` | 0 to 4 | 173h |
| Texture Resolution | `BaseMip` | 0 or 1 | the picture reader: full or half size |
| Texture Filtering | `textureFilteringMode` | 0 to 5 (restart) | the picture upload: how sharp at a slant |
| Player Textures | `componentTextureLevel` | 8 or 9 (restart) | the character's skin sheet size |
| Particle Density | `particleDensity` | 0.1 to 1 | particles, when they exist |
| Weather Intensity | `weatherDensity` | 0 to 3 | weather, when it exists |
| Full-Screen Glow Effect | `ffxGlow` | on/off | a glow pass, when it exists |
| Death Effect | `ffxDeath` | on/off | the grey ghost-world look |
| Projected Textures | `projectedTextures` | on/off | spell circles on the ground |

**The Stereo panel** (3D glasses: `gxStereoEnabled`, depth, separation)
is not copied: the original's own support for it depends on one vendor's
old driver.

## Suggested Implementation Steps

1. View Distance now: it replaces the fixed far plane and the fixed tile
   reach, with a test that the loaded tiles cover the distance.
2. Every other row in the same change as its feature.

## Open Questions

None yet.
