# 1101a - Family Enrollment and Staying in the World

## Status
- Created: 2026-08-01
- Parent: Issue 1101 (Bellwether — attended play)
- Phase: 11
- Priority: High (nothing downstream exists without a family in the world)
- Depends on: mod-playerbots altbot support

## Overview

Defines who is in a player's family, how they get there, and the hard
part: keeping them in the world while the attending player isn't
playing.

## Current Behavior

A player creates characters on their account. To hand one to bot
control they type `.playerbots bot add <name>` — or `.playerbots bot
addaccount <accountname>` for the whole account at once — from a
character that is logged in. The bots join as **altbots**: player-made
characters under bot control, distinct from **rndbots**, which are
generated from `.conf` settings and self-manage.

The distinction matters here:

| | Altbots | Rndbots |
|---|---|---|
| Origin | characters the player made | generated from config |
| Gear | manual (`autogear`, `maintenance`) | automatic on level-up |
| Talents | manual | automatic |
| Roaming | none — they follow or idle | autonomous world roaming |
| Guidance | **means something** | ignored in favour of self-management |

There is no concept of a persistent *family*. There is a party, which
dissolves. There is no record that these five characters belong to this
player as a set, and no record of which of them are currently enrolled.

## Intended Behavior

### The roster

A family is a named, persistent set of the player's characters. It
survives logout, restarts, and profile switches. Minimum record per
member:

| Field | Type | Meaning |
|-------|------|---------|
| `owner_account` | int | who attends this family |
| `family_name` | string | a player-chosen name for the set |
| `ward_guid` | int | the character |
| `enrolled` | bool | currently under bot control for attendance |
| `joined_at` | timestamp | when this character became a ward |
| `standing_order` | text | last guidance that stuck (see 1101l) |

Stored in the characters database of the active profile. The
`standing_order` column is here rather than in a separate table because
it is per-ward and read on every enrollment.

### Enrollment

Enrolling a family is the altbot commands above, driven from the roster
rather than typed one name at a time. Enroll all, enroll a subset, drop
one. The mechanism is upstream's; what this adds is that it's a set with
a name, and that it can be re-established without the player retyping it.

### The anchor is a ward — resolved, 2026-08-01

User directive: *you'll be playing your own characters. They'll just act
using playerbots AI.*

So there is no headless-session problem to solve, and no character
parked in an inn doing nothing to justify. The player is logged in and
playing. What changed is that their character drives itself.

The mechanism is already in the tree — `playerbots.conf.dist`:

```
# Player can be activated as a bot (selfbot)
# Selfbot permission level (0 = disabled, 1 = GM only (default),
#                           2 = all players, 3 = activate on login)
AiPlayerbot.SelfBotLevel = 1
```

Level 2 lets any player hand their own character to bot AI on demand.
Level 3 does it on login, which is the attended default: you log in and
your character is already going. Which level ships is a config-patch
decision under `config/patches/C*.sh`, gated per profile like the rest.

That makes the family uniform. The character the player is logged in on
is not special — it is a ward, running the same AI, taking the same
guidance, appearing in the same view.

And the wards are not each other's dependents. Per the parent: *each a
single connection, collected into a single view for the user.*
mod-playerbots already gives every bot its own world session, so the
connections are genuinely separate; the family is the view assembled
over them, not a party and not a leader with a train. No ward is
structurally load-bearing for the others.

What remains to be **verified rather than assumed** is what upstream
actually does to those sessions when the human's own character logs out.
Whether they persist, drop, or drop after a timeout is a behaviour of
the module, not a decision this issue gets to make, and it changes what
the session lifecycle in 1101n has to handle. Test it early; the answer
is cheap to get and expensive to guess wrong.

Two paths are closed rather than deferred:

- **A headless session holder** — a server-side owner keeping altbots
  logged in with no player present. Declined. It was only ever needed to
  serve a framing the directive above replaces, and it would have cost a
  patch against playerbot internals plus a new way for bots to outlive
  their cleanup.
- **Enrolling the family as rndbots** — declined. Rndbots self-manage
  and would override guidance, which removes the point. Recorded so
  nobody re-proposes it.

### Taking the wheel back

Because the player is present, control is a dial rather than a state.
Selfbot AI can be switched off for the character they're looking at and
left on for the rest. Guidance keeps applying to the wards; the one in
their hands takes input.

This is the common case, not an edge: a player fights the fight in front
of them and lets the other four get on with it. The roster's `enrolled`
flag is what tracks it per ward.

### Lifecycle

Explicit answers required for:

- Player enrolls, then logs the anchor out → family unenrolls cleanly,
  standing orders persist, session ends (1101n)
- Worldserver restarts mid-session → family re-enrolls on next anchor
  login, or doesn't, and the player is told which
- A ward dies while attended → parent's open question; 1101f raises the
  alarm regardless
- A ward levels past the profile cap → still a ward, nothing special
- Player enrolls a character that's already someone else's ward →
  refused, with a message naming the other family

## Implementation Steps

1. Create the roster table in the active profile's characters database.
   Schema above. Migration ships as a patch under the E-patch install
   step, per the patch system.
2. ALE-side roster module: create family, add ward, remove ward, list,
   set enrolled state. Reads and writes the table; no bot commands yet.
3. Enrollment driver: for each enrolled ward, issue the altbot add the
   same way the console command does. Establish whether this is
   reachable from ALE directly or needs a binding on the 916b shim.
4. Set the selfbot permission level as a config patch under
   `config/patches/`, gated per profile. Confirm the player's own
   character takes bot AI, and that it can be handed back.
5. **Verify the logout behaviour before designing around it.** Enroll
   three wards, log the human's character out, and observe what happens
   to the other two sessions — persist, drop immediately, drop after a
   timeout. Write the answer down here; 1101n's session lifecycle is
   built on top of it.
6. Unenrollment on logout, and re-enrollment on login, both driven from
   the roster rather than from memory.
7. Refuse double-enrollment across families.
8. Per-ward take-the-wheel-back: switch selfbot AI off for one character
   without disturbing the others or their standing orders.
9. Test: enroll three, log out, log back in, confirm all three return
   with their standing orders intact; kill the worldserver mid-session
   and confirm the family state on restart is either fully restored or
   clearly reported as not.

## Files to Create

- Roster table migration (E-patch step)
- ALE Lua roster module
- Console commands for roster management, or a section of 1101n's
  `.bell` command set

## Open Questions

- Does `.playerbots bot add` work when issued programmatically from ALE,
  or does it need a binding through the 916b C++ shim? This decides
  whether 1101a depends on 916b or is independent of it.
- Is a family per account, or per player-who-may-have-several? The table
  above assumes per-account, which forbids a player running two families
  at once. Is that right?
- Cross-account families via `AiPlayerbot.AllowTrustedAccountBots` and
  `.playerbots account link` — in scope, or a later issue? Two people
  attending one family is a genuinely different social object.
- How many wards is the ceiling, and is it a config value or a
  consequence of the salience budget in 1101d?
- ~~Selfbot permission level 2 or 3?~~ **Not a gate.** Level 3 starts a
  session already going and makes driving the deliberate act; level 2 is
  the reverse. It is one config value, flipped in a config patch,
  observable in a minute of play. Ship level 3, and if starting already
  in motion feels wrong, flip it and record the change in
  `docs/balance-updates.md` with the reason — this is knob-turning, not
  design.
- When the human's character logs out, what happens to the other wards'
  sessions? Upstream behaviour, verified in step 5 rather than decided
  here — but the answer shapes 1101n, because "your family kept playing
  while you were logged out" and "your family stopped" are different
  products.

## Related

- Parent: [1101 - Bellwether](1101-bellwether-attended-play.md)
- [1101n - Session lifecycle](1101n-session-lifecycle-and-observability.md)
  — enrollment is the first half of a session start
- [1101l - Guidance and standing orders](1101l-guidance-capture-and-standing-orders.md)
  — owns the `standing_order` column's contents
- [916b - ALE bindings for playerbots](916b-ale-bindings-playerbots.md)
  — the existing shim, and the likely home for any binding this needs
- `docs/playerbots/Playerbot-Commands.md` — altbot vs rndbot, the add /
  addaccount / remove commands, and the account-linking section
</content>
