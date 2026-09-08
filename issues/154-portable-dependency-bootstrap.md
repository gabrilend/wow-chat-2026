# 154 - Portable Dependency Bootstrap

## Status
- Created: 2026-09-08
- Phase: 1 (Foundation — build pipeline)
- Priority: High (blocks installing the project on any machine but the
  original operator's)
- In progress. Every implementation step below is written and exercised
  on the operator's own machine, but nothing has yet been run on a
  second computer, which is the only test that settles whether this
  worked. The open questions at the bottom are unanswered.

### What has not been demonstrated

The scripts were exercised along every path that does not take forty
minutes: help text, argument rejection, directory resolution in both
argument forms, refusal when run as a lone downloaded file with no
`--dir` and the per-marker listing in that refusal, recognition of the
real checkout by all three markers, creation of a `--dir` that did not
exist, the environment
report with requirements deliberately missing, configuration generation
onto a brand-new directory from a single downloaded file, the existing
configuration on this machine being correctly recognised as already
describing this project despite being reachable by two different paths,
the confirmation gate refusing to run without a terminal, password
generation and file permissions, and `diff` confirming the three copies
of the duplicated section still match.

Not exercised: a MySQL build from source, and therefore none of the
steps that follow it — data directory creation, the setup server
starting and stopping, the root password reaching the server, database
creation, or the application grant. Nor a Boost or ccache build, since
both are already installed here. Those run only on a machine that does
not already have them, which is the machine this issue exists for.

## Problem

The three scripts that build the project's compiled dependencies from
source — Boost, ccache, and MySQL — only work on the machine they were
written on. Someone cloning this repository onto a second computer
cannot run any of them successfully, and the failures they get are the
confusing kind: an error from deep inside cmake or b2 that names a
missing symbol rather than a missing package.

That is the opposite of what these scripts are for. Their entire job is
to make dependency installation less confusing.

### The location assumption

Every script under `scripts/` opens with a hard-coded absolute path to
the project directory. That is the house convention, and for the
operator's own machine it is correct and convenient. But three of these
scripts are the *first* thing a new machine runs, before anything else
exists, and on that machine the hard-coded path is wrong.

Two of them — the Boost builder and the ccache builder — accept no
argument at all, so the path cannot be corrected without editing the
file. The MySQL builder does accept a directory, but see below.

The same assumption is baked into a data file, not just scripts: the
MySQL server configuration at `mysql/conf/my.cnf` is tracked in git and
contains the operator's absolute path in seven places — the base
directory, the data directory, the temp directory, the socket, and three
log paths. A fresh clone therefore starts a MySQL server pointed at
directories that do not exist on the new machine.

### The unverified environment

None of the three checks that the tools they invoke are present. The
Boost builder needs a C++ compiler and `curl` and `tar` and `file`. The
ccache builder needs cmake and `xz` and the zstd development headers.
The MySQL builder needs cmake, bison, a C++ compiler, `wget`, and the
OpenSSL and ncurses development headers. A machine missing any one of
them discovers this several minutes into a build.

The MySQL builder also passes three cmake options that the version it
builds does not read. Two of them ask MySQL to download and use its own
copy of Boost; that was real on the 8.0 line, but 9.x ships the Boost
headers it needs inside its own source tarball and its cmake says to
always use the bundled copy. The third switches off a memcached plugin
that no longer exists as an option. All three are silently ignored,
which is worse than an error, because they read as if the build were
still being steered by them.

### The argument collision

The MySQL builder's header says it "downloads latest version or uses
specified version". It cannot. Its first argument is claimed by the
directory parser, which takes any argument not beginning with a dash.
Passing a version number therefore sets the project directory to the
literal version string, shifts it away, finds no version argument
remaining, and silently installs the newest release instead — into a
directory named after the version, relative to whatever directory the
operator happened to be standing in.

### The unguarded pipeline

The MySQL builder sets `pipefail` but not `errexit`, alone among the
three. A failed cmake proceeds to make; a failed make proceeds to make
install; a failed install proceeds to initialise a database against
binaries that were never written. The quiet version of that last case is
worse than the loud one: an older server binary left over from a
previous run will happily initialise a data directory that does not
match the source just compiled.

The same missing guard turns a soft failure into a hard one elsewhere.
The target version is discovered by scraping a vendor web page. Nothing
checks the result. When the scrape returns nothing — page layout
changed, no network, a `grep` without PCRE support — the empty string
flows into a download URL, the download fails, and the build continues
into a source directory that was deleted moments earlier.

### The unattended stop

The MySQL builder pauses for a keystroke before doing any work, so it
cannot be driven by another script or run overnight.

### The half-finished install

It ends by initialising the database with no root password and printing
three steps for the operator to perform by hand: start the server, set a
password, create the databases. The first two are mechanical and belong
in the script. It also names the start script incorrectly — it points at
a noun-first name that issue 121 proposes but which has not been created.

### The core count

The Boost and ccache builders default to four parallel jobs regardless
of the machine. The MySQL builder uses every core the machine reports.
Neither is right: the first wastes a large machine, and the second can
exhaust memory on a machine with more cores than spare gigabytes, since
MySQL translation units routinely need around two gigabytes each.

## Intended Behavior

A person clones this repository onto a machine that has a compiler and
little else, runs three commands from any working directory, and gets a
built Boost, a built ccache, and a running MySQL server with a password
they can find.

### One file, downloadable on its own

The expected way someone else gets these is downloading the individual
script file, not cloning the repository. So each of the three is
entirely self-contained: no shared library beside it, no template file,
no other part of the checkout. A single file lands on a machine that
has never seen this project and works.

That means the environment-checking machinery is present in all three
copies. The duplication is the accepted cost of the shape: one file a
stranger can use is worth more than one copy a maintainer can edit.

To keep three hand-maintained copies checkable, the duplicated section
is byte-identical in all three — it runs from the `# Environment checks`
banner to the closing brace of `resolve_project_dir`. Anything that
differs inside that range is drift. The check, from the project
directory:

```sh
block() {
    awk '/^# Environment checks$/{on=1} on{print}
         on && /^resolve_project_dir\(\) \{/{seen=1}
         seen && /^# \}\}\}$/{exit}' "$1"
}
diff <(block scripts/boost) <(block scripts/ccache)
diff <(block scripts/boost) <(block scripts/mysql-install)
```

Both should print nothing. Run it after editing any of the three.

### Location

Each script determines the project directory in this order: an explicit
`--dir` argument, otherwise the parent of the directory the script
itself lives in. The result is converted to an absolute, symlink-resolved
path before anything uses it. No hard-coded path remains.

This deliberately departs from the house convention of a hard-coded
default. The convention serves a single-machine project; these scripts
run before the machine is known.

The derivation from the script's own location is only trusted when the
script really is sitting in a checkout of *this* project. A copy
downloaded on its own into some other directory has nothing to derive
from, and guessing there would build into the operator's home directory
or wherever they happened to be standing. It stops and asks for `--dir`
instead, naming which files it looked for and which it found.

What proves a checkout is three specific files, all of them tracked in
git so a fresh clone has them before anything is built:

| File | What it is |
|------|------------|
| `scripts/worldserver` | This project's wrapper around the game server launcher |
| `patches/patches.sh` | This project's patch runner |
| `docs/concept-catalog.md` | The concept catalogue |

All three are files this project wrote, which is the point rather than
an oversight. The question is "is this a checkout of *this project*",
not "is this an AzerothCore server" — a marker shared with every
AzerothCore fork would answer the second, and the second is not being
asked. Files nobody else has are the ones that discriminate.

Generic shapes are deliberately not used: a `scripts/` directory and a
`docs/` directory sit in an enormous number of projects and in plenty
of home directories, so finding them proves nothing.

All three must be present. Requiring three specific paths costs an
operator one `--dir` argument when the check is wrong; a loose check
being wrong costs a build landing in the wrong place.

The cost of naming project-written files is that renaming any of them
turns the derivation off. It turns off loudly: the refusal prints every
marker with whether it was found, so a rename appears as one MISSING
line naming the file that moved, and the fix is to correct the list in
all three scripts.

No marker check is applied to an explicit `--dir`, because on a fresh
install none of those files exist yet — the operator saying where the
project goes is better evidence than a file listing. A `--dir` naming a
directory that does not exist is created.

The repository's own build scripts — install, compile, update — take
the same `--dir`, so a second machine can go from clone to running
server rather than stopping once its dependencies are built. They carry
a shorter version of the resolution, without the standalone refusal:
they are useless without a full checkout around them, so if they are
running at all, they are inside one.

### Configuration generation

The MySQL server configuration becomes a generated artifact rather than
a tracked file with paths in it. The settings live inside the installer
script, which writes them out with the project directory substituted
in. Inside the script rather than in a template file beside it, because
a downloaded copy has no template beside it.

When an existing configuration is found whose real paths do not resolve
to the current project directory, the installer backs it up,
regenerates it, and says so — comparing resolved paths rather than
strings, so a project directory reachable by more than one route does
not trigger a spurious rewrite.

### Preflight

Before any download or compile, each script verifies everything it will
need and reports the whole picture at once: which requirements are
satisfied, which are missing, what each missing one is needed for, and
the package name to install it under on the common package managers.
Header availability is tested by asking the compiler to preprocess a
one-line file that includes it, so the answer reflects the compiler's
real search path rather than a guess at where headers live.

Network reachability of each download host is part of the preflight,
tested by opening a connection rather than by running a download tool,
so that the answer is still trustworthy on a machine where the download
tool is one of the things found missing.

The three cmake options the current MySQL version ignores are removed,
so that what the script passes and what the build reads are the same
set.

### Parallelism

Job count is derived, not assumed: the smaller of the machine's online
processor count and the number of jobs its total memory can hold at the
per-job memory each build actually needs. An explicit `--jobs` argument
or the existing `THREADS` environment variable overrides the derivation.

### Version selection

All three pin a known-good version. The MySQL installer gains an
explicit opt-in for discovering the newest release, and validates what
it discovers before using it. Version and directory are separate named
arguments that cannot be confused for one another.

### Root password

The installer generates the root password itself rather than leaving the
server open. In order: create the file, restrict its permissions to the
owner alone, then write the password into it — so the secret is never
briefly present in a world-readable file. The password is letters and
digits only, so it survives being pasted into a shell, a connection
string, or a configuration file without quoting. The file lives in the
project root and the installer prints its full path.

### Completion

The installer starts the server itself, applies the password, creates
the four databases the project documents, grants the application user
its privileges from the existing secrets file, and stops the server
again. When the secrets file is absent it completes the server-level
work, reports precisely which steps succeeded and which did not, and
names the file to create.

## Suggested Implementation Steps

1. Write the environment-checking section — directory resolution, tool
   and header verification, host reachability, job-count derivation —
   once, and place an identical copy in each of the three dependency
   scripts. Verify with `diff` that the three copies match.
2. Convert the Boost and ccache builders to argument-derived
   directories, environment checks, and derived job counts.
3. Move the MySQL server settings into the installer and add the
   generation step, replacing the tracked configuration file.
4. Rewrite the MySQL installer's argument handling to named arguments,
   add the missing shell guard, validate the discovered version, remove
   the interactive pause behind an opt-in confirmation flag, and add the
   password and database phases.
5. Correct the start-script name in the closing message, and in
   `scripts/mysql-client`, which points at the same absent name.
6. Ignore the generated password file in git.
7. Remove the two Boost version constants in the compile script that are
   set and never read, and pass the resolved directory through when it
   self-bootstraps ccache.
8. Give install, compile, and update the same `--dir`, scanning it out
   of the arguments before the profile is read rather than in their
   argument parsers, which run far later.

## Related Documents

- issues/149-project-local-ccache-build-from-source.md — why ccache is
  built from source into the project at all
- issues/121-mysql-script-naming-aliases — the start-script name the
  closing message assumes
- issues/completed/105-project-local-database — the original local MySQL
  design
- issues/107-credential-manager-script — the credential store the
  application user's password comes from
- scripts/install — owns per-profile database creation and the
  application user; this issue deliberately does not duplicate that

## Related Decisions

- **Standalone files over a shared library** (2026-09-08). A shared
  helper under `scripts/lib/` was built first and then removed. It was
  the better shape for a repository and the wrong shape for the way
  people actually get these scripts, which is downloading one file. The
  duplicated section is kept byte-identical so drift is detectable.
- **Settings inside the installer, not a template file** (2026-09-08).
  Same reason: a downloaded file has no template beside it.
- **`mysql/conf/my.cnf` stays tracked for now.** It was tracked
  deliberately by issue 105, which marked it "TRACKED - server config"
  so the tuning — buffer pool, port, character set, the
  trigger-creators permission — would be shared while credentials were
  not. The absolute paths came along inside that same file, which is
  the defect. The `.gitignore` rule is in place for machines that do
  not have the file yet; untracking the existing one is left to the
  operator, since it stages a git change.

## Open Questions

- Should `scripts/install`, `scripts/compile`, and `scripts/update` also
  move to argument-derived directories, or does the portability
  requirement stop at the three dependency builders? They currently
  hard-code the path the same way, so a second machine can bootstrap its
  dependencies but not yet build the server.
- `scripts/install` creates the application user with a name and
  password written literally into the script, while `scripts/generate-configs`
  reads the same pair out of `secrets.conf`. Two homes for one
  credential. Should the literal pair in the install script be replaced
  by a read of the secrets file?
- The version pinned here is the one currently installed, 9.6.0. The
  vendor's newest is 26.7.0 — MySQL has moved to a year-based version
  number. Should the pin move up, and if so does anything in the
  project's schema or the AzerothCore client library care?
- `scripts/start-mysql` does not know about the generated root password,
  because it does not need one to start the server. But nothing yet
  reads `mysql-root-password` either. Should `scripts/mysql-client`
  learn to offer a root connection using it?
