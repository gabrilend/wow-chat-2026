# 192 - The econ Profile

## Status
- Created: 2026-10-20
- Phase: 1
- Related: 176 (cc-test: the stock-world profile this one is shaped
  like), 153a (the checklist of places a profile name must resolve),
  136 (canonical profile definitions), 136b (every profile running at
  once), 617o (the buddy pathfinding to be shared), 173 and 173w (the
  custom client, and its queued inputs: the outside route into the
  world), 916 (the LLM chat module)
- Blocked by: 189c (the priority runner, whose undo runs last first:
  econ layers patches on basic's) and 189e (patches that carry their
  own files: Sargobras's Lua placed for basic and econ)
- Priority: Medium

## Origin

The owner, 2026-10-20:

> hi can we create a new profile called "econ" for developing economic
> simulations? We should prototype some behaviors here and possibly use
> them in the buddy-bot design. Also we want to create a world for AI's
> to live in and develop themselves if they so choose. I will walk you
> through how that could be set up.

On who trades:

> we will write them in lua. We will cache decisions for each bot and
> allow them to develop a personality over time. Then, we will route
> between those decisions using a decision model, which is something I
> came up with back in like, 2022 btw and is only now being used at
> scale...

On whether an AI lives inside the server or drives a character from
outside:

> let's build the capability for both. We'll need a system that can
> pathfind for example, and we have something that's a start for that.
> We can re-use the buddy-bot pathfinding for that, and either run it on
> the server or have it supplied through an external program using the
> custom-client.

## Current Behavior

There is no econ profile. Nothing resolves the name `econ`: no source
patch list, no install steps, no config gates, no databases, no Lua
directory, no realm row.

The plumbing (192a) waits: most of it is in files shared by every
profile (the patch lists, the install steps, the config-gate test), and
on 2026-10-20 another agent was working in the repository. The owner:
"just work on files you definitely own."

## Intended Behavior

A seventh profile, `econ`, a world where economies are simulated and
where AIs may live and develop themselves if they choose. What is
learned here can move into the buddy design (617).

### The world (decided 2026-10-20)

- **Stock, like cc-test:** stock AzerothCore with playerbots and the Lua
  engine (mod-ale), nothing else. No ambushes, travellers, custom items,
  or level-cap changes. The economy is what is being studied, so nothing
  else in the world should be pushing on it.
- **No random bots.** The traders are written here, in Lua (below), not
  playerbots' random population, which farms and trades on its own rules
  and would mix its behaviour into the measurements.
- **Shares ports with the others** (auth 4362, world 4462): one realm
  runs at a time on this computer. Every server running at once is 136b,
  for when there are more machines.
- Its own databases (`acore_world_econ`, `acore_characters_econ`,
  `acore_playerbots_econ`) and realm id 7 (the next free row after
  cc-test's 6).

### The traders (decided 2026-10-20)

- Written in Lua, in `src/lua-econ/`.
- **Clans, with playerbots as the clanmates.** The clan system of 617l
  (a character and its companions, with a guild of their own) is reused,
  and Sargobras is there, so a player has an economy to take part in.
  The clanmates are playerbots, not buddies. The owner, 2026-10-20: "We
  should re-use the clan system, and Sargobras can be there as well.
  That way we can have an economy to interact with. But, instead of
  being buddy-bots, the clanmates should be playerbots."
- **Each bot keeps a cache of its own decisions.** Over time the cache
  *is* the bot's personality: two bots that began alike drift apart by
  what happened to each.
- **A decision model routes between the cached decisions** (the
  owner's model, 2022). The cache is a **tree**: branches group
  situations, leaves are decisions.
  - **Down the tree:** at each branch the situation is matched against
    the children, and a child is taken only above a strict confidence
    threshold (the owner's example: 85%).
  - **Back up the tree:** if a branch holds only leaves and none fits,
    the route climbs one tier and asks whether the branch itself suits,
    now at a lenient threshold (example: 50%). Any other path that is
    possible from there is tried in turn. The search keeps going,
    looking for a leaf both distinct enough and close enough to the
    situation. The owner, 2026-10-20: "I'm just making up those numbers
    they could be anything, but the idea is it's more lenient on the
    way back."
  - **Back at the root with nothing found:** the bot hands the situation
    to a **larger model**. The same happens for a situation that is
    especially impactful, or chronically troubling enough that the bot
    sees it as a consistent pattern. **What the larger model decides is
    what gets cached**: it becomes a new leaf, placed in the branch it
    fits best.
  - **After each new leaf, the whole tree is re-read** in the
    background, slowly and at low priority, looking for contradictions
    and for changes that should be made. **New and old decisions are
    weighed alike.** Not favouring the new leaves room for regret; not
    favouring the old allows long-term growth and change.

  The owner, 2026-10-20, verbatim:

  > oh and the decisions that it makes when it encounters something new
  > or especially impactful or chronically concerning that they
  > claritously realize is a consistent pattern, it should use a larger
  > model. The outcomes of which are what we cache.

  > basically the decision model works through a tree. If it reaches a
  > branch with only leaf nodes and none of the leaf nodes really fit, it
  > goes up a tier and evaluates if the branch is suited. For example if
  > it has 85% confidence threshold for normal routing, then on the way
  > back it gets lowered to 50%. I'm just making up those numbers they
  > could be anything, but the idea is it's more lenient on the way back.
  > If a different path would be possible, it checks that one, and it
  > keeps going on this process looking for leaf nodes that are unique
  > enough and aligned enough to the situation or context that they'd be
  > suitable. If it can't find any and it goes back to the root, then it
  > needs to shell out to the larger model and do some processing. Then,
  > once it's created a new result / leaf node, it slots it in the most
  > suitable place and then iterates through the ENTIRE tree
  > asynchronously in the background with low priority, searching for
  > contradictions or changes that should be made. There should be no
  > preference to the new decision, which provides space for regret, and
  > it should have no preference for the old decisions, allowing
  > long-term growth and change.

### Two ways for an AI to live there (decided 2026-10-20: both)

- **Inside the server:** the AI is a bot the server plays; its decisions
  are handed to it (from the Lua decision model, or from outside through
  a channel to be designed).
- **From outside, as a player:** an external program drives a character
  through the custom client (173), the way a person would.
- Both need the same abilities in the world, first of all **pathfinding**.
  The buddy pathfinding (617o) is reused: run on the server for the
  inside route, or supplied to the external program through the custom
  client for the outside route.

## Suggested Implementation Steps

Planned sub-issues (to be written as each is reached):

| ID   | Name                         | Dependencies | Description |
|------|------------------------------|--------------|-------------|
| 192a | econ-profile-plumbing        | None         | resolve `econ` everywhere a profile name resolves (153a's list, as cc-test did in 176) |
| 192b | decision-cache               | 192a         | each bot's tree of decisions, the record that becomes its personality |
| 192c | decision-model-routing       | 192b         | the search down at strict confidence and up at lenient, the hand-off to the larger model, and the background re-read |
| 192d | shared-pathfinding           | 192a         | the buddy pathfinding available to econ bots on the server, and to external programs through the custom client |
| 192e | a-world-for-ais              | 192c, 192d   | the walkthrough the owner will give: how AIs live and develop there |

`192a (foundation) → 192b → 192c → 192e`, and `192a → 192d → 192e`
(192d alongside 192b and 192c).

For 192a, the steps cc-test took:

1. Add `econ` to the profile list (`scripts/profiles`): source tree
   `source-beta`, the same pinned commit as basic and cc-test (the shared
   tree must pin identically), modules mod-playerbots and mod-ale.
2. Its source patch list and install steps in `patches/patches.sh`,
   starting from cc-test's minus the buddy module and its patches (open
   question 2).
3. Gate the config patches: database connections, paths, ports, realm id
   7 (C019 and `scripts/set-active-realm`, a pair), no random bots
   (C023), Warden left at stock.
4. An empty `src/lua-econ/` with a README (E001 stops if a profile has
   none).
5. `scripts/test-profile-config-gates` learns econ's expected values;
   `scripts/test-compile-module-set` its module set.
6. `docs/profiles/econ.md`, the table of contents, CLAUDE.md's profile
   list, 136's canonical list.
7. The owner runs the first `scripts/install` with `.profile` set to
   `econ`.

## Open Questions

1. (Partly answered 2026-10-20) **The decision model.** It is a tree
   searched down at a strict confidence and back up at a lenient one,
   handing what it can't place to a larger model whose answers become
   leaves (Intended Behavior, above). Still open:
   - **What "confidence" measures**: how a situation is compared with a
     branch or a leaf, and what a situation is made of (prices, purse,
     bags, who is near, what happened last). The owner, 2026-10-20: "um,
     I'm not really sure. Let's keep working on the problem, and then we
     can better grasp better perspectives on difficult problems like
     that." So it is answered by building: 192b's first trader shows
     what a situation holds, and this is asked again from there.
   - **"Distinct enough and close enough"**: the second test a leaf must
     pass. What does distinct guard against?
   - **What the background re-read does** with a contradiction it
     finds: merge the two leaves, ask the larger model, or keep both
     and record the conflict.
   - **Does a leaf ever leave the tree?**
   - **Which larger model**, and where it runs (916's LLM chat module
     already talks to one).
2. (Answered 2026-10-20) **Buddies or plain bots:** the clan system
   and Sargobras, with playerbots as clanmates. (Answered 2026-10-20)
   **How:** econ takes the Sargobras, clan and buddy patches as they
   are, and econ's own patches are layered on top later, changing or
   undoing parts of them. The owner: "first apply the Sargobras and such
   patches to the econ profile in addition to the beta profile, then
   later on when we're doing the econ specific patches or whatever we'll
   apply additional patches that might unpatch part of the Sargobras or
   clan or buddy-bot functionality, or might change some of it, etc...
   Again it should be idempotent and reversible so that we can run it
   backwards and it'll first undo the econ patches, then later when it's
   undoing Sargobras et al then it'll handle it correctly because we set
   it back to it's default state."
   - **Reverts in reverse:** the patch system's work, in 189. Done
     2026-10-20 by the session building 189: undo now runs last first
     in both stages (`scripts/test-patch-undo-order`). econ's layered
     patches still wait for 189c, the priority runner they will be
     listed in.
   - (Answered 2026-10-20: "probably basic.") The Sargobras, clan and
     buddy patches are basic's (B036 to B052, E040 to E045, E050, E052);
     econ takes them from basic's lists.
   - (Answered 2026-10-20) **Sargobras's Lua travels with its patch.**
     His scripts are in `src/lua-basic/` today (`sargobras.lua` and the
     files it uses), and E001 links one Lua folder per profile. The
     owner: "don't link, copy during compilation. Except, don't copy,
     include them with the patch file somehow, then copy them into both
     basic's directory and econs. This is a pattern we should examine
     for other applications in our patches." So the scripts move out of
     `src/lua-basic/` into a home owned by one patch, which copies them
     into each listed profile's Lua folder when applied and removes them
     when reverted. Moving files out of `src/lua-basic/` changes basic,
     so it waits until no other agent is working on basic.
   - (Answered 2026-10-20) **Where the copies land:** the installed Lua
     folders (`installed-files-<profile>/bin/lua_scripts/custom/`). The
     owner: "the template is in git, the build files are not." The
     patch's own copy is the only one committed.
   - **The pattern, applied to two more** (owner, 2026-10-20: "sure we
     can do those two I guess."): a patch that carries its own files
     (Lua, SQL, data) and places them for each profile that lists it,
     instead of the files sitting in one profile's folder and the others
     reaching in. The two: the buddy SQL that cc-test reads from basic's
     sources (`_buddy_sql_src` in `patches/E-patches.sh`), and the buddy
     module (B036 copies `modules/mod-buddies` in). These are patch
     system work and belong with 189 or their own issue when started.
3. **What is traded, and through what?** The auction house, trades
   between bots, vendors, or a market of our own design.
4. **The walkthrough of the AI world** (192e): what "develop themselves
   if they so choose" asks of the world.
