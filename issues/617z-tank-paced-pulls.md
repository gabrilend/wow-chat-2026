# 617z - Tank-Paced Pulls: "go faster", "slow down"

## Status
- Created: 2026-10-12
- Phase: 6
- Parent: 617 (buddy bots)
- Related: 617y (spoken orders: the hearing, the channels), 617c3 (the
  dungeon draw: who is tank and healer), 617t (dungeon stand-ins: a tank
  may be a stand-in), 617c4 (dungeons)
- Priority: Medium
- State: in progress (the pace's decision core built 2026-10-31; a healer
  buddy's own "slow down", a player's pull picked up, harmless packs and
  the waiting line added 2026-11-06; the server's part not yet)

## Origin

Verbatim, 2026-10-12:

> can we make commands for the buddy-bots "go faster" and "slow down" for
> when we're in dungeons, and the tank is pulling, and the healer's mana
> percentage is taken into account? So, like "do I pull or not" is a
> question of "do I think, based on how well and fast we've been doing,
> could the healer heal me through that monster fight?" if so, then the
> tank moves forward. If not, then he hangs back. The healer can say "go
> faster" because they know they have health potions and such that the
> tank doesn't know about. So, they can do, but only if the monsters have
> a chance of harming them. Otherwise, they refuse to fight.

Answer, 2026-10-12 (verbatim), on whether a healer buddy may say it too:

> healer buddies can say it to the tank if the tank is doing too dangerous
> and they can't keep up. They know their character better, so the tank
> should default to going faster. if the healer asks to slow down though
> he will for a time, until he builds up confidence again which happens
> over time. she should whisper it to him.

## Current Behavior

**The pace's decision core, built 2026-10-31** (`roam/buddy_pace_core.h`,
plain arithmetic, checked by `scripts/test-buddy-pace`, 24 checks, a quick
test; step 6): a pack weighs its normals plus three per elite, 10% more
per level above the group; the tank remembers its last five fights (the
healer's mana spent and the pack's weight) and expects a pack to cost the
record's mana per weight times its weight; it pulls when the healer's
mana less that cost keeps a reserve that grows as its confidence falls
(up to 40% for a fully nervous tank). Confidence starts at 0.9; "wait",
"slow down", "go slower" take 0.3 off (never below 0.1) and it regains
0.05 a minute back to 0.9; a healer's "oom", "out of mana" or "mana"
stops it until "ready"; a fight the healer came out of above the reserve
adds 0.05 (the owner's "go faster" by pulling more). It clears 10 to 30
yards either side of its route by confidence. Every number is the
agent's call, to be judged in game.

**Added 2026-11-06 (offline, on a branch for review)**, in the same core
and its test (now 48 checks; 19 of 19 deliberately broken versions of
the additions caught):
- **A player's pull, picked up** (`PlayerPulled`): the tank says "Fine,
  I'll take them." (a little put out), remembers the fight, and if the
  healer came out of it above the reserve, its confidence rises at once
  to at least what it would have needed to pull that pack itself at the
  healer's mana as it began (`NeededFor`): "they'll adjust to the new
  speed and pull accordingly". A pull that drained the healer teaches no
  new speed.
- **What it says when it holds** (`WaitLine`, question 6): "Waiting for
  ready." after an "oom", "Waiting for mana." when short.
- **Harmless packs** (`GreyLevel`, `PackPlan`, question 5): a pack at or
  below the tank's grey level (the game's own: 13 for a level-20 tank)
  is walked past, unless it is hostile, when it is swept up on the way by
  area attacks without asking the healer ("If they are hostile they are
  picked up and cleared by AoE on the way").
- **A healer buddy's own "slow down"** (`HealerVoice`): whispered to the
  tank when two of its last three fights ended with its mana under 25%,
  or a fight where the group's health fell faster than it could heal; then
  it keeps quiet for three fights, which aren't counted, and starts fresh.
  The tank hears it as any "slow down".
Not built: the route to the next boss (the dungeon's boss order and its
forks), hearing the words in group chat, the walk ahead and the pull, and
the server feeding the pieces above (the healer's mana at each fight's
start and end, whether the group fell behind, the pack's levels and
hostility).

Before: nothing paced a dungeon but the player. Inside a dungeon each buddy follows
its owner (the bot module's own following), and when the owner comes
within a little more than a monster's notice range, the owner's buddies
not yet fighting go at the nearest hostile monster the owner can see
(`AggroPass`, `patches/B036-mod-buddies/mod-buddies/src/buddies_roam_strategy.cpp`). So
the player is always the one who pulls, by walking forward; no buddy
decides to move ahead, and no buddy looks at anyone's mana.

## Intended Behavior

**The tank leads.** In a dungeon, the group's tank (a buddy or a stand-in)
walks ahead to the next pack and pulls it, instead of the group drifting
in behind the player.

**Before each pull the tank asks one question:** could the healer carry
me through this fight? It weighs:
- the healer's mana, as a share of the full bar (a whole number, 0-100);
- how the group has been doing: how long recent fights took, and how much
  mana and health they cost, kept as a short running record;
- how hard the next pack looks: how many monsters, their levels and
  ranks (normal, elite).

Yes: it moves forward and pulls. No: it hangs back and waits (the healer
drinking, mana coming back) and asks again.

**The tank's confidence**, one number per tank: how much risk it
accepts, so the same mana and the same pack can give a different answer.
It starts high: the tank defaults to going faster, because the healer
knows their own character better (potions in their bags, cooldowns) and
will say so when it's too much.

**"slow down"**, whispered by the healer to the tank: the tank's
confidence drops and it pulls more carefully for a time, then its
confidence builds back up on its own, a little at a time, toward the
fast default.

**"go faster"**, whispered by the healer: the confidence goes back up at
once, without waiting for it to rebuild.

**The healer may be a player or a buddy.** A player whispers the words
themselves. A healer buddy says "slow down" when it can't keep up: when
fights leave its mana too low too often, or the group's health falls
faster than it can heal. It whispers it to the tank the same way.

**Fights worth having:** the tank only pulls monsters that could hurt the
group; anything that can't, it refuses to fight (open question 5 asks
what "could hurt" means and what happens to the harmless ones instead).

## Suggested Implementation Steps

1. Answer the open questions.
2. The running record: per group, the last few fights' length and their
   cost in the healer's mana and the group's health.
3. The guess for the next pack: its expected cost from the record, scaled
   by the pack's size, levels and ranks; compared with the healer's mana
   now and a risk setting.
4. The tank's confidence: one number per tank, starting at the fast
   end, lowered by a whispered "slow down", rising back over time, raised
   at once by "go faster" (whispers heard as 617y's are). A healer buddy's
   own judgment of when to whisper "slow down".
5. The tank's walk ahead: to the next pack's edge, then the pull (the
   class's own pull from range, or walking into range). Waiting in place
   when the answer is no.
6. A plain-numbers test of the decision, as `buddies_stand_ins_pick.h` is
   tested: given mana, record, pack and risk, pull or wait.
7. In game: Ragefire Chasm with Birth healing (617t2's scene).

## Open Questions

Gathered 2026-10-28 into 617's own list (question 21), merged with the
same questions from other sub-issues; answers are written back here.

- **Answered 2026-10-28** (617's question 21, the rest):
  - **The route**: the "skeletonized" pathfinding is the floor skeleton
    built for the exploration comparison page (`docs/HTML/exploration-compare.html`,
    `scripts/build-exploration-compare-page`: the floor shaved from its
    edges to one square wide, Zhang and Suen's thinning, then a graph of
    knots (ends and forks) and the runs between). Each dungeon's skeleton
    is its map of ways; at a fork toward the next boss the tank takes one
    at random.
  - **Going faster**: no word for it. "If the DPS wants to go faster, they
    should just pull more mobs. The tank will pick them up and be a little
    upset. They should sense how well they're doing and if they can handle
    it, they'll adjust to the new speed and pull accordingly." The tank
    picks up what a player pulls (saying it's a little put out), and
    learns the group's pace from how such fights go.
  - **Harmless packs**: "If they are hostile they are picked up and
    cleared by AoE on the way to the next patches."
  - Slowing: any player's "wait", "go slower" and the like (above); a
    healer's "ready", "oom", "mana".

- **Added 2026-10-28** (617's question 21): "Also any player should be able
  to say wait and it slows down the tank. Or go slower. Or similar." Any
  player in the group may slow the tank: "wait", "go slower", "slow down"
  and words like them; a healer's "oom" and "mana" do the same.

- **Answered 2026-10-28** (617's question 21, the route): "We want to fight
  our way to each boss in the correct order - make sure if the boss isn't
  available or whatever that we target the correct one, for example the
  murloc in wailing caverns. Also, if there are multiple paths we could
  take, pick one at random. We can use the "skeletonized" path finding
  mechanism for that." The tank heads for the bosses in the dungeon's
  order, fighting what is in the way; a boss that isn't there yet (Mutanus
  the Devourer, the murloc who appears only when the escort ends) is
  handled as the dungeon intends; where several ways lead on, one is taken
  at random. The "skeletonized" pathfinding: asked back (the nearest thing
  built is 617e6's map of rooms and the passages between them).

- **Answered 2026-10-28** (617's question 21, in part): "The healers should
  be able to say ready and oom or out of mana or mana and the tank slows
  down or stops. We discussed this before." So a healer's words set the
  pace: "ready" lets the tank on; "oom", "out of mana" or "mana" slows or
  stops it; with the 2026-10-12 design above (the tank's own judgement of
  the healer's mana and the pack).

1. (Answered 2026-10-12: a player or a healer buddy, whispered to the
   tank.) When the player is the healer (Birth is a shaman), does the
   tank lead even though its owner is in the group?
2. (Answered 2026-10-12: "slow down" lasts for a time, and confidence
   builds back up over time.) How long to rebuild, from a "slow down" to
   full speed: a few pulls, a few minutes? Does a second "slow down"
   before it has rebuilt drop it further?
3. The tank walking ahead: does it need a route through each dungeon
   (packs in order, as a player learns them), or does it take the nearest
   pack it hasn't fought yet? **Answered 2026-10-30** (the owner, word
   for word): "make a route to the next boss. They sometimes can be
   completed in varying orders, but it's usually a T-intersection or
   similar, only rare bosses like VoA can have them fought in any order.
   / make a route to the next boss, and then fight anything along the way
   that might aggro onto allies. We can clear a bit more or less,
   confident tanks clear more, nervous or scared tanks try to clear the
   bare minimum and skirt the edges of the arenas and dungeons and such."
   The tank routes to the next boss (the dungeon's boss order, branching
   at its forks; any order only where a dungeon allows it, as Vault of
   Archavon), fighting the packs on the way that could reach the group.
   How much more it clears follows its confidence (the solo record and
   "safe enough", 623): a confident tank clears wider, a nervous one the
   bare minimum, keeping to the edges of rooms.
4. A player who isn't the healer (playing damage): can they also say "go
   faster", or only the healer? Asked 2026-10-30 with the agent's call,
   anyone in the group; quoted back without objection, taken as agreed,
   for the owner to correct.
5. "only if the monsters have a chance of harming them. Otherwise, they
   refuse to fight": a monster too low (grey to the tank) is skipped and
   walked past? Or the tank refuses a "go faster" order when the next
   pack is harmless, because faster gains nothing there? Asked again
   2026-10-30 with the agent's call, walked past; quoted back without
   objection, taken as agreed, for the owner to correct.
6. When the answer is "wait", does the tank say so ("Waiting for mana."),
   as "My bags are full." is said (617y)? **Answered 2026-10-30:**
   "sure."

## Decisions (2026-11-06)

The agent's calls while adding to the core, for the owner to curate; each
is one field of `BuddyPace::Settings` or one line of the core:
- **Learning a player's speed**: a player's pull the healer came out of
  well sets the tank's confidence to at least what that pull needed; it
  never lowers it.
- **The put-out line**: "Fine, I'll take them."
- **Harmless** means grey to the tank, by the game's own rule; a grey pack
  that will attack is swept up, one that won't is walked past.
- **When a healer buddy speaks up**: two of three fights ending under 25%
  mana, or falling behind the group's damage; then three fights of quiet
  ("if the healer asks to slow down though he will for a time, until he
  builds up confidence again").
