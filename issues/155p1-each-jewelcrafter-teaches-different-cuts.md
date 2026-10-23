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

Answers, 2026-10-13 (verbatim):

> we need one in each capital city.

> great, so we need 4 lists of randomly sorted gemstones, distributed
> throughout the 300 levels in a roughly evenly proportioned way.

> should be 4. Also, they should be their own creature type. Some odd
> eccentric (autistic) who is visiting from afar. They're just so happy
> to be there that once every hour at a random time +/- 30 minutes,
> they'll dance for a minute, then go back to standing around learning.

And on the trainers outside the capitals:

> we should remove these. Same for all Outland and Northrend profession
> trainers. (155n)

Read as: a jewelcrafter in each of the eight capitals; four orders of the
cuts, random, each spread evenly over 1-300 with the colours as even
along the skill as the counts allow; one order per capital of a side
(each order used once on each side). The capital jewelcrafters are a new
creature type of their own, not the Visiting Jewelcrafter: an odd,
eccentric visitor from afar, so happy to be there that about once an hour
(every 30 to 90 minutes, at random) they dance for a minute, then go back
to standing about learning. Silvermoon's and the Exodar's stock trainers:
open (replaced by the visitor, or kept with one of the four orders).

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
## Answers, 2026-10-22

1. **Every trainer teaches every cut**, each in its own random order: with
   N cuts of a quality, a new one every (that quality's skill range) / N
   points at every trainer. Visiting another capital changes which cuts
   come early, not which exist.
2. (Answered 2026-10-13) The eight capital jewelcrafters: Outland's and
   Northrend's profession trainers are removed (155n). Since 2026-10-22
   (155e1) the six capitals without a jewelcrafter have the Profession
   Mentor teach it, the eccentric visitor of this issue; Silvermoon and
   the Exodar keep their stock jewelcrafters, with their own orders.
3. **The 0.5% Wrath uncommon drop from every Outland monster ends.** Wrath
   gems drop from Outland's rare elites and the dungeon and raid bosses.
4. **Where the cuts come from stays as 155p built it** (the owner: "I
   think wrath cuts come from Outland, and Outland cuts from Azeroth.
   There's different quality levels too, so we have to keep that in
   mind."): the trainers teach only Outland's cuts; Wrath's come from the
   Designs dropping in Outland and its dungeons and from the Earthen
   Gemcutter. Spreading over 1-300 keeps the qualities apart: uncommon
   cuts over the lower part of the range, rare over the upper (open
   question 1 below: where the split falls).
5. **Raw gems for the low-skill cuts: Azeroth's gemstones, enchanted**
   (the owner: "you should be able to cut the azeroth gemstones into gems
   that suit their color. But, we'll need to enchant the gemstones,
   otherwise they're just pretty rocks. [...] One gemstone should make two
   cut gemstones, typically."). A mechanic of its own: issue 155p2.
6. **The split: uncommon cuts over 1-200, rare over 201-300** (the owner,
   2026-10-22: "I'm leaning toward 1-200 / 201-300 though. I like the
   idea of spending more time with the lower quality gems, because it
   means we can start with like 1 socket per item or two at level 10, then
   one socket per item at level 20 with one item having 2, or similar.
   Then, at the point where the player and their clan starts learning how
   to create blue gems, they could be at the max socket count (or
   similar, some items only have one or two sockets of course." And on
   sockets in general: "we designed the socket count to keep the gear
   roughly in proportion to others of it's type, maybe with a +10% margin
   if you use the best gems and -10% if you use the worst ones [...] In
   general the power of a socket comes from it's flexibility, not your
   ability to put powerful gems in it, but powerful gems should still
   exist.") Checked against 155p as built: filled dungeon blues land about
   10% above the stock blue, whites at about the same-level green; sockets
   start at item level 17 (one per item), with tier I +4 gems (vendors) at
   item level 17-27, tier II +6 (uncommon cuts) at 30-45, tier III +8
   (rare cuts) at 45-63.
7. **Before the uncommon cuts: mundane glass gems** (2026-10-22, asked
   whether a new jewelcrafter should cut +6 gems for low-level gear): "the
   +4 gems are mundane, and any jewelcrafter can cut them at any level
   with no enchanting requirements. they need only access to expensive
   glass. They get them up enough levels (always white difficulty,
   requires vendor item, one orb for 10 gems or 100 chiplets) enough
   levels to be level suitable appropriate to start using the uncommon
   gems." So the +4 gems (155p's tier I) become a jewelcrafting recipe
   family of their own: cut from a vendor-sold orb of expensive glass
   (one orb makes 10 gems, or 100 chiplets), no enchanting needed, their
   recipes staying "white" (a chance of skill at every cut) so they carry
   a jewelcrafter up to where the uncommon cuts begin. The uncommon cuts
   then start later than skill 1, at the skill suiting item level 30
   gear (open question 1).

## Open Questions

1. **Where the uncommon cuts begin:** at about skill 75-100 (where gear
   reaches item level 30), spread from there to 200?
2. **The glass recipes' range:** do they stay white all the way (a chance
   of skill-up at every cut, to 300), or only until the uncommon cuts
   begin, then grey?
3. **"one orb for 10 gems or 100 chiplets":** a cut from an orb gives 10
   gems, or, as an alternative recipe, 100 chiplets (for the other crafts
   of 155p2)?
