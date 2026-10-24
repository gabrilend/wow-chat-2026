# 720 - Hide Shoulders, Beside Hide Helm and Hide Cloak

## Status
- Created: 2026-10-15
- Phase: 7
- Related: 617f (creature outfits: the server shaping what a client
  draws, B047), 175 (custom items told to the client ahead)
- Priority: Low
- State: planned; open questions first

## Origin

Verbatim, 2026-10-15:

> Also, can we add an option to "hide shoulders" like there is for "hide
> cloak" and "hide helmet"?

## Current Behavior

The game client (3.3.5a) has two display toggles in its interface
options, Show Helm and Show Cloak. Each sets a flag on the character that
the server keeps and passes to everyone who sees it; nothing exists for
shoulders, and the client has no checkbox for one.

## Intended Behavior

A character can hide its shoulder piece the way it can hide its helm or
cloak: the item is still worn and still gives its stats, but nobody
(the character included) sees it drawn.

How it works: everything a client draws of another character's gear comes
from the character's visible-item fields, one per slot, which the server
fills from the worn items. A hidden shoulder is the server leaving the
shoulder's visible field empty while the flag is set. The client needs no
change, so the toggle is a chat command rather than a checkbox.

## Suggested Implementation Steps

1. Answer the open questions.
2. A per-character flag, kept with the character (a small table, or a
   spare bit of the character's player flags if one is free and the
   client ignores it).
3. A reversible source patch (B-series) at the place the server sets a
   slot's visible item: for the shoulder slot, with the flag set, write
   nothing.
4. A command, `.shoulders hide` / `.shoulders show`, usable from a macro;
   it updates the visible field at once.
5. In game: hide, look at yourself and at a friend from outside.

## Open Questions

1. (Answered 2026-10-23: "cool") Works on the stock client: the server keeps one "what this slot looks like" value per visible slot for every player, and a source patch writes "nothing" into the shoulder value while the real shoulders stay equipped (stats unchanged; everyone, the wearer included, sees bare shoulders). The game's own hide-helm and hide-cloak are one flag each, with no shoulder flag, so this needs the patch and a chat command to switch it; a plain addon could add a checkbox that sends the command (no AIO). A chat command (no client change), or should a checkbox wait for the
   custom client?
2. (Answered 2026-10-23) "Buddies shouldn't get it." Players only. Buddies too (the owner hiding a buddy's shoulders, or buddies hiding
   theirs at random)?
