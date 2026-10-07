# Conversation Summary: ee3e437d-85af-485c-8ed0-8478da64add8

Generated on: 2026-10-07 09:59:14
Models: claude-opus-5-5

--------------------------------------------------------------------------------

### User Request 1

hello claude we have so many issues in this project. Can you work on any that
don't have any open questions until we run out? I'm going to have someone else
work through the open questions with me so we can unblock more work.

--------------------------------------------------------------------------------

### User Request 2

Base directory for this skill: /home/ritz/.claude/skills/issue-lifecycle

# Issue lifecycle

The owner's CLAUDE.md is the authority on what issue files are for and what
they must contain; where it and this skill ever disagree, CLAUDE.md wins. This
skill adds the mechanics CLAUDE.md leaves open: which tools answer which
question, in what order, and what to do when a tool says no.

All tools live in one place and are called by absolute path:

| Tool | Answers |
|---|---|
| `/home/ritz/programming/ai-stuff/scripts/validate-issues <project>` | is the issue tree consistent; next free number per phase |
| `validate-issues <project> --next <phase>` | the number to give a new issue |
| `validate-issues <project> --file <issue>` | is this one issue well-formed and are its links matched |
| `/home/ritz/programming/ai-stuff/scripts/progress-dashboard.lua <project> -m` | done/open counts per phase (for progress files and demos) |
| `/home/ritz/programming/ai-stuff/scripts/commit-own-changes <repo> -F -` | commits exactly the lines this session wrote, plus the changed transcripts of the commit's projects (any conversation's), and runs the repository's commit hooks, without touching the shared staging area |
| `/home/ritz/programming/ai-stuff/scripts/stage-own-changes <repo>` | previews what that commit would take; writes nothing |
| `/home/ritz/programming/ai-stuff/scripts/claim-own-change <file>` | records lines this session changed by a route the edit ledger cannot see (see Committing) |
| `/home/ritz/programming/ai-stuff/scripts/adopt-left-behind-changes <repo> -- <path>...` | takes ownership, line by line, of uncommitted work a finished session left, leaving lines any other session still holds (see Committing) |

Each tool has a `.info.md` beside it; read that rather than the source.

## Before writing a new issue

1. **Search first, including `issues/completed/`.** Grep the issue tree for
   the feature's nouns, not just the likely title. A completed issue about the
   same machinery is reopened and extended rather than duplicated: history is
   more useful stacked vertically in one file than spread across several.
2. **Pick the phase by what the work builds on**, not by when it is being
   done. Lower numbers are foundations; later issues depend on earlier ones.
3. **Take the number from the tool:** `validate-issues <project> --next
   <phase>`.
   It reads the project's own naming shape (522, 1001, 9-007, A04) and never
   reuses a number that a completed file already holds.
4. **Write the blueprint** with the three sections CLAUDE.md requires, plus
   link fields in the shape the project already uses (look at a neighbour).
   Name related functions, structures and files instead of pasting code.
5. **Check it:** `validate-issues <project> --file <new-issue>`, and fix what it
   reports on the new file. If the new issue blocks or is blocked by others,
   add the matching line to the other side too.

## While working

- Keep **Current Behavior** true. It is the only section that changes while
  an issue is in progress; rewrite it in place rather than appending a log.
- A question that surfaces is written into the issue (an "Open questions"
  section) and then asked. An issue with an unanswered question is in
  progress, not done.
- Anything discovered that changes another issue's assumptions is written into
  that issue now, not at completion.

## Splitting into sub-issues

Split when an issue holds work streams that could be built, tested or reviewed
separately, or when it cannot be finished in one sitting. Do not split an issue
that is already one mechanism. When splitting, produce and then write out:

1. **A table** — `| ID | Name | Dependencies | Description |`, where ID is the
   parent number plus a lower-case letter (103a, 103b), Name is dash-separated
   lower-case words, Dependencies is "None" or sibling IDs.
2. **The rationale** — the distinct work streams, why one issue cannot hold
   them, what splitting buys.
3. **The execution order** — a small dependency graph, e.g.
   `103a (foundation) → 103b (needs 103a) → 103c (parallel with 103b)`.

Each row becomes a file `{parent}{letter}-{name}.md` with the three sections.
The parent keeps its blueprint and gains a short list of its sub-issues; the
analysis itself is not appended to the parent (that would be worklog, not
blueprint). Run `validate-issues` afterwards: it reports orphaned sub-issues
and one-sided links.

## Completing an issue

An issue is complete only when nothing in it is deferred and no open question
is unanswered. Then, in this order:

1. **Run the project's tests.** A fixed bug gets a test that would have caught
   it.
2. **Rewrite the issue as the blueprint of what was built**: Current Behavior
   states the built system; steps name the real functions and files; decisions
   not taken are stated with their reason. Poetry the owner wrote during the
   work goes into the issue verbatim.
3. **Move it** into `issues/completed/` (`git mv`, so the history follows).
4. **Update `issues/phase-<N>-progress.md`** for that phase. Take counts from
   `progress-dashboard.lua <project> -m`, or better, name the command instead
   of copying numbers that will go stale.
5. **Update related issues** whose Current Behavior or assumptions changed.
6. **Run `validate-issues <project>`** and fix new findings that the change
   caused. Findings older than the change are reported to the owner, not
   silently fixed in passing.
7. **Commit** as below.

## Committing

The rule (CLAUDE.md): a commit carries exactly the lines this session wrote —
never another session's work, even if it sits in the same file — and every
changed transcript of the commit's projects rides along — the session's own
project folder and the projects of the files it commits — this
conversation's and any other's left behind (a session that committed, talked
on and quit), so each project's story in git stays whole.

Commit small and often: each piece as soon as it is done and checked, not a
pile at the end.

1. Optionally preview: `stage-own-changes <repo>` lists what would be taken
   and what left out, and writes nothing.
2. Commit: `commit-own-changes <repo> -F -` with the message on standard
   input. It builds the commit on a private staging list from this session's
   own lines (the edit ledger the edit hook keeps) plus those transcripts, and
   never touches the shared staging area, so nothing another
   session has staged can ride along. Plain `git commit` is refused by the
   commit gate.
3. Message style: say what the software now does, in plain English and by
   mechanism or analogy; mention any extra changes and why. No function names.

**When it stops or leaves something out.**

- **A tangled ("mixed") block** means another session changed lines right
  next to or on top of yours. Nothing is committed. Tell the owner which file
  and line; decide together what that region should say. `--leave-mixed`
  commits your other blocks meanwhile.
- **Lines that are yours but were written by a route the ledger could not see**
  (a script you ran, a generator, `sed`, a rename): record them with
  `claim-own-change <file>` and say so in the commit message.
- **Nothing to commit, but the work is there**: an earlier session wrote it
  and ended, or the machine rebooted and emptied the ledgers. Look first with
  `adopt-left-behind-changes <repo> --dry-run -- <path>...`, then adopt and
  commit one batch at a time with `commit-own-changes <repo> -F - --
  <path>...`. Lines reported as **held** belong to another session. Take them
  (`--from <session>`) only if that session has finished, and ask the owner
  if unsure. Say in the commit message that the work was adopted and from
  whom. This is the route for a left-behind backlog, not the token.
- **A warning about the shared staging area** means someone had staged that
  file by hand in a way that overlaps your commit; their entry was left alone.
  Tell the owner.

The one-time permission tokens (`/tmp/claude-allow-*`) belong to the person.
Never create one; if a gate names a token, relay the gate's message and let
the owner decide.

## Open questions

- Phase ≥ 10 in compact names depends on the project's issue-number width;
  `validate-issues` decides it from evidence (progress files, `phase-N-demo`
  names). A project with none of those gets a warning. Should the house rule
  fix one width (two digits, as in the 522 example) for every new project?

--------------------------------------------------------------------------------

### Assistant Response 2

> Starting with the custom client's next step (preparing map tiles on the second
> thread), which the last session marked as having no open questions. Reading
> the loading code now.

> Reading how doodads load per tile, to plan moving tile preparation onto the
> reading-ahead thread.

> Building and taking a baseline measurement (12-second walk from Astranaar).

> Measured: of the ~31 ms a tile load stalls while walking, the ground is 23 ms.
> Building the ground preparation on the second thread now.

> Writing the preparation half now (the arithmetic moved out of the drawing
> file).

> Now the server-height reader's lock (it loads tiles lazily, and both threads
> will ask it).

> Now the sending half in `ground.c`.

> Now the helper thread: preparing each ring tile's ground, handing it over, and
> letting go of ones she turned away from.

> Wiring it into the main loop.

> Updating the test, and adding checks that the helper's prepared ground matches
> one prepared on the main thread exactly.

> Tests pass (191). Measuring the walk and comparing pictures.

> Ground stall halved (23 → 11 ms a load). Checking what's left in those 11 ms
> before going further.

> Regenerating the whole picture array's smaller copies costs ~5 ms per tile.
> Moving that to the helper too: it'll make each new picture's smaller copies
> itself, so only the new layer is sent.

> Adding a check for the smaller copies, then building.

> 193 checks pass. Building the last committed version separately to compare
> pictures pixel for pixel.

> Pictures match (at most 0.03% of pixels differ, by more than 2%). Measuring
> the walk.

> Walking loads: 31 → 14 ms (ground 23 → 5). Running the address-checked
> build on a walk and a jump across the zone before committing.

> No memory faults on either. Since this adds shared state between threads, also
> trying a race-checked build.

> No races found. Adding that race-checked build to the build script as
> `--tsan`, beside `--asan`.

> Updating the checklist, the issue, and the data-path document.

> Committing this step.

*[commit] ec4c12ba0 in wow-chat-2026 - The next tiles' ground is made ready on the second thread*

> Committed. Moving on to step 8d (parsing new doodad models on the helper
> thread). Reading the model loader.

> Before splitting doodads, measuring where their 9 ms goes (new models, new
> buildings, placing copies, water).

> Another session just created an issue about the custom client ("moving to its
> own project"). Checking it before continuing on the same code.

> Now the hash index for placements already placed.

> Only 3 loads per walk makes the averages noisy. Timing the placing step
> directly instead.

> The lookup saved 2–5 ms; placing still costs up to 7 ms. Looking at what
> else it does (solid shapes into the collision world).

> The remaining placing cost is filing ~21,000 solid triangles per tile into the
> collision grid: real work, not waste. Recording measurements and committing.

> Same placements after a jump (8,885 copies, 282,768 solid triangles, as
> before). Committing.

*[commit] 4818766c3 in wow-chat-2026 - Placing a tile's doodads asks a table instead of searching every placement*

> Leaving 173u there: it still holds an unanswered question ("entirely GPU" as
> goal or principle). Surveying the other issues without open questions.

> Several issues say "Completed" or "Resolved" but still sit in the open folder.
> Checking those first (the house rule: move them as they are, if everything in
> them is addressed).

> Moving two finished issues (parallel update spinners; the position-error fix)
> into `completed/`, unchanged.

*[commit] bbc27ef86 in wow-chat-2026 - Two finished issues filed with the completed ones*

> Next: tooling issues I can build and test without the server build. Reading
> 128 (script command history), 146 (patch status command), 123 (HTML source
> export).

> Many custom-client sub-issues say "Open Questions: None". Checking what each
> still has left.

> Picking concrete left-over client pieces I can build and check with pictures.
> First: walking (173i) — she can only run today. Reading the movement code.

> Adding walking: walk speed 2.5 yards a second (the game's, times her 120%),
> toggled with the stock key (numpad `/`), the model's own walk animation, and a
> `--walking` picture option.

> Writing the mover and animation changes.

> Now the toggle key and picture option in `main.c`.

> Adding tests: walking moves at 2.5 × 1.2 yards a second every way, and plays
> the walk.

> The walk plays. Walking was the only thing left in 173i; checking whether that
> issue is now complete.

> 173i's only remaining item was the walk. Rewriting it as the blueprint of what
> was built and filing it as completed.

*[commit] 7051a0110 in wow-chat-2026 - She can walk: the keypad's slash toggles walking and running*

> Next: 173n's underwater light (the zone's own "underwater" lighting when the
> camera is below the surface). Reading the light code.

> Light.dbc's next field is the "clear underwater" parameter set (Ashenvale's
> lights each name one). Wiring it: when the camera is below the water's
> surface, the light comes from that set.

> Now in `main.c`: is the camera under water this frame?

> An approximation already exists (fog to the water's colour within 40 yards,
> marked "to compare"). Checking what the game's own underwater set says before
> replacing it.

> Now replacing the approximation in `main.c` with the zone's own underwater
> set.

> Builds; 199 checks pass. The game's underwater set at Astranaar: fog from 0 to
> 167 yards, teal. Taking an underwater picture to compare with the old
> approximation.

> Left: the old grey approximation. Right: the zone's own underwater light —
> the dark teal the game uses in Ashenvale's lakes. Updating 173n and 173r.

*[commit] 74edbb7e1 in wow-chat-2026 - Under water, the world is lit by the zone's own underwater light*

> Next: the video settings issues (173b5 resolution, 173b6 effects) — concrete
> and testable. Reading them.

> Building 173b5's window settings: windowed/fullscreen, maximized, resize lock,
> vsync (live), and saving the window's size when she quits after resizing.
> Looking up the original's wording for each.

> Adding a settings check for the new window settings, then building and trying
> a fullscreen-off/maximized start.

> Maximized starts work (the picture comes out at the window manager's size).
> Testing the size-saving on a real quit.

> No window-automation tool is installed, so the quit-and-save path can't be
> exercised from here; I'll note that in the issue for you to try once. Updating
> 173b5.

*[commit] 7d2456096 in wow-chat-2026 - The window opens as the Resolution settings say, and keeps its size*

> Next: 173b6 (video effects).

> Particles exist now (173o), so their row, Particle Density, can be built.
> Reading the particle emitter.

> Building Particle Density: the emitters' birth rate times the slider (0.1 to
> 1), passed down from the settings so the particle code stays settings-free.

> Particle Density works (201 checks). Next row: Texture Filtering. Checking how
> pictures are filtered now.

> Building Texture Filtering (bilinear, trilinear, anisotropic 2x–16x; read at
> start, as the original marks it) as one helper every picture upload calls.

> Builds. Comparing pictures at the default (should be unchanged) and at 16x
> anisotropic (ground at a slant should sharpen).

> 16x anisotropic (bottom) shows the slanted ground visibly sharper than
> trilinear (top); the default matches before. Updating 173b6 and committing.

*[commit] d8c0e9c62 in wow-chat-2026 - Two more Effects settings: Particle Density and Texture Filtering*

> Next candidate: 173b3 (key bindings). Reading it.

> The owner asked to hold key bindings until the action bar, so skipping 173b3.
> Checking 173g's "moss fault" item (it may already be fixed).

> The moss check needs your eyes in-game (already asked in the in-game checks
> doc). 173g's "Left" list is also stale: particles and moving pictures were
> since built (173o, 173n). Tidying it.

> All 710 doodads and buildings found in both agree within 0.0007 yards. Making
> sure the check can fail: temporarily swapping two of the server's angles.

> The check fails when the angles are wrong (591 of 710, off by up to 12.7
> yards), so it discriminates. Updating 173g.

*[commit] 1dfed6141 in wow-chat-2026 - Doodad and building placement checked against the server's own*

> Committed. Next, checking the buddy pathfinding issues (617o2, 617o3, 617o4):
> they may be offline computations I can build and test without the server.

> 173s, 173j and 173k show nothing left. Checking whether they're actually
> finished and just never filed.

> Comparing a far jump (everything at Astranaar must be dropped) against a fresh
> start at the destination: the counts should be identical if nothing is left
> behind.

> I'll add a small mover function that gives the intended speed for the keys
> held, and pace her animation by it.

> Adding a test (running into a wall: the intended speed is still the run's),
> then building.

> 204 checks pass. Updating 173i's blueprint (the animation now follows the
> keys' speed), and filing 173s's long-walk step and the completed 173j.

*[commit] f514274af in wow-chat-2026 - Running into a wall, she runs on the spot*

> Now 173s (long-walk step done → complete) and 173j (complete; its one known
> gap moves to the creatures issue).

*[commit] 8c932780c in wow-chat-2026 - Two custom-client issues finished and filed: tiles streaming, figures standing*

> Committed. Now your second point: a plan for queued inputs and several test
> characters at once. Checking for an existing issue first.

> Writing the plan as a new custom-client sub-issue (173w), related to the
> cc-test server profile another session just started (176).

*[commit] 3c9216c55 in wow-chat-2026 - A plan for queued inputs and many test characters in the custom client*

Both of your points are handled. She now runs on the spot when she hits a wall.
The test-characters plan is written up as 173w, but it has four questions I need
you to answer before I build it.

**The wall:** her run animation was timed by how far she actually moved each
frame. Against a wall that distance is zero, so she froze mid-stride. Now it's
timed by the speed the keys you're holding ask for, so the run keeps going
against a wall like the original. A test checks that speed, but I couldn't watch
it happen: a picture can only be taken once she has stopped. 173w would fix that
gap.

**Done this session** (custom client; 204 checks pass; each step committed
separately):
- **Loading the next map tiles:** the second thread now also builds the next
  tiles' ground. Walking into a new tile used to freeze the frame for 31 ms; now
  it's 14 ms. Pictures are unchanged. Memory-checked and race-checked builds
  found no faults; the race-checked one is new (`build-custom-client --tsan`).
- **Placing doodads** checks a table instead of searching about 7,000 earlier
  placements. That step went from 10.6 to 5.9 ms on the same tile load.
- **Walking:** the keypad `/` toggles walk and run, with her own walk animation.
  173i is finished and filed.
- **Underwater light:** she's now lit by the zone's own underwater light, from
  the game's light table, instead of my grey stand-in.
- **Window settings:** windowed, maximized, vertical sync and resize lock, and
  the window's size is saved when you quit.
- **Effects settings:** Particle Density, and Texture Filtering up to 16x, which
  makes ground seen at a slant sharper.
- **Placement check:** a new test compares 710 doodads and buildings at
  Astranaar with where the server's own collision files put them. All 710 agree
  within 0.0007 yards.
- **Filed as finished:** tile streaming (173s) and the standing figures (173j).
  Tile streaming's last check passed: a far jump leaves exactly what a fresh
  start there has. I also moved two issues that were already marked done but
  still sat with the open ones (120, 606b).

**Questions for 173w (queued inputs and test characters):**
1. Should a queue be plain lines like `2.5 press JUMP`, or a Lua file, which
   could loop and compute?
2. Should many test characters run in one windowless program sharing one loaded
   world, or as one client program each (that needs the network), or both, in
   that order?
3. In a shared run, should test characters collide with and see each other, or
   each act as if alone?
4. Once queues exist, keep `--walk`, `--dive` and the others as shortcuts, or
   replace them with `--queue FILE`?

**Other things that need you:**
- **Gamma (173b5):** the original changes the display's brightness curve; I'd do
  it in the client's shaders. Should the slider raise each colour to the power
  1/(1+gamma), or should we match it by eye against the original?
- **Saving the window size** isn't checked yet: there's no tool here to send
  Escape to the window. Please resize the window once, press Escape, and look at
  `src/custom-client-c/settings/Config.wtf`. Saving rewrites that file, so any
  comments you've typed into it are lost.
- **Issue 307** exists twice: the full write-up in `issues/` and an older
  moved-pointer version in `completed/`. Moving the full one would overwrite the
  pointer, so which should I keep?

I skipped key bindings, since you asked to hold them until the action bar. Most
other open issues need a server build or in-game testing, which you run.

On question 2, try putting it a second way: what do you most want to learn from
many characters at once — that lots of separate behaviours each still work, or
how characters behave around each other?

--------------------------------------------------------------------------------

