# 506a - Feldowinn Design Profiles

## Status
- Created: 2026-09-27
- Phase: 5
- Parent: 506
- Blocked by: None
- Priority: High

## Current Behavior

**Built 2026-09-27.** `assets/feldowinn/design-questions.lua` (9
questions over 9 pieces), `src/tools/feldowinn/profiles.lua` (the rules;
`.info.md` beside it), `scripts/generate-feldowinn-profiles` (writes
`assets/feldowinn/profiles/round-NNN.lua`; round 1 made, 24 profiles, seed
1). Tested in `scripts/test-feldowinn`: settled/leader rules, a settled
question explored about 0.15 times as often as an open one, the carried
share of a leader falling from about 0.89 to under 0.55 after six
downvotes, reproducible rounds, no repeats, a malformed votes line
stopping the generator with the line named.

## Intended Behavior

- **Design questions** (`assets/feldowinn/design-questions.lua`): the
  open questions about Feldowinn's gear, each with the options to try
  ("how does 'a link to time' show?": hourglasses, gold clockwork,
  sundial halos, time-crystal shards...) and the pieces it applies to
  (helm, shoulders, chest, gloves, belt, legs, boots, weapon, and a
  shield as an off-piece).
- **A profile**: one gear piece with an answer to every question that
  applies to it: silhouette, materials, palette, motifs, the healing
  sign; which one or two questions it is exploring (its focus); a stable
  id (a hash of its answers); a text prompt for image generation built
  from its answers; the round it was made in.
- **Weighting by votes** (`assets/feldowinn/votes.tsv`, profile id, ups,
  downs): an option's score is the net votes of the profiles that used
  it. A question counts as answered when one option leads with at least
  3 net votes and 2 more than the next. Each profile's focus questions
  are drawn weighted toward unanswered ones; focus answers are drawn
  evenly (explore). Its other answers carry the leading option
  (persistence) with a probability that falls as profiles carrying that
  leader collect downvotes; otherwise a random option (variation widens).
- `scripts/generate-feldowinn-profiles` writes a round of profiles to
  `assets/feldowinn/profiles/round-NNN.lua`; seeded, so a round can be
  made again.

## Suggested Implementation Steps

1. The questions file; the generator; its test (`scripts/test-feldowinn`:
   weighting toward unanswered questions, widening after downvotes,
   answered detection, reproducibility).

## Related Issues

- **506** parent; **506d** writes the votes it reads
