# 189d - Our SQL as Patches, After Upstream's

## Status
- Created: 2026-10-20
- Phase: 1 (Foundation & Tooling)
- Parent: 189
- Blocked by: 189c
- Related: 183 (the `z_` names this replaces)
- State: completed 2026-10-23: built; its in-game check taken as done (the owner, 2026-10-23: "let's mark all the issues that are just waiting on a visual check as complete")
  the switch-over's first run (step 6)

## Origin

Asked how our SQL should reach the databases under the gates, the owner,
2026-10-20: "we should use their updater since I think they're quite
proud of it and I want to encourage them. So how about this, during the
compile stage, when we get to the part where we should be applying sql
updates, let's start the server and let them apply naturally. We already
do this for the validation step." On the bot module's database, which
`dbimport` does not prepare: "we will need to update dbimport probably.
No sense having two mechanisms for the same action." (A server start
prepares that database too, so with a start as the gate there is one
mechanism and `dbimport` is not needed.) On the switch from the `z_`
names: on the next install, by itself. Told the gate is an extra start,
the owner: "we need the double startup first to test without the SQL,
then with. If it passes both then it's 100% validly applied." So the two
starts are two tests: the server reaches "World initialized" on
upstream's databases alone, then again with ours applied.

## Current Behavior

Built 2026-10-20, not yet compiled. Our SQL still goes through the
server's own updater (its folders registered in each database's
`updates_include`, the files recorded in `updates`); what changed is when
it is placed.

- **The SQL stage.** The 50 install steps that hand SQL to the updater
  (directly, or through the two-side helper: E007-E017, E019-E033,
  E036-E040, E042-E046, E050, E052-E058, E060-E065) are kind `sql` at
  priorities 2000-8999, each its old priority plus 1000, so their order is
  unchanged. The install stage keeps E001, E004, E006, E049, E059 and the
  settings. `scripts/plan-patches PROFILE --stage sql` lists a profile's.
- **Gate 2000.** After the install stage the compile starts the shadow
  server once (`scripts/validate --no-promote`, the validation's own start
  and wait for "World initialized", log
  `tmp/shadow-gate-2000-<profile>.log`, no promotion), so the updater
  brings every database to upstream's state, the bot module's included.
  A start that fails stops the compile before our SQL is placed.
- **Then ours.** The runner's SQL stage (`apply_patches_sql`) runs the
  SQL steps, then the mirror (`_mirror_staged_sql`) copies each staged
  file into the folder the updater scans, under its own name, stamped
  with the source commits (so a pin move still runs it again). The
  validation start that follows applies them, after upstream's by time.
- **The switch-over.** In every SQL stage, `_forget_z_prefixed_updates`
  removes from each folder's database the `z_` record of each of our files
  (from issue 183's names), and the mirror removes the `z_` copies, so the
  server never warns of a missing file. Each file is then applied once
  more, under its own name, at the validation start (each is written to be
  safe to run again; every pin move has run them all again). After the
  first run there is nothing left to forget. It replaced
  `_forget_unprefixed_updates`, and `z_` names are gone.
- **By hand**: `scripts/apply-patches` runs the install stage then the SQL
  stage (no server start between: with the binaries unchanged the
  databases are already at upstream's state); `--revert` undoes the SQL
  stage first, then the install stage.
- **New steps**: `scripts/add-patch-header FILE --profiles "..." --kind
  sql` (priority 2300 + 10 × number by default).

Checked: `scripts/test-patch-plan` (32 checks) holds that every step
handing SQL to the updater is in the SQL stage and nothing else is, and
`add-patch-header --kind sql`'s rule; `scripts/test-patch-undo-order` (5)
that the runner applies the install stage then the SQL stage, and undoes
the SQL stage first; `scripts/test-sql-mirror` (8) the own names, the
`z_` copies removed, the stamp, a pin move; `scripts/test-forget-z-prefixed-updates`
(3, a scratch table in `_smoke_test`) that only our files' `z_` records
go; all 51 quick tests pass. Not run here: the SQL stage against the real
databases, which is the switch-over itself; it first runs in the owner's
compile.

**Things to watch in that compile:** the gate's start is the first of
two tests (without our SQL, then with it, at validation); on a brand-new database, code
or scripts that read our own tables at start would find them missing at
the gate's start (the start still counts if the world initializes), and
have them after the validation start. E049 (the buddy towns' bake) still
reads a table our SQL makes and skips, saying so, until it exists, as
before.

## Intended Behavior

Upstream's updates are applied before ours by a server start (gate 2000),
not by sorting names; our SQL is placed after it and applied by the same
updater at the next start; the `z_` names and the tidy-up of old names
are gone, with the switch-over done by the next install.

## Suggested Implementation Steps

1. The SQL steps' headers onto the SQL stage (priority + 1000, kind `sql`;
   a temporary tool, `/tmp/wow-chat-2/move-sql-steps.lua`, not kept).
2. The runner's stages shared (`_apply_stage`, `_unapply_stage`) and the
   SQL stage (`apply_patches_sql`, `unapply_patches_sql`) in
   `patches/patches.sh`.
3. `scripts/validate --no-promote`; the compile's gate 2000 between the
   stages; `scripts/apply-patches` both stages.
4. The mirror under the files' own names; `_forget_z_prefixed_updates`.
5. Tests: the plan's invariant, the undo order, the mirror, the switch.
6. The owner compiles each profile; the gate's log, the SQL stage's
   report (how many `z_` records forgotten) and the validation's log show
   it worked, and the next start warns of no missing file.
