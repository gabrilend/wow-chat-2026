# 718e - The Fall into the Chapel, the Rise, and the Wisps That Lead Out

## Status
- Created: 2026-10-22
- Phase: 7
- Parent: 718 (death knight sacrifice and open Acherus; the skip's fall and
  rise)
- Related: 718d (talents), 718f (buddies' food), 155z10 (drops by monster
  rank: the west path's "extra rewards"), 617a3 (buddy creation, where a
  buddy first appears), B041 (things only one player can see or select),
  617e4 (town circles: a measured-map tool of the same kind)
- Priority: Medium
- State: planned; open questions first
- First profile: basic

## Origin

The owner, 2026-10-22, in order (the plan changed as it was talked
through; the last word is the plan).

After the first full skip with Gabrubre: "we should change where you get
teleported to. Right now you are right underneath Acherus, but...
there's no monsters to fight. [...] Also, can you make sure that your
buddy-bot spawns within ~20 yards in front of the player? And the player
should face Sargobras. And Sargobras should face the player. Your
buddy-bot should also face the player. But they're somewhere behind
Sargobras, so that you don't have to move your camera to see them."

Then the wisps: "let's have a series of signposts in the form of blue
ethereal whisps that casually appear all throughout the zone and path
their way through to one of it's two exits. [...] there should be about
30 wisps spawned for each half of the DK starting area, and they should
be roughly equidistantly separated, with minor variations caused by them
coalescing through terrain chokepoints and etceteras. They walk their way
to the exit."

> the wisps are spawned throughout the DK starting zone area. If they are
> in the northern half of the map, they walk generally northward until
> they filter out of the zone through the cave in the north. When they
> do, they get to the cave mouth and they curve upward. Imagine if right
> at the cave entrance there's a radius point placed 20 yards above, and
> the circumference of that circle for the first maybe 20% of it's
> distance forms an arc that charts the path that the whisps will fly,
> through and away and then they wink out of sight as they fade into the
> color of the sky.
>
> the others will float from the east and guide through the Scarlet
> Citadel, straight to it's mouthpoint entrance. And we try to spawn them
> equidistantly, so the entire map is covered. In this way, the new player
> can never be lost, as they are guided exactly to where they need to go
> to be back with the rest of the game.

Then, the start:

> Tyr's hand has elites, right? That sounds excellent to me. So, what if
> we changed the starting spot again (sorry) and put it near the chapel
> down south? Where the DK in the story makes their choice. We can have
> the player phase through the doodad until they're exactly in the
> building, then we can re-enable it just in-time for fall damage to do
> the trick. And if fall damage doesn't always feel reliable, we can also
> apply it manually. Then, when Sargobras is resurrecting, we should
> remove the ability to "release spirit" because otherwise they'll get
> lost. He should say that the quick path is to the west, through the
> Scarlet Army. But the north has two caves, one of which holds a pathway
> out. To the north is level 58-60 enemies, tough, but doable with a
> buddy-bot. To the west, level 60 elites, requires a party of DKs to
> overcome. But, with extra rewards.

## Current Behavior

The skip (`src/lua-basic/death-knight-souls.lua`, the skip and the rise)
puts the death knight on the Plaguelands map at the Ebon Hold's spot
(2336, -5678, z 382), moved up to 6 yards at random; it falls to the
ground under Acherus (about z 154) and dies. That ground is the western
edge of the Scarlet Enclave's land on the Plaguelands map, which holds no
creatures at all (none east of y -5778).

The rise: a level-100 Sargobras you can't talk to appears 4 yards from
the body in a random direction, facing the body; he points, freezes, a
red circle appears, the death knight is raised where it lies with its
facing unchanged, and its buddies are asked for. A death knight that
released its spirit meanwhile is brought back to its body. Nothing stops
it from releasing. The buddy module puts each buddy near its owner;
nothing places or turns it.

**Tyr's Hand** (creature spawns read 2026-10-22, around x 1540-1870, y
-4780 to -5610 on the Plaguelands map) holds the Scarlet Crusade, about
200, nearly all elite: Scarlet Warder 53-54, Enchanter 53-55, Cleric
54-55, Curate 55-56, Archmage 55-57, Praetorian 56-57, Trooper 58-59 (not
elite), Inquisitor 61, Crusader Lord Valdelmar 60; High General Abbendis
(59, rare elite). So most are mid-50s elites, not 60 (open question 4).
**North of Light's Hope** lies a Scourge camp: 57-60 (Dark Adept,
Shadowmage, Scourge Champion, Death Singer, Stitched Golem and others),
with Deathspeaker Selendre (56, rare).

## Intended Behavior

**The fall, into the chapel.** The skip places the death knight inside
the chapel in the south of the Enclave (open question 1: which), high
under its roof, and it falls to the chapel floor and dies. If the fall
from there isn't high enough to kill, it is killed on landing (the fall
watch, which already looks for the landing, deals the damage). The game
client decides what is solid, not the server, so a building can't be
turned off and on for one player; placing the death knight already inside
gives the same result (open question 2).

**The rise, arranged for the camera:**

- the death knight faces Sargobras, and Sargobras faces it;
- each buddy stands within about 20 yards in front of the death knight,
  behind Sargobras as the death knight sees him (all of them in view with
  the camera as it is), facing the death knight;
- **no releasing the spirit** while the rise is under way (from the
  death until the raise), so nobody wakes in a graveyard far away.

**Sargobras's parting line**, said at the rise, in his words (the
owner's meaning, open question 3 for the exact wording): the quick way is
west, through the Scarlet army: elites, a party of death knights' work,
with richer spoils. The north has two caves, and one of them holds a way
out: tough, but doable with a buddy.

**The two ways out, and the wisps.** Blue ethereal wisps appear,
unhurried, all over the Enclave's land, about 30 for each way out, spread
evenly so the whole land is covered, and each walks its way out by the
ground's own paths (bunching where the land narrows). A player who
follows any wisp is never lost:

- **The northern half's wisps** walk north to the cave that leads out.
  At the cave mouth each curves upward along an arc: a circle whose
  centre is 20 yards above the mouth, its first fifth or so traced as
  the flight path, up and away, and the wisp fades into the colour of
  the sky.
- **The others** float in from the east and lead through the Scarlet
  Citadel at Tyr's Hand to its entrance.

**The west path's richer spoils:** the elites there drop more (155z10's
knobs, or this path's own).

## Suggested Implementation Steps

1. Answer the open questions.
2. **The chapel fall:** the landing spot inside the chapel (from a `.gps`
   reading there); the fall watch kills on landing if the fall didn't.
3. **No release during the rise:** compiled code (the buddy module
   already drops some of a player's requests to the server before they
   are handled, `buddies_clan_lock.cpp`); the client's "release spirit"
   request is dropped for a death knight in its rise, with a line saying
   why.
4. **The facings and the buddies' places:** as above; each buddy moved
   and turned when it appears after the rise (the death knight buddy gear
   script already waits for that, 10 seconds).
5. **The wisps' spots, generated:** a tool samples the Enclave's land
   (heights from the server, as 617e4's measuring did), keeps walkable
   points, assigns each to the way out it reaches sooner, and picks about
   30 per way spread evenly (farthest-point sampling), writing a Lua data
   file and a picture of the halves, the spots and the exits.
6. **The wisps:** a blue wisp creature (a model chosen by look); spawned
   at the rise (visible to whom: open question 5); each walks to its exit
   by the server's pathfinding; the northern ones then fly the arc
   (points along it, flying movement) and fade; gone after a few minutes
   either way.
7. **Sargobras's line** said by the rising Sargobras before he goes.
8. Tests: the spot picker on a made-up grid with a narrow pass; the arc's
   points (start at the cave mouth, rise 20 yards over a fifth of the
   circle); in game, one skip: the fall kills, release is refused, the
   arrangement is in view, wisps walk both ways.

## Open Questions

1. **Which chapel?** "The chapel down south, where the DK in the story
   makes their choice": the Chapel of the Crimson Flame, in the Enclave's
   south? A `.gps` reading inside it would settle the spot.
2. **"Phase through the doodad":** the server can't make a building
   passable for one player and solid again (the client decides what is
   solid). Placing the death knight inside, under the roof, then letting
   it fall or killing it on landing: the same result you wanted?
3. **Sargobras's exact words.** For example: "West, through the Scarlet
   army, is the quick road. Elites, a task for a band of death knights,
   but richly paid. North are two caves, and one of them leads out: hard,
   but a buddy at your side will see you through."
4. **"Level 60 elites" at Tyr's Hand:** they are mostly 53-57 elites
   today. Raise them to 60 (with 155m's true creature levels, or the
   multipliers of 155i), or leave them?
5. **Whose wisps:** only the skipper sees its own wisps, or everyone in
   the Enclave?
6. **The two caves:** where are they (a `.gps` at each mouth), and which
   one leads out?
