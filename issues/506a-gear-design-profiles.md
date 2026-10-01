# 506a - Gear Design Profiles

## Status
- Created: 2026-09-27
- Phase: 5
- Parent: 506
- Blocked by: None
- Priority: High

## Current Behavior

**Built 2026-09-27.** `assets/gear-designs/design-questions.lua` (9
questions over 9 pieces), `src/tools/gear-designs/profiles.lua` (the rules;
`.info.md` beside it), `scripts/generate-gear-profiles` (writes
`assets/gear-designs/profiles/round-NNN.lua`; round 1 made, 24 profiles, seed
1). Tested in `scripts/test-gear-designs`: settled/leader rules, a settled
question explored about 0.15 times as often as an open one, the carried
share of a leader falling from about 0.89 to under 0.55 after six
downvotes, reproducible rounds, no repeats, a malformed votes line
stopping the generator with the line named.

## Intended Behavior

- **Design questions** (`assets/gear-designs/design-questions.lua`): the
  open questions about the set's look, each with the options to try
  ("how does the Light show on the gear?": engraved runes, a sunburst
  emblem, light through the seams, no glow...), the subject the prompt
  names (a string, "a Retribution Paladin"), and the pieces it applies to
  (helm, shoulders, chest, gloves, belt, legs, boots, weapon, and a
  shield as an off-piece).
- **A profile**: one gear piece with an answer to every question that
  applies to it: silhouette, materials, palette, motifs, the healing
  sign; which one or two questions it is exploring (its focus); a stable
  id (a hash of its answers); a text prompt for image generation built
  from its answers; the round it was made in.
- **Weighting by votes** (`assets/gear-designs/votes.tsv`, profile id, ups,
  downs): an option's score is the net votes of the profiles that used
  it. A question counts as answered when one option leads with at least
  3 net votes and 2 more than the next. Each profile's focus questions
  are drawn weighted toward unanswered ones; focus answers are drawn
  evenly (explore). Its other answers carry the leading option
  (persistence) with a probability that falls as profiles carrying that
  leader collect downvotes; otherwise a random option (variation widens).
- `scripts/generate-gear-profiles` writes a round of profiles to
  `assets/gear-designs/profiles/round-NNN.lua`; seeded, so a round can be
  made again.

## Suggested Implementation Steps

1. The questions file; the generator; its test (`scripts/test-gear-designs`:
   weighting toward unanswered questions, widening after downvotes,
   answered detection, reproducibility).

## Related Issues

- **506** parent; **506d** writes the votes it reads
