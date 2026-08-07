# todo-file asides (preserved)

The project root carried five loose note files — `todo`, `todo-urgent`,
`new-issue`, `new-issue-2`, and `new-issue-please-sort`. On 2026-08-07
their contents were sorted into issue files and the originals moved to
`issues/completed/archived/`, where they sit unchanged.

So this file is not the only surviving copy — the originals are intact
one directory over. What this file adds is the map of where each piece
went, and a place for the writing that was neither a feature request nor
a bug report: philosophy, a version-scheme sketch, a line of poetry, a
build error caught mid-thought. Those are reproduced below in the order
they were written, so the thinking reads as a whole rather than as
fragments scattered across six issue files.

Where each piece landed:

| Source file | Content | Landed in |
|---|---|---|
| `todo` | CLAUDE.md ↔ concept-catalog deduplication | 110 (reopened, second pass) |
| `todo` | Unlock quests as dynamic-questing prototype | 412 |
| `todo-urgent` | fg-sora-cluster | 918 |
| `todo-urgent` | alpha/beta/release version semantics | 152 |
| `todo-urgent` | development philosophy, "feldowinn" | here, and 918 |
| `new-issue` | Mage equipment invisible with "?" icon | 148v |
| `new-issue-2` | Mage has no spells at level 20 | 148w |
| `new-issue-please-sort` | vanilla → basic, release → expert | 152 |

---

## From `todo-urgent` (2026-04-07)

The whole file, verbatim. The first paragraph became issue 918. The
version-scheme paragraph became a section of issue 152. The rest is
below because it belongs to itself.

> fg-sora-cluster each one runs a bot that's constantly ollama generating
> thoughts. I only
> have computers for three, but they'd follow beside me. Each one would be
> configured to
> look like me,
> talk like me,
> but be beside me.
>
> some of them you could tell "two truths and a lie" and they'd coordinate with
> one
> another. supplying each of their thoughts to each of their contexts, with
> slightly
> different motions to next be applied upon next. see wow-chat development
> philosophy:
>
> ```
> [ 66%] Built target scripts
> make: *** [Makefile:136: all] Error 2
>
> [ 66%] Built target scripts
> make: *** [Makefile:136: all] Error 2
> <LeftMouse>
> ```
>
> here's the new version. It's not ready yet, check back next weekend. 1.0 won't
> have everything... is beta now (technically alpha but I didn't want to use too
> many branches)_/'-> alpha meaning, still adding features, beta means testing,
> then development cycle for each 1 digit increment. decimal point digits are for
> patches. each development cycle has an alpha, beta, but no digit increments -
> just, alpha, beta, then release as-is.
>
> alpha is probably about 80% done, with lots of room left for sequels. beta
> doesn't have too much to do, just pulling things together. The faster we do
> beta, the better off release will be, which is why we document bug-fixes in
> alpha and combine them into a meta-compendium that fully describes the
> operations of the system. Can build any system this way. Source code is the
> build artifact of LLM back-and-forth with user dialogue. Specifically, the
> artifacts created from that process are used to create the artifacts of the
> system - LLM transcripts compiles issue files which compile source code which
> becomes machine code binary which becomes a useful interaction or enjoyable
> experience which is itself a useful interaction. the core kernel of machinery
> is that it is designed for an action - it will do what that action
> compel-design-guides.
>
> -- continue original from "see wow-chat development philosophy":
>
> feldowinn, chorus of angels

### The compilation chain

The middle paragraph is the project's own account of how it is built,
and it is worth pulling out because it is the reason the issue files are
written the way they are:

> LLM transcripts compiles issue files which compile source code which
> becomes machine code binary which becomes a useful interaction or
> enjoyable experience which is itself a useful interaction.

Each stage is the build artifact of the one before it. The transcripts in
`llm-transcripts/` are the source; the issue files are compiled from
them; the source code is compiled from the issue files; the binary from
the source. That is why issues have to be comprehensive enough to
reconstruct the code, and why the transcripts get bundled into every
commit — you do not throw away the source of a build artifact.

It is also why bug fixes get documented and combined "into a
meta-compendium that fully describes the operations of the system."
The compendium is the thing being built. The server is what falls out
of it.

---

## From `todo` (2026-04-02)

The whole file, verbatim. Both halves became issues — the first became
110's second pass, the second became 412.

> Okay great... Now, can you look at the CLAUDE.md file and the
> concept-catalogue.md file in docs/ and remove
> everything from the CLAUDE.md except things that aren't in the
> concept-catalogue? we're including the
> concept catalogue, so it doesn't make sense to include concepts twice.
>
> Also, I changed my mind for the unlock quests. Can we make them a prototype for
> the upcoming dynamic questing system, in phase 4? For now, we can let them be a
> prototype. How it'd work is when they're the right level (and every level after
> that, until they learn the spell) the NPC with the quest will spawn as one of
> their travellers. Then, once they have the quest, the monsters for that quest
> will spawn amongst their ambush-queues - for every time it's regenerated,
> exactly one of the monsters will take the place of one other monster. If the
> player has two such quests, then two monsters will be replaced, one of each
> type per queue. Then, once the quest is complete (and only then) the
> quest-giver will respawn (unless they're already in the traveller banks, in
> which case they can spawn normally from that too. If a quest doesn't need
> monsters but instead needs other things, like items or whatever, then those
> will be forcefully added to the loot tables of 1 of the monsters in the ambush
> queue, and when being looted they will always go to that player, even if
> another player fully tags and kills the monster,

The sentence ends without a closing period. It is kept that way.
