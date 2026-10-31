# 813 - Instant Attacks Count Attack Power by the Real Weapon Speed

## Status
- Created: 2026-10-30
- Phase: 8 (combat rules)
- Related: 625b (a buddy's weapon preference: the speed leans read this
  rule), 803 (monster accuracy level cap: another combat rule changed by
  a source patch)
- Priority: Medium
- State: built 2026-10-30 as a setting, off; waiting for the compile, then the owner names basic in C042 to turn it on

## Origin

Told on 2026-10-30 that some instant attacks count attack power at a
fixed speed per weapon kind, the owner, word for word: "that seems dumb
and wrong. We should use the actual weapon speed."

## Current Behavior

**Built 2026-10-30, waiting for the compile:** source patch B064 adds the
setting `Combat.InstantAttacks.RealWeaponSpeed` (0 by default: stock),
named in `WorldConfig.h`, read in `WorldConfig.cpp` beside `Daze.Enabled`,
documented in `worldserver.conf.dist`, and asked by the attack power
multiplier for a weapon (`Unit::GetAPMultiplier`): when it is 1, a request
for the fixed speed gets the real one. Its apply and revert were
round-tripped on copies of the four files. Settings patch C042 sets it to
1; its profiles line is "none" until the owner names basic there (built
and on are separate decisions). Every profile built from source-beta
carries the setting, off.

What stock does (below) is unchanged until the setting is 1:

Stock 3.3.5a, read in the server on 2026-10-30. A weapon attack's damage
is the weapon's own roll plus attack power ÷ 14 × a speed in seconds.
For plain swings and most abilities that speed is the weapon's real
speed. Abilities whose spell carries the "normalized weapon damage"
effect (effect type 121) use a fixed speed per weapon kind instead: 1.7
for daggers, 2.4 for other one-handers and fists, 3.3 for two-handers,
2.8 for ranged weapons (the server's attack power multiplier for a
weapon, asked for "normalized"). Read from Spell.dbc on 2026-10-30,
the player abilities with that effect: Mortal Strike, Overpower,
Whirlwind, Devastate (warrior); Sinister Strike, Backstab, Ambush,
Hemorrhage (rogue); Crusader Strike (paladin); Obliterate, Plague Strike
(death knight); Aimed Shot (hunter). The same fixed speed is used in two
places in the stat code that work out a weapon's damage range when asked
for the normalized kind.

## Intended Behavior

The real weapon speed everywhere: an ability that counts attack power
counts it by the speed of the weapon it strikes with, whatever kind of
weapon damage effect it has. A slow weapon's instant attacks hit
harder, a fast weapon's lighter, as its swings do.

What follows from it, to be seen in play (written down so it isn't a
surprise): instant attacks then lean to slow weapons more strongly than
in stock, for every class that uses them (the stock rule was made to
keep slow weapons from dominating instant attacks); dagger rogues'
Backstab and Ambush count attack power at a dagger's real speed (1.4 to
1.8) where stock counts 1.7, so it moves little for them; a slow
one-hander (2.6 to 2.8) gains over stock's 2.4; a two-hander of 3.6 or
3.8 gains over stock's 3.3. The buddies' weapon-speed leans (625b) read
the rule as built: with this on, the normalized kind leans slow as the
plain kind does.

Behind a switch that starts off, as every new behaviour (the design
target): a source patch on the profiles that take it, basic first.

## Suggested Implementation Steps

1. A source patch (a B-patch in the house's apply/unapply style) at the
   server's attack power multiplier for a weapon: when asked for the
   normalized speed, return the real attack time instead, as it does for
   creatures. One change covers the spell damage and both stat-code uses.
2. Its header: profiles basic (or none until the owner turns it on),
   with its priority; `scripts/check-patch-headers --fix-lines` and
   `scripts/generate-patch-lists` after.
3. A test: the patch applies and unapplies cleanly on the source tree;
   in game, a Mortal Strike with a 3.8 two-hander and one with a 3.3
   two-hander of the same damage per second and the same attack power
   (the first hits harder by attack power ÷ 14 × 0.5).
4. 625b's speed leans: the normalized kind leans like the plain kind
   where this patch is on.

## Upstream

The owner, 2026-10-30, word for word: "the weapon swing thing for weapon
attacks might be a viable candidate for upstream contribution btw."
AzerothCore aims to play as 3.3.5a did, and the fixed speed is how
3.3.5a played, so a change of the default would likely be refused there;
an off-by-default `worldserver.conf` setting (for example
`Rate.NormalizedWeaponSpeed.UseReal = 0`) is the shape most likely to be
taken. Built that way here too, the patch and the contribution are the
same code: the B-patch adds the setting and its check, and basic's
config patch turns it on.

**Slow weapons already won in 3.3.5a, where this rule doesn't reach.**
The owner, 2026-10-30, word for word: "okay but that's not how 3.3.5a
was, I remember getting a slower weapon and dealing more damage with it
than a faster weapon on my ret paladin with Seal of Command procs.
Though Seal of Command was changed towards the end of Wrath I think. Can
you tell me when it switched to the cleave mechanic?" Both are true:
the fixed speed reaches only the abilities listed above. Read from
Spell.dbc and the proc table on 2026-10-30: 3.3.5a's Seal of Command
procs on every melee hit (chance 100, no procs-per-minute rate) for 36%
of weapon damage by the plain weapon-percent effect, at the real speed,
striking up to 2 more targets; Divine Storm is the plain kind too
(110% weapon damage). Of a Retribution paladin's attacks only Crusader
Strike is normalized, so a slow two-hander won. The history (warcraft
wiki): patch 3.2.0 (2009-08-04) made Seal of Command 36% weapon damage
on every swing; 3.2.2 (2009-09-22) made it chain to 2 more targets only
when the attack that triggered it strikes a single target. Before 3.2.0
it was a chance per hit.

## Open Questions

1. Every player on basic, or only buddies (and other bots)? Written as
   every player. **Answered 2026-10-30:** "everyone."
2. Offer it upstream as an off-by-default setting (above), once it has
   been played on basic? **Answered 2026-10-30:** "obviously once we've
   tested it and make it rockhard and bulletproof."
