# 917a - What It Can See

## Status
- Created: 2026-08-01
- Parent: Issue 917 (Ask the bots in plain text)
- Phase: 9
- Priority: High (nothing can be written without this)

## Current Behavior

Bot state is scattered across the world objects and playerbot internals.
Nothing assembles it, and nothing turns entry IDs into words.

## Intended Behavior

A block of plain text describing the player's bots right now. The model
reads this and looks nothing else up — whatever isn't here doesn't exist
as far as the layer is concerned.

Per bot: name, class, level, health and resource, where they are (zone
and subzone by name), what they're fighting if anything, what the bot AI
thinks it's doing, and anything obviously wrong — broke, bags full,
dead, far from the others.

The IDs get joined against the world database on the way out:

| ID | Table | Becomes |
|----|-------|---------|
| creature entry | `creature_template` | name, rank, level |
| item entry | `item_template` | name, quality |
| zone / area | `areatable` | zone and subzone names |

These are static per world build — cache them at load rather than
querying per request, and report the counts at startup so an empty table
is loud.

Rendered as text, not JSON. The reader is a language model, and a
sentence costs fewer tokens than a nested object saying the same thing.

## Implementation Steps

1. Build the name caches at ALE load; report counts.
2. Collect per-bot state for the player's bots.
3. Render to text. Keep it compact — this goes in every request.
4. A console command that dumps the current block, so it can be read
   without involving the cluster.
5. Check the length at realistic bot counts. If ten bots overflow what's
   sensible to send, the block needs a summary form.

## Open Questions

- Which bots — the player's own, their party, everyone nearby? The
  answer decides the block's size more than anything else.
- How much detail per bot? Enough to answer "who needs repairing" is a
  different block than enough to answer "who's in trouble."
- Does it include what the bots can *see* — nearby creatures, other
  players? A request like "avoid that thing" needs it; it also multiplies
  the length.
- Refreshed per request, or kept warm and refreshed on a timer? Per
  request is simpler and correct; on a timer is cheaper.

## Related

- Parent: [917 - Ask the bots in plain text](917-ask-the-bots-in-plain-text.md)
- [916b - ALE bindings for playerbots](916b-ale-bindings-playerbots.md) —
  likely home for the playerbot-internal reads
- `docs/wiki/docs/creature_template.md`, `docs/wiki/docs/areatable.md`
</content>
