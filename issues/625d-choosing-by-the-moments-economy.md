# 625d - Choosing an Answer by the Moment's Economy

## Status
- Created: 2026-10-29
- Phase: 6
- Parent: 625 (buddies favour the abilities their talents touch)
- Blocked by: 625a (the talent weights), 625c (the list it draws from)
- Related: 625e (what each fight taught), 627 (the bots think only when something happens), 617e5b (boss
  fights by the warnings: when a fight makes everyone move), 617c5 (party
  buffs shared out)
- Priority: High
- State: planned

## Origin

The owner, 2026-10-29, asked whether the draw among a concern's answers
should lean on how badly hurt an ally is, word for word:

> when they're very low, we want fast heals. When they are slightly
> injured, we want cheap heals. a HoT is usually cheap in the action
> economy, but overheals are expensive in mana economy. the more concerns
> we have, the more important action economy is - the less mana we have,
> the more important mana economy is. more mp5 (from spirit or mp5) means
> mana economy is devalued and action economy is told to be extravagant.
> movement requirements mean we have to use things that are mobile
> friendly, and if those are common in this fight then we try and do the
> cast-time static abilities when we don't have to move at higher
> priority so we can save the instant ones for the movement intensive
> periods. Oh and cooldowns should try and coincide with other cooldowns
> or procs / buffs that make us feel empowered. "cast bloodlust? Thanks,
> I'll go all in" etc.

And, asked whether "can't be used right now" covers "rejuvenation is
still active, shouldn't cast again now": it does, already (below).

## Current Behavior

Not built. What the bot module already gives (read 2026-10-29):
- A heal-over-time already on the target is skipped until it is about to
  end: a heal's usefulness check asks whether the caster's own aura is on
  the target and below its refresh time (`CastAuraSpellAction::isUseful`).
- Each heal carries a rough size (`estAmount`, a percent of health) and a
  mana-efficiency label (very low to very high: Rejuvenation is very
  high).
- One mana rule: below 60% mana (`AiPlayerbot.SaveManaThreshold`), the
  healer-saves-mana multiplier zeroes heals that would mostly overheal or
  are inefficient. It is a switch, on or off at a line, not a weight that
  grows as mana falls.
- Nothing weighs speed, movement, or cooldowns lined up with buffs.

## Intended Behavior

Among the answers one concern offers (625c's list), each answer's chance
is its talent weight (625) times how well it suits the moment, read from
five measures. Each measure is a number from the buddy's own state, kept
in one place with its reason, so it can be tuned by feel.

1. **Urgency: fast when very low, cheap when slightly hurt.** The lower
   the target's health, the more an answer's speed counts (its cast time
   plus the global cooldown: instant and short casts first); the higher,
   the more its cost counts.
2. **Action economy: how much is going on.** The more concerns firing at
   once (several allies hurt, enemies close, threat), the more each second
   of casting is worth, so fast answers and heals that keep working on
   their own (heals over time) count for more.
3. **Mana economy: how much is left, and how fast it comes back.** The
   less mana, the more cost and overheal count: a heal larger than the
   health missing wastes the difference. Regeneration (spirit and mana
   per 5 seconds, from gear and buffs) shrinks that weight: a buddy that
   refills fast is told to be extravagant, and leans on action economy.
   **Never overheal below 90% mana** (the owner, 2026-10-29: "bots should
   emphasize never overhealing unless they're at 90% or above mana"): an
   answer whose expected heal is larger than the health missing is
   refused below 90% mana, and allowed above it.
   **Healing ahead of the damage** (the owner: "HoTs can be placed on
   things expecting damage soon, like if they take aggro, and you can
   pre-cast some spells if the tank is charging, like to proc earthliving
   or to get the Regrowth HoT up and running."): an ally about to be hit
   counts as hurt for heals over time: one who has just taken aggro, a
   tank charging in. A healer may begin a cast as the tank charges, so a
   heal over time is running, or Earthliving is ready to proc, when the
   first blows land. These are not overheals: they are spent on damage
   about to come.
4. **Movement.** While moving, only instant answers can be used (the
   module already refuses a cast while moving). Across the fight, the
   buddy keeps how much of the recent time it has had to move: in a
   fight full of movement, cast-time answers are raised while standing
   still, so the instants are saved for the moving stretches. The measure
   starts again at each phase change (the owner, 2026-10-29: "should
   reset when the phase changes"), and what each fight's phases asked is
   written down to be read later (625e).
5. **Empowered moments.** Cooldowns (Nature's Swiftness, Innervate,
   trinkets, racial abilities) wait for a moment that multiplies them:
   Bloodlust or Heroism, a haste or power buff from an ally, a proc, or
   another cooldown of its own. "cast bloodlust? Thanks, I'll go all
   in": while one is up, cooldowns count for much more, and the buddy
   spends them together. A cooldown is not held so long that it is never
   used: past a fight's middle, or in a critical concern, it is used
   anyway.
   **A plan for the fight** (the owner, 2026-10-29, word for word: "if a
   boss has a weak phase, use cooldowns there - make a plan for the fight
   in their rough general schedule in their head, and make sure that
   their CDs can coincide. Then after that, try and get as many uses of
   it as they can. Typically, a party will bloodlust at the start after
   the tank has got everything settled, unless there's a specific weak
   phase. This is so that the cooldowns from the bloodlust phase might
   have a chance to come off cooldown by the end of the fight, enabling
   another sprint toward the end."). Each buddy keeps a rough schedule of
   the fight: Bloodlust at the start once the tank has the enemies
   settled, unless the boss has a weak phase, in which case there; its
   own cooldowns lined up with it; then as many more uses as the fight's
   length allows, timed so they come back for a sprint at the end.
   **A weak phase is learned, not looked up** (the owner, 2026-10-30,
   word for word: "we are going to build custom bosses eventually so we
   should build a system that learns. I think it's okay if the bots all
   learn at once, together, and remember. Then we can cache it and
   eventually turn off the system that learns for that specific boss
   once we really have it nailed down. The idea being that it would do so
   automatically."). What a boss's weak phase is comes from what earlier
   fights taught (625e), not from a hand-written table, so a custom boss
   needs nothing written for it. The learning is shared: every buddy that
   fights a boss adds to one memory of that boss, and every buddy reads
   it. When a boss's memory is settled it is cached as that boss's plan,
   and the learning for that boss is switched off; the plan is then read,
   not relearned. **Switched off by hand** (the owner, 2026-10-30, word
   for word: "we will turn it off manually when we've tested every boss
   thoroughly."): the learning runs on its own, but nothing decides by
   itself that a boss is learned; each boss's learning has its own
   switch, turned off by the owner once that boss is tested thoroughly.
   If what makes up a fight changes, its plan is rebuilt from scratch
   (625e, the boss's fingerprint).

The same five measures serve damage and tanking answers: a damage
buddy's urgency is a target about to die or a crowd to strike, its mana
the same, its movement the same, its empowered moments the same.

## Suggested Implementation Steps

1. The measures as plain arithmetic in the buddy module's pure core (no
   server code): from a target's health, the concerns firing, mana and
   regeneration, the share of recent time spent moving, and the buffs
   up, a weight for each answer (from its cast time, cost, size, and
   whether it is a cooldown). Each measure's numbers in one place.
2. Its offline test, by cases: a druid with an ally at 20% casts mostly
   fast answers; at 80%, mostly cheap ones; out of mana, no overheals;
   with high regeneration, mana barely weighs; in a moving fight,
   standing still, cast-time answers first; Bloodlust up, cooldowns used.
3. The multiplier (625) reading the measures for the answer it is asked
   about, within one concern's band.
4. Watched in game on the army of 64 (617e17) in a test scene, and
   described by feel, as the movement is (617e16).

## Open Questions

1. A buddy's empowered moments: only buffs that make its own answers
   stronger or faster, or any big moment in the fight? **Answered
   2026-10-29:** a boss's weak phase counts, and the buddy plans the fight
   around it (above).
2. How far back "this fight's movement" looks? **Answered 2026-10-29:**
   it starts again at each phase change, and is written down (625e).
3. How does a buddy know a boss's weak phase before the fight: from the
   boss warnings' own tables (617e5b), from what earlier fights taught
   (625e), or both? **Answered 2026-10-30:** learned from earlier fights,
   by all buddies together, cached and the learning turned off per boss
   once settled, automatically (above, word for word).
4. What counts as "settled", so a boss's learning turns itself off: the
   same weak phase found in the last N fights, the plan's timings moving
   less than some amount, or a number of fights? And can the owner turn
   a boss's learning back on (a boss changed, a buff to buddies)?
   **Answered 2026-10-30:** "we will turn it off manually when we've
   tested every boss thoroughly." A switch per boss, by hand; a changed
   fight is relearned from scratch (625e).
