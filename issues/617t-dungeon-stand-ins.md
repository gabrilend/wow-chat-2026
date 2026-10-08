# 617t - Dungeon Stand-ins

## Status
- Created: 2026-10-04
- Phase: 6
- Parent: 617 (buddy bots)
- Priority: Medium
- Related: 617c3 (the dungeon draw: its tank and healer sums), 617a4 (the
  buddy kit: white gear by level), 617j2 (gems and sockets), 155p (white
  gear sockets on basic)

## Origin

Verbatim, 2026-10-04:

> can we also make issue files to make it so that if you have fewer than 4
> buddy-bots, if you enter a dungeon, you get companions that are equipped
> with the level appropriate white gear randomly selected and created?
> They should be socketed according to their class styles. Also make sure
> that we have an item for every spot, and when available give them PvP
> trinkets, rings, and necklaces, the best available at that level. Also
> we need 1 tank, 1 healer, and the rest of the profiles treated as DPS,
> which is different than the default rule which has exceptions for
> half-heal/tank specs and third-heal/tank specs.
>
> Also can we put meta gems on white quality weapon items? Not sure how to
> acquire them yet... We should mark it as an open question.

## Current Behavior

Not built. Entering a five-player dungeon draws the group's own buddies
into the empty seats (617c3); a player with fewer than four buddies goes
in with empty seats.

## Intended Behavior

A player entering a five-player dungeon with fewer than four buddies gets
stand-in companions for the seats left empty after the draw. "Fewer than
four" counts the roster's buddies unlocked for the player's level (owner,
2026-10-04: "In your roster, unlocked for your level. So between levels 1
and 30"): a buddy slot opens at level 1 and every ten levels, so below 30
a player has fewer than four.

**The missing role, 30 to 59** ("if the user doesn't have a tank/healer
until level 50 and 60, for levels 30 through 49 the farthest party member
that isn't required can be replaced by a stand-in buddy-bot that is that
particular role"): from level 30 a player has four buddies, but none may
be a tank or a healer yet. Then the party member farthest away who isn't
needed for a role steps out, and a stand-in of the missing role takes its
seat.

- **Roles, strictly**: the group ends with exactly one tank and one
  healer, everyone else damage; a stand-in is made for the missing roles
  first. Unlike the buddies' draw (617c3, where a part-healer counts 0.4),
  a stand-in is wholly its role.
- **Made fresh**, at the player's level, a random class and race of the
  player's faction that can take the role.
- **Gear**: white (common) items for its level, chosen at random among
  those its class can use (the kit's rule, 617a4: what some vendor sells,
  its last five levels), an item in every slot. Where no white exists for
  a slot (neck, rings, trinkets), the best PvP item available at its level
  (honor and battleground rewards it could use).
- **Sockets**: filled by its class's style (the gem colours and stats its
  class and role want, 617j2's rules).
- **Kept, not deleted** (owner, 2026-10-04: "you can scale them up to the
  next bracket and have them spawn the next time someone needs that
  particular race/class combination"): when the dungeon ends a stand-in
  leaves the world and is kept, raised to the next level bracket (ten
  levels) with its gear made again for that bracket.
- **Levelling tracks** (owner, 2026-10-08: "There are situations when a
  stand-in might be lower level. Also it might end up being 1 level each
  match, we'll see. It's meant to roughly match the rate of player
  levelling, though maybe there should be some that go slow or fast, to
  make sure that everyone knows some stand-ins and are greeted with new
  ones too. parallel levelling tracks."): a stand-in only levels when it
  is used, never while stored. The size of the step (a ten-level bracket,
  or one level a match) is to be tuned so stand-ins as a whole climb
  about as fast as players do. Each stand-in is on one of several
  parallel tracks, some slower and some faster than that rate, so a
  player keeps meeting stand-ins they already know, and new ones too.
- **Reused anywhere above** ("They should be able to be chosen for *any*
  higher level bracket btw. But their level doesn't go down."): the next
  time any player needs a stand-in of that race, class and role, a kept one
  at or below the needed bracket is raised to it and used before a new one
  is made; never one above.
- **Which dungeons**: the low ones, up to 30; up to 49 for a player still
  without a tank or healer buddy; up to 59 for one who has a tank but no
  healer and plays damage themselves ("up to 30, then up to 49 if they lack
  a class. Actually it's 59 if they get a tank for example and the player
  is dps spec, then they could lack a healer until level 59").
- **Again, or a step up** ("they can also do the same dungeon they just
  completed. If they do a slightly higher dungeon, in the same tier, they
  can be bumped up to that level too."): a kept stand-in may run the same
  dungeon again, or a higher one of the same tier, raised to its level.
- **A reward per dungeon** ("For each dungeon they complete, they should
  get a free, powerful blue item for their spec from the loot table
  randomly selected of the dungeon they just completed. But only the
  visible items, the non PvP ones."): on each completion, one blue (rare)
  item drawn at random from that dungeon's loot, among items it can use
  and that suit its spec, never PvP gear and never an item the player
  can't see in the loot (quest-only or hidden entries).
- **Battlegrounds** ("Maybe they can also fill in slots in battlegrounds?
  Like what if we doubled the number of buddy-bots that could join a
  battleground, but the 'doubled' amount was the buddy-bot templates that
  we had on file?"): each side doubles, the second half drawn from the
  kept stand-ins (617i). Sides in 3.3.5a: Warsong Gulch 10, Arathi Basin
  15, Eye of the Storm 15, Strand of the Ancients 15, Alterac Valley 40,
  Isle of Conquest 40 (the owner remembered Warsong as 15; it is 10).
- **Arenas** ("Can we also do it for arenas? So, 3v3 becomes 6v6 where 3
  and 3 are stand-ins."): each team doubles, the added half stand-ins:
  2v2 becomes 4v4, 3v3 6v6, 5v5 10v10.

## Suggested Implementation Steps

1. After the draw (617c3), count the empty seats and the missing roles.
2. Make each stand-in the way the buddy module makes a buddy (617a3), on
   the companion account, with no roster slot.
3. Gear and sockets by the kit's and 617j2's rules, plus the PvP jewellery
   search; a test listing what a stand-in of each class gets at levels 20,
   40 and 60.
4. On the way out: out of the world, up a bracket, re-geared, kept in a
   pool by race, class and role.

## Open Questions

1. Meta gems on white weapons: can white weapons carry a meta socket, and
   how would a player (or a stand-in) come by the meta gem?
2. (Answered 2026-10-04) Kept, scaled up a bracket (ten levels), used
   again for that race and class at any higher bracket.
3. (Answered 2026-10-04) "Fewer than 4": the roster's buddies unlocked for
   the player's level; from 30 to 59, a missing tank or healer is filled
   by a stand-in in place of the farthest unneeded member.
4. (Answered 2026-10-04) Up to 30; 49 or 59 when a role is missing (above).
5. (Answered 2026-10-04) Battlegrounds double each side's size; arenas
   double each team, the added half stand-ins.
6. (Answered 2026-10-04) "only stand-ins": the doubled places in
   battlegrounds and arenas are filled by stand-ins only; players queue to
   the stock sizes.
7. **The step per use**: a ten-level bracket (as above) or one level a
   match ("it might end up being 1 level each match, we'll see")? And how
   many tracks, at what speeds compared with a player?
8. **Players playing a stand-in** (owner, 2026-10-08: "We should make it
   so players can play one too, any race-class that exists (which should
   probably end up being all of them eventually)"): to be asked; see the
   Alterac Valley test scene's questions (176a1).
