# 629c - The Bar-Chart Line

## Status
- Created: 2026-10-17
- Phase: 6
- Parent: 629 (battleground fronts)
- Blocked by: 629a (the fronts), 629b (getting there)
- Related: 155z2 (front lanes: lanes side by side that never cross),
  619 (the pack retreat)
- Priority: Medium

## Origin

See 629 (the owner's words, 2026-10-17, quoted in full there): "the
buddy-bots create a line shaped like a "bar chart" type thing [...] when
it was within a certain distance (maybe 3-6 steps until facing the foe)
they'd pick the one with the fewest allies in it" / "if there's a
differential of like, 3 in one bar-chart section to another, then 2
allies will come to assist with greater need having lesser priority" /
"the stand-ins have to fight for every inch of ground, so we don't get
surround. Sometimes some break through, but they need to heal and
recover so they are often contested. But they won't be chased too far,
the frontline is more important."

## Current Behavior

Not built.

## Intended Behavior

- **Sections.** Each front (629a) is cut across its width into sections
  of equal width, side by side. Each section keeps, per side, the count
  of allies in it: the bars of the chart.
- **Joining the line.** A bot on its way in, 3 to 6 steps from facing the
  foe, picks the section with the fewest of its allies (a tie broken by
  the nearest) and walks to it.
- **Help where it's uneven.** Where a section holds 3 more allies than
  another, 2 allies leave the fuller section for the thinner one. With
  several thin sections, the order of help follows the owner's "greater
  need having lesser priority" (629's question 2).
- **Encircled, fighting to the last.** A section left thin can be
  surrounded. Those in it don't break and run; they fight until they
  fall (melee giving ground only by backsteps, 629d).
- **Every inch.** Because every section is held, the line can't be
  walked round. A bot that breaks through the enemy line stops to heal
  and recover behind it, so the ground behind each line is contested
  too.
- **No long chases.** A bot follows a foe that broke through or fled no
  farther than a set distance behind its own line, then returns to its
  section.
- **The line moves with the fighting.** Each side's line is where its
  bots in the sections stand; a side that wins its sections walks
  forward along the axis, toward the next objective.

Section: its front, its index across the width (small integer), its
width (yards), and per side the count of allies in it (small integer)
and the list of who they are.

## Suggested Implementation Steps

1. In the paper simulation (629, step 2): sections, the pick on arrival,
   the help rule, chases cut off; drawn as an animated bar chart beside
   the map picture, both sides' bars facing each other.
2. Compare readings of question 2 in the simulation (help the worst
   first, help the worst last) and show the owner both pictures.
3. In the buddy module: the counts kept each second, the pick and the
   help as orders to each bot.

## Open Questions

1. How many sections across a front, or how wide is one (yards)?
2. Does a section's count include allies that are dead and waiting to
   rise, or only the living?
