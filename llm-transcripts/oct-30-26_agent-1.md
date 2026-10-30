# Conversation Summary: c2eaec8d-78e8-4b4c-b302-3efe7dafb458

Generated on: 2026-10-30 02:17:26
Models: claude-sonnet-5-5

--------------------------------------------------------------------------------

### User Request 1

You are writing one entry of a walkthrough of a software project: Everland
Ghostsong, a World of Warcraft 3.3.5a private server (AzerothCore) with
roguelike survival changes: an empty world where monsters spawn around players,
treasure, wandering travellers, and "buddies", AI companion characters (built on
the playerbots module) that follow and fight beside each player.

The walkthrough lists every question the project's issue files ask, in groups of
a few, each group under a short context. A reader who knows World of Warcraft
and the project broadly, but not this corner of it, reads the context and can
then answer the group's questions.

Here is one group. Read the issue files named (they are in the project folder
you are in) for what each question rests on; read docs/concept-catalog.md or
docs/capability-architecture.md only if you need the wider picture.

Question 617e12#1 (from issues/617e12-hand-drawn-battle-areas.md, "Hand-Drawn
Battle Areas"; still open):
(Answered 2026-10-08) **How an area is drawn:** polygons, drawn by an AI from
pictures, quest overlays, spawn queries and wiki pages (above). Still open:
which model and how it is run (one zone at a time, offline, its drawing reviewed
in the zone view from above, 617e7, before it is kept?), and how the pictures
are made (the custom client's windowless pictures, 176a, or the zone view's
renderer).

Question 617e12#2 (from issues/617e12-hand-drawn-battle-areas.md, "Hand-Drawn
Battle Areas"; still open):
(Answered 2026-10-08) **The town's rule, where:** in every town, its surrounding
plains included; sometimes talk, mostly fight. Still open: how often "sometimes"
is (one target in five a townsperson?), and do errands (617e4: trainer, vendor,
repair) still come first when due?

Question 617e12#3 (from issues/617e12-hand-drawn-battle-areas.md, "Hand-Drawn
Battle Areas"; still open):
**Town circles and drawn areas:** the town side (area 3) holds the town circle.
Does being inside a drawn area with this rule replace the town circle's
behaviour there, or does the circle still mean "town errands first"?

Question 617e12#4 (from issues/617e12-hand-drawn-battle-areas.md, "Hand-Drawn
Battle Areas"; already answered there):
(Answered 2026-10-08) **The other starting valleys:** two or three areas each,
and every other zone split too, monster kinds the clue.

Question 617e12#5 (from issues/617e12-hand-drawn-battle-areas.md, "Hand-Drawn
Battle Areas"; already answered there):
**"Almost no monsters, almost no friendly people":** counted how (the spawns
inside the area, per square yard, below a threshold?), and decided once when the
area is drawn, or live?

First, for each question, list its components: every term, mechanism, number,
earlier decision or choice a reader must understand to answer it.
Then write the context: two to four short paragraphs of plain English that
explain every component of every question. Rules: no issue numbers, no code
names (functions, files, variables, settings by their code names); say what
things do, by mechanism or analogy; name numbers with their units; for a choice,
say what each option would bring. Do not answer the questions, and do not repeat
them.
Finally, for each component, quote exactly the sentence of your context that
explains it ("explained_by": copied character for character from the context).

--------------------------------------------------------------------------------

