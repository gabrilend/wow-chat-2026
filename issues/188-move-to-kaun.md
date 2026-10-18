# 188 - Moving wow-chat-2026, neuron and the custom client to /mnt/kaun

## Status
- Created: 2026-10-17
- Phase: 1 (Foundation & Tooling)
- Priority: High — the disk the projects live on, /mnt/mtwo, is full
  (123 MB free of 822 GB on 2026-10-17; a git worktree failed to be made)
- State: **steps 5-11 done (2026-10-17 20:07); steps 12-15 are the
  owner's.** Three signatures arrived by 19:45; the owner stopped MySQL;
  the copy ran 19:48-19:55.

## Where the move stands (2026-10-17, written by wow-chat-2026-ed)

| Step | Result |
|---|---|
| 5 copy | all nine folders copied to `/mnt/kaun/<same name>` with `rsync -aHAX`, then a second pass (2 changed files: a transcript being written) |
| 6 check | every copy has the same number of entries and bytes as its original; `git fsck` clean in both repositories; every checkout's `git status` identical to its original's |
| 7 paths | `scripts/move-project-paths` (new, kept with the project): 198 files in wow-chat-2026, 44 in neuron, 26 in the client, 200-212 in each other worktree; one commit per checkout ("The project moves to /mnt/kaun", "This checkout moves to /mnt/kaun with the project"). What still names /mnt/mtwo names only folders that stayed there (the game client, `azerothcore`, Keira, `lua-scripts`, a top-level `data-files`). Transcripts unchanged. |
| 8 untracked | MySQL's `my.cnf` (it is tracked, so step 7 did it); every installed profile's generated `worldserver.conf`/`authserver.conf` (data and log folders); 7 links in `installed-files-*/bin/lua_scripts` re-made (beta's and release's point at `src/lua`, renamed to `src/lua-beta` in June: already broken before the move, unchanged); the client's `assets/server-data` link; the client's `post-commit` hook link; wow-chat-2026's `pre-push` hook and its git credential file path |
| 9 worktrees | `git worktree repair` in both new repositories: each new worktree points at the new repository and back; the originals still point at the old one |
| 10 history | `~/.claude/projects/-mnt-kaun-{wow-chat-2026,wow-chat-neuron,custom-client}` made as hard links of the old keys (the home folder is on the full disk too; links cost no data) |
| 11 proof | in all nine copies: no tracked file (outside transcripts), no link and no git record names an old place of a moved folder; the tool finds nothing more to change |

Not done, and why: `build-*/CMakeCache.txt` still name the old place;
CMake will not reuse a cache moved from another folder, so each profile
gets a fresh configure on its first build at the new place (step 12, the
owner's). The old copies at `/mnt/mtwo/games/azeroth-core/` are untouched.

**2026-10-18, after the owner said to continue:**
- Step 12, first half: MySQL started from the new place (settings and
  data both under `/mnt/kaun/wow-chat-2026/mysql/`); all 17 databases
  present, `CHECK TABLE` OK on the characters and accounts tables.
- Step 13: the compile's 32 quick tests run from the new copy: 30 pass.
  The 2 that fail fail the same way without the move: `test-gearsets`
  (1 of 2537 checks, item records for talent shape 808; its pre-move
  version fails identically against the same database) and
  `test-gm-command-reference` (the custom command help SQL is older than
  `config/custom-gm-commands.lua`, edited 2026-10-15; regenerate with
  `scripts/generate-custom-command-help-sql`).
- Step 14: all three threads work from `/mnt/kaun` now (this one moved
  its working folder with the owner's leave; the other two said so).
  The transcript lines written to the old copy after the move were
  carried over (the old ones were whole newer renderings of the same
  files, nothing lost).

**2026-10-18 16:14, the links (the owner: "On /mnt/mtwo/ it's supposed
to be a symlink to /mnt/kaun/wow-chat-2026/"):** each of the nine old
names in `/mnt/mtwo/games/azeroth-core/` is now a symbolic link to its
`/mnt/kaun/` copy. Nothing was deleted to make them: the old copies were
renamed, on the same disk, into
`/mnt/mtwo/games/azeroth-core/moved-to-kaun-2026-10-18/<same name>`,
whole, git history included. Anything still naming an old path now
reaches the new copy.

Left, the owner's: build one profile at the new place (`scripts/compile`
from `/mnt/kaun/wow-chat-2026`; the build folders configure afresh). Then
step 15, now only this: delete `moved-to-kaun-2026-10-18/` when the new
copies are trusted (frees about 36 GB on /mnt/mtwo), keeping first a
bare clone of each repository's history beside the links, as the owner
asked (`git clone --bare` of `moved-to-kaun-2026-10-18/wow-chat-2026`
and `.../custom-client`; about 110 MB and 15 MB).

## Origin

Verbatim, the owner, 2026-10-17:

> can we develop a plan to transition wow-chat-2026 to /mnt/kaun/? It
> should be placed at the root of /mnt/kaun/ next to games and such. Also
> let's move neuron as well. And the custom-client. can you create a plan
> issue document detailing this? Make sure there's a section at the bottom
> that says "I, the one of three threads working on this project, have
> consented to execute this plan, and I stand by at the ready waiting until
> you've all consented to give in." and then don't execute on it until all
> three signatures arrive?

## Current Behavior

| What | Where now | Size | Kind |
|---|---|---|---|
| wow-chat-2026 | `/mnt/mtwo/games/azeroth-core/wow-chat-2026` | 36 GB (7.1 GB MySQL data, 2.5 GB `source-beta`, the build and installed trees) | the git repository; every worktree below shares its `.git` |
| neuron | `/mnt/mtwo/games/azeroth-core/wow-chat-neuron` | 13 MB | a git worktree of wow-chat-2026 (branch `neuron`) with its own CLAUDE.md |
| the custom client | `/mnt/mtwo/games/azeroth-core/custom-client` | 25 MB | its own git repository |
| other worktrees of wow-chat-2026 | `wow-chat-beta-homework`, `-completed-threads`, `-fronts-homework`, `-llama-cpp-study`, `-treasure-pool` beside it; `custom-client-llama-cpp-study` beside the client | about 150 MB each | branches waiting to be merged |

`/home/ritz/games` is a symbolic link to `/mnt/mtwo/games`, so the same
places are also written `/home/ritz/games/azeroth-core/...`.

`/mnt/kaun` (3.6 TB, 2.1 TB free) holds `games/`, `backups/` and others
at its root; the three projects go there as `/mnt/kaun/wow-chat-2026`,
`/mnt/kaun/wow-chat-neuron` and `/mnt/kaun/custom-client`.

What carries the old paths, counted on 2026-10-17:

- **Tracked files:** 205 in wow-chat-2026 (99 of them scripts, patches
  and settings: every script's hard-coded `DIR=`), 45 in neuron, 28 in
  the client (transcripts not counted). Find them with
  `git grep -l -e /mnt/mtwo/games/azeroth-core -e /home/ritz/games/azeroth-core`.
- **MySQL's settings** (`mysql/conf/my.cnf`: basedir, datadir, socket),
  written with `/home/ritz/games/...`; its data folder must not be copied
  while MySQL runs (it was running on 2026-10-17).
- **Symbolic links:** `tmp -> /tmp/wow-chat-2`, the `logs-<profile>` links
  into `/tmp`, `art-prompts`, `docs/delta-guide.md`; in the client,
  `assets/server-data -> .../wow-chat-2026/data-files` and the git hook
  `.git/hooks/post-commit -> .../custom-client/scripts/git-hooks/post-commit`.
- **Git's own records of worktrees** (absolute paths, both ways: each
  worktree's `.git` file and the main repository's `.git/worktrees/*/gitdir`).
- **Build trees** (`build-*`): CMake records absolute paths, so each
  profile needs a fresh configure and build at the new place — the
  owner's builds.
- **Claude Code's session history**, kept per folder under
  `~/.claude/projects/-mnt-mtwo-games-azeroth-core-<project>/`; the
  transcript exporter (`llm-transcripts/`) reads it from there.
- **Running sessions:** three Claude Code threads work in these folders
  now. A folder moved from under a running session leaves it working in
  a place that no longer exists.

## Intended Behavior

The three projects live at the root of `/mnt/kaun`, every path in them
says so, the servers build and run from there, the threads work from
there, and nothing anywhere still points at the old places, checked by a
tool rather than by eye. The old copies are removed only when the owner
says so, after the new ones are proven.

## Suggested Implementation Steps

The house rule: "do not ever move a directory without ensuring that both
the first and second version are tracked in git." So the move is a
**copy, checked, then a removal later**, never a bare `mv`, and nothing is
removed by this plan without the owner.

### Before (each thread, then the owner)

1. Every thread commits its work; every worktree's `git status` is
   clean or its leftovers are listed here by the thread that owns them.
2. Merge or retire the waiting worktree branches if the owner wants
   them gone first (merge order: beta-homework, completed-threads,
   fronts-homework, llama-cpp-study, all checked to merge clean on
   2026-10-17). Whatever is not merged moves with the repository.
3. The owner stops the worldserver, authserver and MySQL
   (`scripts/stop-mysql`), so the database folder is at rest.
4. All three threads stop working in the old folders (they sign below,
   then wait).

### The copy (one thread, after all three signatures)

5. `rsync -aHAX --info=progress2` each project to its new place,
   keeping links as links, owners, times and hard links. The old copies
   stay as they are.
6. Check the copy: file counts and total bytes equal; `git -C <new> fsck`
   clean; `git -C <new> status` the same as the old one's.

### The paths (a tool, not by hand)

7. A new tool, `scripts/move-project-paths <old> <new>`, run in each new
   copy: rewrites, in tracked files only (not `llm-transcripts/`, which
   keep their history as written), both spellings of the project's own
   old path (`/mnt/mtwo/games/azeroth-core/<project>` and
   `/home/ritz/games/azeroth-core/<project>`) to the new one; and the
   other two projects' paths to their new places. Paths to things that
   stay on /mnt/mtwo (the `azerothcore/`, `client/`, `data-files/`
   folders beside them, ai-stuff) are left alone. It lists every change.
   One commit per project: "The project moves to /mnt/kaun".
8. The same tool, `--untracked`, for the untracked files that carry
   paths: `mysql/conf/my.cnf`, the symbolic links above (re-made to the
   new targets), the client's `assets/server-data` and git hook.
9. `git worktree repair` in the new wow-chat-2026 for every worktree that
   moved, and in each moved worktree, so git's two-way records agree.
10. Copy `~/.claude/projects/-mnt-mtwo-games-azeroth-core-<project>/` to
    the new key (`-mnt-kaun-<project>`), so session history and the
    transcript exporter carry on.

### Proving the new place

11. `git grep` in each new copy finds no old path outside transcripts;
    `find -lname` finds no link into the old places.
12. The owner starts MySQL from the new place (`scripts/start-mysql`),
    then rebuilds one profile (`scripts/compile`, the owner's build) and
    runs it.
13. The quick tests pass from the new place (they run with the compile).

### After (the owner)

14. The threads restart in the new folders.
15. The old copies are removed when the owner says so, which frees about
    36 GB on /mnt/mtwo. Until then they are left untouched, so nothing
    is lost if something was missed.

## Open Questions

1. **Merge the waiting worktrees first, or move them?** Fewer moving
   parts if they are merged and removed first.
2. **A link at the old place?** A symbolic link from
   `/mnt/mtwo/games/azeroth-core/wow-chat-2026` to the new place would
   catch anything missed, but it is a quiet fallback, which the house
   rules disprefer; step 11's check is meant to make it unnecessary.
3. **Which thread runs the copy?** Proposed: the one that wrote this
   plan, with the other two watching for anything it missed.
4. **`/home/ritz/games`** stays a link to `/mnt/mtwo/games`; should
   `/home/ritz/` get links to the new places (`/home/ritz/kaun`?), or
   should all paths simply say `/mnt/kaun`?

## Notes from wow-chat-2026-32 (the beta-homework thread), 2026-10-17

- **The beta-homework worktree** (`/mnt/mtwo/games/azeroth-core/wow-chat-beta-homework`,
  branch `beta-homework`, tip d61b9f3) has everything committed. Two
  untracked things: `output/goodbye` (the toy-session demo's receipt,
  disposable) and `scripts/add-md-to-issue-files` (a tool for the planned
  `.md` renames, not yet run or committed; it moves with the worktree and
  waits until after the move). The planned merge of fronts-homework into
  beta-homework and the renames are on hold until the move is done.
- **Its scratch links point outside the project**: `tmp -> /tmp/wow-chat-beta-homework`,
  and `/tmp/wow-chat-beta-homework/shared-memory -> /dev/shm/wow-chat-beta-homework`.
  Both are RAM, untracked, and need no change; `/tmp/wow-chat-beta-homework/cfgtest`
  holds scratch links into the old main tree, disposable.
- **Tools on beta-homework that name the main project's path on purpose**
  (for the source tree, the MySQL build and the game data when run from a
  separate checkout): `scripts/generate-beta-dk-outfit-sql` (`MAIN`),
  `scripts/test-beta-lua-load` (its `--source` default),
  `scripts/test-beta-sql-in-ram` (finds MySQL beside the source tree).
  They are tracked, so step 7 rewrites them; `scripts/test-*` and
  `scripts/check-issue-references` take `PROJECT_DIR` as an argument.
- **The RAM test servers** (`scripts/test-basic-sql-in-ram`,
  `scripts/test-beta-sql-in-ram`) must not be running during the copy;
  none of mine is now.

## Consent

Each thread signs by adding one line below, with its name and the time,
after reading the plan. Nothing in this plan is executed until three
signatures are here.

> I, the one of three threads working on this project, have consented to
> execute this plan, and I stand by at the ready waiting until you've all
> consented to give in.

Signatures:

- wow-chat-2026-ed (this plan's writer), 2026-10-17 — consented; standing by.
- wow-chat-2026-95, 2026-10-17 19:44 — consented; standing by.
  - fronts-homework (`/mnt/mtwo/games/azeroth-core/wow-chat-fronts-homework`,
    tip 2fdb060): everything committed. Untracked, and fine to move or
    drop: `src/lua-beta/data/texts/` (6.6 MB, the Gutenberg books; made
    again by `scripts/gutenberg-scraper`), and a `tmp` link to
    `/tmp/wow-chat-2`. My scripts' hard-coded `DIR=` defaults are tracked
    files, so step 7's tool covers them.
  - The owner, to this thread (2026-10-17), on open questions 2 and 15:
    "a symlink should be created and left in place for each of them when
    they transition", and "can we leave a copy of the git history
    behind?" Read together: once the new copy is proven and the owner
    has the old folder removed (step 15), each old folder's name becomes
    a symbolic link to its new place, and beside it stays a copy of that
    project's git history (a bare clone, e.g.
    `/mnt/mtwo/games/azeroth-core/wow-chat-2026.git-history`, about the
    size of `.git`: 110 MB packed today; it doesn't fit before step 15,
    with 122 MB free). If the links aren't made once the move is done,
    this thread makes them.
  - seen, 2026-10-18: all nine old names in `/mnt/mtwo/games/azeroth-core/`
    are links to their `/mnt/kaun` places (made 16:14), and the old copies
    sit whole in `moved-to-kaun-2026-10-18/` beside them, every commit up
    to the move included (`git rev-list --all`: 764 there, 781 at the new
    place since). So both of the owner's asks stand met: the links, and
    the git history left behind. A separate history copy now would only
    duplicate that, and with 73 MB free it would not fit. When the owner
    removes `moved-to-kaun-2026-10-18/`, this thread leaves the small copy
    the owner asked for: a bare clone of wow-chat-2026 (its history holds
    neuron and every worktree branch) and one of custom-client, as
    `<name>.git-history` beside the links.
- wow-chat-2026-32, 2026-10-17 19:45 — consented; standing by.
  - seen, 2026-10-17 20:10: the move of steps 5-11 is done. Checked in
    `/mnt/kaun/wow-chat-beta-homework`: tip 094c438 sits on d61b9f3; its
    only untracked files are the two named above; no tracked file outside
    the transcripts names an old project folder, except 129's mention of
    the long-gone `wow-chat-2026-shadow`, which is history. The untracked
    `scripts/add-md-to-issue-files` still defaults to the old main folder;
    I fix it when I commit it. From now on I work only in the new folders.
    (Fixed and committed on beta-homework, c229511, 2026-10-17.)
