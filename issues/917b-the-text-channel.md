# 917b - The Text Channel

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
</content>
