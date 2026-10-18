# docs/HTML/battleground-front/

Made by `scripts/generate-battleground-front-gifs`, which plays the
battleground front rules (`src/lua-basic/lib/battleground-front.lua`,
issue 629) from one seed and draws every half-second as a frame, so the
owner can see the rules before any server code is written.

- `worst-last.gif`: help reaches the least desperate section first (the
  owner's words, read literally: "greater need having lesser priority").
- `worst-first.gif`: the most desperate section is helped first.

- `doubled-worst-last.gif`, `doubled-worst-first.gif`: twice the bots
  (80 a side) on a field twice as wide, in 10 sections, so each section
  holds as many as before and two sections fall short at once more often
  (the owner's "double the number of units", issue 629c).

The first two are 40 a side (Alterac Valley's size) on an 80-yard
field in 5 sections. All are seed 7, 40% ranged, four simulated
minutes at twice real time. Side a (blue) starts at the
bottom and pushes up; side b (red) at the top pushes down. Filled dots
are melee, hollow dots ranged, a white rim a bot that broke through
and is healing. The dashed lines across the field are each side's line
(the average position of its bots on the line). The bars above and
below are each side's allies per section; a dashed mark in a bar band
sits at the fullest section's count less the help gap of 3, so a bar
that ends short of it is a section help is sent to.

Remake with `scripts/generate-battleground-front-gifs`.
