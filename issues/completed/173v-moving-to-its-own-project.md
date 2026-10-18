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

**Moved 2026-10-07.** The client lives in the W client,
`/mnt/kaun/custom-client/`, and is built, run and
tested there (its CLAUDE.md, `scripts/build --test`, `scripts/run`).
What was done, in 173v's step order:

1. **The W client's documents** rewritten from the three sources with
   the answers below: one engine in C for both games with Lua scripting
   (001, 002), server authority for both games (004), handles and coded
   errors (001), our own archive reader, zlib, a bash build (002, 008),
   Blizzard's files as placeholders until the first replacement and a
   player's folder packed into an archive on the way in (012), the
   rendering as built (005), the decisions listed in 000.
2. **The crosswalk** in the W client's roadmap (009): every source file
   to its reading-order number and the W-client issue it fills, and every
   173 issue to where it continues.
3. **The code** copied by a migration tool (numbered 013 to 044), then,
   in the W client, every part converted to a handle and every failure
   to a code with its sentence (`013-errors.h`); the main loop's state
   one App structure; a clean shutdown order; particles seeded so a run
   repeats; the reader library (`libwreaders.so`) built and loaded from
   LuaJIT. 211 checks pass; pictures match the old client's; the
   address- and race-checked builds run clean.
4. **Scripts:** the build, run and info generators replaced by the W
   client's own; the options catalog's generator moved there, reading
   through the C reader (`scripts/libs/wreaders.lua`), its output
   identical. The creature-list generator stays here (it reads this
   project's world database) and writes into the W client's
   `assets/world/` (not yet run against a database since: MySQL was
   down).
5. **Documents** moved (W client docs 045 to 048), with this project's
   table of contents pointing there.
6. **Issues:** the W client's issues filled by the code rewritten, new
   ones for the pieces without (109, 309, 310, 401 to 404, 801, 802,
   1001); every 173 issue points at where it continues.
7. **CLAUDE.md:** the build permission moved to the W client's CLAUDE.md;
   a pointer here.
8. **The old folders and scripts** (`src/custom-client-c`,
   `src/custom-client` (the Lua first version, removed rather than moved:
   answer 5), the client's scripts and documents) renamed `-done` for one
   commit, the W client's code at its commit e1ebf84.

   Removed in the next commit, as the house rule asks.

9. **The conversations** (answer 7): copied, frozen, into the W client's
   `notes/wow-chat-2026-conversations/` (October 3 to 7), outside its
   `llm-transcripts/` so the transcript tools never take them for its
   own; a README there says the living versions and their HTML stay here.

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
5. (Answered 2026-10-07) **The Lua first version** (`src/custom-client/`):
   "remove it when we transition to the W client." It does not move.
   - **world-edit-to-execute's client goes to C too:** "we will need to
     transition the world-edit-to-execute client to C as well, so they
     fit in the same engine. We can use lua for scripting of course." So
     the merged W client is one engine in C. Lua stays as the scripting
     language (game rules, the interface, addons), not as a second engine.
   - **Pictures without a window** (asked for under 176): the client can
     draw a scene straight to a picture file with no window open, so
     hundreds of test scenes can be photographed in one run.
6. (Answered 2026-10-07) **The creature list generator:** move or stay?
   Neither in the long run: "let's just build in networking." The client
   gets real networking, tested against a stripped-down server profile,
   cc-test (issue 176). The generator retires when the client's world
   comes from the server. Where networking is built (here before the
   move, or in the W client after it) is asked in 176.
7. (Answered 2026-10-07) **The conversations:** copies go with the client:
   "copies I guess. Though I don't think they'll be picked up by any of
   our tooling, so that might need to be investigated. Just put it in the
   issue file for now." To investigate during the move: the transcript
   tools (the exporter, the commit hook that bundles `llm-transcripts/`,
   and the transcript-care tools) find a conversation's project from
   where the session ran. Copied files from another project may be
   skipped, rebuilt over, or filed twice. Check each tool against a
   copied file before relying on it.
   - (Answered 2026-10-07) "let's just copy them over as a reference,
     outside of the llm-transcripts directory, with explicit instructions
     to view them here if we want pretty HTML or whatever. We'll need to
     reference this project from time-to-time anyway." So no tool needs
     checking: the copies sit where the tools don't look (step 9 above).
8. (Answered 2026-10-07) **Issue numbers:** "W client numbers only. The
   letters indicate 'sub-issues' and should not be altered, because they
   provide organization." So a moved piece takes the W client's number
   for the issue it fills. A letter is used only where it marks a real
   sub-issue in the W client's own tree, never to carry a 173 letter
   across. The "came from" line names the 173 issue once.
9. (Answered 2026-10-07) **Game data and profiles** (173d): read in place
   for now. "the visual tests might depend on assets, but most of the
   gameplay tests won't. I think assets should be installed on a
   per-profile basis (even on the user's end, each 'server' is a profile
   for them, and could have different visual settings)". So for a player,
   each server they play on is a profile of the client's own, with its
   own assets and its own visual settings. The W client's design
   documents carry this.
10. (Answered 2026-10-07) **The packet tap** (173l) is not something the
    client connects through: "that's just for testing purposes. It's not
    a Warden." It sits between a client and a server only during a
    recorded test session.
11. (Answered 2026-10-07) **Live shadows and torch light** (173h) are
    built in the merged engine, after the move: "let's do it in the
    merged engine."
12. (Answered 2026-10-07) **The asset resolver** (replacement packs
    first, then Blizzard's archives, then a placeholder): not now. "we
    don't have a replacement pack yet ... we only have the blizzard ones
    for now, not even placeholders. We're just using them as, well,
    placeholders." So the code moves reading straight from the archives,
    as it does here; the resolver is built when the first replacement
    exists.
13. (Answered 2026-10-07) **Code shape:** the W client's rule is that
    no part keeps its state inside its own file: each part hands out a
    handle (a pointer to its state) from an init call, and every call
    takes the handle. This client kept one copy of each part's state in
    the file (one ground, one set of doodads per program) and returned 0
    or 1 with a sentence saying why. The owner: "We should convert during
    the move." On what handles make possible: "the ability to add dynamic
    ground and doodads seems like pretty awesome behavior. We just have
    to make sure that it's synced correctly FROM the server, not TO the
    server. We might also have to validate player positions if we build
    something like that, so they can't just reshape the world and walk
    through locked doors or whatever." On errors: "The W client's errors
    feel more flexible because they allow the calling code to branch
    depending on errors. Ours is more readable, but we could just create
    more verbose error types and expand the list." So every part moves
    with a handle, and errors become typed codes from a list that grows
    as needed (detailed enough to branch on), each still carrying its
    readable sentence. World changes (ground, doodads) only ever come
    from the server to the client; the server checks player positions
    against the world it holds.
14. (Answered 2026-10-07) **The shared reader library** (archives,
    tables, pictures, models as a library world-edit-to-execute calls
    from Lua): built during the move.
15. (Answered 2026-10-07) **What of world-edit-to-execute joins the W
    client:** "The renderers need to merge. We should be able to load
    both model types and animations and particles... all visual stuff.
    Also audio is shared, and probably networking maybe? Not sure if
    Azerothcore could support the kind of networking that Warcraft 3
    uses. The game mechanics are typically pretty agnostic to rendering
    and audio, but often are deeply coupled with networking. The goal is
    to be able to play both games seamlessly in the same binary, and to
    re-use as much of the code as we can between them. The goal is to
    condense the two games into a single project." So: one binary
    playing both games; one renderer drawing both games' models,
    animations and particles; one audio system; each game's rules kept
    apart from the drawing.
    - (Answered 2026-10-07) **Networking:** "I think we transition WETE to
      Azerothcore then. We can have AC be the lockstep host, meaning
      everyone sends their commands to it." So WC3 maps run on
      AzerothCore too: players send their orders to the server, which
      stamps each with its tick and passes it on.
    - (Answered 2026-10-07, replacing the lockstep host above) **Server
      authority:** "I think lockstep isn't worth the implementation cost.
      Let's just do server-authoritative and call it good. Maybe lockstep
      for WETE LAN games or something...?" So on AzerothCore a WC3 map
      runs as the WoW world does: players send orders, the server runs
      the simulation and sends each player what they can see (a unit's
      full state as it comes out of the fog). Lockstep is left as a
      possible later mode for world-edit-to-execute's LAN games. Also
      asked and set aside with it: switching a game to server-only when
      a player's packets keep going missing (two systems to keep right,
      and a hand-over mid-game, for a case server authority never has).
    - **Set aside by the answer above: orders sent player to player as well.** The owner: "they
      also send their commands to every other player as well, who
      simulate what they can see on their end ... player A sends commands
      to the server and player B, player B simulates on their end, and
      the server doesn't need to send player B player A's commands.
      Unless player B notices that something is amiss and then that
      player gets a big stamp on their head that says 'don't trust this
      asshat' - is that valid? Any edge-cases?" The edge cases found
      (packet loss looking like cheating, simulating only what is seen
      breaking lockstep, a player lying about another, addresses exposed
      between players) are in the conversation of 2026-10-07; what
      sending player to player is meant to save (server traffic, delay,
      or server work) decides whether it is worth it.

## Since then (checked 2026-10-17)

- The move stands: the W client builds and tests on its own, and this
  project's documents point there. Paths in this file (`src/custom-client-c`,
  `scripts/build`, `docs/009-roadmap.md` and so on) are the W client's, or
  this project's old ones removed in step 8; `scripts/check-issue-references`
  reports the old folders as "moved out" with a pointer here.
- The creature-list generator that stayed here
  (`scripts/generate-custom-client-creatures`, writing into the W client's
  `assets/world/`) is still the one tie between the two projects' files.
- The cc-test profile (176) is this project's side of the client's testing:
  a stock server with playerbots, the Lua engine and the buddy module, for
  the W client's test scenes.
