# Strategem: Everything Is Damage and Health

A strategem is a data flow pattern that recurs across the project and is
worth standardizing. This one says:

> Don't hand-set what something is worth. Every weight a buddy uses,
> whatever economy it comes from (time, mana, threat, movement, a boss's
> mechanics, a buff, a form), is a route to one of two things: damage
> dealt and health kept. Each value is worked out from its roots, what the
> game's own data says the thing does and what the people involved can do
> with it, down to whose damage and whose health it moves and by how much.
> A number set by hand is a placeholder for a root not yet traced, and
> says so.

The owner, 2026-10-30, word for word: "Remember we don't want to specify
exact values. We want their value to come cleanly from the roots of the
weights that determine their output - at the end of the day, EVERYTHING
that we weigh collapses to just damage, and health. It's just a question
of whose it is, and what route through the complicated combat ideaspace
leads us to victory most assuredly."

## Why

A hand-set value ("Bloodlust is worth 1.3") is right for one buddy and
wrong for the next, and wrong for all of them after a patch. A value
traced to its roots (Bloodlust gives 30% haste; this buddy's casts are
this much moved by haste; so this much more damage in these 40 seconds)
is right for each buddy and stays right when the game or the buddy
changes, because it is worked out again.

## The shape

1. **The roots are the game's own data**: what each spell, aura, buff and
   talent does, read from its tables (625a's talent table, 625f's buff
   table), never retyped.
2. **The middle is each character's**: its abilities, talents, stats and
   resources, what it is doing and about to do.
3. **The leaves are damage and health**: whose, how much, how soon. Every
   economy's verdict is said in these, so they can be added up and
   compared.
4. **A hand-set number** is allowed only as a starting value
   (`strategems/grown-and-relearnable.md`), with a note naming the root it
   stands in for, until that root is traced.

## Where it is used, or will be

- The talent draw (625): talents' worth from the game's spell flags.
- The window values (625f, `buddies_window_buffs.h`): a buff's gifts from
  the game's table; how much each ability is moved by them is, for now,
  set by hand per kind of ability (cast-time spells, energy-bound strikes,
  damage over time), standing in for the ability's own cast time, global
  cooldown and resource, to be read instead.
- Buffs given to who uses them most (625l): each member's damage and
  health to come under the buff.
- The healer's seat (625i), the threat economy (625j), the fight's length
  (625h): each said in damage and health.
