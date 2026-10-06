# 719 - True Ability Tooltips

## Status
- Created: 2026-10-04
- Phase: 7
- Priority: Medium
- Related: `docs/roadmap.md` project-wide decisions (no AIO; no required
  addons, 2026-09-25), 155y (the first optional client addon,
  `src/client-addons/EverlandNoMap/`), 916o (the custom client), 155k1
  (stamina rescale: more numbers the stock client can't show)

## Origin

Verbatim, 2026-10-04:

> can we make an issue file for an AIO addon or something similar? I want
> to expose a value from the server to the client, specifically, the
> spellpower / attackpower etc adjusted tooltip values for abilities and
> such.

## Current Behavior

Not built. An ability's tooltip is written by the game client from its own
data files: the spell's base numbers, with some tooltips adding the
character's spell or attack power by the client's own rules. Whatever the
server does differently is invisible there: custom spells and classes,
changed coefficients, rescaled items (155k, 155k1), talents and auras the
client doesn't model. The project has decided not to use AIO (the
server-sent interface framework) and that no feature may depend on an
installed addon until the project ships its own client.

## Intended Behavior

The server knows each ability's real numbers for this character right
now, and an optional addon shows them in the ability's tooltip. Nothing
depends on the addon: without it the stock tooltip shows as always, which
keeps within the 2026-09-25 rules ("something similar" to AIO, without
AIO and without being required).

**On the server** (C++, a module: the Lua engine can't reach the server's
bonus calculations): for every spell the character knows with a damage,
healing or absorb effect, the effect's number after everything the server
applies when it is cast: base points for the rank and level, the
character's spell power or attack power times the spell's coefficient,
talents, auras and other modifiers (the server's own "bonus done"
calculations, with no target, so a target's own resistances and modifiers
are left out and said to be). One record per effect:

| Field | Type | Meaning |
|---|---|---|
| spell | integer | spell id |
| effect | integer | effect index 0-2 |
| kind | integer | 1 damage, 2 healing, 3 absorb |
| low, high | integers | the range after bonuses |
| per_tick | integer | for periodic effects, per tick (0 otherwise) |
| ticks | integer | number of ticks (0 for direct) |
| cooldown, duration | integers | milliseconds, as the server applies them |
| cost | integer | the power cost, as the server applies it |

**Carried** over the client's addon-message channel (a fixed prefix,
whispered by the server to the character only; at most 255 bytes per
message, so records are packed several to a message and split across
messages), sent at login and again, at most once a second, when something
that changes them changes: equipment, auras, level, talents, a new spell.
Only the records that changed are re-sent.

**Shown** by an optional addon (`src/client-addons/`, like 155y's, offered
on the website): it keeps the latest records and, when the game draws a
spell's tooltip, adds one line per effect under the stock text, e.g.
"Everland: 412 to 480 Fire damage" (the character's own number only).
The stock
description is left as it is: the addon sees only the finished text, not
the client's placeholders, so replacing numbers inside it would be
guesswork.

## Suggested Implementation Steps

1. Server: the per-spell calculation for the character, with a console
   command that prints a character's records, checked against casts in
   game (a spell's real hits fall inside the range).
2. Server: the packing, the sending on login and on change, the
   once-a-second limit.
3. Addon: receive and keep the records; the tooltip line.
4. A test of the packing (records -> messages -> records, every split).

### Answers, 2026-10-04 (Ritz)

- The original number is not shown: "nope ignore the original number,
  just the calculated one. We want to prove the value of resistances on
  foes, and switching your attack patterns to address them. Armor values
  too. Also Resilience A+ GOLD STAR". The line shows the character's own
  number only ("Everland: 412 to 480 Fire damage"); base_low/base_high are
  dropped from the record.
- Cooldowns, durations and costs as the server has them: "yes", in the
  same records.
- No estimate against the target: "all you have to do is cast the spell
  and see what the number is in order to know the target's resistance.
  It's kinda better that way actually." The difference between the
  tooltip and the hit is the target's armour or resistance, for the player
  to read.
- Abilities only, no items: "Abilities only need be compared against each
  other, while stats have to be measured and balanced."

## Open Questions

1. Resilience: the gold star noted; does resilience belong in this issue
   (it lowers what the player takes, not what an ability deals), or in a
   separate one about showing a player's defences?
