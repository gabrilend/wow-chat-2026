# 917b - The Text Channel

> **Part of this will not be implemented, because it needs AIO:** the addon surface ("AIO is already installed" is no longer true for the plan).
> The project no longer plans to use AIO, the server-to-client addon framework
> (Ritz, 2026-09-25: "I think we should update the plan of the project to
> NOT use AIO, or at least to mark anything that requires it as 'will not
> implement because it needs AIO. But here's how we would if we could:'").
> The AIO parts below are kept as how we would build them if we could. Surfaces that need no addon stand.

## Status
- Created: 2026-08-01
- Parent: Issue 917 (Ask the bots in plain text)
- Phase: 9
- Priority: High

## Current Behavior

No way to say anything to the layer, because there is no layer.

## Intended Behavior

The player types a request; a reply comes back as text. In-game, and as
plain as possible.

The reply says what was done, in a sentence. Including when nothing was
done, and why — a request that produced no commands and no explanation
is indistinguishable from a broken pipeline.

Three candidate surfaces, and the choice is mostly about typing comfort:

- **A slash command or dot-command.** `.ask have everyone repair`.
  Nothing to build beyond registration; awkward for long sentences.
- **A whisper to a named target.** Feels like talking to someone, which
  is the right feeling. Needs something to whisper to.
- **An addon frame with a text box.** Most comfortable to type in, most
  to build, and AIO is already installed.

Start with whichever is fastest to stand up. The rest of the layer
doesn't care which one it is, and shouldn't be written so that it does.

## Implementation Steps

1. Register the input surface; echo the request back to prove the round
   trip before anything else exists.
2. Route the request to 917c along with the state block from 917a.
3. Return the reply as text.
4. Report failure paths distinctly — cluster unreachable, request not
   understood, commands written but refused. Silence is not an option
   here; per house rules a fallback is a warning and a warning is an
   error.
5. Rate-limit, so a stuck key doesn't queue fifty inferences.

## Open Questions

- Which surface first?
- Does the reply go only to the asker, or can others in the party see it?
  Visible replies make this a shared tool at a table; private replies
  keep the channel quiet.

  **The owner's answer, 2026-09-29 (shared with neuron's issue 1003),
  verbatim:**

  > "statement: moving innkeeper to garage." and "query: who wants to go on an
  > adventure?" and "warning, warband in the area" and "undocumented strangers
  > demand circumspicion"

  Read in neuron's 1003 as: who hears a line depends on its kind, named at its
  front — statements, queries and warnings to everyone; the back-and-forth of
  a request to the asker; and a speaker nobody has a record of met with
  circumspection. That reading is being checked with the owner there.
- Should the player be able to see the commands it wrote, not just the
  summary? Yes for debugging; possibly always, since watching it work is
  how someone learns to trust it.
- Does the channel survive a relog, or is each session a fresh
  conversation?

## Related

- Parent: [917 - Ask the bots in plain text](917-ask-the-bots-in-plain-text.md)
- [616 - Public healer frames addon](616-public-healer-frames-addon.md) —
  the AIO precedent if the addon surface is chosen
- [1006 - rmail in-game text editor](1006-rmail-ingame-text-editor) —
  the existing thinking about typing prose inside the client

## Shared Build Pass (neuron)

neuron's `docs/shared-with-wow-chat-2026.md`, pass 2. A fourth surface, needing
no addon: **a custom chat channel.** neuron's issue **1003** designs it — a
player joins `neuron`, a server-side hook (`PLAYER_EVENT_ON_CHANNEL_CHAT`)
hears what is said there, and replies go back as chat packets shaped like
channel messages. Comfortable for long sentences, and it "feels like talking to
someone". Built once, used by both.

This issue's second open question — reply to the asker only, or to others? —
is 1003's second open question too. One answer serves both.

155x refuses only the built-in numbered channels, so a player-made channel is
unaffected.
</content>
