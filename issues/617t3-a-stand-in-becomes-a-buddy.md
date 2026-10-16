# 617t3 - A Stand-in Becomes a Buddy

## Status
- Created: 2026-10-15
- Phase: 6
- Parent: 617t (dungeon stand-ins)
- Related: 617t1 (the stand-in maker), 617n (weapon kinds), 617a3
  (buddy creation), 617b (choosing a buddy at Sargobras), 176a1 (the
  Alterac Valley scene, where the idea was first written)
- Priority: Low
- State: planned; the design is open

## Origin

Verbatim, 2026-10-15, on weapon kinds:

> When they are instantiated as buddy-bots, they might lose weapon
> skills! That's fine. Though it does produce an incongruity... If the
> stand-in-becoming-buddy-bot wore a weapon in a battleground / dungeon,
> then they should have that skill trained first from among the potential
> weapon skills learned when instantiated. I don't think it could be the
> case that a player would have fewer than the buddy-bot has weapon
> appearances, but we should account for that possibility too.

Asked whether this is planned: "but it's planned, right?" It was, eight
days earlier: on 2026-10-08, planning the Alterac Valley scene
(`llm-transcripts/oct-8-26-through-oct-9-26.md`, line 155; quoted in
176a1), verbatim:

> stand-ins are not driven by player-bots per se, they are meant to have
> stats for combat and long-term progression such as level and character
> attributes. Also spec profile. But much of the other stuff can be
> elided. Until they're spawned as buddy-bots, they will level up as
> become randomly selected from to a buddy-bot become at max level.

And, asked what makes a stored stand-in gain a level (the same
transcript, line 380): "this is what I meant [a stand-in only goes up
one ten-level step each time it is used]. There are situations when a
stand-in might be lower level. Also it might end up being 1 level each
match, we'll see. It's meant to roughly match the rate of player
levelling, though maybe there should be some that go slow or fast, to
make sure that everyone knows some stand-ins and are greeted with new
ones too. parallel levelling tracks." This issue gathers that thread,
which lived only in 176a1 and 617t's levelling rules, into its own plan;
an earlier draft of it (the same day) wrongly said it had never been
planned.

## Current Behavior

Stand-ins (617t1) are characters on their own accounts, drawn into
dungeons, battlegrounds and arenas, and dismissed after. None ever joins
a player as a buddy; a buddy is always made fresh from a roster slot
(617a3).

## Intended Behavior

Stand-ins level only when used, on parallel tracks of different speeds
(617t). Once a stand-in reaches the maximum level, it joins the pool new
buddies are drawn from: when a player is given a buddy of its race and
class (and role), it may be drawn at random from those stand-ins instead
of being made fresh, keeping its name, face, race, class and history. On becoming a
buddy it follows the buddy rules: its weapon kinds are cut to its new
owner's count (617n), keeping first the kinds of the weapons it was seen
wielding, even past the count if it wielded more kinds than the owner
knows.

## Suggested Implementation Steps

1. Answer the open questions.
2. Moving the character from the stand-in account to the owner's
   companion account (617a2), and filling the roster slot with it.
3. Its weapon kinds: the kinds of its worn weapons first, then cut to the
   owner's count; its other gear and spells by the buddy rules of its
   level.

## Open Questions

1. "Randomly selected ... at max level": only max-level stand-ins enter the
   pool, so only a player at the maximum level (or choosing a buddy
   slot there) can be given one; is that the intent, or may a stand-in
   at the player's own level be drawn too?
2. Does it take an owed roster slot, or replace a buddy the player has?
3. Does it keep its gear, or get the kit of its level?
