# 920d - The Chat Window Addon

## Status
- Created: 2026-10-20
- Phase: 9
- Parent: 920 (legendary friends in every friends list)
- Blocked by: 920c (whispers answered)
- Priority: Parked (with its parent, 920: the legends are Blizzard's characters; see 920's "Parked")

## Current Behavior

Not started. After 920c a legend's replies arrive as ordinary whispers in
the game's chat frame, mixed with everything else.

## Intended Behavior

The owner: "They should be kept as user-based chatbot style UI messages in
each player's client, like an interface addon."

An interface addon (Lua and XML in the client's `Interface/AddOns/`, the
stock 3.3.5a addon API, so the stock client runs it; AIO is not used,
`docs/roadmap.md`) that gives each legend a window like a messenger's: their
name and a small portrait at the top, the conversation in bubbles, a text box
at the bottom. It opens from the friends list (a button beside a legend's
name) or by a slash command. Sending a message sends an ordinary whisper;
whispers from a legend are shown in its window and kept out of the main
chat frame. It works without the addon too: the addon only changes how the
same whispers look.

The conversation shown when a window opens comes from the server's store
(920c), asked for through addon messages (the client's hidden whisper
channel for addons), so the phone's messages (920e) show up here as well.

## Suggested Implementation Steps

1. The addon's window, built and tested against a fake whisper source
   (a slash command that injects replies).
2. Filtering legends' whispers into their windows.
3. History on open: an addon-message request, answered by a server script
   from the store, in pages.
4. Portraits: the game's own portrait art where one exists (Mograine,
   Terokk), drawn art otherwise; shipped art must be the project's own.
5. A screenshot test through the client's scripted-run options, filed in
   `development-history/`.

## Open Questions

1. Should the addon be required (installed with the profile's client
   files), or optional?
