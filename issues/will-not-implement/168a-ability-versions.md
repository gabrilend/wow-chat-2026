# 168a - Ability Versions, Chosen at Chromie

## Status
- Created: 2026-10-27
- Phase: 1
- Parent: 168 (Chromie, keeper of settings)
- Related: 1101 (the advanced profile, where most old versions belong),
  `docs/profiles/advanced-ability-versions.md` (the abilities that changed)
- Priority: Low
- State: will not implement (2026-10-27), for now: the advanced profile
  takes its place

## Origin

The owner, 2026-10-27:

> can we add an option to Chromie to enable us to switch to a different
> version of a spell or talent that got overhauled? This one is a doozy but
> I kinda miss the old TBC version of Seal of Command? Gah maybe I just want
> to play on a TBC server... But, I think it'd be neat if I could play with
> both options? But only one at a time. Blizzard didn't just change them for
> balance, but also for class identity.

## Current Behavior

**Will not implement, for now.** The owner, 2026-10-27: "I think this
system is replaced by the Advanced profile. For now at least." The old
forms come as the advanced profile's own abilities (1101), not as a choice
at Chromie; this file is kept in case the choice is wanted again.


Each ability exists in its 3.3.5 form only. Chromie (168) is planned as the
place a player changes server behaviours; nothing of hers is built.

## Intended Behavior

- **A choice per overhauled ability**, at Chromie: its 3.3.5 form, or an
  older one (its TBC form first). One at a time, per character: choosing
  one replaces the other in the spellbook, on the action bars, and in the
  talent it belongs to.
- **Built as a second spell, not a switch inside one**: the older form is
  its own spell (a row in `spell_dbc` cloned from the 3.3.5 one, with the
  old effects), so the server's spell code runs it unchanged and each form
  can be tested on its own. The character learns one and forgets the other.
- **Which abilities**: the list in
  `docs/profiles/advanced-ability-versions.md`; Seal of Command first (the
  owner's ask).
- **Not for buddies at first**: a buddy keeps its class's current form
  (the bot module knows those), until a strategy for the old form is written.

## Suggested Implementation Steps

1. Seal of Command's TBC form as a spell of its own (its effects read from
   a TBC-era description, written as `spell_dbc` rows; a quick test that the
   row loads with the file's column count, as `scripts/lib/spell-data.lua`
   checks).
2. Chromie's menu entry: "the old Seal of Command / the new one", the swap
   (learn one, forget the other, the action bar button moved).
3. The rest of the list, one ability at a time, each with its test.

## Open Questions

Both set aside with the issue (2026-10-27).

1. Only on the advanced profile (1101), or on basic too?
2. Talents that changed shape (a talent whose rank does something else):
   one choice for the talent, or per rank?
