title: Talents Guiding Abilities
subtitle: A buddy leans on the abilities its talents improve
part: Minds
state: planned; this page is the plan, and the per-class table is built once the owner approves it
issues: 625 625a 625b
gifs: 3a 3b 3c 3d 3e

The owner, 2026-10-15: "would it be possible to cause buddy-bots to be
more likely to use the abilities that are mentioned or affected by the
spec talents they are slotted? Just... in general." And 2026-10-29: "We
could use the embedding of the icon and the name and the text to maybe
also guide it a little bit ... we should check token-by-token to find
word-by-word relationship associations. And then maybe prioritize or
increase in value the relationships that are a little unseen, like "all
of your subtlety spells" or "weapon attacks" and similar."

## Today

A buddy fights by the bot module's fixed priorities for its class. A
talent that makes Rejuvenation stronger changes nothing about how often
Rejuvenation is cast. Nothing in this plan is built yet.

## Reading a talent four ways

gif: 3d

Each talent, and each item set bonus, is read four ways, and the readings
are checked against each other:

1. **The game's own list.** Every class spell carries a hidden set of
   flags, and a talent names the flags of the spells it changes. The
   server applies talents by exactly this, so it is the answer that wins
   any disagreement.
2. **The broad targets.** Some talents name no spell but a whole school
   of magic, a weapon kind, or a kind of ability: those are expanded to
   every ability of the class that matches.
3. **The icon.** A talent usually wears its main ability's picture.
4. **The words**, token by token, with a text embedding as a fuzzy check.

## The icon

gif: 3a

Checked in the game's spell table: Improved Rejuvenation and Rejuvenation
share icon 64. Starlight Wrath shares Wrath's icon (263) but also speeds
Starfire, which the icon alone misses. So the icon finds a talent's main
ability, not all of them.

## The words

gif: 3b

A tooltip is read word by word. An ability's name in it ("your
Rejuvenation spell") ties the two. Category phrases ("weapon attacks",
"finishing moves", "Shadow spells", "bleed", a tree's name) are looked up
in a small table that says which abilities each covers. A text embedding
(each text turned into a list of numbers, close lists meaning close
meanings) compares the talent's text with each ability's text, to catch
what the table lacks. A link only the words find is shown for a look by
eye before it counts.

## The broad ones count for more

gif: 3c

A talent that touches many abilities would spread thin and count for
little on each. Its weight on each ability it covers is raised instead,
so a buddy with talents for "all your Shadow spells" leans toward its
Shadow spells as a whole. (Counting how many talents name an ability was
dropped on 2026-10-22: it would make a druid cast only Healing Touch.)

## At the action bar

gif: 3e

The result is a weight for each ability: the more talent points spent in
talents that touch it, the more it is favoured when the buddy chooses
what to do. Abilities its talents never mention keep their ordinary
weight, and an ability it does not know is never asked for (seen
2026-10-15: a hunter asked 41,000 times for an aura it did not have). The
same weights steer its gems, gear and loot.

## What is built once approved

A generated table for every class, read from the game's own spell tables:
each talent, the abilities it touches by each reading, coloured by where
the readings agree, the word-only links set apart for judging.

## The questions

questions:
