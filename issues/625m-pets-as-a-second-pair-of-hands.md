# 625m - Pets as a Second Pair of Hands

## Status
- Created: 2026-10-30
- Phase: 6
- Parent: 625 (buddies favour the abilities their talents touch)
- Related: 625f (the action economy: time is the currency), 625j (the
  threat economy: a pet's taunt moves attention), 625a (what each talent
  touches: the pet talents)
- Priority: Medium
- State: in progress (the pet's lane built offline 2026-11-06; the
  server's side next)

## Origin

The owner, 2026-10-30, word for word, in the middle of the threat economy
(625j holds the whole passage):

> Even hunter stealth / hunter pet taunts are important to consider (by
> the way, hunters should treat their pets abilities as their own for
> these purposes. They are free in the action economy, or rather, they
> cost 1 pet gcd or similar, while other abilities cost 1 hunter gcd and
> such. This is the case for anyone with a pet who behaves similarly, like
> warlocks. They should cast the pet abilities intentionally, for a
> specific goal, and they should ascertain those goals dynamically, as if
> they were any other ability.

## Current Behavior

Not built. The bot module leaves a pet's abilities to the game's own
autocast (each ability on or off, and a command to toggle them,
`TogglePetSpellAutoCastAction` in the module's pet actions): the pet
casts what is switched on whenever it can, with no aim.

**The pet's abilities are already in the game's data** (found
2026-11-06): `scripts/generate-ability-data` lists them under their
master's class in `buddies_ability_data.h` (Claw, Bite, Growl, Cower and
Dash under the hunter's; Firebolt, Torment, Suffering, Spell Lock, Devour
Magic, Seduction and Shadow Bite under the warlock's), with their cast
times, cooldowns, global cooldowns and costs. So step 1 is mostly done;
not found there: the ghoul's Gnaw and the Water Elemental's Freeze (the
table's one "freeze" is a shaman's, spell 63685).

**The pet's lane, built 2026-11-06 (offline, on a branch for review):**
`buddies_pet_lane.h` (step 2), on the action economy's look ahead for
short abilities (`buddies_rotation_time.h`, 625f), which gains what a
pet needs: a resource of its own (a pool, its most, and how fast it comes
back; each cast paid for or waited for), a deadline a cast must land by,
and a worth that fades each second until it lands. The lane is that look
ahead run on the pet's abilities with the pet's own global cooldown and
resource, beside the buddy's and never against it. Each pet ability is
priced by its goal from what the moment shows (the server reads it):
- **damage**: its own worth (Claw, Firebolt);
- **interrupt**: the enemy's cast in progress, if it lands before that
  cast does (Spell Lock); nothing with none under way;
- **taunt**: what the loose enemy costs each second (625j's curve) for as
  long as it would stay loose, each second before the taunt lands lost
  (Growl, Torment);
- **dispel**: what the worst mark still costs, the same way (Devour
  Magic).
The plain attack stays on the game's autocast (open question 1); the lane
says when to pause it: while the plan starts with an ability with a goal,
holds the resource for one coming back, or wants one off the global
cooldown that can't yet be paid for (Growl with 10 focus: Claw would keep
spending the focus Growl needs). Costs are read in the pet's own unit
(focus and energy as they are, rage and runic power from the game's
tenths, mana as its amount or its share of base mana). Checked by
`scripts/test-buddy-pet-lane` (31 checks, a quick test): a wolf claws on
autocast until an enemy is loose and Growl is slipped in; Spell Lock is
worth the 2000 heal it stops, nothing with no cast; a taunt worth 3000 back
in 2 seconds holds 50 focus and pauses the autocast; the hunter's lane
and the wolf's each pick their own, the same with or without the other.
15 of 15 deliberately broken versions of the lane and 14 of 14 of the
resource, deadline and fading caught; the short abilities' own test (32
checks) still holds. Not yet: the server's side (step 3: the pet's
autocast switched by the lane, its abilities cast through the pet's own
action, behind a switch), and the Sight read from the fight (625j's curve,
the enemy's cast, the marks on the party).

## Intended Behavior

- **The pet's abilities are the buddy's.** A hunter's, warlock's, death
  knight's or frost mage's pet's abilities (Growl, Claw, the Felhunter's
  Spell Lock and Devour Magic, the Voidwalker's Torment and Sacrifice, the
  Succubus's Seduction, the ghoul's Gnaw, the Water Elemental's Freeze)
  are answers the buddy weighs like its own, chosen for a goal it works
  out from the moment (a taunt to take an enemy off a healer, an
  interrupt on a cast that matters, a dispel of what hurts most), not left
  to autocast. The plain attack (Claw, Bite, Firebolt: damage with no
  other goal) stays on autocast as filler.
- **Two lanes of time.** The pet has its own global cooldown and its own
  resource (focus, energy, mana), so in the action economy (625f) a pet's
  ability costs a pet global cooldown, not the buddy's: two lanes of
  actions side by side, each spending its own time. A pet ability is never
  weighed against a buddy ability for the same slot.
- **Goals, as any other ability's.** What a pet ability is worth is said
  in damage and health like everything else (the strategem): Growl's worth
  is the curve it bends (625j), Spell Lock's the damage or healing the
  interrupted cast would have done.
- **Like any other ability, from the game's data.** The pet's abilities,
  costs and cooldowns are read from the game's tables beside the classes'
  (`scripts/generate-ability-data`: the pets' spell families), not listed
  by hand.

## Suggested Implementation Steps

1. The pets' abilities read from the game's tables (the pet spell
   families and their skill lines), in the ability listing.
2. The pet's lane in the action economy: its own global cooldown and
   resource, its abilities weighed by their goals, with tests.
3. In the server: the buddy's pet with autocast off for the abilities the
   buddy now chooses, cast through the pet's own action, behind a switch.

## Open Questions

1. Should the buddy keep autocast on for the pet's plain attack ability
   (Claw, Bite, Firebolt: a filler with no goal beyond damage), and choose
   only the abilities with a purpose, or choose every pet ability itself?
   **Answered 2026-10-30** (the owner, word for word): "the plain attack
   can be autocast I guess." So the pet's plain attack stays on the
   game's autocast as filler, and the buddy chooses the rest.

## Decisions (2026-11-06)

The agent's calls while building `buddies_pet_lane.h`, for the owner to
curate:
- **A taunt's worth** is the health the loose enemy costs each second,
  above what it would cost on the tank, times how long it would stay
  loose with no taunt (the rest of the fight when nobody knows), each
  second before the taunt lands taken off. A dispel is priced the same way
  from the mark's cost a second and the time it has left.
- **An interrupt** is worth the whole of the enemy's cast, but only if it
  lands before that cast does.
- **The autocast pause**: the plain attack's autocast stays on unless the
  lane's plan starts with an ability with a goal, holds the resource for
  one, or wants one off the global cooldown that can't yet be paid for. A
  wait for the plain attack's own resource leaves the autocast on.
- **Off the global cooldown** (Growl, Spell Lock): slipped in whenever
  worth something and paid for, as the buddy's own are; their costs are
  not raced against the rest, which is why the pause above watches them.

