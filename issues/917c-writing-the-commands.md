# 917c - Writing the Commands

## Status
- Created: 2026-08-01
- Parent: Issue 917 (Ask the bots in plain text)
- Phase: 9
- Priority: High (this is the feature)
- Depends on: 917a (state), 916d (the Ollama client)

## Current Behavior

A player who wants five bots to repair types it five times, or learns
the party-chat form, or installs an addon that knows it for them.

## Intended Behavior

The request plus the state block go to the cluster. What comes back is a
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
- [916d - Ollama HTTP client](916d-ollama-http-client.md) — the client
- [916i - Response validator and directive apply](916i-response-validator-and-directive-apply.md)
  — the validate-retry-report shape to match
- `docs/playerbots/Playerbot-Commands.md` — the vocabulary
</content>
