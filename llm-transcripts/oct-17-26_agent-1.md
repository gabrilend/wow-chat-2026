# Conversation Summary: 90bf80e4-2922-4058-918c-551568e85c2a

Generated on: 2026-10-17 15:51:19
Models: claude-opus-5-5

## Contents

1. 2026-10-17 15:16, after Request 1 - I'm listing what isn't planned for AI
   generation yet, so the game feels as distinct from WoW as Warhammer or
   Wildstar did. Next: you answer the three questions, starting with what makes
   a baked NPC go back to being a full player character.

--------------------------------------------------------------------------------

### User Request 1

Hi, can you make me a list of the things that we don't currently have plans for
AI generating? I'm thinking landscape, quests, dialogue, and unit types (all
characters should be able to be randomized. We can do this by making NPCs into
players behind the scenes, and "baking" their presets into NPCs that can be
spawned quickly. That way, it's relatively easy to process them all, and also we
can easily change them by simply spawning a player type character with the newly
modified gear and such, and then baking them in the background if we expect to
have them long-term. Otherwise, accept the performance hit on that player
character.) Also spell effects. I think we have something for UI elements? What
else can you think of? Our goal is to transition World of Warcraft to something
that is as distinct to World of Warcraft as any other MMO of the era, such as
Warhammer Online or Wildstar. Unfortunately, there are so few of them still
running... We will have to use our best judgement based on what records we can
find on the internet and such.

--------------------------------------------------------------------------------

### Assistant Response 1

> Still reading what's already planned before I write the list.

No current plan covers AI generation of landscape, quests, quest text and
dialogue, creature models, spell effects, sound, or about a dozen other things.
Here's what is planned, then what isn't, ordered from most to least valuable for
making it feel like a different game.

## Already planned (so you can rule these out)

- **Gear appearance.** The gear gallery pipeline goes from a written design to
  concept art to 3D model to texture, borrows a skeleton, and adds generated
  animations. The design side and the voting page are running. The image-to-3D
  stages are written but untested, because the image generator's install isn't
  finished yet.
- **Interface pieces.** The planned interface-piece image generator draws
  scrollbars, close buttons, frames, tabs, tooltips and so on from a short
  description. Whole windows can be built from those descriptions. Not built
  yet.
- **Bot speech.** The planned LLM chat module has bots talk in character for
  their race, class and spec, and also adjusts their fighting priorities.
  Separately, a planned feature lets you give the buddies orders in plain text.
- **Lore.** One existing idea generates shepherd stories, narrator lines and
  rumors. It's written as an idea, not an implementation plan.
- **Quests, partly.** The class-unlock quests are being redone as a prototype
  for "dynamic quests": the quest-giver arrives as one of your travelers, and
  the quest's monsters join your ambush spawns. The roadmap also lists
  "procedural quest generation" with no plan behind it.
- **Creature choice.** Ambushes would pick monsters by meaning, comparing name
  embeddings instead of picking at random. This selects existing creatures; it
  doesn't create new ones.

## Not planned

1. **Style rules every generator reads.** These would be the palette, silhouette
   rules, how ornate armor is versus how worn, and how the light falls.
   Warhammer looked like Warhammer and Wildstar looked like Wildstar because one
   art direction ran through everything. Without a shared rulebook, each
   generator drifts toward "generic fantasy". I'd build this before any
   generator below.
2. **Characters and creature types.** This is your bake-to-NPC idea, covered
   under the next heading.
3. **Spell effects.** There's no plan for generating them. The particle system
   in our own client already reads and runs the original emitters, so generated
   emitter settings plus generated sprite sheets would slot into it.
4. **Landscape.** Our client already reads and paints the original's ground
   files: heights, holes, up to four ground textures per chunk, blend maps and
   color tints. A generator would write that same tile format, with height and
   texture layers. After that come doodads (rocks, trees, props) and the sky and
   zone light, which are also already read.
5. **Quests as content.** This means objectives, places and monster choices,
   built on the dynamic-quest prototype.
6. **Quest text and NPC dialogue.** The chat module covers bots talking. It
   doesn't cover the gossip text, quest text and books that the world's
   creatures carry.
7. **Creature models and their animations.** The gear pipeline makes items and
   animations for gear. Generating whole new monsters on a borrowed skeleton
   isn't planned.
8. **Buildings and dungeon interiors.** These are large "world model" files with
   rooms and portals between them. This is the hardest format of all.
9. **Icons.** There are thousands of spell and item icons. The interface-piece
   generator could be stretched to cover them, but no plan says so.
10. **Sound:** music, ambient loops, spell sounds, creature voices.
11. **Names and the place map:** zone names, creature names, item names, faction
    names.
12. **Item stats and loot tables.** Gear appearance is planned, but item power
    and drops aren't.
13. **Boss encounters:** fight scripts, ability rotations and telegraphed danger
    zones on the ground (Wildstar's signature).
14. **Abilities and talent trees.** A custom spell and class system exists, but
    nothing generates its content.
15. **Loading screens, the login scene and cinematics.**
16. **Public events.** Warhammer's public quests were zone-wide goals that
    anyone nearby could join, in stages. Nothing is planned for them, and they
    would fit the empty-world, ambush design.

## Your bake-to-NPC idea

Some of this is already built or planned:
- **The stand-in maker** creates player characters run by the bot system, with a
  race, class and gear chosen for their role. It's written but not tried in game
  yet.
- **Dressing a creature from a gear record** is planned. The record holds a race
  and a list of equipped items, and the creature is shown as a player of that
  race wearing those items, the way Sargobras is dressed.

That second piece is the "bake" step. One way to do it at runtime is the packet
the client uses for the Mage's Mirror Image. In it, the server tells every
nearby client "draw this creature as a player of race X, skin Y, face Z, wearing
items A to K". That costs one packet per viewer and needs no client patch. The
other way, a permanent preset, is a row in a client-side file, and every
player's client would then need an updated file.

Two technical problems I can see:
- **Cost.** A player-type character costs far more than a creature. It has a
  full bot "brain" that ticks continuously, about 19 equipment slots plus bags,
  database rows, and talent and spell state. A creature is a template number
  plus a position. "Accept the performance hit" works for a few dozen. With
  hundreds, the server's update loop starts falling behind.
- **Only humanoids can bake.** The dress-as-a-player trick only works for
  playable race bodies. Wolves, dragons and the generated creature models from
  item 7 can't be baked this way, so "all characters randomized" needs a second
  path for non-humanoid creatures.

## Questions back

1. When a baked NPC needs to change, say it picks up a new sword mid-life, what
   decides whether it goes back to being a full player character or just gets
   its gear record edited? Is a gear record enough to make one, or does it also
   need talents and spells?
2. Of the Warhammer and Wildstar features you remember, which one felt most "not
   WoW" to you? Was it the art, the combat, or a system like public quests or
   Wildstar's paths?
3. Should generated content be reviewed by people before it goes live? The lore
   idea currently says "requires no human review", and that's a big choice for
   landscape and quests.

These three questions are open, so I'm counting the list as in progress until
we've gone through them. I haven't written any files; if you want this saved as
a document or issue files, say which.

--------------------------------------------------------------------------------

### User Request 2

can we make issue files to make it so that buddy-bots have an NPC profile baked
for them from their sql stats and use that instead of their playermodel when
wandering around? And if you right click on one, you can talk to them. Left
click selects to heal or buff or whatever. It'll stop and stand still, and you
can do things to it like say "hey take this thing I found" or "can you trade to
me any healing potions" and it'll use the actual trade window to make it seem
like a player. The player is actually there, and if they're in combat they'll
stop talking to you. So it's definitely a "do while nothings doing" type of
thing.



<pasted_content id="ee2b">
> 1. Style rules every generator reads. These would be the palette, silhouette
> rules, how ornate armor is versus
>      how worn, and how the light falls. Warhammer looked like Warhammer and Wildstar looked like Wildstar
>      because one art direction ran through everything. Without a shared rulebook, each generator drifts toward
>      "generic fantasy". I'd build this before any generator below.
</pasted_content id="ee2b">


players will be able to provide their own and modify it as they please. If the
same simulation is running in the background, they can render it however they'd
like and it'll display the same information.

This, by the way, is the core of the soren-ds UI system.

can you add an issue file in that project to build infrastructure for as such?

also can you make buddy-bot behavior that's for bots in battlegrounds? They
should try and spread out, and always fight for territory to the north. Or
rather, on the (right angle to equator) axis displaced by orientation. So for
example in Alterac Valley, the Alliance would push south, while the Horde pushes
north. And the buddy-bots create a line shaped like a "bar chart" type thing,
where when an NPC was spawned it took a skeleton path system road toward the
front and when it was within a certain distance (maybe 3-6 steps until facing
the foe) they'd pick the one with the fewest allies in it. When ranged units
were struck, they'd put a melee character between themselves and their foe,
close enough that they can still use ranged attacks on them... but ideally with
enough distance to defeat their foe. anyway if there's a differential of like, 3
in one bar-chart section to another, then 2 allies will come to assist with
greater need having lesser priority. This will create moments where units are
encircled, and they will fight to the last. Melee units don't run, they back up
and recede when need is [great/grand]. but only backsteps, meaning they go slow.

some places aren't north/south like Arathi Basin isn't I think for example so
for that one we should make a determinant axis for each "border" between one or
more objective. This can provide a more granular battlefield terrain, for
example in Alterac Valley the various towers and graveyards are objectives to
fight over. So combat tends to prioritize that. But the stand-ins have to fight
for every inch of ground, so we don't get surround. Sometimes some break
through, but they need to heal and recover so they are often contested. But they
won't be chased too far, the frontline is more important.

at each road Y intersection, the NPC takes a direction. They choose through a
shuffled random pick, meaning, deck of cards shuffled without replacement. In
this way, we don't have to do random number calculations, we can just flip a
switch back and forth everytime they use it for each NPC. And we can save them
up and batch them for calls to the database if we want, if we think that'll make
it easier to send them along.

--------------------------------------------------------------------------------

### User Request 3

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

### Assistant Response 3

> Checking existing related issues before writing new ones.

> Reading soren-ds's display, compositor, and app docs to find where the "same
> simulation, your own renderer" infrastructure fits.

> The buddy NPC issue files are written. Now the battleground front lines.

> The battleground files are written. Last one is the soren-ds issue.

> The wow-chat files pass the validator. For soren-ds, I need to add the
> matching link lines to the neighbouring issues.

I wrote 11 issue files: four parent issues in the game project with seven
sub-issues between them, and one in soren-ds. All pass the issue checker.
Nothing is committed yet, because your rule is to commit when an issue is
completed. Say so if you want these committed now as plans.

**Buddies as baked NPCs** (a parent and four parts)
- **The bake:** a tool reads each buddy's look and worn gear from the characters
  database. It writes a creature of the buddy's own, plus a dressing entry so
  the creature is drawn as a player of its race wearing those items. That's the
  same dress-up trick already written for Sargobras. It rebakes when the gear
  changes, in batches.
- **The swap:** while a buddy roams with nothing to do, the creature walks in
  its place. Combat, a group, an errand or a battleground brings the player body
  back.
- **Right-click to talk:** the creature stops, faces you, and offers choices
  like "take this thing I found" and "can you trade me any healing potions". The
  item choices open the real trade window from the buddy's side. Combat closes
  the conversation and cancels the trade. I checked the server's trade code:
  before a trade opens it only checks distance (about 11 yards), not whether the
  other player is visible. So a hidden buddy standing at its creature can trade.
  One thing to check in game is whether the window shows its name.
- **Left-click to select:** heals and buffs cast on the creature reach the
  buddy.

**Battleground fronts** (a parent and four parts)
- **Axes and borders:** each battleground pushes along the map's north–south
  line, turned by its own heading. Each border between neighbouring objectives
  also gets its own axis.
- **Road forks by deck:** each bot holds its own shuffled deck at each fork;
  with two branches, it's a switch flipped each time. The decks are written to
  the database in one batch at the match's end.
- **The bar-chart line:** a bot picks the section with the fewest allies when
  it's 3–6 steps from the foe. A gap of 3 sends 2 helpers, breakthroughs stop
  to heal, and no long chases.
- **Shelter and backsteps:** a struck ranged bot puts a melee ally between
  itself and its foe. Melee bots only give ground by slow backsteps.

**soren-ds: "looks"**
Every app is split into its state and a look the user supplies:
- **The state** is a fixed list of named, typed fields the app writes and never
  draws from.
- **A look** is an ordinary program the user writes, reading those fields and
  drawing them, plus a style-rules file.
- **Showing everything:** the loader refuses a look that leaves out a field
  marked must-show, and names the missing fields.
- **Swapping and sharing:** looks can be swapped while the app runs without
  losing state. Two looks, or two devices, can draw the same state at once.

I added the matching link lines to seven existing soren-ds issues. Those are the
only lines changed there.

The files hold 23 open questions. These three decide the most:

1. While the creature wanders, is the buddy still logged in and hidden beside
   it, or logged out? Hidden is what "the player is actually there" sounds like,
   but it only saves drawing. Logged out saves the server's real cost, the bot's
   thinking and the player update, but every conversation or heal waits a second
   or two while the buddy logs in.
2. "Greater need having lesser priority": when two sections both need help,
   should the more desperate section get help last? Read literally, that's what
   makes the encirclements you described.
3. "A skeleton path system road": did you mean the bot module's hand-placed
   roads, a centre line traced through the walkable ground, or roads a game
   master records by walking them?

--------------------------------------------------------------------------------

