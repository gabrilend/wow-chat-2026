# Conversation Summary: 384f5d8d-9dbe-49dd-bda6-33d2b49ebbcf

Generated on: 2026-10-30 02:17:27
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

Question 176a2c#1 (from issues/176a2c-arathi-basin-flow-chart-routes.md, "Arathi
Basin: Flow-Chart Routes"; still open):
**The pointers: per side, per match.** Each side has its own set, reset at each
new match. Or should a side's pointers carry over from one match to the next, so
the spread continues?

Question 176a2c#2 (from issues/176a2c-arathi-basin-flow-chart-routes.md, "Arathi
Basin: Flow-Chart Routes"; still open):
**Captured bases on the way:** when a squad reaches a base its side already
holds, does it pass through by the rule, or might it stop to guard (176a2b's
question 3)?

Question 176a2c#3 (from issues/176a2c-arathi-basin-flow-chart-routes.md, "Arathi
Basin: Flow-Chart Routes"; still open):
**The goal:** "to reach the enemy base": once a squad stands at the enemy's
home, what next? Turn round by the same rule toward their own home, fight there,
or wait?

Question 176a2c#4 (from issues/176a2c-arathi-basin-flow-chart-routes.md, "Arathi
Basin: Flow-Chart Routes"; already answered there):
(Answered 2026-10-08) **What "forward" means:** any road but the one just come
by.

Question 176a2c#5 (from issues/176a2c-arathi-basin-flow-chart-routes.md, "Arathi
Basin: Flow-Chart Routes"; still open):
**The crossings table above: complete and right?** Read as one map it has places
to settle: (a) the Stables' left exit offers the Farm "along the cliff": is that
the long road round the west (the bot module's Farm-to-Stables path, 595 yards),
or a road by the Gold Mine? (b) the Farm's two exits: do both lead to the
Blacksmith-Farm crossing (left by the Lumber Mill road, right by the Gold Mine
road), or is one of them a different crossing? (c) is the Gold Mine's right fork
(Blacksmith, Stables) the same crossing as the Blacksmith's "one way" fork (Gold
Mine, Stables), and the Lumber Mill's right fork the same as the Blacksmith's
"other way" (Lumber Mill, Farm)? (d) the two homes: which crossing does each
home's road reach?

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

