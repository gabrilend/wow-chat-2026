# 630 - Sargobras, the Unseen Guild Master, and Belonging to Many Guilds

## Status
- Created: 2026-10-20
- Phase: 6
- Related: 617b (Sargobras), 617l (a guild for each clan), 617b2
  (whisper Sargobras), 189e (Sargobras his own patch), 192 (econ, which
  takes Sargobras too)
- Priority: Medium
- State: planned; nothing built

## Origin

The owner, 2026-10-20, asked how Sargobras's scripts should travel with
his patch (189e), verbatim:

> he is his own patch. he deserves all the space to do with as he
> chooses. for he is the real guild master. he sometimes logs on to each
> guild's roster, with no record of his arrival nor departure, and views
> it as if he was an other. nobody ever sees him online, but sometimes
> when they login it says "Sargobras has logged off." just like it would
> with a guild member. As if he left as soon as they arrived. But only if
> they're the only guild member online. Yes, this means we'll need a patch
> that allows players to be in as many guilds or clans as they'd like,
> viewable and selectable through the UI.

## Current Behavior

A character is in one guild at most (the game's own rule). Each clan (a
character and its buddies) gets one guild, named by its owner at
Sargobras (617l). Sargobras is an NPC, not a guild member, and appears in
no roster.

## Intended Behavior

1. **Sargobras is in every guild, unseen.** He is on every guild's
   roster as its real master, never shown online and with no record of
   when he came or went.
2. **"Sargobras has logged off."** When a character logs in and is the
   only one of the guild's members online, sometimes the guild's own
   "has logged off" line for him appears, as for any member: as if he
   left as soon as they arrived. Never when another member is online.
3. **Many guilds.** A player can belong to as many guilds or clans as
   they like, seeing and choosing between them in the game's own guild
   window.

## Suggested Implementation Steps

1. Find how the client shows guild membership: one guild per character
   in the 3.3.5a client's guild frame and its packets (the guild id in
   the character's own fields). Whether "many guilds, chosen in the UI"
   can be shown with the stock client (switching the active guild, a
   chat command or a gossip menu that changes it) or needs the custom
   client (`/mnt/kaun/custom-client/`).
2. A source patch, per that answer: a character's set of guilds, one
   of them active at a time, saved in the characters database.
3. Sargobras in every roster: a guild member row the server keeps for
   him in each guild (a character that never logs in), hidden from
   online lists.
4. The logged-off line: at a character's login, if no other member of
   the active guild is online, by some chance, the guild's own sign-off
   event for him, so it looks and sounds like any member's.
5. Tests: the roster has him, never online; the line appears only when
   the character is the only one on.

## Open Questions

1. **How often "sometimes"?** Each lone login, one in a few, or once a
   day per character?
2. **Many guilds in the stock client**: the 3.3.5a client shows one
   guild; is switching which one is shown (step 1) what "viewable and
   selectable through the UI" means, or is it the custom client's to
   show them all at once?
3. **Clans and guilds**: is a clan (617l) one of the guilds a player
   belongs to, so their own clan is always among them?
