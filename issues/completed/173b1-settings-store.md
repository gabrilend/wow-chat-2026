# 173b1 - The Settings Store

*Continues in the W client (`/mnt/kaun/custom-client/`), since the move on 2026-10-07 (173v): 103, 1001. This issue stays as the record of how the client began; its paths are as they were then.*

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173b (the options menu)
- Blocked by: None
- Completed: 2026-10-06
- Blocks: 173m (the camera), and every other 173b sub-issue
- Priority: High

## Origin

See 173b (the owner's words, 2026-10-06): settings are added "as soon as
we're working on the feature, rather than in some later pass where we've
already built out infrastructure that's too rigid and has to be
refactored."

## Current Behavior

**Built 2026-10-06** in C (`src/custom-client-c/settings.h`, `settings.c`),
with 11 checks in `tests/test_client.c`, all passing (54 in the program).
- **The table** holds three rows so far, each replacing a number first
  light had fixed in its source: `gxResolution` (1280x720, read at
  start), `cameraDistanceMaxFactor` (2: the zoom-out limit is 20 yards
  times it, so first light's 40), and `cameraYawMoveSpeed` (180: the drag
  rate is 0.006 radians a pixel times speed / 180, first light's rate at
  180).
- **`main.c`** reads the window size at start, and reads the zoom limit
  and drag rate every frame. The zoom limit is applied every frame, so
  the `--zoom` picture option is held to it too.
- **The file** is `src/custom-client-c/settings/Config.wtf` (git-ignored),
  named once in `scripts/custom-client` and passed as `--settings`. It is
  read at start and never written by the client yet (no menu).
- **Refusals:** a value outside its declaration is refused with a reason
  (`cameraYawMoveSpeed "20": out of its range (90 to 270)`). A bad file
  line is printed with its line number and skipped. A default its own
  declaration refuses stops the client at start, naming the row. A name
  that code asks for and the table lacks stops the client, naming the file
  and line that asked.

## Intended Behavior

One place where every setting is declared, and one file where the
player's choices are kept.

**A declaration** is one row in a single table, in code (configuration in
structure, as the house style asks), with these fields:

| Field | Type | Meaning |
|---|---|---|
| name | text | the stored name, the original's where it is the same setting (`cameraSmoothStyle`, `farclip`); a project name otherwise |
| section | text | the menu panel it appears in (`Camera`, `Effects` ...), from the reference page's panel names |
| kind | one of: toggle, slider, choice, text, key | toggle = on/off; slider = a number in a range; choice = one of a list; text = typed in (a resolution); key = a bound key (173b3) |
| default | number or text | the value before the player changes it |
| min, max, step | numbers (sliders only) | the range, as the original's when it has one |
| choices | list of {label text, stored value} (choices only) | in the order shown |
| label, explanation | text | the words in the menu and its tooltip, the original's where they apply |
| applies | one of: live, restart | live = read again every time it is used; restart = read once at start (a window mode a library can only set at start) |

**Reading** a setting is a lookup by name that returns its current value.
Code asks for it each time it uses it (each frame, for the camera), so a
change takes effect at once. No code copies a setting into its own
variable at start, unless the setting is marked `restart`. An unknown name
is an error that names the setting and the file asking for it. It never
silently returns a default.

**Saving:** the player's changes go to one plain text file, one
`name value` per line, in the same shape as the original's
`WTF/Config.wtf` (`SET cameraSmoothStyle "1"`). The file lives in the
client's installation folder (owner, 2026-10-06). That folder isn't built
yet, so for now the file is kept in the project, at
`src/custom-client-c/settings/Config.wtf` (git-ignored: it is the
player's, not the project's). The run script (`scripts/custom-client`)
names it in one line and hands it to the client, so moving it later
changes that one line. Until the options screen exists (173b2), the file
is edited by hand and read at start; the client doesn't write it on quit,
so hand edits are never overwritten. The original's own `Config.wtf` is never read (owner,
2026-10-06: "no"). Only values that differ from the default are
written. On load, a line naming an unknown setting, or holding a value out
of its range, is reported by name and line number and skipped. The
report is never silent.

**C only.** The Lua client is deprecated (173k), so the store has no Lua
twin.

## Suggested Implementation Steps

1. The declaration table and the lookup (`settings.c`'s table of
   declarations; `settings_find`, and `settings_num` / `settings_text`,
   which stop the client on an unknown name).
2. Load and save the file. Tests: a round trip keeps every non-default
   value; a bad line is reported with its line number; an unknown name
   asked for by code fails loudly.
3. Move the client's existing fixed numbers that are settings into the
   table, as the first rows: the window's size (`gxResolution`), the
   zoom-out limit (`cameraDistanceMaxFactor`), and the drag rate
   (`cameraYawMoveSpeed`).

## Open Questions

None.
