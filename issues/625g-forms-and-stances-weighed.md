# 625g - Forms and Stances, Weighed

## Status
- Created: 2026-10-30
- Phase: 6
- Parent: 625 (buddies favour the abilities their talents touch)
- Related: 625c (every tree's list), 625f (the action economy), 625h (the
  resource economy)
- Priority: Medium
- State: in progress (the trip's weighing built offline; reading each
  talent's numbers from the game, and the server, next)

## Origin

The owner, 2026-10-30, word for word:

> the hybrid tree shares looks great. Though a feral druid can often do
> cool things if they have things like Natural Shapeshifter and Furor - we
> should treat various states as important. This also applies to like,
> warrior stances. Some talents allow you to shift into and out of forms
> easily, sometimes even rewarding you for doing so - furor is especially
> important for feral druids in cat form, who can let their energy
> regenerate while casting a couple rejuvenations and such. Similarly a
> warrior can switch to defensive mode temporarily to cast a taunt or
> something, but they have to weigh the cost of losing their rage to do
> so. The weighting for each ability should be very dynamic and update
> according to their context around them, and their stats and talents
> and... so much... But once we build a sufficiently discrete and clear
> system then it should resolve such things naturally.

## Current Behavior

**The trip's weighing, built 2026-11-06 (offline, on a branch for
review):** `buddies_form_trip.h`, step 2.
- **The form's own numbers from the game** (`ShiftMana`, `ShiftSeconds`):
  entering a form costs its mana from the generated ability table (cat
  form 35% of base mana), less a talent's share (Natural Shapeshifter's
  percent); the time is its global cooldown (a druid's form 1.5 s, a
  warrior's stance none).
- **The resource through the trip** (`Returned`): what it held, plus what
  comes back while away (energy's 10 a second; rage nothing), of which a
  change keeps at most what the stance or talent keeps, plus the gift on
  entering again (Furor's chance times its amount), held to the cap.
- **The trip as one answer** (`Weigh`), in damage and health: what the
  answers outside give, plus the resource gained (or less the resource
  lost), less the form's own work for the trip's whole time, less the
  mana (the answers' and entering the form again).
- **Whether to go** (`Take`): only when it comes out ahead; an answer the
  role doesn't need only while the role's own concerns are quiet or the
  healer seats are short or dry (open question 1, below).
Checked by `scripts/test-buddy-form-trip` (25 checks, a quick test): a 5/5
Furor cat at 20 energy casting two Rejuvenations comes back at 100 energy
and ahead; without Furor it loses its 20; a warrior at 60 rage keeping 10
loses 50 rage's worth for a taunt and stays put, keeping 50 it goes; 16 of
16 deliberately broken versions of the header caught. Not yet: what each
change keeps and each entering gives read from the game's talent tables
(step 1: Furor, Tactical Mastery and the like, given here as inputs), the
form's worth a second and a point of its resource from the forward pass's
rates, and the trip offered to the draw in the server (step 3, seen in
game).

The bot module puts a druid in the form its strategy names and
a warrior in its tree's stance, and changes them by fixed rules.

## Intended Behavior

- **A form or stance is a state with a price and a gift.** Changing costs
  a global cooldown, mana, and what the old state held (a warrior's rage
  above what the stance keeps, a cat's energy); some talents make it
  cheaper (Natural Shapeshifter) or pay for it (Furor: energy or rage on
  entering a form). These are read from the game's own data, like 625a's
  table.
- **An answer from another state is weighed with the trip.** A cat druid
  with Furor weighs "out of cat, two Rejuvenations, back into cat" as one
  answer: the heals, the energy that comes back meanwhile, and Furor's
  gift on returning, against the time and mana. A warrior weighs a quick
  defensive stance for a taunt against the rage it loses.
- **Not a special case.** Each state's cost and gift are inputs to the
  economies (625f time, 625h resources, 625j threat), so the stance dance
  falls out of the weighing ("once we build a sufficiently discrete and
  clear system then it should resolve such things naturally").

## Suggested Implementation Steps

1. From the game's tables: each form and stance, what changing costs and
   keeps, and the talents that change that (Natural Shapeshifter, Furor,
   Tactical Mastery, Improved Berserker Stance and the like).
2. The trip as one answer in the draw: its total time, cost and gain.
3. Seen in game: a Furor cat healing an ally and returning; a warrior's
   taunt from battle stance.

## Open Questions

1. Should a buddy ever leave a form or stance for an answer its role
   doesn't need (a cat druid healing an ally a healer is already healing),
   or only when its role's concerns are quiet?
   **Decided 2026-11-06 (the agent's call, for the owner to curate):**
   only when its role's concerns are quiet, or when the party's healer
   seats are short or dry (625i: the others step in when the healer runs
   dry), and only when the trip comes out ahead; an answer that is the
   role's own duty (a tank's taunt from another stance) needs only to come
   out ahead. This follows "the role's duty first" (625c, 625i): a cat
   druid whose healer is healing keeps clawing.

## Decisions (2026-11-06)

The agent's calls while building step 2, for the owner to curate:
- **One price in damage and health**: the trip's gain and losses are all
  said in damage and health (strategems/everything-is-damage-and-health.md),
  so a heal, a taunt's saved health, rage and energy weigh on one scale.
- **The keep is per change, at most once in effect**: both the change out
  and the change back cut the resource to what is kept; nothing lowers it
  while away, so the result is the same as one cut on return.
- **Energy carries on while away** (the owner: "who can let their energy
  regenerate while casting a couple rejuvenations"): a form whose resource
  carries on is given a keep of its cap; one that starts afresh on entering
  a keep of 0. Which is the game's is read in step 1.
- **The talents' numbers are inputs**: the core reads only the form's
  mana and global cooldown from the generated ability table; Furor's gift,
  a stance's keep and Natural Shapeshifter's share are given by the caller
  until step 1 reads them from the game's talent tables.
