# profiles.lua

Gear designs from open questions, steered by votes (issue 506a).
Pure: no files; `scripts/generate-gear-profiles` and
`scripts/test-gear-designs` do the reading and writing.

| Function | In | Out |
|---|---|---|
| `P.rng(seed)` | number | a function returning 0 <= r < 1 (seeded, reproducible) |
| `P.id(piece, answers, questions)` | piece (string), answers ({question id = option id}), the questions list | 8 hex digits: a hash of piece and answers, so the same design keeps its id and votes |
| `P.tally(questions, profiles, votes)` | the questions; earlier profiles; `{[id] = {up, down}}` | `{score[q][o], carried[q][o], uses[q][o], leader[q], answered[q]}`: net votes per option, downvotes on designs that carried it, how often it was used, the leading option (nil while nothing is liked), and whether the question is settled |
| `P.keep_chance(t, qid)` | a tally, a question id | 0..1: how likely a non-focus answer carries the leader (falls with downvotes on carried designs, never below `KEEP_FLOOR`) |
| `P.make(Q, t, r)` | the questions file, a tally, a random source | one profile `{id, piece, answers, how = {q = "focus"/"carried"/"random"}, focus = {q, ...}}` |
| `P.prompt(Q, profile)` | the questions file, a profile | the text-to-image prompt (focus answers first) |
| `P.round(Q, earlier, votes, count, seed)` | questions, earlier profiles, votes, how many, seed | the new profiles (each with `prompt`), the tally used, notes (repeats that couldn't be avoided) |

Constants (the owner's knobs): `ANSWERED_NET` 3 and `ANSWERED_MARGIN` 2
(settled), `WEIGHT_OPEN` 1 / `WEIGHT_ANSWERED` 0.15 (focus weighting),
`TWO_FOCUS_CHANCE` 0.5, `KEEP_BASE` 0.85 / `KEEP_PER_DOWN` 0.1 /
`KEEP_FLOOR` 0.2 (persistence and widening), `SHIELD_WEIGHT` 0.3,
`NEGATIVE` (the shared negative prompt). The gallery mirrors the settled
rule in its own script; change both together.
