# 917c - Writing the Commands

## Status
- Created: 2026-08-01
- Parent: Issue 917 (Ask the bots in plain text)
- Phase: 9
- Priority: High (this is the feature)
- Depends on: 917a (state), 916d (the model runner)

## Current Behavior

A player who wants five bots to repair types it five times, or learns
the party-chat form, or installs an addon that knows it for them.

## Intended Behavior

The request plus the state block go to the model (916d). What comes back is a
list of commands to issue — the same chat commands and dot-commands a
player would have typed.

```
"have everyone repair and meet me at the bridge"
    → /p maintenance
    → /p follow
```

### Validated before issued

Commands are checked against the real vocabulary before anything is
sent: the command exists, the bot named exists and belongs to this
player, the target makes sense. A command that fails the check is not
issued and is reported, not silently dropped.

This is the same shape as the response validation in 916i — reject,
retry once with the failure named, then say plainly that it couldn't be
done. Small models fix a specific complaint they wouldn't have avoided
in general.

### Shaped by a grammar (llama.cpp, 2026-10-17)

The request carries a grammar (GBNF, as in 916h and 916l) built per
request from the curated vocabulary and this player's bots:

```
root    ::= line ( "\n" line ){0,5}
line    ::= "/p " command | "/w " bot " " command
command ::= <the curated command list, each a quoted literal>
bot     ::= <this player's bot names>
```

So "the command exists" and "the bot named belongs to this player"
cannot fail on a reply from a trusted place; if they do, that is a bug in
how the grammar was built, reported as one (916i's rule). "The target
makes sense" stays with the validator: the grammar does not know what is
in sight. At most six lines, so a reply cannot run on. The real
library accepts this grammar's syntax (`scripts/check-llama-grammar`,
2026-10-17).

### Where it may run

Commands steer bots, like guidance, so the 916e rule would keep them off
players' machines. But "parity, not permission" (below) changes the
answer for one machine: a request about a player's own bots, built only
from that player's words and that player's state, may run on **that
player's own** machine (916d's in-client, or their 916o companion
program). Whatever comes back, the player could have typed. It still
never runs on a *different* player's machine, and its reply still passes
the full validator, since that machine can ignore the grammar.

### Parity, not permission

The check is for *malformed*, not for *forbidden*. Per the parent: the
player either does something themselves or the system they built does
it, and a player can log their character out. There is no list of
things the layer may not write. If a command is one a player could
type, it can be written.

### Say what happened

The reply names the commands issued, or says why none were. Watching it
work is how a person learns whether to trust it, and a summary that
hides the commands hides exactly the information that builds or destroys
that trust.

## Implementation Steps

1. Assemble the prompt: the request, the state block, the command
   vocabulary. Keep the vocabulary curated — the full playerbot command
   list is long, and a shorter list is fewer ways to be wrong.
2. Parse the reply into a command list.
3. Validate each command; reject the batch or the item, decide which.
4. Issue the surviving commands through the bot chat path.
5. Report back: issued, rejected, and why.
6. Retry once on a malformed reply with the specific complaint.
7. Test the ordinary requests first — repair, follow, attack that, come
   here, sell, rest — and see how many need no model at all because an
   exact-match table would catch them.

## Open Questions

- How much of the command vocabulary does the model need to see? The
  full list is very long. A curated subset is more reliable and less
  capable, and the tradeoff should be measured rather than guessed.
- Do common requests bypass the model entirely via an exact-match table?
  Probably, and it would make the frequent path instant.
- One command or several per request? "Repair and meet me" is two. A
  batch that half-fails needs a rule.
- Does it ever refuse to guess and ask back instead? Ambiguity is
  common — "have her back off" with three bots out.
- Does it confirm before anything destructive? A player doesn't get a
  confirmation dialog before vendoring their gear either, but a player
  meant to do it.

## Related

- Parent: [917 - Ask the bots in plain text](917-ask-the-bots-in-plain-text.md)
- [916d - The model runner](916d-llama-cpp-model-runner.md) — llama.cpp in one of three places
- [916i - Response validator and directive apply](916i-response-validator-and-directive-apply.md)
  — the validate-retry-report shape to match
- `docs/playerbots/Playerbot-Commands.md` — the vocabulary
</content>
