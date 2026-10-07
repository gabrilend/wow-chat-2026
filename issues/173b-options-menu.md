# 173b - Options Menu

*Continues in the W client (`/mnt/mtwo/games/azeroth-core/custom-client/`), since the move on 2026-10-07 (173v): 1001 (the store: 103). This issue stays as the record of how the client began; its paths are as they were then.*

## Status
- Created: 2026-10-04
- Phase: 1
- Parent: 173 (the custom client)
- Blocked by: 173a
- Priority: Medium (the settings store, 173b1, is High: every feature
  reads it)
- Reference: `docs/custom-client-stock-options.md`, written by
  `scripts/generate-stock-options-catalog` from the original client's own
  menu files

## Origin

See 173 (the owner's words, 2026-10-04). Widened 2026-10-06, verbatim:

> I'm thinking... We should go through the settings menu in the original
> client and make sure that we have all of the settings properly
> implemented for things like UI, camera, keybinds, etc. So we'll need
> issue files, probably with sub-issues for each section in the menu.
> [...] If we have the plan for the settings menu set up, then whenever we
> deal with one of the other things we can A. have a guideline for what
> sort of configuration we should support as we're building that
> particular feature, and B. we could add the options to be tweakable as
> soon as we're working on the feature, rather than in some later pass
> where we've already built out infrastructure that's too rigid and has to
> be refactored.

## Current Behavior

Not built. The custom client has no settings: its window opens at
1280 x 720, and its speeds, keys and camera numbers are fixed in the
source.

The original client's whole menu has been read from its archives and
written out as a reference page (`docs/custom-client-stock-options.md`):
its three windows (Video, Sound & Voice, Interface), their 22 panels, every
setting's label, kind, range and stored name, and its 275 bindable actions
in 13 sections. Run `scripts/generate-stock-options-catalog` to rebuild it.

## Intended Behavior

The custom client offers every setting the original's menu offers, plus
the project's own. Each setting is built **together with the feature it
controls**, not in a later pass: when a feature is built, its section's
sub-issue below is the list of what it must be configurable by, and those
settings go into the store at the same time.

Two pieces come first because everything else stands on them:
- **The settings store (173b1):** every setting declared once, in one
  place (name, kind, range, default, which section). Saved between runs.
  Any code reads a setting by name every time it needs it, so a change
  takes effect at once, with no rebuilt structures.
- **The options screen (173b2):** the menu itself, drawn from the store, so
  a newly declared setting appears in its panel without screen code.

Then one sub-issue per section of the original's menu. Key bindings are a
section of their own (173b3). Camera and mouse come early (173b4) because
the camera is the next feature (173m).

| ID | Name | Dependencies | Description |
|---|---|---|---|
| 173b1 | settings-store | None | Every setting declared once (name, kind, range, default, section, when it takes effect); saved to a file; read by name, live |
| 173b2 | the-options-screen | 173b1, 173c | Escape's game menu and the three settings windows, each panel built from the store: tick boxes, sliders, drop-downs, Okay / Cancel / Defaults |
| 173b3 | key-bindings | 173b1 | Every action bound by name, not fixed keys; the original's 275 actions in its 13 sections; rebinding screen; two keys per action |
| 173b4 | camera-and-mouse | 173b1 | The Camera and Mouse panels and the camera key bindings, built with 173m |
| 173b5 | video-resolution | 173b1 | Window size up to ultrawide (typed or picked), refresh, anti-aliasing, windowed / maximized, vsync, UI scale, gamma |
| 173b6 | video-effects | 173b1 | View distance, terrain blending, particles, ground clutter, texture resolution and filtering, shadows, weather, glow, death effect |
| 173b7 | sound | 173b1 | Volumes (master, effects, music, ambience), what plays, output device, channels, quality |
| 173b8 | controls-and-combat | 173b1 | Auto loot and its key, loot window at the mouse, deselect on click, self-cast and focus-cast keys, auto attack, target of target |
| 173b9 | display-and-objectives | 173b1 | Minimap rotation, loot detail, clock, threat, colorblind mode, item level; quest tracking and quest text |
| 173b10 | action-bars | 173b1 | Which extra bars show, locked bars, always-show bars |
| 173b11 | names-and-nameplates | 173b1 | Whose names float overhead and whose nameplates show, by friend / enemy and kind |
| 173b12 | combat-text | 173b1 | Floating combat text, what it shows, and how it floats |
| 173b13 | status-text-and-unit-frames | 173b1 | Numbers on the health and mana bars; the party and raid frames' options |
| 173b14 | buffs-and-debuffs | 173b1 | Durations, dispellable and castable markings, consolidation |
| 173b15 | social-and-chat | 173b1 | Chat bubbles, filters, chat style, guild alerts, chat-window mouse behaviour |
| 173b16 | features-help-and-languages | 173b1 | Tooltips, tips, error display, language; the panels the original has that this project won't copy, and why |

Order: 173b1 first, then 173b4 with the camera (173m), then 173b5. Key
bindings (173b3) wait for the action bar (owner, 2026-10-06), because
until then there is nothing to bind but movement. The rest follow their features: the effects panel with painted
ground, doodads and shadows (173f, 173g, 173h), sound with the first sound,
the interface panels with the interface (173c onward).

## Suggested Implementation Steps

1. 173b1 (the store) before the next feature, so the camera is built on it.
2. Each section's sub-issue is opened when its feature is built. Its
   settings are added to the store in the same change as the feature.
3. 173b2 (the screen) when 173c's interface pieces exist. Until then, the
   settings file is edited by hand and read at start.
4. Regenerate the reference page when the original's files are read from
   a different client build. The script fails rather than guessing when a
   panel it expects is missing.

## Decisions

- **The original's settings file is not read** (owner, 2026-10-06). Its
  stored names are still used where a setting is the same thing, because
  they are a ready-made, well-known vocabulary.
- **The original first.** The plan rebuilds the original's settings
  before adding new ones. The client is for any WoW private server, not
  only this project's profiles (see 173, *Who the client is for*).

## Open Questions

None.
