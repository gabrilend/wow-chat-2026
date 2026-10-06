# 173b6 - Video: Effects

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

Not built. The client draws 3 x 3 map tiles round her (its tile reach),
with a far plane of 1600 yards and fog in the distance, all fixed.

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
