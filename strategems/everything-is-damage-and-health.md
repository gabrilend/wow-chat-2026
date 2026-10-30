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

## Everything, one system at a time

The owner, 2026-10-30: "technically this ultimately applies to equipment
choices, talent picks, EVERYTHING. But it's a large goal. So we gotta
iterate towards it by bringing each system into alignment one-by-one."
So each system that weighs things is brought in on its own, its
hand-set values traced to their roots one by one, and this list keeps
where each stands:

| System | Where its worth comes from now | Aligned |
|--------|--------------------------------|---------|
| The talent draw (625) | the game's spell flags; a raise per point | partly |
| Window values (625f) | the game's buff numbers, and each ability's profile from its own data (`scripts/generate-ability-data`) | yes (the shares of casts come at run time) |
| Cooldown timing (625f) | each use worth its moment's window factors over the time left (`buddies_cooldown_plan.h`) | yes (the fight's length, 625h, comes at run time) |
| Buff targeting (625l) | (planned from the roots) | planned |
| Gear choice (617j, 625b) | the bot module's stat weights per class and spec | not yet |
| Talent picks (617g) | the ten shapes, drawn at random | not yet |
| Gems (617j2) | the spec profiles' colours and stats | not yet |
| Loot rolls (617j) | the 10% upgrade bar and the blend of three trees | not yet |
| The economies (625h, 625i, 625j) | (planned in damage and health) | planned |

## Where it is used, or will be

- The talent draw (625): talents' worth from the game's spell flags.
- The window values (625f, `buddies_window_buffs.h`): a buff's gifts from
  the game's table, and how much each ability is moved by them from the
  ability's own cast time, channel, global cooldown, resource and ticks
  (`scripts/generate-ability-data`, 768 abilities).
- Buffs given to who uses them most (625l): each member's damage and
  health to come under the buff.
- The healer's seat (625i), the threat economy (625j), the fight's length
  (625h): each said in damage and health.
