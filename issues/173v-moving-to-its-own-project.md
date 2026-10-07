# 173v - Moving to Its Own Project

## Status
- Created: 2026-10-07
- Phase: 1
- Parent: 173 (the custom client)
- Blocked by: None (can start any time; the open questions below come first)
- Related: every 173 sub-issue (each one moves with the code it describes);
  the sibling project `../custom-client` (the W client), its
  `docs/000-vision-summary.md`, `docs/009-roadmap.md` and its eleven
  phases of issues
- Priority: High

## Origin

The owner, 2026-10-07, answering "should the custom client stay inside
this project, or become a project of its own?":

> it will become it's own project. See ../custom-client for details. Can
> you build an issue file for migrating it?

This agrees with what the owner said on 2026-10-06 (quoted in 173): the
client is "something that anyone can use to play World of Warcraft
private servers", kept separate from this project's server profiles.

## Current Behavior

Two halves, each missing what the other has.

**Here (wow-chat-2026): working code, no project of its own.**
- `src/custom-client-c/`: the client in C on Raylib. About 30 source
  pairs (`.c` + `.h`), each with a generated `.info.md`; the test program
  in `tests/`; the generated creature list in `world/`; the settings
  folder `settings/`. Count lines with `wc -l src/custom-client-c/*.[ch]`.
- `src/custom-client/`: the first version in Lua, deprecated (173k), kept
  as the reference until the engine is fully built in C.
- Scripts: `build-custom-client`, `custom-client`, `test-custom-client`,
  `generate-custom-client-info`, `generate-custom-client-creatures`,
  `test-client-models`, `client`. Each has the hard-coded project folder
  at the top.
- Documents: `docs/custom-client-datapath.md`,
  `docs/custom-client-ingame-checks.md`,
  `docs/custom-client-optimization-checklist.md`,
  `docs/custom-client-stock-options.md`, all listed in this project's
  table of contents.
- Issues: 173 and its sub-issues (173a to 173u, 173b1 to 173b16), some
  completed.
- The conversations that built it are in this project's
  `llm-transcripts/` (from 2026-10-04 on).
- CLAUDE.md's "Compiling" section lets Claude build this client and
  names the build script by its path here.

**There (`/mnt/mtwo/games/azeroth-core/custom-client`): a project of its
own, no code.**
- Its own git repository, ten commits. The latest describe the "W client":
  one open client for the WoW world and for Warcraft III maps converted by
  the sibling project world-edit-to-execute.
- Documents 000 to 012: vision, architecture, technology stack, asset
  formats, network protocol, UI and addons, audio, build system,
  roadmap, table of contents, balance updates, asset replacement and
  provenance.
- Eleven phases of issues (101 to 1108), every one pending. `src/` is
  empty. `.file-index-counter` holds 12.
- Choices it made on paper that differ from the working code here:
  - **Build:** CMake wrapped by a shell script. Here: one shell script
    calling the compiler directly.
  - **MPQ archives:** StormLib. Here: the project's own reader, written
    from the format's public description.
  - **Compression:** miniz. Here: the system's zlib.
  - **Asset resolver:** every asset is looked up through a resolver
    (replacement pack first, then the owner's Blizzard files, then a
    visible placeholder) and counted by where it came from. Here: read in
    place from the game's archives (173d), with no resolver yet.
  - **File names:** numbered for reading order (the owner's house rule).
    Here: plain names (`adt.c`, `m2.c`).
  - **A shared reader library:** the MPQ, DBC, BLP and later M2 readers
    built as a C library that world-edit-to-execute calls from Lua. Here:
    compiled straight into the one program.

## Intended Behavior

The client lives in `../custom-client` as the W client's first working
code, and is built, run and tested from there. Nothing it needs is left
behind in this project.

- **The W client's design is the plan, and the working code is what it
  starts from.** Each built 173 piece fills the matching W-client issue,
  and that issue's Current Behavior says what is already there. Where the
  two disagree (the list above), each disagreement is decided once, in
  the W client's documents, before the code moves.
- **Both versions stay in git** (house rule: never move a directory
  unless both the old and the new version are tracked). The last commit
  here that holds the client is named in the W client's first commit of
  it, and the other way round.
- **The issue files are kept, never deleted** (house rule). The 173
  family stays in this project as the story of how the client began. Each
  one gains a line pointing at the W-client issue that continues it. The
  W-client issues point back.
- **This project keeps only what belongs to this project.** That is the
  parent issue 173 as a pointer, and anything that reads this project's
  own databases or profiles (to be decided per script, see the open
  questions).
- **The scripts work from anywhere** with the new project folder as their
  hard-coded default, the folder still taking an argument.
- **The tests pass in the new place** exactly as here (`--test`, the
  address-checked and race-checked builds), and the reference pictures
  match pixel for pixel.

## Suggested Implementation Steps

1. **Answer the open questions below** and write each answer into the W
   client's documents (technology stack, build system, roadmap) first.
2. **The crosswalk:** a table, kept in the W client's roadmap, from each
   173 sub-issue and each source file here to the W-client issue it fills.
   For example: archives (`mpq`) to 105; tables (`dbc`) to 106; pictures
   (`blp`, `texture`) to 107 and 204; ground (`adt`, `ground`) to 301 and
   302; buildings (`wmo`) to 304 and 305; light and sky (`light`, `sky`,
   `horizon`) to 306; streaming (`maps`, `prefetch`) to 303; camera to
   207; models, animation and particles (`m2`, `anim`, `particles`,
   `figure`, `character`) to phase 4; movement and collision (`mover`,
   `moves`, `collide`, `navmesh_slope`, `water`, `liquid`) to phase 8;
   settings to 103 and phase 10. Pieces with no W-client issue get a new
   one in the right phase.
3. **Copy, don't carry history.** The files are copied into the W
   client's repository in one commit that names the commit they came from
   here. Their history stays in this project's git, where it is mixed in
   with this project's other work.
4. **Move the code** into the W client's `src/`, renamed to its
   reading-order numbers if that is decided, with
   `.file-index-counter` updated. Write a test before the move (the
   current suite plus a picture comparison) and run it after.
5. **Move the scripts** into the W client's `scripts/`, with the
   hard-coded folder changed. Move the build-time log into the new
   project's `tmp/shared-memory/`. The new project's `tmp/` already
   points at `/tmp/azc-custom-client`; check that it follows the two-tier
   layout (`tmp/shared-memory/` into `/dev/shm`).
6. **Move the documents** into the W client's `docs/` with its numbering,
   and add each to both tables of contents (the one here keeps a pointer).
7. **Update the issues.** Each W-client issue that a moved piece fills
   gets its Current Behavior rewritten. Each 173 issue here gets a pointer
   line. Then run `validate-issues` on both projects.
8. **Find stragglers.** Grep both projects for `custom-client-c`,
   `custom-client`, the script names and the document names, including
   CLAUDE.md ("Compiling") and the concept catalog. Fix every reference.
9. **Move the "Compiling" permission** in CLAUDE.md to the new project's
   CLAUDE.md, with the same five-minute rule. Leave a one-line pointer
   here.
10. **Leave the old folders** in this project for one commit, renamed
    `-done` (the house rule for retired files), then remove them in the
    next commit.

## Open Questions

1. (Answered 2026-10-07) **History:** carry it, or copy the files? Copy:
   "nah we have wow-chat-2026 issues interspersed, it's not worth it.
   We'll just migrate over there."
2. (Answered 2026-10-07) **Build:** shell script or CMake? The shell
   script: "bash is easier for me. We can always call cmake inside of
   bash." The W client's build-system document (008) is rewritten to
   match. If CMake is ever needed, the shell script calls it.
3. (Answered 2026-10-07) **MPQ reader:** our own or StormLib? "We use our
   own extracter." The W client's technology stack (002) is rewritten:
   no StormLib. The W client also plans to *write* archives (replacement
   packs), which our reader does not do yet. That becomes a W-client
   issue. Compression stays the system's zlib unless decided otherwise.
   - **How players share assets** (asked back, 2026-10-07): "either. A
     plain folder of files would be converted into a compressed archive
     when received. When we use our system to pass the files back and
     forth over the network, we will work with the compressed archive
     version, but we shouldn't require them to, and do the conversion as
     part of the input process." So a player may hand in a folder or an
     archive. A folder is packed into an archive when it is taken in, and
     only archives travel over the network. This goes into the W client's
     asset-replacement document (012).
4. (Answered 2026-10-07) **Numbered file names:** during the move:
   "ideally yes, because we're merging two projects into a third."
   - **The third project** (the owner, 2026-10-07): "I think there's been
     a lot of work done in the
     /home/ritz/programming/ai-stuff/world-edit-to-execute/ project too,
     so we'll need to merge both systems into the W client's planning
     documents." world-edit-to-execute has its own Phase W (W01 to W08:
     reading the WoW archives, WC3 maps in the WoW client, WoW models
     with WC3 behaviour, comparing against the real client, the asset
     forge and similarity scores, one restyled theme, its own server) and
     Lua code (`src/mpq`, `src/net`, `src/render` and more). The W
     client's documents are rewritten from all three sources before any
     code moves. Where two of them built the same thing (an MPQ reader
     exists in both), the merge chooses one and records why.
5. **The Lua first version** (`src/custom-client/`): move it too as the
   reference, or leave it here, deprecated, until it is removed?
6. (Answered 2026-10-07) **The creature list generator:** move or stay?
   Neither in the long run: "let's just build in networking." The client
   gets real networking, tested against a stripped-down server profile,
   cc-test (issue 176). The generator retires when the client's world
   comes from the server. Where networking is built (here before the
   move, or in the W client after it) is asked in 176.
7. **The conversations:** the transcripts that built the client stay here
   (house rule: they ride with this project's commits). Should copies, or
   only references, go with the client?
8. **Issue numbers:** do the moved pieces keep their 173 letters (for
   example "173f, now 301") or go only by the W client's numbers?
