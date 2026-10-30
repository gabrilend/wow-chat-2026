# 625m - Pets as a Second Pair of Hands

## Status
- Created: 2026-10-30
- Phase: 6
- Parent: 625 (buddies favour the abilities their talents touch)
- Related: 625f (the action economy: time is the currency), 625j (the
  threat economy: a pet's taunt moves attention), 625a (what each talent
  touches: the pet talents)
- Priority: Medium
- State: planned

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

## Intended Behavior

- **The pet's abilities are the buddy's.** A hunter's, warlock's, death
  knight's or frost mage's pet's abilities (Growl, Claw, the Felhunter's
  Spell Lock and Devour Magic, the Voidwalker's Torment and Sacrifice, the
  Succubus's Seduction, the ghoul's Gnaw, the Water Elemental's Freeze)
  are answers the buddy weighs like its own, chosen for a goal it works
  out from the moment (a taunt to take an enemy off a healer, an
  interrupt on a cast that matters, a dispel of what hurts most), not left
  to autocast.
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
