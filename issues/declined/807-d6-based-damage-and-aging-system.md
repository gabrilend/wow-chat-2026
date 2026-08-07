# 807 - D6-Based Damage & Aging System — DECLINED

## Status
- Created: 2026-07-16 (from the `notes/d6-vision` design note)
- **Decision: Declined 2026-07-16 — will not implement.** A wholesale
  re-derivation of the damage/HP/stat math (dice-based rolls, reworked
  stat curves, aging-driven de-leveling) diverges too far from the WotLK
  combat base the server is built on, and from the current vanilla
  direction. Recorded here so the idea is preserved and reconsiderable,
  not lost. Revisit only if the project ever forks combat math wholesale.
- Phase: 8 (Endgame — progression has stakes)
- Priority: N/A (declined)
- Source: recategorized here from the old `notes/d6-vision` (not deleted — moved
  home; the raw note is preserved verbatim in the appendix below)

## Mechanism (recorded for future reference)

The proposal replaces continuous damage/HP numbers with a dice-normalized
system layered on top of the existing stat curves:

- **Weapons normalize to 1d5**, where a rolled **1 is an automatic miss**.
  The distribution is deliberately miss-favored ("always in favor of miss,
  never the max").
- **Damage is quantized to increments of 10** — achieved not by rewriting
  the combat engine but by **re-scaling the strength / intellect /
  spell-power (etc.) stat curves** so their contributions land on those
  steps. The final step is 15 rather than 10 because a **5-damage floor**
  applies to every landed hit.
- **Gear provides power** and the character **improves hour-by-hour**;
  difficulty slowly eases as you outgrow it, up to a point where "nothing
  can stand against you."
- **Aging → measured de-leveling.** Continuing to earn experience ages the
  character and degrades stats over time; avoiding XP-granting experiences
  ("just do the boring fundamentals") avoids degradation. Progression and
  decay are two sides of the same clock.
- **Agility and intellect grant bonuses too**, weighted toward the bonus
  side, with the d6 randomization developed in increments of 10 (1d6 with
  the 1s dropped as misses). Values **round down** — "the pursuit is the
  challenge of the hunt."

## Problem

WotLK combat is continuous and gear-curve driven; damage and mitigation
scale smoothly. The vision asks a different question: what if combat felt
like dice — legible, quantized, miss-prone — and what if progression were
not monotonic but a tide (grow strong, then age and soften), so that when
to *stop* earning XP becomes a real choice?

## Intended Behavior

If ever built: weapon swings roll 1d5 (1 = miss); stat curves are retuned
so damage lands on 10-step increments with a 5 floor (top step 15); gear
is the primary power source; characters strengthen over play then de-level
through an aging process tied to XP intake; agility/int add miss-favored,
round-down bonuses. The original phrasing is in the appendix below.

## Why declined (not deferred)

This is a combat-math replacement, not a knob. It would touch damage,
mitigation, stat scaling, XP, and a new aging subsystem simultaneously —
a parallel ruleset to WotLK's, with its own balance surface. The project's
current shape (vanilla profile on the WotLK base, level bands, playerbot
ambient world) doesn't call for it, and the maintenance/verification cost
of a second combat model isn't justified by the current goals. The vision
is preserved intact in the appendix below; declining is a direction choice,
not a judgment on the idea.

## Appendix — original vision note (verbatim)

Recategorized here from `notes/d6-vision` on 2026-07-16. Kept word-for-word so
the origin voice survives the move.

> what if we made the damage and hp totals use a d6 system? we could normalize all
> the weapons to 1d5 damage, with the 1 being an automatic miss. then, if we try
> to only give out increments of 10, (with the last one being 15 because there's a
> minimum of 5 damage dealt on every hit) which we can do by modifying the scaling
> values of the strength, intellect, spell-power, etc curves. I like the idea of
> gear providing power, and I like the idea of a character improving hour-by-hour,
> also the slow worsening of difficulties until you get to the stage where nothing
> can stand against you. Then, you de-level according to the aging process,
> undergoing measured degradation. Don't want to degrade? then don't do
> experiences that give experience points. just do the boring fundamentals. these
> are the advices given to a mental institution student, granted passage to only
> by the most educated of mystics. are you strange and mystering? then the OSC can
> help you dream by guide you.
>
> also, agility and int should give bonuses too. more weighted toward the bonuses,
> with the d6 system randomization being developed in increments of 10, 1d6 with
> the 1s dropped as misses. always in favor of miss, never the max. round down,
> because the pursuit is the challenge of the hunt.
