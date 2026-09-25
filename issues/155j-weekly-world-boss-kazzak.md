# 155j - Weekly World Bosses: Kazzak, Doomwalker, Fel Reaver

## Status
- Created: 2026-09-24
- Phase: 1
- Parent: 155
- Blocked by: 155a, 155i (his damage and health are tuned per creature)
- Related: 155f, 155h, 155k, 617
- Priority: Medium

## Origin

Verbatim, 2026-09-24:

> Let's say that Doomlord Kazzak is intended to be the ultimate boss of this
> patch expansion thing. Let's say that his drop table can be expanded to
> include all raid items that are similar item level to the things he
> normally drops. He should spawn and be slayable once-per-week per server.
> Ideally, we'd take everyone who contributed and value their contribution
> somehow, damage and healing done, health damage taken, some other
> metric... Such that we find the exact contribution score. Then, that's
> their chance of getting a piece of loot. This piece of loot is tradable to
> anyone who was there for 2 hours. But they need to be in the zone and have
> dealt at least one single point of damage to him, or healed a single point
> of health from someone who dealt damage to him while he was alive and
> engaged in combat. NPC bots should never be considered for loot from
> Doomlord Kazzak. The NPC bots are not considered for contribution value.
> This is a separate issue file of course. Doomwalker is that like Doomlord
> Kazzak? Can we give loot to the Fel Reaver and make it an open world boss
> similar to Doomlord Kazzak? We should give it loot with appropriate ilevel
> for it's relative health and damage values. It doesn't have any
> mechanics, but I remember Kazzak does, is that right? Maybe it could be a
> Patchwerk style fight, a gear check, who can say...

Later the same day, verbatim:

> How about we say that the Fel Reaver has one mechanic from each boss.
> There'll be four: Kazzak's mark, which drains mana, explodes, and forces
> a tank swap if it lands on a tank. Doomwalker's earthquake and chain
> lighting should be considered one "mechanic". The charge is another
> mechanic, and getting stronger when killing a player is a fourth. The fel
> reaver should always enrage at 20% health. It should choose 2 mechanics
> from the prior list and copy them exactly. Each Kazzak mechanic should
> provide 1/2 of Kazzak's health and damage, and each Doomwalker mechanic
> should provide 1/2 of the Doomwalker's health and damage, so a competent
> raid leader might be able to tell before the fight starts if both Kazzak
> mechanics are active, or both Doomwalker mechanics are active, but if
> it's one-and-one then there's no way to tell. The Fel Reaver should drop
> Kharazhan items that are level 120 and below, only epics.

> items dropped should be number of people who contributed * default number
> of items / 40. Does that make sense to scale? The weekly reset time should
> just be, whenever I take the server down... And the weighted contribution,
> well, I'm not sure until we do some scaling. Depends on how powerful the
> heroes are. We'll have to do some sims when we build this feature, for now
> we won't be fighting Kazzak for a while so it's fine if we leave him
> unfinished.

> The three of them are the same tier. Kazzak is probably going to be
> hardest because of the 2 minute timer, we might need to make that into a
> 20% reset as well, and potentially remove the abilities that increase in
> power as heroes are slain.

Answers, verbatim, 2026-09-24:

> I'm not sure if we'll need to scale them. They are raid bosses, after
> all.

> Oh, my bad. Pretend I didn't say "tank swap" haha

> Always at least one item per kill. We should round up when we need to.
> I'm worried about a 20% enrage that always occurs because his damage
> values are so much higher than the doomwalker. If Capture Soul is removed
> from him, we should remove it from the Fel Reaver and replace it with
> some other type of ability.

> Fel Reaver's abilities are taken from Doomwalker and Kazzak. So whatever
> becomes of their abilities, so too does the Fel Reaver inherit.
> Doomwalker should use Kazzak's contribution rules. So should the Fel
> Reaver. They should all three spawn once per week (or however long it
> takes me to reset the server).

## Current Behavior

Stock (read 2026-09-24 from the world database and the boss scripts):

- **Doom Lord Kazzak** (Hellfire Peninsula, one spawn): level 73, about
  850,000 health, melee about 11,100 per second before armor. Scripted
  (`boss_doomlord_kazzak`): Shadow Bolt Volley, Cleave, Thunderclap, Void
  Bolt, **Mark of Kazzak** (drains the target's mana, then explodes on
  them), **Twisted Reflection** (heals him when he damages the marked
  player), **Capture Soul** (he gains power when he kills a player),
  Frenzy (every 30 seconds from the first minute), and **Berserk at 3
  minutes** (the stock script's timer; the owner remembered 2). Mark of
  Kazzak only picks players who use mana, so a warrior tank is never
  marked. Drops 2 of a pool of 10 epics, all item
  level 120 (loot table 18728 → reference 26043, count 2).
- **Doomwalker** (Shadowmoon Valley, one spawn): the same kind of boss, an
  open-world raid boss of the same era. Level 73, about 1.6 million health,
  melee about 5,600 per second. Scripted: Earthquake, Chain Lightning,
  Sunder Armor, Overrun (charges and knocks down), Enrage below 20%, and
  Mark of Death (a player he kills is marked; he kills marked players
  instantly if they come back). Drops from a pool of 10 epics, item level
  120.
- **Fel Reaver** (Hellfire Peninsula, two spawns): not a boss. An elite
  level 70 that walks a patrol path; about 105,000 health, melee about
  1,000 per second, no boss script. Its loot is the ordinary level-70
  world-drop table (reference 6002), like any elite of its level.
- Raid items of item level 115–125 on this client: Karazhan (115–125),
  Gruul's Lair (125), Magtheridon's Lair (125). That is "similar item
  level" to Kazzak's 120.

## Intended Behavior

**Kazzak, Doomwalker and a reworked Fel Reaver are one tier**, the top of
basic, each a once-per-restart world boss (the week resets whenever the
server is restarted).

**Doom Lord Kazzak**
- Spawns once per restart; killable once.
- Loot: **his own 10 items** (Ritz, 2026-09-24: "Kazzak has his own items
  too. Only the Fel Reaver gets a new loot table."), required level 60.
  The earlier widened pool is dropped.
- **Items per kill = contributors × 2 ÷ 40, rounded up** (2 is his stock
  count, 40 the raid he was built for): at least one item every kill; 5
  contributors give 1, 60 give 3.
- **Contribution**: damage to him, healing on players who damaged him, and
  damage taken from him; the weights are set later by simulation. A
  player's share is their chance of receiving an item.
- **Eligible**: a player (never a bot) in the zone who did at least 1
  damage to him, or healed at least 1 health on someone who had, while he
  was alive and in combat. Bots never count and never receive loot.
- **Trading**: tradable for 2 hours among that kill's eligible players.
- **Maybe** (Ritz: "might"): remove the ability that grows as players die
  (Capture Soul). The 3-minute Berserk stays for now: an always-on 20%
  enrage worried the owner, because Kazzak's damage is far above
  Doomwalker's.
- **Scaling**: possibly none. Ritz: "They are raid bosses, after all."
  They are level 73 and built for level-70 raids; a level-60 raid's first
  attempt decides.
- **Left unfinished for now** (Ritz: "we won't be fighting Kazzak for a
  while"): the contribution weights wait for simulations.

**Doomwalker**: same tier as Kazzak; spawns once per restart; uses
Kazzak's contribution, eligibility, items-per-kill and trading rules; drops
his own 10 items, required level 60.

**Fel Reaver** becomes a world boss built from the other two:
- A pool of four mechanics, each copied exactly from its source:
  1. Kazzak's **Mark**: drains mana, then explodes (stock; it only picks
     players who use mana).
  2. Doomwalker's **Earthquake + Chain Lightning** (one mechanic).
  3. Doomwalker's **charge** (Overrun).
  4. Kazzak's **growing stronger when he kills a player** (Capture Soul).
     If Capture Soul is removed from Kazzak, it is removed here too and
     replaced by another ability. The Fel Reaver always inherits whatever
     its source bosses' abilities become.
- Each spawn picks **2 of the 4**. Each Kazzak mechanic adds half of
  Kazzak's health and damage, each Doomwalker mechanic half of
  Doomwalker's. So both-Kazzak and both-Doomwalker spawns can be told
  apart by health before the pull; any one-and-one spawn looks the same.
  At stock values: both Kazzak = 850,000 health and ~11,100 melee per
  second; both Doomwalker = 1,590,000 and ~5,650; one of each = 1,220,000
  and ~8,390. On basic these come from Kazzak's and Doomwalker's tuned
  values (155i), not stock.
- Always **enrages at 20% health**.
- Drops **Karazhan epics of item level 120 and below**, required level 60.
- **Both stock spawns stay: two Fel Reavers**, each once per restart, each
  drawing its own 2 mechanics. Both use Kazzak's contribution,
  eligibility, items-per-kill and trading rules.

## Suggested Implementation Steps

1. Once-per-restart spawn: remove the permanent spawns; at server start a
   script summons each boss, and a kill is not repeated until the next
   restart.
2. Fel Reaver: a boss script that draws 2 of the 4 mechanics at spawn,
   calls the same spells as Kazzak's and Doomwalker's scripts, sets health
   and damage from their tuned values, and enrages at 20%.
3. Contribution counter: a script on the boss adds up each player's damage
   to him, healing on eligible players and damage taken, per kill.
4. Loot: on death, a weighted draw per item among eligible players, by
   contribution share. Items bound on pickup with the stock "tradable for 2
   hours to people present" rule narrowed to the eligible list.
5. Loot-pool generator: every raid item of item level 115–125, required
   level set to 60, written as the boss's loot table.
6. Test: a scripted kill on the RAM server with two players and two bots;
   bots get no share, and the draw follows the recorded contributions.

## Related Issues

- **155** parent; **155i** per-creature multipliers
- **155f**, **155h** — the tiers below him
- **155k** Outland world gear — where Fel Reaver's loot would sit
- **617** buddies — excluded from contribution

## Open Questions

- **Levels.** Stock: Kazzak and Doomwalker 73, Fel Reaver 70, while
  Magisters' Terrace's Kael'thas is proposed at 78 (155f) with lower loot
  (item level 100 epics against these bosses' 115–120). Ritz: "That
  feels... wrong somehow". Proposal: the three world bosses share one
  level above every dungeon boss (80), Kael'thas drops to 77, so level
  reads as tier. **Answered 2026-09-24: no.** "I think they would be
  impossible at level 80. Let's leave them as they are and see if that's
  fine." Stock levels stay (Kazzak and Doomwalker 73, Fel Reaver 70);
  revisit after the first attempts.
- (Answered 2026-09-24) If Capture Soul goes, the Fel Reaver's pool takes
  whatever replaces it on Kazzak.
- (Answered 2026-09-24) At least one item per kill, rounded up. Berserk
  kept for now. All three spawn once per restart and share Kazzak's
  contribution rules. The Fel Reaver inherits its sources' abilities. No
  tank swap. Scaling perhaps unneeded. Reset: whenever the server
  restarts. Contribution weights: by simulation, later. Doomwalker and
  Kazzak keep their own items; only the Fel Reaver gets a new table. Two
  Fel Reavers.
