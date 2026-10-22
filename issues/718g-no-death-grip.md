# 718g - No Death Grip: Another Class's Taunt in Its Place

## Status
- Created: 2026-10-22
- Phase: 7
- Parent: 718 (death knight sacrifice and open Acherus)
- Related: 718d (death knight talents), 718a (allegiance after the story:
  a death knight's master could pick its taunt), playerbots (bot death
  knights use Death Grip in their tank and pull logic)
- Priority: Low
- State: planned; open questions first
- First profile: basic

## Origin

Verbatim, 2026-10-22:

> also can we remove death-grip from the game and replace it with one of
> the other taunt abilities, chosen at random or maybe based on race?

Then, the same day, on the choice:

> okay actually how about... taunt for Alliance, Growl for Horde? Does
> Growl require bear form? If so, then taunt for both, /sigh

Growl does need Bear Form (or Dire Bear Form), so: Taunt for both. Taunt
in turn needs Defensive Stance (open question 2, rewritten).

## Current Behavior

A death knight knows Death Grip (spell 49576: pulls the target to it and
taunts it) from creation; no trainer teaches it (the trainers teach only
Dark Command, the death knight's own taunt, 56222). Its script is the
core's (`spell_dk.cpp`, Death Grip). Bot death knights (and any death
knight buddy) use it in their tank and pull logic.

Other classes' single-target taunts, and what each needs (Spell.dbc, to
be confirmed in game):

| Spell              | Id    | Class   | Needs                         |
|--------------------|------:|---------|-------------------------------|
| Taunt              |   355 | warrior | Defensive Stance              |
| Growl              |  6795 | druid   | Bear Form                     |
| Hand of Reckoning  | 62124 | paladin | nothing; 30 yards             |
| Righteous Defense  | 31789 | paladin | nothing; taunts what attacks a friendly target |
| Mocking Blow       |   694 | warrior | Battle or Defensive Stance    |

A death knight has no stances or forms, so as they stand only Hand of
Reckoning and Righteous Defense would work for it; Taunt, Growl and
Mocking Blow would need their stance or form requirement lifted (a
spell-data change on the server, which the client may still grey out).

## Intended Behavior

No death knight knows Death Grip. In its place every death knight knows
the warrior's Taunt (decided 2026-10-22), usable without a stance (open
question 2). A death knight made before
the change loses Death Grip and gets its replacement at its next login.
Bot death knights use the replacement where they used Death Grip.

## Suggested Implementation Steps

1. Answer the open questions.
2. Find exactly how Death Grip is learned (likely with the death knight's
   class skill line at creation, `playercreateinfo_skills` and the
   client's SkillLineAbility.dbc), and stop that one spell from being
   learned (a Lua login and level-up check that removes it is the
   fallback-free minimum; a source patch at the learning point is the
   tidy one).
3. The choice: a characters-database row per death knight (its taunt),
   written the first time it is chosen; the spell taught at login if
   missing.
4. Stance or form requirements, if a taunt that has one is allowed: a
   world-database spell change (`spell_dbc` overrides) with its revert.
5. Bots: the playerbots death knight strategy's Death Grip actions,
   pointed at the replacement (a source patch).
6. Tests: a new death knight has no Death Grip and has its taunt; relog,
   same taunt; an old death knight converted at login; a bot death knight
   taunts with it.

## Open Questions

1. (Answered 2026-10-22: Taunt, for every death knight, Alliance and
   Horde alike.)
2. **Which spell.** Then the owner: "oh we need something that doesn't
   require defensive stance. Options? Maybe an NPC ability?" Every taunt
   in the client's Spell.dbc that needs no stance or form (read
   2026-10-22; "family" is the class whose spells it is filed with, 0 none):

   | Id    | Name              | Filed with | Notes                                  |
   |------:|-------------------|------------|----------------------------------------|
   | 37486 | Taunt             | warrior    | a creature's copy, no stance           |
   | 37548 | Taunt             | warrior    | a creature's copy, no stance           |
   | 39270 | Growl             | druid      | a creature's copy, no form             |
   | 53477 | Taunt             | hunter     | (likely a pet's)                       |
   | 29060 | Taunt             | none       | creature                               |
   | 54794 | Taunt             | none       | creature                               |
   | 70428 | Taunt             | none       | creature                               |
   | 62124 | Hand of Reckoning | paladin    | the paladin's own                      |
   | 31790 | Righteous Defense | paladin    | its effect part (the spell is 31789)   |
   | 56222 | Dark Command      | death knight | the death knight's own              |

   So the owner's first wish works after all: Taunt (37486 or 37548) for
   the Alliance, Growl (39270) for the Horde, neither needing a stance or
   form. Each is to be tried in game with one death knight first: that it
   shows in the spellbook (a creature's spell may be flagged hidden), its
   range and cooldown (a creature's copy may differ from the player's),
   and that the client casts it. Taunt for Alliance, Growl for Horde?

   (The note this replaces:) **Taunt needs Defensive Stance**, which a
   death knight can never be in. The server can drop that requirement for death knights (its own
   copy of the spell's data), but the game client checks a spell's
   stance itself before it even asks the server, and may grey Taunt out
   ("Must be in Defensive Stance"). Test that first, in game, with one
   death knight. If the client refuses: Hand of Reckoning (the paladin's
   30-yard taunt, needs nothing), or a custom client change (the W
   client, `/mnt/kaun/custom-client/`)?
3. **"From the game"**: only death knights, or Death Grip gone everywhere
   (it is also cast by some creatures: those stay)?
4. **Dark Command**, the death knight's own taunt, stays?
