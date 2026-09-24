# 159 - Equipment Portrait Grid

## Status
- Created: 2026-09-23
- Phase: 1 (Foundation & Tooling)
- Priority: Medium — needed before expert's level-60 starting kit (156) is
  hand-picked; useful at once for vanilla's level-20 kit (148h)

## Origin

Verbatim, 2026-09-23, on expert's level-60 starting equipment:

> We'll need to copy the starting equipment patch and issue and modify it for
> level 60 characters. I'll need to hand-pick the equipment, of course... Can
> you create a tool which outputs a picture of the character with the
> intended equipment equipped? Not sure how we could do that, maybe a custom
> renderer? Is there an open source one we could download? Anyway making a
> grid of pictures of the starting equipments will help us pick them easier.
> This should also help with the level 20 sets as well. We will use these
> pictures to assess them for aesthetic accordance. The pictures should be
> auto-generated. But that's another issue file.

## Current Behavior

Starting kits are chosen as item ids in a generator script
(`scripts/generate-vanilla-starting-equipment-sql` for vanilla's level-20
kit, 148h). Nobody sees what a kit looks like on a character until they
roll one in the client. There is no tool that turns a (race, sex, class,
item list) into a picture.

## Intended Behavior

One command takes a kit definition, meaning the items per class, and
produces:

- one picture per (race, sex, class) wearing that class's kit, front-facing,
  same pose, lighting and background for every picture;
- a grid image (and an HTML page) laying them out as races × classes, one
  grid per sex, with item names under each picture;
- all of it regenerated automatically whenever the kit changes, so a
  candidate swap ("try the other chest piece on paladins") is one edit and
  one command away.

The pictures are for judging looks, so they must be faithful to what the
3.3.5 client shows: the same models, textures and gear pieces.

## Suggested Implementation Steps

Three candidate routes. Route 1 is the most likely to be faithful; route 3
is the most self-contained. Both have counterparts being built in phase W of
world-edit-to-execute (see Related Issues).

1. **Photograph the real client.** Everything needed already runs here: the
   server, playerbots, a Wine-launched client (`scripts/client`). A studio
   script:
   - creates or reuses one bot character per (race, sex, class) on a studio
     account;
   - equips the kit server-side (the way B025 equips vanilla's kit on bots);
   - stands them one at a time on a fixed spot in a quiet indoor place,
     facing a fixed camera;
   - logs a GM character into the client at a fixed camera position, and
     has the client take a screenshot for each (a keybind driven by
     `xdotool`, or the client's own screenshot command from a macro).

   Pixel-exact to what players see; needs the client and a display (or a
   virtual framebuffer), and it is slow (seconds per picture).
2. **Use an existing open-source model viewer.** WoW Model Viewer (open
   source, GPL, C++) could load 3.3.5 MPQ data and dress characters in its
   older releases. Unverified: whether a current build still reads 3.3.5
   data, and whether it can be driven from a script (no GUI) to render in
   bulk. Other open-source projects (WebWowViewerCpp, the Blender M2
   importers built on pywowlib) render 3.3.5 models, but assembling a
   *dressed character* (body geosets, skin-texture compositing of armour
   pieces, attached helm and shoulder models) is the hard part. Their support
   for that needs checking one by one.
3. **Write the renderer.** Read the M2 character models, the item display
   data (ItemDisplayInfo.dbc) and the textures straight from the MPQs, and
   composite them the way the client does. Fully scriptable, headless and
   fast, but it reimplements the client's character-assembly rules, which is
   substantial work, and every mistake is a picture that lies.

Step zero for any route: spend a short time evaluating route 2's
candidates against one test kit. If one renders a dressed 3.3.5
character from the command line, it wins; otherwise route 1.

The grid layout and HTML page are the same for every route: a small
generator that takes a folder of pictures named `race-sex-class.png` and
the kit definition, and writes the grid.

Aesthetic judgement: the pictures feed a human choice, and the
`canvas-and-paintbrush` skill describes keeping every generated picture
with a rating so later picks can draw on earlier ones. Worth applying once
the pictures exist.

## Related Issues

- **148h** vanilla's level-20 kit — the first set to photograph
- **156** expert — its level-60 kit is picked with this tool
- **148v** cloned kit items render invisible: an item id the client's own
  item table (`Item.dbc`) lacks gets its look only from the item cache, and
  the cache is filled only when the client asks, which a server-side equip
  does not trigger. A kit built from cloned ids photographs wrong on a cold
  client, so route 1 must warm the cache (or use original ids)
- **153g** image-per-token grounding (explore) — also generates images, for
  a different purpose

### In other projects (linked both ways, 2026-09-23; re-check, since phase W is being designed now)

The owner asked that route 3 be linked to phase W of
`/home/ritz/programming/ai-stuff/world-edit-to-execute/`, which is building
most of what the routes above need:

- **W04** (`issues/W04-compare-the-real-client-against-the-open-client.md`):
  an unattended rig that runs a throwaway AzerothCore server, fills a scene
  in with GM commands, runs the **real** 3.3.5 client under Wine on a
  virtual screen, and records it. That is route 1, built for another
  purpose; this issue should reuse it rather than build a second one.
- **W03** (`issues/W03-show-wow-models-with-wc3-unit-behavior.md`): loads
  and draws WoW M2 models in that project's engine. It is the starting
  point for route 3's renderer. Dressing a character (geosets,
  item-texture compositing, attached helm and shoulder models) is beyond
  W03's current scope and would be this issue's addition.
- **W01** (`issues/W01-read-the-wow-client-archives.md`): readers for the
  client's archives (MPQ), tables (DBC: `ItemDisplayInfo`, `CharSections`),
  textures (BLP) and models (M2). They are built once, in C, in the
  separate W client (`/mnt/mtwo/games/azeroth-core/custom-client/`, its
  issues 105–107 and 401), and shared as `libwreaders.so`. Route 3 reads
  through these.

Each of the three now carries a line pointing back here.

## Open Questions

- **Route?** Route 1 needs the client running under Wine with a display;
  is a virtual framebuffer (Xvfb) acceptable, or will this run on your
  desktop?
- **Which races/sexes?** All ten races × two sexes × each race's classes is
  about 120 pictures per kit. Is the whole matrix wanted every time, or one
  race per class for a first pass?
