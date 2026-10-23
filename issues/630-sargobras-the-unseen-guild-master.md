# 630 - Sargobras, the Unseen Guild Master, and Belonging to Many Guilds

## Status
- Created: 2026-10-20
- Phase: 6
- Related: 617b (Sargobras), 617l (a guild for each clan), 617b2
  (whisper Sargobras), 189e (Sargobras his own patch), 192 (econ, which
  takes Sargobras too)
- Priority: Medium
- State: a design reference, not built for any current profile (the
  owner, 2026-10-20: "the current design doesn't have space for it, so
  alas we cannot include it"); the standard future profiles design toward
  (`docs/roadmap.md`, Project-wide decisions)

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

Asked whether he shows only when you're the only member online, and how
the clan relates to many guilds, the owner, 2026-10-20, verbatim:

> only online when you're the only player online, right? Note this
> behavior is impossible with buddy-bots because players are given a clan
> for them that cannot include other players. HAHAHA TRICKED YOU SARGOBRAS
> let it be known that in future profiles this behavior might be allowed
> to occur, structurally as a mechanic. But, the current design doesn't
> have space for it, so alas we cannot include it. However in the future,
> we should have this be the standard, and each design should reference
> it. (lawyer giving case studies)

> yes the clan is all of them. the tribe of tribes, one for each half of
> the life. Horde vs Alliance, Rando vs Stranger.

## Why no current profile can build it

The line appears only when the character is the only member of the guild
online. In basic (and cc-test, and econ as planned), a player's guild is
their clan: themselves and their buddies (617l), and no other player can
join it. So "the only member online" is always true and the moment means
nothing: there is no one else whose absence makes his leaving felt.
Sargobras outwits the design, as the owner put it. A profile whose guilds
hold several players, or whose player belongs to several guilds (step 3),
makes room for it.

Told no current profile can build it, the owner, 2026-10-20, verbatim:

> the good news is, you can still walk around with other players. It's
> just, the combined groups will always have two of each character, and
> they'll be the ones who are in combat the most (targets, to bring
> people toward AoE opportunities, rewarded on dps meters)

So players still travel together: two clans walking as one group hold
two of each character (each player's own, side by side), and those pairs
are the ones most in the fight, the targets that draw everyone toward
area-damage chances, and rewarded for it on the damage meters.

## As a design reference

Every new profile's design says how it would make room for the unseen guild
master, or why it cannot, citing this issue the way a case is cited. The
clan, when there are many guilds, is all of them: "the tribe of tribes, one
for each half of the life. Horde vs Alliance, Rando vs Stranger."

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
   day per character? (Asked again when a profile first makes room for it.)
2. **Many guilds in the stock client**: the 3.3.5a client shows one
   guild; is switching which one is shown (step 1) what "viewable and
   selectable through the UI" means, or is it the custom client's to
   show them all at once? (The same.)
3. **Clans and guilds.** Answered 2026-10-20: the clan is all of them
   ("the tribe of tribes").
4. **"one for each half of the life. Horde vs Alliance, Rando vs
   Stranger"**. Answered 2026-10-20, verbatim: "no it just means...
   characters can't talk to the other faction, they are the strangers.
   Your faction is the randos. As determined by tabard, or at a glance,
   race." And where it belongs: "this belongs in the team-sport based
   battlegrounds, which is certainly an option, especially if we combine
   with City of Heroes and use their medi-porters... Then we can heal and
   rewind the rest. [of the creatures, when their corpse_fade() distance
   expires.]" (written into 629, battleground fronts).
5. **"two of each character"**: when two players' groups walk together,
   is it each player's character beside its buddy twin (the same
   character twice), or two players' characters of each class? And are
   the pairs what the enemy aims at by design (a rule), or simply the ones
   most often in the fight?

## Decision, 2026-10-23: build the server side now

Asked what "as many guilds or clans as they'd like, viewable and
selectable through the UI" means, given the stock client shows one guild
per character: "Ah yes that's a custom client issue. For now, just build
the server-side part, and then leave the client work up to the
custom-client. We want Sargobras (and players) to be able to be in
multiple guilds at once."

What the server side is, from the stock schema (read 2026-10-23): the
characters database allows one guild per character (`guild_member` has a
unique key on the character), and the client shows the guild in the
character's own fields. So:

- **Memberships:** a table of our own holds every guild a character
  belongs to, with its rank in each. The stock `guild_member` row is the
  active one, the one the stock client shows. Switching the active guild
  moves the stock row quietly (a source patch, so no "has left the guild"
  and "has joined" lines go out to either guild), keeping the rank from
  our table. How a player switches with the stock client: a command for
  now (the custom client draws its own chooser later).
- **Sargobras in every roster:** he can't be a stock member of every guild
  (the same unique key), so the server adds him to each guild's roster as
  it is sent, never online, with no joined or left record.
- **"Sargobras has logged off.":** at a character's login, when no other
  member of its active guild is online, now and then the server sends the
  guild's own signed-off event for him.
- **Client work** (seeing every guild at once, a chooser in the guild
  window) is the custom client's (`/mnt/kaun/custom-client/`).

The profiles where it matters: none that run today (basic's guilds are
clans, 617l); the server side is built so a profile with shared guilds
can switch it on.
