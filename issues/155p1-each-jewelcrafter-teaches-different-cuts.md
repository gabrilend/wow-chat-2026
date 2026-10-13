# 155p1 - Each Jewelcrafter Teaches Different Cuts

## Status
- Created: 2026-10-13
- Phase: 1
- Parent: 155p (sockets and socket bonuses on basic gear)
- Related: 155n (professions capped at 300), 155p's gem supply
  (`sql/basic/db_world.src/18-gem-supply.apply.sql`, E033) and titan
  jewelers (`19-titan-jewelers`, E034)
- Priority: Medium
- State: planned; open questions first

## Origin

Verbatim, 2026-10-13, after hearing the gem supply as built (trainers
teaching Outland's cuts for gold over skill 150-300, Wrath gems dropping
across Outland):

> the profession issue files must be incomplete then. We are intended to
> rebalance the professions such that low level socketed items are
> socketable with jewelcrafting gems, and we scooch the jewels we can
> craft down such that the WotLK gems are the highest tier available in
> Outland from... I think dungeon and raid bosses? And anyway early
> jewelcrafters can make TBC gems while later ones can make WotLK gems.
> Or maybe it's WotLK gems in Outland? And earlier jewelcrafting recipes,
> each one should be taught by a different jewelcrafting master. Sorta.
> It's a complicated design and that part we haven't talked about yet,
> so here's the spec design. Feel free to check the llm-transcripts for
> the rest:

> "Hi can we make it so that the jewelcrafting masters teaching Outland
> jewelcrafting recipes in Azeroth (WotLK gems are for rare elite
> monsters in Outland and the dungeon and raid bosses) and, since it's a
> certain amount of gems, we should spread them out evenly throughout the
> levels. But, there will be N gemstones and 300 profession levels. So we
> need to divide 300 by N to figure out how often we get a new recipe.
> And, here's the thing that's neato interesting, each JC profession
> teacher teaches a different one at each tier. They will be arranged
> such that none of them are teaching the same recipe at that level. So,
> a player could walk between all the capital cities and learn them all
> early, if they wanted to. Or at least for their desired favorites. We
> should make sure that we always teach the same color at that level
> among all the jewelcrafters, so that we always have a roughly even
> split across the colors.

(The quoted design was not found in the transcripts as of 2026-10-13: it
is new here.)

Worked on together, 2026-10-13 (verbatim):

> which three lists? They will each need their own list, probably. I mean
> it depends on the distribution of gems, there's what, like 6 colors?
> red blue yellow, green purple orange. so, over 300 levels we could do
> 300 / 6 which equals one gem every 50 levels. But, that sucks, so let's
> divide the 50 levels into 17 lists, one for each trainer. That's
> like... 3ish? so... maybe we iterate through the 6 colors 3 times
> throughout the 300 levels, so it goes... red purple blue green yellow
> orange, red purple blue green yellow orange, red purple blue green
> yellow orange. That's... 18 total tiers, and 300 divided by 18 is...
> something idk. The math for this is probably wrong?

> okay second attempt. So, if we split the 300 levels into tiers. uh, how
> many gemstones are there? lemme go count... okay there's a bunch but
> let's say there's N gemstones of each color. Then we'd -- stack
> overflow -- uhhhh, did you get anything from that?

The count, 2026-10-13 (cuts the trainers teach on basic, colour from the
client's gem table): purple 15 (7 uncommon, 8 rare), yellow 14 (6, 8),
orange 13 (6, 7), red 12 (5, 7), green 10 (4, 6), blue 6 (3, 3): 70.
Eighteen tiers (six colours, three rounds) are 16 2/3 skill points
apart. A colour's cuts split over its three rounds give 2 to 5 cuts a
tier, so at any tier only that many of the seventeen trainers can teach
a different cut.

Answers, 2026-10-13 (verbatim), on hearing that at a tier a colour has
only 2 to 5 cuts for 17 trainers:

> okay so we should teach the gems in a random order then. We should
> distribute them such that the colors are as evenly distributed through
> the levels as possible. There should be 17 different orders, for 17
> trainers. Can you tell me, why 17? Some of them are faction specific,
> so that number will go down. Can we just have this random order be for
> the capital city ones? What other ones exist? Probably in Eversong Woods
> or Azuremyst or something... I'm thinking just the capital vendors...
> We have a special vendor that teaches all the professions in each
> capital city, right? How does that go?

Who teaches jewelcrafting on basic (2026-10-13, the world database): 17
kinds of trainer. Six are Northrend's grand masters (list 111; Northrend
is closed on basic). Seven are Outland's masters (list 112: three in
Shattrath, Honor Hold, Thrallmar, the Stormspire, and one more in
Shattrath). Three stock trainers (list 113): Silvermoon (two) and the
Exodar. Then the Visiting Jewelcrafter (list 113), one creature per side
standing in six capitals: Stormwind, Ironforge, Darnassus; Orgrimmar,
Thunder Bluff, the Undercity. No trainer teaches every profession: each
capital has the stock one-profession trainers. So the capitals have
eight jewelcrafters, four a side (Alliance: Stormwind, Ironforge,
Darnassus, the Exodar; Horde: Orgrimmar, Thunder Bluff, the Undercity,
Silvermoon). For each to teach its own order, the six Visiting
Jewelcrafters become six creatures, each pointed at a list of its own.

Read as: one random order of the cuts per capital trainer, eight orders,
each spread over 1-300 with the colours as even along the skill as the
counts allow, and no two trainers of a side teaching the same cut at the
same skill.

## Current Behavior

Built by 155p (E033, E034), not yet seen in game:
- three shared trainer lists teach jewelcrafting to 300: list 111 (six
  trainers), 112 (seven, Outland's masters among them), 113 (Silvermoon,
  Eversong, the Exodar, and the Visiting Jewelcrafter in each of the six
  capitals). Every trainer on a list teaches the same recipes;
- Outland's cuts on those lists: 34 uncommon spread over skill 150-225,
  36 rare over 250-300, in the order sustain, sustain and power, power,
  power and focus, focus;
- Wrath gems: uncut uncommon and rare from any Outland monster (0.5% and
  0.05% a kill), epic from bosses; Wrath cuts from recipe drops in
  Outland and the Earthen Gemcutter (list 155300) at skill 300;
- low-level gear (white from vendors in the capitals, dungeon blues) has
  sockets for +4 to +8 gems (155p's tiers); the +4 cut gems come from
  prospecting copper and tin and from Outland's gem vendors.

## Intended Behavior

**Recipes spread evenly over the skill.** The cuts that jewelcrafters
learn from trainers (Outland's: N of them) are spread evenly across the
whole 1-300, a new step every 300/N points (or every 300/(N/T), see
open question 1), instead of only 150-300.

**Each trainer teaches a different cut at each step.** At any one step,
no two jewelcrafting trainers teach the same recipe: each has its own
list. A player who walks between the capitals can learn every cut of a
step early, or just their favourites.

**One colour per step.** All trainers' cuts at a step are of one gem
colour, and the colours take turns from step to step, so the colours
stay evenly split.

**Wrath gems are the top tier**, found in Outland from rare elite
monsters and from dungeon and raid bosses (not from every monster as
now; open question 3).

## Suggested Implementation Steps

1. Answer the open questions.
2. A generator: the cuts sorted into colours; steps along 1-300; at each
   step one colour, one cut per trainer; writes one trainer list per
   trainer (each trainer creature pointed at its own list) into the gem
   supply SQL's generated block.
3. A test: no recipe twice at one step; every step one colour; colours
   evenly split; every cut taught somewhere.
4. The Wrath gem drops moved to rare elites and bosses.
5. In game: two capitals' jewelcrafters, side by side, at one skill.

## Open Questions

1. The spacing: "divide 300 by N" with N the number of cuts gives one
   recipe per step across all trainers; but with each trainer teaching a
   different one at the same step, a step holds as many cuts as there
   are trainers (T), so the steps are 300 / (N / T) apart. Which?
2. Which trainers count: all seventeen or so (the three lists, Outland's
   masters too), or only the "jewelcrafting masters ... in Azeroth" (the
   capitals' and Silvermoon's and the Exodar's)? Outland's own masters
   then teach what?
3. "WotLK gems are for rare elite monsters in Outland and the dungeon
   and raid bosses": does that end the 0.5% Wrath uncommon drop from
   every Outland monster?
4. "early jewelcrafters can make TBC gems while later ones can make
   WotLK gems": Outland's cuts on the trainers from 1 to 300, and Wrath
   cuts only from drops and the Earthen Gemcutter? Or Wrath cuts on the
   trainers' upper steps too?
5. Raw gems for low-skill cuts: Outland's cuts need Outland's raw gems
   (from prospecting mithril and thorium, 155p). A jewelcrafter at skill
   50 learning an Outland cut can't make it until then. Should the
   low-skill cuts' raw gems come from somewhere earlier (prospecting
   copper and tin, vendors)?
