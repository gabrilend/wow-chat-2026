# Conversation Summary: ee3e437d-85af-485c-8ed0-8478da64add8

Generated on: 2026-10-07 10:33:53
Models: claude-opus-5-5

## Contents

1. 2026-10-07 10:02, after Request 2 - I've been working through the issues that
   have no open questions, mostly in the custom client, and wrote your
   queued-inputs plan as issue 173w. Next, I need your answers to its four
   questions before building it.

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

### User Request 3

can you write the queued inputs and test characters concepts ideas and questions
into an issue file for me? We can come back to it later, when we implement the
new test-patch system for the cc-test profile (see if you can find those issues,
it might make sense to update them instead of creating a new issue)

--------------------------------------------------------------------------------

### Assistant Response 3

*[commit] 38c253b32 in wow-chat-2026 - The test-patch system gets its own issue: test scenes for cc-test*

I wrote it into a new issue, **176a (test scenes)**, under the cc-test profile
issue (176). It's committed.

I looked for an existing issue to update first. 176 describes the test-patch
idea in your answer to its second question, and says it would become "its own
issue once its shape is clear". No such issue existed yet, so 176a is that
issue, and the queued-inputs ideas go in it rather than in a separate one.

176a contains:
- **What a test patch is:** each one sets up a single scene in its own place in
  the world. That covers the creatures, the test characters and where they
  start, each character's queue of inputs, what each one logs, and what result
  is expected.
- **Queued inputs:** a list of timed moments, each pressing or releasing an
  action under the original game's action names, taking a picture, or writing a
  log line. The queue plays at a fixed pace, so every run comes out the same.
- **Logs and checking:** logs are written to RAM, and ordinary test code
  compares them with what's expected. Any difference goes to an agent, which
  decides whether the new result is wanted and, if so, updates the test.
- **Many test characters at once** in a run with no window, plus pictures taken
  without a window.
- **Your words quoted** from 176 and from this conversation.
- **Six open questions:** the queue's format; who plays the characters (the
  client logged into the server, the client alone without a server, or both);
  whether characters in one run meet; who writes the log (the client, the
  server, or both, compared); how scenes are kept apart; and whether the picture
  options stay as shortcuts.

The client-only plan from last turn (173w) is kept, as issues are never deleted.
It now says it's the client's half of 176a and that its questions live there.
176 points to 176a too.

One thing to check: 176 belongs to the other session working on cc-test. I added
one line to it saying where the test-patch system now lives, and nothing else in
that file changed.

--------------------------------------------------------------------------------

### User Request 4

okey dokey now can we work on abilities maybe?

--------------------------------------------------------------------------------

### Assistant Response 4

> **[Asked the user]**
>
> *Q1 — Abilities:* Which "abilities" should we work on?
> - Client: casting & action bar — Custom client: an action bar (173b10), her
>   spells read from the game's own files, casting plays the cast animation and
>   the spell's particles. All local, no server; I can build and test it myself.
>   Note: networking moves to the W client, so this would move with it (173v).
> - Server: ability tomes — 405 / 155q: abilities learned from tomes instead
>   of trainers. Partly built; needs your server builds and in-game checks.
> - Server: ability scaling — 715 linear ability scaling (no rank jumps)
>   and/or 148w (mage arrives at 20 with an empty spellbook). Server-side; your
>   builds and in-game checks.
> - Server: true ability tooltips — 719: tooltips that show the server's real
>   numbers (custom spells, changed coefficients). Needs client-side display
>   too.
> → **Selected:** Client: casting & action bar

> Casting and the action bar it is. Reading the action-bar issue and anything on
> spells and interface drawing in the client.

> No issue exists yet for the client's action bars or casting (173b10 only
> covers their settings and says so). Checking how far the interface drawing
> (173c) has got, since the bar needs it.

> Planning this as a new client sub-issue. First, what she is (class) and
> whether the spell tables are readable already.

> Before writing the plan I need three decisions from you.

**[Asked the user]**

*Q1 — Her class:* She's a night elf hunter today, and a hunter's early spells
are mostly instant (Auto Shot, Aspects, Tracking), so casting shows little.
Which class should her first spellbook be?
- Druid (Recommended) — Night elf druid: Wrath and Healing Touch have cast
  times, cast animations and visible spell effects; Rejuvenation and Mark of the
  Wild are instant. Shows the most of casting. Her outfit becomes a druid's.
- Keep hunter — Auto Shot, Serpent Sting, Arcane Shot, Aspects. Mostly
  instant; tests the bar and cooldowns more than casting.
- Selectable (--class) — A picture/run option picks the class; druid by
  default. A little more work, but every class can be checked.
→ *(no answer recorded)*

*Q2 — Spellbook:* With no server yet, where does her list of known spells come
from?
- Game files by level (Recommended) — Everything her class learns up to a
  chosen level, read from the client's own tables (SkillLineAbility: class,
  level learned). No server needed; replaced by the server's list once
  networking exists.
- Server's world database — Generated from the world database (starting spells
  + trainer lists), like the creature list (173t). Closest to what the server
  teaches.
- A hand-written list — A short fixed list in the code, e.g. from
  docs/class-spells-level-1-20.md.
→ *(no answer recorded)*

*Q3 — Targets:* There's no combat or server, so what does a cast land on?
- Bystanders as targets (Recommended) — Tab or a click targets a bystander or
  creature; a cast faces it, its missile flies to it and its impact plays there.
  Nothing takes damage. Self-cast spells land on her.
- No targets yet — Casts play her animations, the cast bar and the effects at
  her hands only; anything needing a target lands in front of her.
→ *(no answer recorded)*

--------------------------------------------------------------------------------

### User Request 5

[Request interrupted by user for tool use]

--------------------------------------------------------------------------------

### User Request 6

oh, let's build the server interface first. Question, can you see the W client
at ../custom-client? Does it have stuff we could work on? If so, I'm going to
move you over there, let me know if you see potentials. We're going to merge
this custom client into that one ASAP, is there an issue file for that here? If
so, can we work on that instead?

--------------------------------------------------------------------------------

### Assistant Response 6

Yes, I can see `../custom-client`, and yes, there's a merge issue here: **173v
(moving to its own project)**. All 11 of its questions are answered, so it can
be worked on now.

**What the W client has:**
- **Documents 000–012:** vision, architecture, technology stack, network
  protocol, rendering, interface, audio, build, roadmap.
- **Issues for phases 1–3** (foundation, rendering, world geometry), all
  pending. Phases 4–11 exist only as roadmap headings and their phase-demo
  files.
- **No code:** `src/` is empty.

Almost every pending W-client issue in phases 1–3 has already been built here,
in C: the archive reader, data tables, pictures, window, camera, ground,
buildings, light and sky, streaming. So there's little to *build* there that
isn't merge work. The value is in landing this client's code there.

**The merge (173v), as its answers set it:**
1. Rewrite the W client's documents from three sources: this client, the W
   client's own plans, and `world-edit-to-execute`. That third project has 119
   issues and its own Lua code, including an archive reader and networking.
   Where two sources built the same thing, pick one and record why. This happens
   before any code moves.
2. Write a crosswalk table from each file and 173 issue here to the W-client
   issue it fills.
3. Copy the code over with reading-order numbered file names, a bash build
   script, our own archive reader, and system zlib. Run the tests before and
   after, and compare pictures pixel for pixel.
4. Move the scripts and documents, rewrite the W-client issues' current-behavior
   sections, and add pointers from the 173 issues.

**Two cautions:**
- **Another session wrote those 11 answers today** (commits `9a6b049` and
  `db4a569`). It may already be doing the merge, so check with it before you
  send me over, or we'll both rewrite the same documents.
- **"The server interface" means networking,** and 176 decided networking gets
  built in the W client *after* the move. So the order is the merge first, then
  the login and world connection there.

If you move me over, I'd start with step 1: read the three projects' documents
and draft the W client's rewritten ones. Do you want the merged documents
drafted as one big change, or one W-client document at a time with you reading
each?

--------------------------------------------------------------------------------

### User Request 7

Great, let's do the merge now.

--------------------------------------------------------------------------------

### Assistant Response 7

> Nothing of the merge is in progress on disk (the W client's tree is clean; the
> other wow-chat session is idle). Starting step 1: reading the three sources'
> planning documents.

> Now world-edit-to-execute's side: its W-client bridge design, Phase W issues,
> and what code it has.

> Before writing, I found four places where the W client's plans and our working
> code disagree, and 173v's answers don't settle them. Each one changes what I
> write and move.

> **[Asked the user]**
>
> *Q1 — Resolver:* The W client plans for every asset to be looked up through
> a resolver (replacement pack first, then Blizzard's archives, then a
> placeholder, each counted). Our client reads straight from the archives. When
> does the resolver come in?
> - After the move (Recommended) — Move the code as it is, with the pictures
>   matching; the resolver becomes the first W-client issue built on top,
>   routing every read through one place.
> - During the move — Every archive read is rerouted through a new resolver as
>   the code moves. Bigger move, harder to compare before and after.
> → **Answered:** we don't have a replacement pack yet. What does "replacement
> pack" mean? New models? Yeah we only have the blizzard ones for now, not even
> placeholders. We're just using them as, well, placeholders.
>
> *Q2 — Code shape:* The W client's architecture rules say no module-level
> state: every part hands out a handle from an _init() and typed error codes.
> Our code keeps state inside each file (the ground's tiles, the doodads'
> models) and returns 0/1 with a reason string. Which wins?
> - Move as-is, refactor later (Recommended) — The rule stays the goal; each
>   module is converted to handles in its own W-client issue, with tests passing
>   before and after each.
> - Our shape becomes the rule — The W client's architecture document is
>   rewritten to describe the code as it is (state per file, reason strings).
> - Refactor during the move — Convert every module to handles and error codes
>   as it moves. Much bigger move.
> → **Answered:** I need more context I think
>
> *Q3 — Shared lib:* The W client plans the archive, table and picture readers
> as a shared library (libwreaders.so) that world-edit-to-execute calls from
> Lua. When is that built?
> - During the move (Recommended) — The readers (archives, tables, pictures,
>   models) already have no window dependency, so the build script also makes
>   them a .so with a plain header; world-edit-to-execute can use it at once.
> - Later — Move first; the library is a W-client issue afterwards.
> → **Selected:** During the move (Recommended)
>
> *Q4 — WC3 engine:* world-edit-to-execute has its own whole WC3 engine in Lua
> (game loop, units, pathfinding, JASS triggers) and a C renderer. Which of it
> belongs in the W client's plan?
> - Drawing and input only — The W client draws WC3 maps and sends orders;
>   AzerothCore runs the rules (as decided 2026-09-23). world-edit-to-execute
>   keeps its converter, forge and its own engine.
> - Its whole runtime — The W client takes in the WC3 runtime too (rewritten
>   in C, triggers as Lua scripts), so a WC3 map can run with no server; the
>   AzerothCore route stays for multiplayer.
> - Decide later — Plan only the WoW-world side now; record the WC3-engine
>   question in the W client's documents.
> → **Answered:** The renderers need to merge. We should be able to load both
> model types and animations and particles... all visual stuff. Also audio is
> shared, and probably networking maybe? Not sure if Azerothcore could support
> the kind of networking that Warcraft 3 uses. The game mechanics are typically
> pretty agnostic to rendering and audio, but often are deeply coupled with
> networking. The goal is to be able to play both games seamlessly in the same
> binary, and to re-use as much of the code as we can between them. The goal is
> to condense the two games into a single project.

*[commit] 5313a665a in wow-chat-2026 - The merge's answers on the resolver, the shared library and the two engines*

> The issue file itself wasn't in that commit (my edit came through a script the
> change ledger can't see). Claiming it and committing again.

*[commit] 2564857df in wow-chat-2026 - The merge's answers on the resolver, the shared library and the two engines*

I've recorded your answers in 173v (committed). One question still blocks the
move: the code shape. Here's the context you asked for, then your other two
points.

**The code-shape question.** It's about where each part of the client keeps its
memory.

*Our client today:* each part keeps its memory inside its own file. The ground
code holds one table of 4,096 tile slots, declared at the top of `ground.c` and
shared by the whole program. The doodad code holds one list of models the same
way. There is exactly one ground and one set of doodads in the program, and
nothing outside those files can make a second. Every call just says "load tile
26, 32", and the file knows which ground that means.

*The W client's rule:* `ground_init()` allocates that table and hands back a
pointer to it, called a handle. Every later call passes the handle in: "load
tile 26, 32 *into this ground*." The program can hold two grounds at once. A
test can build its own private one and throw it away without disturbing the real
one.

Errors differ too:
- *Ours:* a call returns 0 (fine) or 1 (failed) and writes an English sentence
  ("the ground picture X is in none of the archives") into a buffer the caller
  passed in.
- *The W client's:* a call returns a numbered code from a fixed list, for
  example "not found" or "corrupt". The caller's code can branch on it, and the
  sentence goes to the log.

Why it matters for this merge:
- **What handles enable.** You said one binary should play both games
  seamlessly. If it ever needs a WoW map and a WC3 map loaded at the same time,
  or 176a's many headless test characters each with their own world, the client
  needs more than one ground. Handles allow that; one table per file doesn't.
- **Cost:** converting means touching every one of about 30 files and every call
  between them.

Three ways to go:
- **Move as-is, convert later.** Lowest risk: pictures match before and after
  the move. Each part is then converted in its own W-client issue, with tests
  before and after.
- **Our shape becomes the rule.** The W client's architecture document is
  rewritten to describe one copy per file.
- **Convert during the move.** The biggest change at once, and the hardest to
  check.

To ask it a second way: can you picture the client ever needing two of the same
thing alive at once? Two maps, two worlds for two test characters, a preview
window showing a model beside the game. If yes, handles will be needed
eventually, and the choice is only *when*.

**"Replacement pack"** means files the project makes itself to stand in for
Blizzard's: new models, textures, sounds. The resolver would look in those
first, then in Blizzard's archives. None exist yet, so the code moves reading
the archives directly, and the resolver waits for the first replacement.

**The two engines** are recorded as one binary for both games. It has one
renderer drawing both games' models, animations and particles, and one audio
system. Each game's rules stay separate from the drawing. The shared reader
library gets built during the move.

Still open: whether networking can be shared. AzerothCore works as a server that
holds the world while each client sends its moves. WC3 multiplayer is
"lockstep": no server holds the world; every player's machine runs the same
simulation, and only the orders are sent between them. Those are different
designs. AzerothCore could relay WC3 orders, but whether it should is a question
for later.

--------------------------------------------------------------------------------

### User Request 8

So the ability to add dynamic ground and doodads seems like pretty awesome
behavior. We just have to make sure that it's synced correctly FROM the server,
not TO the server. We might also have to validate player positions if we build
something like that, so they can't just reshape the world and walk through
locked doors or whatever.

The W client's errors feel more flexible because they allow the calling code to
branch depending on errors. Ours is more readable, but we could just create more
verbose error types and expand the list.

We should convert during the move.



<pasted_content id="ea9d">
> Still open: whether networking can be shared. AzerothCore works as a server
> that holds the world while each client sends its moves. WC3
> multiplayer is "lockstep": no server holds the world; every player's machine
> runs the same simulation, and only the orders are sent between
> them. Those are different designs. AzerothCore could relay WC3 orders, but
> whether it should is a question for later.
</pasted_content id="ea9d">


how is "only the orders are sent between them" and "each client sends its moves"
different? Kinda seems like with WETE we just have every player as the server.
That's... Kinda cool actually? I wonder if there's a way we could update
Azerothcore to do something similar... Though, the consequences for cheaters are
much lower in WETE, so perhaps we would benefit from having an authority.

I'm picturing a peer-to-peer mmo where each player simulates their local state
and also syncs to a server. Not sure if that'd help things at all. No sense for
a player in Tanaris to simulate someone's moves in Azshara, but the server's
already doing that anyway so, not sure if a peer-to-peer system would really
bring value to the WoW system.

--------------------------------------------------------------------------------

### Assistant Response 8

> Recording your answers in 173v first, then the networking explanation.

*[commit] 1c7dd293c in wow-chat-2026 - The client's parts get handles and typed errors as they move*

Recorded and committed: the parts convert to handles during the move, errors
become typed codes that still carry their sentence, and world changes only come
from the server.

**How "only the orders are sent" differs from "each client sends its moves":**

*AzerothCore (an authority):*
- When you press W, your client moves you itself. A few times a second it tells
  the server "I am at x, y, z, facing this way, running forward."
- When you cast Fireball, it sends a request: "cast spell 133 on that creature."
- The server alone works out everything else: whether the spell hits, the
  damage, every creature's AI, health and loot. It sends the results to every
  client near you.
- So a client sends *its own state and requests*, and receives *the world's
  results*. Your client never computes a creature's health.

*WC3 (lockstep):*
- Nobody sends positions or health at all. Each machine sends only commands,
  tagged with a tick number: "at tick 4,812, unit 12 moves to (300, 450)."
- Every machine runs the *entire* game from those commands, deterministically,
  and must get bit-for-bit the same answer.
- The traffic stays tiny however many units there are: 200 footmen moving costs
  one order, not 200 positions.

The price of lockstep:
- Every machine must simulate *everything*.
- The game advances only as fast as the slowest player's orders arrive. One
  lagging player stalls everyone.
- Every machine knows the whole game state, so "map hacks" (seeing through the
  fog) are easy.
- Cheating on *outcomes* is hard, though: a client that changes its own numbers
  just falls out of sync and gets dropped.

So yes, your reading is right: in WETE every player is the server. WC3's host
was mostly a relay that stamped the ticks.

**Would peer-to-peer help the WoW side?** I agree with your instinct that it
mostly wouldn't:
- MMO servers already do "interest management." The world is cut into grid
  cells, and the server only sends you what's in the cells around you. Tanaris
  never hears about Azshara.
- Peer-to-peer would offload server work only if players simulated their own
  areas. Then the server would have to trust them or re-check them, and
  re-checking costs about what simulating did.
- With persistent loot and characters, cheating matters far more than in a
  one-hour WC3 match.

**What modern games do instead** is the hybrid you're picturing: client-side
prediction with server authority.
- Your client simulates *you* immediately, so movement feels instant.
- The server simulates the truth and corrects you if you disagree. That's where
  your "validate player positions" lives.
- AzerothCore does a weak version: it largely trusts the client's movement
  packets, and 173e covers what it does check.

**Where that might land for WC3 maps:** AzerothCore could be the lockstep
*host*, stamping ticks and relaying orders. It could also run the same
simulation itself as a referee, which brings back the authority you said would
help. Your "every player is the server" idea survives, with one trusted machine
checking the work.

When I rewrite the W client's network document (004) during the merge, I'll put
this down as the open networking question, with your words.

Continuing with the merge: next I rewrite the W client's documents (tech stack,
build, architecture with handles and typed errors, formats, rendering, roadmap
and crosswalk), then the code moves.

--------------------------------------------------------------------------------

