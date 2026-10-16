# 617y - Spoken Orders: "go sell", "follow me", "follow so-and-so"

## Status
- Created: 2026-10-12
- Phase: 6
- Parent: 617 (buddy bots)
- Related: 617h1 (the selling trip), 617a5 and source patch B045 (buddies
  take no bot-module chat commands), 617m (language-model buddies), 917
  (tool calls)
- Priority: Medium
- State: planned; open questions first

## Origin

Verbatim, 2026-10-12:

> can we add a mechanic where after a bot says "my inventory is full" we
> can say "go sell" to them and any bot that has a full inventory will
> return to the nearest town and sell their goods? it might be most or
> all of them, and then the player probably should follow them back or
> they'll get eaten or slain. it's important to always stay by your
> peers, which is why you should also be able to say "follow me" or
> "follow so-and-so" and then the buddy bot who hears you will do that
> thing. eventually we can add llm capabilities, and make it narrate
> itself. Then, we use the embedding model to parse what it said into one
> of the tool call possibilities instead of training it to speak like a
> robot.

Answers, 2026-10-12 (verbatim):

> we need the whisper to know when we should send them.

> well, if any of them have full inventories they'll join the journey,
> and if all of them do, the player might be forced to, especially if
> they're somewhere dangerous like Outland.

> only people in the player's party... or raid, maybe. >:) and the
> messages should go to the largest groupsize log that a player is a part
> of - raid if in a raid, party if in just a group with one or more
> player, and as a whisper if alone. If one player in a raid says "go
> sell" then any buddy-bots with full inventories will do so. If they say
> follow me, though, to the largest groupsize channel, only the player's
> clanmates would agree. Because saying "follow me" means "I need a team"
> and you guys know best how to work with each other.

## Current Behavior

**"Attack", 2026-10-15; syntax-checked, not yet rebuilt or run**
(`buddies_orders.cpp`, ObeyAttack). The owner: "There should be a macro
based command that tells my buddy-bots to 'attack my target' as in,
engage / and I should be able to name them by name...". "attack" or
"engage" said in party, raid or /say sends every buddy of the speaker at
the speaker's target; "attack Zugsqonuw Usanda" only those named;
whispered "attack" to a buddy, that buddy. Only the speaker's own buddies
obey, since the target is the speaker's. A missing target or an unknown
name is told to the speaker. The order goes straight to the bot module's
"attack my target" action; its chat commands stay closed to buddies
(B045). As a key: a macro "/p attack" or "/w Zugsqonuw attack" on the
action bar, bound to a key. A whispered order also draws the buddy's
placeholder answer in the other faction's tongue (617a5).

**Not live yet (2026-10-13).** The owner tried "go sell" and it did
nothing: the running server is the build of 2026-10-03
(`installed-files-basic/bin/worldserver`); the build carrying the orders,
the selling trip and B048 finished 2026-10-12 22:11 in the shadow
install and has not been promoted. Other spoken commands are ignored on
purpose (B045, owner 2026-09-25). Seen the same night in Sen'Jin Village
(a town circle, 75 yards): a buddy wandered from townsperson to
townsperson instead of selling. In that build a town visit sells only
grey junk (and everything at nine-tenths full, where there is no auction
house); the rest waits for the selling trip. The owner also saw it run
rather than walk in town; the town visit walks, the walk between areas
runs. To check after promotion, with `.buddy trace <name>`.

**"My bags are full" and "go sell", 2026-10-12, syntax-checked, not yet
built** (`modules/mod-buddies/src/buddies_orders.cpp`; the selling trip's
start in `buddies_roam_strategy.cpp`):
- a buddy whose bags reach full says "My bags are full." once (again only
  after they have had room and filled again), where its owner sees it:
  the owner's raid chat, else party chat, else a whisper (sent to the
  group's members directly, so a buddy in a far party of its own still
  reaches them);
- "go sell" (any case; "please" allowed), said in party or raid chat or
  /say by a player, reaches the buddies of every player in the speaker's
  party or raid (the speaker's own when alone); whispered to one buddy, that
  buddy, when the speaker is its owner or in its owner's group. Each
  hearer with full bags answers "Off to sell. Come with me if you can."
  the same way and sets off on the selling trip;
- the selling trip sets off only on that order now (it used to start by
  itself when the bags were full); a full buddy keeps roaming until told;
- the bot module's own "My bags are full" whisper at every failed pickup
  stays silenced (B048): the one line above replaces it.

Before that:

- **Full bags:** the server now running (built 2026-10-03) has a full
  buddy keep looting while the bot module whispers "My bags are full" at
  each failed pickup. Written since then and in the next build: the
  selling trip (617h1), where a buddy past full walks to the nearest town
  and sells on its own, and B048, which stops the whisper.
- **Orders (still):** buddies ignore every bot-module chat command (B045, owner
  2026-09-25: buddies run on their own rules; the language-model layer
  reaches the same actions later as tool calls, 617m / 917).

## Intended Behavior

Spoken orders, heard by buddies within hearing (say, party, or a whisper
to one), each a small fixed action:
- **"go sell"**: every buddy that hears it and has full bags (past the
  selling trip's threshold) leaves on its selling trip now, to the nearest
  town. Its owner should follow, or the buddies may die on the road ("it's
  important to always stay by your peers").
- **"follow me"**: the buddy that hears it follows the speaker, instead
  of roaming, until told otherwise.
- **"follow <name>"**: the buddy follows that player or buddy.

Later (617m): the buddy narrates itself in its own words through a
language model, and what it says is matched to one of these actions (a
tool call) by an embedding model, rather than the buddy being trained to
speak in commands.

## Suggested Implementation Steps

1. Answer the open questions.
2. The hearing: the Lua chat hook (as Sargobras listens for a clan name)
   matching the phrases, the speaker the buddy's owner (or any player:
   open question 2).
3. "go sell": start the selling trip at once for each hearer with full
   bags (617h1's entry point, from the buddy module through a Lua call or
   a roster flag it watches).
4. "follow": a follow state in the buddy module's strategy, in place of
   roaming, with how it ends (open question 3).
5. Tests offline; then in game.

## Open Questions

1. (Answered 2026-10-12: the order is wanted; read as: the trip waits for
   it.) Is that right, or should a full buddy also set off by itself after
   a while unheard?
2. (Answered 2026-10-12: players in the speaker's party or raid; "follow
   me" only the speaker's own buddies, its clan.)
3. How does "follow" end: "stop", the owner logging out, a town, a
   dungeon, after a time?
4. (Answered 2026-10-12, for "follow me": said to the group's largest
   channel, the speaker's own buddies agree.) "follow <name>": the named
   one's buddies, or the speaker's?
