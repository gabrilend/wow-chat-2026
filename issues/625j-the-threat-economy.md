# 625j - The Threat Economy

## Status
- Created: 2026-10-30
- Phase: 6
- Parent: 625 (buddies favour the abilities their talents touch)
- Related: 625f (the action economy, whose origin names this; its
  lockouts), 625i (the healer's seat), 625m (pets as a second pair of
  hands), 625l (buffs given to who uses them most), 617z (tank-paced
  pulls), 617c3 (the dungeon draw)
- Priority: Medium
- State: in progress (the levers, attention, the fight curves and tank swaps built; the tank's load next)

## Origin

The owner, 2026-10-30 (the whole passage in 625f): "threat economy (can
the tank handle more monsters, should an off-tank pull off of a faltering
main tank, etc)".

Then, the same day, word for word:

> make sure we add as a consequence of casting divine shield or divine
> protection or similar that all threat from the target is wiped. Because
> that's what happens, right? So, we shouldn't cast it on characters that
> we want to have threat on them. Unless they're critically dying, and
> then we'd favor Lay on Hands or similar instead, because both of them
> negate the "incoming damage on target" cost, but one of it does it by
> wiping threat and setting incoming (physical) damage to 0, while the
> other does it by giving the paladin's max hp as a heal. Both of these
> cause the simulation running in their head to no longer have a curve
> pointed toward "dead tank" and instead point (ideally) toward "victory"
> or similar.
>
> threat is something that has to be managed. This means it doesn't
> matter generally how much of it there is, but more importantly where is
> it stored. It's like a worker placement game, except with "threat" and
> "attention" and such. Threat is a value that builds up and can be wiped,
> attention is just... whoever it's targeting right now. For our bot's
> thought process, it's important to keep the attention onto a tank or a
> durable character - the more durable, the better. We have limited
> levers to impact that attention, including hunter misdirect and rogue
> Tricks of the Trade, but also things like BoP and such. Even hunter
> stealth / hunter pet taunts are important to consider (by the way,
> hunters should treat their pets abilities as their own for these
> purposes. They are free in the action economy, or rather, they cost 1
> pet gcd or similar, while other abilities cost 1 hunter gcd and such.
> This is the case for anyone with a pet who behaves similarly, like
> warlocks. They should cast the pet abilities intentionally, for a
> specific goal, and they should ascertain those goals dynamically, as if
> they were any other ability.
>
> anyway, as I was saying before I got distracted by hunter / warlock
> pets, we should try and keep attention on the tanks, but we can adjust
> it to their benefit with various tools if we'd like and are able. If we
> BoP the main tank so they don't die, that can save a fight, even if a
> fury warrior has to tank for a moment while the tank replenishes. Rogues
> should feint and mages should vanish and whatever else we need to manage
> it correctly, with the end result being the composite curves of
> mathematics we create optimize toward a "victory" condition. These are
> multivariable equations, and they are very, very complicated. But, we
> can set them up so they process easily, just by dropping numbers in at
> the top and watching them rapidly filter down. The constraints are
> flexible, the inputs are not since they are derived from the
> environment, and the outcomes, ideally, are comprehensive and natural
> feeling bot behavior. We are less interested in optimizing for perfect
> output, and more toward feelings of serenity in flow, searching for
> familiarity and wholesome friendly.

The pets' part is its own issue, 625m.

## Current Behavior

The bot module's tanks taunt what they lose and its damage dealers hold
back by fixed threat triggers ("medium threat").

**Built 2026-10-30 (committed, offline):** steps 1 to 3, the tanks' swaps (step 5), and the tank's load (step 4, 2026-10-31).
- The levers, read from the game's spell table by
  `scripts/generate-ability-data` (`BUDDY_THREAT_LEVERS`, and a table in
  `docs/ability-data.md`; 42 of them): what each ability's effects and
  auras do (taunt, threat added or taken, a share, handed on, leaving the
  fight, threat changed while up, immune), following the spells an ability
  sets off one step (Hand of Salvation's tick), and four the server's
  scripts cast for (Righteous Defense's and Death Grip's taunts,
  Soulshatter's halving, Invisibility's turning invisible), each cited.
  Divine Protection is rightly none. The pets' abilities come with them
  (Growl, Torment, Suffering, Lesser Invisibility), for 625m.
- `buddies_threat.h`: whom an enemy attacks, in the server's own order and
  switching rule (online before passed over before offline, then a taunt,
  then the threat; the current one kept until beaten by 10% within melee
  reach or 30% from anywhere), and what each lever does to the list (a
  taunt raises to the top, a share cuts, a hand-on adds to the receiver,
  leaving drops, an immunity passes over and a comeback restores the
  threat kept). Checked by `scripts/test-buddy-threat` (23 checks),
  among them the shielded tank: passed over with its threat kept, the
  fury warrior tanking, the attention back with the tank's first act.
- Step 3, the curve: `buddies_curve.h`. The fight cut into stretches,
  one holder of the attention in each; the holder loses the enemies'
  damage (as much as it lets through) less the healing, which follows
  whoever is hit and never lifts above most; the lowest point of each
  curve, below nothing, is how much that character falls short of seeing
  the end. Their sum, in health, is what a lever is weighed by. Checked
  by `scripts/test-buddy-curve` (11 checks): a tank 10 seconds from dead
  with 30 left is 4000 short; Lay on Hands leaves none short; Hand of
  Protection with a fury warrior next in line 1700, so Lay on Hands is
  favoured; with the priest next in line, Hand of Protection is worse than
  nothing; the most durable after the tank is the fury warrior.
- Tanks swapping by the fight curves (the owner's answer to the
  off-tank's question): each character's marks (a debuff or buff that
  changes what it takes or is healed until it wears off) are in its curve,
  cut where they wear off. The tanks try: the holder keeps it; another
  taunts now; a swap at a moment a mark wears off or every few seconds
  between; a swap and a swap back. Kept: the plan that leaves the team
  least short, then the one that loses least health in all (the healers'
  mana), then fewer swaps. A taunt not yet ready makes the holder keep it
  until it is. Checked (21 checks in all): healing keeping up, no swap; a
  minute too long for one tank, shared; a tank with a stacking debuff
  handing to the other and taking back once clean; a tank marked to take
  half, taunting though no one would die either way.
- Step 4, the tank's load (2026-10-31): `buddies_tank_load.h`. The member
  holding the most enemies; with one more like the average one on it, it
  loses that enemy's damage too (through its armour) and the fight lasts
  longer by that enemy's health at the party's pace; the room is the
  health it would have left at the fight's end that way (above nothing:
  room to pull more; below: hold). Checked by `scripts/test-buddy-tank-load`
  (7 checks): a tank at 25000 under two enemies ends a third 337 above
  nothing (room); at 15000 it holds as it is but a third would kill it.
  In the server (waiting for the compile): shown by `.buddy fight`, and
  asked by `BuddyForwardPassTankRoom` for the tank-paced pulls (617z).
The server reads each enemy's list, everyone's health and marks, the
damage coming in and the healing (625n, built by the 2026-10-31 compile).
Not yet: the damage dealers pulling more or holding by the room (617z).

## Intended Behavior

**Threat is where it is stored; attention is who is being hit.** Each
enemy keeps a threat list: how much threat each character has built on it.
Its attention is the one it attacks now. How much threat there is matters
little; where it sits matters most, like workers placed on a board. The
buddies want each enemy's attention on a tank, or failing one on the most
durable character there, and move it only when moving it helps.

**What the server does with threat** (read from its threat manager,
`ThreatManager.cpp`, 2026-10-30; the owner asked "Because that's what
happens, right?", and in this version it is close, but not a wipe):
- An enemy attacks the highest threat among those it can hurt. A
  character immune to its melee (Divine Shield; Hand of Protection against
  a physical attacker; Ice Block), confused, or held by a stun that breaks
  on damage is **suppressed**: passed over, its threat kept, while the next
  highest takes the attention. Threat it makes while suppressed is lost.
- After the immunity ends it stays passed over until it does something
  that makes threat; then its kept threat counts again, and if it is still
  the highest the attention comes back.
- So Divine Shield on the tank does not wipe its threat: it sends the
  attention to the next in line for the shield's length, and the tank
  takes it back with its first threatening act after. Divine Protection,
  a halving of damage taken, not an immunity, moves no attention at all.
- What does wipe or move threat: Feign Death and Vanish (out of the
  fight), threat cut by a share (Feint, Fade's lowering, Soulshatter, the
  "modify threat percent" effect), threat handed on (Misdirection, Tricks
  of the Trade, "redirect threat"), and taunts (attention forced, threat
  raised to the top: Taunt, Growl, Hand of Reckoning, Dark Command, Death
  Grip, Righteous Defense, the area taunts). These levers are read from
  the game's spell table by their effects and auras (taunt 114 and aura
  11, threat 63 and 91, threat percent 125, redirect 130, sanctuary 79,
  feign death aura 66, threat auras 10 and 103, the immunity auras 39 and
  40), not listed by hand.

**The curve toward victory: fight curves** (the owner's name for them,
2026-10-30). Each buddy keeps, in its head, a running curve for whoever holds attention: their health, falling at the rate
damage comes in less the healing (625i), and so the time until they die.
A curve pointing at "dead tank" before the fight's end (625h) is the cost
every lever is weighed against, said in health (the strategem: everything
is damage and health). The answers that turn it:
- **Lay on Hands**: the paladin's whole health as a heal, the curve
  pushed back, the attention left where it is. Favoured on a tank about to
  die, because the tank keeps the attention.
- **Hand of Protection on the tank**: its physical damage taken goes to
  nothing, so the curve stops; the price is the attention moving to the
  next in line (a fury warrior tanks for a moment) and coming back when
  the tank acts again. The owner: "If we BoP the main tank so they don't
  die, that can save a fight, even if a fury warrior has to tank for a
  moment while the tank replenishes." Weighed by the next in line's own
  curve: how long they last holding it.
- **Divine Shield on oneself** (a paladin tank): the same price on the
  paladin's own threat; for a paladin not tanking, no price.
- **Not shielding who should hold attention**: so a shield, Hand of
  Protection or Ice Block on the tank costs the attention it moves, and is
  chosen only when its curve is bad enough that losing the attention for a
  while is worth it, and Lay on Hands (or a big heal) isn't enough or
  isn't ready.
- **Moving attention to the durable**: Misdirection and Tricks of the
  Trade hand threat to the tank; a damage dealer near the top lowers its
  own (Feint, Fade, Invisibility, Soulshatter, Vanish, Feign Death); a pet
  taunts an enemy off a healer (625m). Each is chosen when it bends a
  curve toward victory more than its cost in time (625f) and in damage
  given up.

**Easy to work out** (the owner: "we can set them up so they process
easily, just by dropping numbers in at the top and watching them rapidly
filter down"): the inputs come from the world (each threat list, each
character's health, incoming damage and healing, the marks on them, the
levers ready); the constraints (who may hold attention, what a lever
moves) are arithmetic over them; what comes out is each answer's worth in
damage and health, handed to the draw. **The aim is how it feels**, not
the best numbers: "We are less interested in optimizing for perfect
output, and more toward feelings of serenity in flow, searching for
familiarity and wholesome friendly."

The earlier lines, kept:

- **What the tank can hold.** A running measure of the tank's load: how
  many enemies are on it, how fast its health falls against the healing
  coming in. While there is room, damage dealers may pull more (617z: "If
  the DPS wants to go faster, they should just pull more mobs"); when
  there isn't, they hold.
- **The off-tank.** A second buddy able to tank (a tank shape, or the
  talents) takes enemies off a faltering main tank: one whose health
  falls faster than it is healed, or who is stunned or down. **Neither is
  fixed** (the owner's answer below): main and off-tank swap as the fight
  goes, each tank's marks (a debuff that makes it take more, or be healed
  less, until it wears off; or one that makes it the one the boss should
  hit) built into the fight curves, and the tanks taunt so the attention
  sits with whichever leaves the team least short. Keeping the tank there
  is the tie's winner: no swap for nothing.
- **Threat as a cost.** An answer that draws a lot of threat costs more
  for a damage dealer near the top of the threat list, less for the tank.

## Suggested Implementation Steps

1. The threat levers read from the game's spell table by their effects
   and auras (`scripts/generate-ability-data`), with a listing to read.
2. Attention as plain arithmetic: given each enemy's threat list and who
   is passed over (immune, confused, stunned), who it attacks; and what a
   lever does to that (a taunt, a hand-on, a cut, a shield's suppression),
   with tests checked against the server's rules above.
3. The curve: each holder's time until death from health, damage in and
   healing in; a lever's worth as the curve it leaves against the one
   before (Lay on Hands against Hand of Protection on a dying tank), with
   tests.
4. The tank's load as plain arithmetic (enemies on it, health falling,
   healing in), with tests.
5. The off-tank's rule: when to step in, and when to hand back.
6. Threat as a cost in the draw.

## Open Questions

1. When an off-tank takes enemies off a faltering main tank, should it
   hand them back once the main tank recovers, or keep them to the end of
   the fight? **Answered 2026-10-30** (the owner, word for word): "the
   main and off-tank roles can switch naturally and elegantly during the
   fight. But, they should keep in mind which tank would be best suited to
   hold the attention, and they should taunt accordingly. For example
   sometimes there's debuffs and stuff that can go to a tank, and you do or
   don't want the boss targeting them for some reason or another. The bots
   should build these into their "fight curves" as we should call them,
   and they should automatically sort themselves into situations that are
   most beneficial for their team." (Above, the off-tank.)
