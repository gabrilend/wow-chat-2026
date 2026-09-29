# 506h - Feldowinn Model Formats: glTF Kept, M2 Exported

## Status
- Created: 2026-09-27
- Phase: 5
- Parent: 506
- Blocked by: None (built and tested without the generator)
- Priority: High

## Current Behavior

**Built and tested 2026-09-27** (static items):
- `src/tools/model/gltf.lua`: read and write binary glTF triangle meshes.
- `src/tools/model/m2.lua`: read WotLK models (M2 + .skin, version 264),
  check them against the drawable-model rules, write static item models
  shaped like the game's own.
- `scripts/convert-gltf-to-m2`: a design's .glb to `NAME.m2` +
  `NAME00.skin` beside it, read back and checked.
- `docs/m2-format-wotlk.md`: the layout, measured from stock files and the
  server's extractor.
- `scripts/test-model-formats` (35 checks): glTF round trip; three stock
  models (helm, shoulder, sword) read and keep every rule; our writer,
  given the stock helm's and shoulder's triangles, writes files that read
  back to exactly the same geometry and bounding box with the stock
  animation record, texture kind, lookups, 304-byte header and 16-byte
  alignment; a .glb converted lands in the game's axes and units with every
  triangle's winding kept; a triangle out of range is reported, a mesh
  over 65,535 vertices is stopped. Planted faults (a mirroring axis turn;
  the triangle check disabled) each fail it.
- `scripts/extract-m2-references` copies the stock models out of the
  client (Python, for the one MPQ reader installed).

**Not tested**: a converted model in a model viewer or in the stock client
(the client's item data must name it: no client changes until the custom
client).

## Intended Behavior

The owner, 2026-09-27, verbatim:

> then, can we make a script or utility that connects or converts them to
> the WoW model file formats? Connect if we eventually intend to use this
> patternology, convert if the blizzard format is superior.

> building this *is* the custom client though, so plan accordingly.

- **Kept format: glTF** (mesh, skeleton, animations), replaceable by the
  project's own when the custom client wants one; every stage reads and
  writes it.
- **Export: M2 + .skin** for the stock client, one way.
- Body armour (chest, legs, gloves, boots) exports as texture in the
  body's layout, not a model (`docs/m2-format-wotlk.md`).

## Suggested Implementation Steps

1. Done: static items, above.
2. Reduction: a decimator bringing a generated mesh to an item's budget
   (a few thousand triangles) before export; the writer refuses more than
   65,535 vertices rather than cut.
3. Texture export: PNG to the game's BLP texture format, and the body
   texture layout for armour pieces.
4. Skinned export (with 506g): bones, tracks, the per-sequence arrays.
5. **Test in a viewer**: open `NAME.m2` in a WotLK model viewer; pass: the
   shape as in the .glb, right way up, facing front.

## Related Issues

- **506** parent; **506f**; **506g**; world-edit-to-execute W01 (the
  custom client's readers), W05 (the asset forge)
