# 170 - Sparring Grounds at Orgrimmar and Stormwind

## Status
- Created: 2026-10-04
- Phase: 1
- Profile: basic
- Blocked by: 169 (nearby duels, 20% end), 617t (stand-ins)
- Priority: Low

## Origin

Verbatim, 2026-10-04:

> Also there should be at least 15 stand-ins always fighting at all times
> in front of Orgrimmar and Stormwind - they are always on alert,
> practicing and recovering and staying fit and strong. They are from a
> variety of different levels, and every 15 duels +/- 1 they go to the
> side and sit down next to a fire for a while. Also, duels end at 20%
> health on this server. Basically everytime they lose a fight, they go
> sit on the side until they recover. Also, we should make campfires
> stack, so they can boost each other's regeneration if they sit near each
> other.

## Current Behavior

Not built.

## Intended Behavior

- **At least 15 stand-ins** (617t's kept ones, of many levels) duel in
  front of Orgrimmar's and Stormwind's gates at all times.
- **Tapping out** (owner, 2026-10-04: "every fifteenish duels they tap out
  with another person who came to watch on at their 14ish'th duel. They'd
  stand by the side, and when the 15th duel came around they'd replace
  them in the fight. which, by the way, is a better way to guard
  places."): around a fighter's 14th duel (plus or minus one), a fresh
  stand-in comes to watch from the side; at the 15th it takes the
  fighter's place. The fighter then walks off to an inn or a resting spot
  (a buddy bed, 617e4), lies down, and after 30-45 seconds leaves the
  world, kept in the database for its next job (owner, 2026-10-04:
  "instead of resting by the fire ... walk to an inn or resting spot ...
  and goes to sleep. They'll despawn after 30-45 seconds. Stored in the
  database for the next task they're job is. That way, we maintain the
  same amount."). Every loss
  (169: out at 20%) also sends a fighter to rest until full health. The
  same relay is the model for guards at any post.
- **Fires stack, everywhere** (owner, 2026-10-04: "+1 spirit per campfire
  for each campfire within 20 yards. So 5 campfires gives 5 spirit per
  campfire, for a total of 25 spirit."): with n campfires within 20
  yards, each gives n spirit, n x n in all (5 fires: 25). Fires within a
  couple of yards of each other count as one (the one nearest the middle
  of the others). All campfires, not only these.
  The ceiling ("They can't overlap so the max is probably 3*20 squared or
  something? Sorry math is hard"): fires at least 2 yards apart packed
  into a 20-yard circle fit about 1,257 square yards / 3.5 square yards a
  fire = about 360 fires, so n x n would reach about 130,000 spirit; at 3
  yards apart about 160 fires, about 26,000. Without a cap, enough fires
  make spirit unlimited (open question 4).

## Suggested Implementation Steps

1. Two sparring spots and their resting sides (fires placed by hand,
   saved like the buddy beds).
2. The sparring loop: pairs, the duel count, the rest, the return.
3. The stacking fires (a regeneration effect per fire in range, added).

## Open Questions

1. (Answered 2026-10-04) +1 spirit per campfire within 20 yards; of
   overlapping fires, one counts (the one nearest the others' middle).
2. (Answered 2026-10-04) All campfires.
3. (Answered 2026-10-04) Overlapping: within 3 yards ("How about 3 yards
   apart?"). At 3 yards about 160 fires fit in a 20-yard circle, so n x n
   could still reach about 26,000 spirit with that many fires.
4. (Answered 2026-10-04) The cap: "the nearest 6 campfires can count. Or
   rather, it stacks to 6": at most 6 fires count, so at most 6 x 6 = 36
   spirit. Also: "it only takes effect outside of combat, and only near a
   duel, to counteract the extra damage from monsters." And the owner's
   worry, put back to them: "I don't want players lighting so many fires!
   ... What do you think?" (the answer of 2026-10-04 proposes counting at
   most one fire per person who lit it).
5. (Answered 2026-10-04) One fire per person, by dousing: "when you light a
   fire, if there's another fire of yours then it douses that one and
   lights the new one. They should last until you move more than their
   buff radius away." Each character has at most one fire; lighting
   another puts the first out; a fire goes out when its maker moves more
   than 20 yards (its reach) from it.
   (Proposed 2026-10-04; the spacing figures that led to the cap: at 3
   yards about 160 fires fit in 20 yards, 4 yards about 90, 5 about 58, 6
   about 40.)
