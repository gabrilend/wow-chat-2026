# 716 - Class Combination Modifier System

## Status
- Created: 2026-06-01
- Phase: 7 (Custom class / race-class infrastructure)
- Parent: none (top-level; was briefly tracked as sub-issue 148g
  before promotion on 2026-06-01 — the system is cross-profile by
  design, not vanilla-specific)
- Priority: Medium (vanilla is the first profile to want this, but
  release/beta and any future profile can use the same mechanism)
- Related: 148 (vanilla profile — first consumer), the 700s cluster
  (custom-class work this sits alongside)

## Problem

WotLK 3.3.5a defines a fixed table of legal race/class combinations
(human warrior yes, tauren mage no, etc.). Profiles in this project
want the freedom to:

- Enable specific non-canonical combinations (e.g. tauren mage,
  troll paladin) on a per-profile basis.
- Disable specific canonical combinations (e.g. remove gnome warrior
  from vanilla while keeping it in release/beta).
- Have the configuration live alongside the rest of the profile's
  recipe, not as a hand-edited SQL blob that drifts from upstream.

The community module **mod-arac** (All Races All Classes) solves the
"enable everything" case bluntly: it unlocks every combination. That's
not what this project wants — the goal is **selective** enable/disable
with the selection living in a recipe file, similar in spirit to the
source-code patching system.

## Naming

The system is called the **class combination modifier**. The name
emphasises that it modifies the race/class availability matrix; it
doesn't define classes or races themselves (those live in other
existing systems).

## Approach

The implementation is a patcher-style system that:

1. Reads a small per-profile recipe file declaring which race/class
   combinations should be enabled and which should be disabled
   relative to the WotLK default.
2. Generates the corresponding database modifications (insert/delete
   rows in `playercreateinfo` and related tables) and the
   corresponding `realmlist.flag` adjustments.
3. Applies them at install time, idempotently, so re-running the
   installer brings the database back into agreement with the recipe.
4. Can be reverted: removing a line from the recipe and re-running
   the installer un-does that combination's modifications.

Mechanically this parallels the source-code patching system
(`patches/B###-*.sh`) but operates on database content rather than
source files. The same design philosophy applies: the recipe is the
source of truth, and the database is a regenerable build artifact
relative to that recipe.

## Specific-But-Vaguely-Defined Requirements

These are intentionally specific about *what* the system must do, but
loose about *how*. The implementer should choose mechanisms that fit
the codebase as it stands at implementation time.

- **A recipe format exists.** Per-profile, plain-text, readable by
  humans and parseable by the installer. The format is unspecified;
  pick whatever is easiest to write and review.
- **Enable, disable, and reset are all expressible.** The recipe can
  add a combination not in the WotLK default, remove a combination
  that is in the default, and revert to the WotLK default for a
  given combination (i.e. "stop overriding this one").
- **The recipe is per-profile.** Vanilla and beta can have different
  combination matrices simultaneously and switching profiles applies
  the right one.
- **Application is idempotent.** Running the apply step twice produces
  the same end state as running it once. Re-running after a database
  rebuild restores the recipe's state.
- **The apply step is reversible by edit.** Removing a line from the
  recipe and re-applying un-does that combination's change to the
  database.
- **Visual correctness at character creation.** Whatever the recipe
  declares enabled is selectable in the character-creation screen of
  the WotLK client; whatever is declared disabled is greyed out or
  hidden. The realm flag mechanism handles this for the categories
  the flag bits cover; non-canonical combinations may need additional
  client-cooperation. If a client patch is needed, declare the
  dependency and defer until that pipeline exists.
- **Compatible with mod-playerbots.** The bot pool respects the recipe
  — bots are spawned only in combinations the recipe enables. Whether
  this requires patching mod-playerbots or merely configuring it is
  unspecified.
- **Studies mod-arac first.** Before any implementation, mod-arac is
  cloned and read for reference. Specifically: how does it modify the
  `playercreateinfo` rows, how does it interact with the realm flag,
  what starter spells/items does it assign to non-canonical
  combinations, and what does it do about race/class-locked quest
  chains. Notes from this study go in `docs/notes/arac-reference.md`
  (or wherever the project's reading notes live) and inform the
  recipe-format design.

## Specifically Out Of Scope

- **Defining new races or new classes.** That work belongs to the
  phase-7 custom-class issues (700s series). This system only
  modifies the matrix of which existing race × existing class
  combinations are legal.
- **Custom starter gear or starter spells per combination.** A
  non-canonical combination (tauren mage) needs to start *somewhere*
  with *some* gear; deciding what is its own problem, tracked
  separately if and when it comes up.
- **Race/class-locked quest chain handling.** Some quests in WotLK
  are restricted to specific races or classes. Adding a tauren mage
  may produce broken quest assignments; surveying and patching that
  is out of scope here.

## Vanilla's First Use Case

Vanilla wants (as a worked example for the initial recipe):

- The user has "specific race/class combinations [they] want to
  enable" — to be enumerated when the recipe format exists and the
  user can write them down.
- The user wants to disable some canonical combinations as part of
  the vanilla ruleset's tighter character — also to be enumerated.

Both lists are TBD; the system needs to exist before they can be
written.

## Implementation Steps

1. Clone mod-arac into a reference location (not into the build).
   Read it. Take notes on the four points above.
2. Sketch a recipe-file format. Get user sign-off on the sketch
   before implementing the parser.
3. Build the apply-step: parser → database modifications →
   realm-flag adjustments. Idempotent.
4. Wire the apply step into `scripts/install` so it runs after the
   vanilla SQL load (after 148a's DK disablement) but before the
   worldserver boots.
5. Write the vanilla recipe with the user-supplied enable/disable
   lists once the user provides them.
6. Test: rebuild vanilla from scratch; confirm the character-creation
   screen and the server-side validation both match the recipe;
   confirm a recipe edit followed by re-install produces the new
   state.

## Policy: Existing Characters Survive Recipe Changes

**Decided 2026-06-01.** If the recipe enables a combination, players
roll characters in it, and the recipe is later edited to disable
that combination, **the existing characters remain.** They continue
to log in, play, and function normally. The recipe change affects
only future character creation — no existing combination becomes
unplayable as a side effect of an edit.

The implementation consequence: the apply step modifies only the
character-creation gating tables (`playercreateinfo`, the realm
flag, etc.) and does not touch the `characters` table or any
per-character data. The existence of a character is independent of
whether the recipe currently allows new ones of its kind.

This is the gentler of the three options considered (grandfather
vs hard-lock vs forced migration). It makes recipe edits low-stakes
— the worst outcome of a mistaken disable is "no new ones can be
made until you fix it," not "everyone's characters are stranded."

## Open Questions

- What recipe format? (YAML? A small custom DSL? A directory of
  per-combination files like the patch system uses? — decide during
  step 2.)
- Does the system need a "dry-run" mode that prints the database
  modifications without applying them, for review purposes?
- How does the system coexist with 148a's DK disablement? The DK
  case is a degenerate combination-modifier change ("disable all
  DK combinations"). The two should compose: 148a's SQL applies
  first, then the recipe; the recipe can re-enable DK combinations
  later if a profile wants to.
- Mod-playerbots interaction: does enabling a non-canonical
  combination cause the bot factory to crash when it tries to spawn
  a bot of that combination, or does it gracefully accept it?
