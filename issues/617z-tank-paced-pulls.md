# 617z - Tank-Paced Pulls: "go faster", "slow down"

## Status
- Created: 2026-10-12
- Phase: 6
- Parent: 617 (buddy bots)
- Related: 617y (spoken orders: the hearing, the channels), 617c3 (the
  dungeon draw: who is tank and healer), 617t (dungeon stand-ins: a tank
  may be a stand-in), 617c4 (dungeons)
- Priority: Medium
- State: planned; open questions first

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

Nothing paces a dungeon but the player. Inside a dungeon each buddy follows
its owner (the bot module's own following), and when the owner comes
within a little more than a monster's notice range, the owner's buddies
not yet fighting go at the nearest hostile monster the owner can see
(`AggroPass`, `modules/mod-buddies/src/buddies_roam_strategy.cpp`). So
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

1. (Answered 2026-10-12: a player or a healer buddy, whispered to the
   tank.) When the player is the healer (Birth is a shaman), does the
   tank lead even though its owner is in the group?
2. (Answered 2026-10-12: "slow down" lasts for a time, and confidence
   builds back up over time.) How long to rebuild, from a "slow down" to
   full speed: a few pulls, a few minutes? Does a second "slow down"
   before it has rebuilt drop it further?
3. The tank walking ahead: does it need a route through each dungeon
   (packs in order, as a player learns them), or does it take the nearest
   pack it hasn't fought yet?
4. A player who isn't the healer (playing damage): can they also say "go
   faster", or only the healer?
5. "only if the monsters have a chance of harming them. Otherwise, they
   refuse to fight": a monster too low (grey to the tank) is skipped and
   walked past? Or the tank refuses a "go faster" order when the next
   pack is harmless, because faster gains nothing there?
6. When the answer is "wait", does the tank say so ("Waiting for mana."),
   as "My bags are full." is said (617y)?
