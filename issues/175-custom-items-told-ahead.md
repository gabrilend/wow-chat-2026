# 175 - Custom Items, Told to the Client Ahead of Time

## Status
- Created: 2026-10-05
- Phase: 1
- Related: 148v (cloned kit items drawn invisible), 160 (the client's cache follows the server), 617r (gearsets), 173 (the custom client)
- Priority: Medium

## Origin

Verbatim, 2026-10-05:

> stale data? what does it "know" about items it "knows"? It's true that
> we could just fake it with buddy-bots, but the client needs to know which
> item models to render, and it needs to show the correct icons and
> tooltips so when the user inspects a buddy-bot, they see the correct
> gear. I could have sworn we figured out how to do custom items...

## Current Behavior

What the original 3.3.5a client knows about an item, and from where:

- **From its own files** (`DBFilesClient\Item.dbc`, 46096 items, read
  2026-10-05): for every item that shipped, its class, subclass, inventory
  type, sheath and display id (the model and look). New item numbers are
  not in it.
- **From the server, kept in a cache** (`Cache/WDB/itemcache.wdb`): the
  rest: name, icon (by display id), stats, required level, tooltip text.
  The client asks for an item (an item query) the first time an event
  needs it, and keeps the answer; 160 makes it forget its answers when
  this project's content changes.

So a custom item (a new number) can work fully, model, icon and tooltip,
once a client has asked about it. 148v's failure was the first sight: the
server put cloned items on a new character without anything that made
the client ask, so they drew as nothing with a red "?" until the player
took them off and put them on again (which made it ask, and from then on
they drew correctly, for good). 148v went back to original item numbers
rather than rely on that. An earlier message (2026-10-05) said a copy
"would be drawn as nothing"; that was wrong: it is drawn as nothing only
until the client has asked.

## Intended Behavior

Custom items work on every client from the first moment: at login (and
whenever a custom item is first shown, such as a buddy appearing in a new
outfit) the server sends each custom item's answer to the client before
the client needs it, as if the client had asked (the item query reply,
sent unasked). The client stores it like any answer, so models, icons and
tooltips are right the first time, for the player's own gear and for
everyone they inspect. The custom client (173) reads the same answers.

With that, gearsets (617r) can name new items: copies of existing ones
with a different required level, or new stat lines on existing looks
(a custom item must still use an existing display id: the model and its
pictures come from the client's own files).

## Suggested Implementation Steps

1. Read whether the 3.3.5a client keeps an item answer it didn't ask for
   (the item query reply opcode handler in the original client; test by
   sending one for an uncached item at login and inspecting).
2. A list of the project's custom item numbers (one range, recorded in
   one place) and a login hook (Lua or a source patch) that sends their
   answers; for many items, only those the player will meet soon (gear
   worn by players and buddies near them, their own bags).
3. The 148v test again on a cold cache: a new character wearing custom
   items at first login, drawn right with no re-equip; a buddy in custom
   gear, inspected, right the first time.

## Open Questions

1. If the client ignores answers it didn't ask for, the fallback idea is
   to cause the asking event (a re-equip moments after login). 148v
   rejected that as a race. Acceptable for buddies only, or not at all?
