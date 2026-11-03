# 623 - Buddies Offer to Trade When You Stand Still

## Status
- Created: 2026-10-15
- Phase: 6
- Related: 617j (giving within the clan: needs the same buddy-opened
  trade window, "nothing in the module does that yet"), 617h (the auction
  house: what a buddy keeps to sell), 622 (its weapon record: what it
  might offer)
- Priority: Medium
- State: planned; redesigned 2026-10-30 (buddies mail and accept trades, never open them)

## Origin

Verbatim, 2026-10-15:

> also we should be able to trade to buddy-bots? And they should be able
> to give things to us? If we stand still for too long, they can offer to
> trade with us... and when the offer is about to expire, another nearby
> buddy-bot prioritizes walking over and being ready to trade you as soon
> as the previous one expires... whichever one's not busy or in combat.

## Asked again, 2026-10-26

The owner: "If I want to give an item to a buddy-bot, they currently
won't accept a trade request. Can we make it so they do? But only if
they're in my clan." So the first piece of this issue, on its own: a
buddy accepts a trade opened by a player of its own clan (its owner and
the owner's clan mates), and refuses anyone else's, saying so.

## Current Behavior

**Earmarks and treats by mail, built 2026-10-31, compiled the same day, not yet seen in game**
(syntax-checked; the town visit's mailbox errand, `buddies_town.cpp`):
- an item is earmarked for the owner when it is gear the owner can wear
  now, not bound to the buddy, that the buddy has no use for itself, and
  that scores at least 5% higher by the owner's own stat weights (the bot
  module's scorer, asked for the owner) than what the owner wears in the
  slot it would go to (or the slot is empty). Earmarked items join the
  bind-on-equip epics already mailed, at the next mailbox of a town visit
  (piece 2; the death knights' mailbox outside a town is not reached yet,
  as the town visit needs a town circle there);
- at each mailbox stop, one time in ten, a treat: usually a copper with
  "I found a lucky penny for you.", one treat in four a purse of its level
  squared times 28 copper (about 10 gold at 60) from its own money, with
  a line in its class's voice (the rogue's is the owner's own words).
**Earmarked items in a trade, built 2026-10-31, waiting for the compile**
(piece 3; syntax-checked; source patch B068 round-tripped on a copy;
`buddies_trade.cpp`): when a trade with a buddy begins, the bot module
asks the buddy module first; a buddy opens its side itself and, when the
trader is its owner, puts in its earmarked items (the same the mailbox
would mail), up to six, through the server's own set-trade-item step; a
clan mate's trade opens with nothing put in. The bot module's whispered
list of the whole inventory is skipped for buddies. The bot module then
accepts whatever the owner offers (buddy accounts are not on its
random-bot list, whose bots bargain).
**"go sell" by bags and walk, built 2026-10-31, waiting for the compile**
(piece 5's first part; the rule in `roam/buddy_sell_core.h`, checked by
`scripts/test-buddy-sell`, 8 checks; the order in `buddies_orders.cpp`):
each buddy hearing "go sell" weighs the share of its bag spaces holding
things it would sell against a bar that rises smoothly with the straight
walk to the nearest vendor on its map (half full within 200 yards, nine
tenths from 1500, in a line between; the agent's numbers), and tells its
owner what it decided and why ("My bags are 65% full of things to sell,
and the vendor is pretty close, so I'm just gonna go sell." / "... only
40% ... so I'll keep going."); "everyone go sell" (or "everybody") sends
every hearer. The selling trip no longer asks for nine-tenths-full bags
itself; the order decides.
Not built: split food and water asked for in a trade (piece 3's second
half), piece 4 (the full-bags offer and arcs), the rest of piece 5 (the
full buddy asking whether it may go, "I'm scared" and the impromptu party
from the solo record and live danger, hearthing back together), piece 6
(buddy-to-buddy giving), and piece 8's refusal of others' trades beyond
B058's clan rule.

**Clan trades, built 2026-10-26 (source patch B058, not yet compiled):**
a player in a bot's own guild may now open a trade with it, and the bot
accepts what it is given; anyone else is refused as before ("I'm kind of
busy now"). A buddy's clan is a guild (617l), so the owner and clan mates
can hand a buddy items even when it is out of their group (in town,
617c2). The change: the bot module's two trade refusals ("neither master
nor group member", "ungrouped without full security", in
`TradeStatusAction::Execute`) each gain "and not in the bot's guild".
Gated to the buddy profiles (basic, cc-test). Round trip and compile
checked; not yet seen in game (whether buddies' trimmed strategies still
react to a trade window is to be seen). The rest of this issue (buddies
offering trades, the helper walking over) is not built.

Before:

- **Player to buddy: works today, through the bot module.** Opening a
  trade window with a bot makes it show its inventory and take part in
  the trade (`docs/playerbots/Playerbot-Commands.md`, Reactions: "open
  trade window | show inventory and start trading"). Not yet tried with a
  buddy in this project.
- **Buddy to player: nothing.** No buddy ever opens a trade window; the
  buddy module has no code that starts a trade between two characters
  (617j's clan giving waits on the same thing).
## Intended Behavior

**Redesigned 2026-10-30: buddies never open trades.** The owner, word
for word:

> buddy-bots should mail upgrades to you. They shouldn't open trades
> with the player, they should just accept trades when asked to trade.
> If a player asks to trade with a buddy-bot, they should give any items
> that are "earmarked" for the player to them. So upgrades and stuff. If
> the player asks for food or water we can give them to them as well,
> but the buddy-bot will always split stacks of them to ensure they have
> some too.
>
> buddy-bots should only mail things when they're in town. Not just
> capital cities, but wherever a mailbox is found. There's a mailbox in
> the DK starting zone that's outside of a town so keep that in mind.
>
> if the buddy-bot says to the player "my bags are full" they might also
> say "my bags are full, can I give you something" and then they should
> walk to the player and follow them in the dynamic arcs and such until
> combat starts again, or until they get a resolution to their concern,
> which is their full inventory. If the player trades with them, they can
> pass off some stuff, but if they trade and then say "go sell" then
> whichever bots (that heard the "go sell" message) that have above a
> certain threshold of inventory spots taken by sellable things will go
> and sell them. If they give the player a couple items it's likely that
> they still need to sell, but, they might be able to push it off a bit.
> If their inventory is full, their "inventory economy" will encourage
> them to give items away, to the player or to other buddy-bots. If the
> other buddy-bots are in range and they want to give an upgrade or a
> consumable or whatever, then they should just do that automatically
> through lua or whatever instead of using the trade window bot-to-bot.
> But they should still walk to each other, face each other, and do the
> talking emote with a random 0-1 second delay, then once it's done they
> should both go their separate ways, having exchanged items of note.

What it means, piece by piece (the stand-still offers and the queue of
buddies waiting to trade, designed 2026-10-15, are dropped):

1. **Earmarked for the owner.** A buddy keeps a mark on items meant for
   its owner: upgrades for the owner (by the owner's own stat weights),
   and the like. Never quest items: a buddy doesn't take them at all
   (the owner, 2026-10-30, word for word: "buddy-bots should not take
   quest items. Their quests are completed when the player completes
   them, so there's no reason for the buddy-bots to take them. They
   should leave them on corpses and leave the nodes behind."; 617j).
   **Money now and then, as a treat** (the owner, 2026-10-30, word for
   word: "maybe once or twice as a treat. Every once in a while. They'll
   usually just send like 1c and say "I found a lucky penny for you." or
   10g pieces for a level 60 and say "this fell out of some rich guy's
   pocket while I was walking close behind him in Stormwind, don't worry
   about it" says the rogue, that sort of thing."). Rarely, a mail
   carries a little money with a line in the buddy's own voice: usually
   a copper ("I found a lucky penny for you."), sometimes a sum fitting
   its level (10 gold at 60), the line fitting its class (the rogue's
   lifted purse).
2. **Mailed from any mailbox.** When a buddy with earmarked items is
   near a mailbox (in any town, not only capitals; also the mailbox
   outside any town in the death knights' starting zone, the
   Scarlet Enclave), it mails them to the owner.
3. **Accepting trades.** A buddy accepts a trade the owner (or a clan
   mate, as asked 2026-10-26) opens, and puts in its earmarked items.
   Asked for food or water, it puts those in too, always splitting a
   stack so it keeps some itself.
4. **Full bags.** A buddy whose bags are full may say "my bags are full,
   can I give you something", then walks to the owner and follows in the
   arcs (617e13's shared arc placement) until combat starts again or its
   bags are no longer full.
5. **"go sell" after a trade.** Every buddy that hears "go sell" and has
   more than a threshold of its bag spaces taken by sellable things goes
   and sells (617h's errand); one that gave a few items away may fall
   under the threshold and stay. The threshold grows with the walk
   (the owner, 2026-10-30, word for word: "depends on how far the vendor
   they're gonna walk to is. 50% is if the vendor is nearby, 80 or 90% if
   it's far. How about if the player says "everyone go sell" then all the
   buddy-bots do it?"): 50% of its bag spaces when the vendor is near,
   rising to 80 or 90% when it is far; "everyone go sell" sends every
   buddy that hears it, whatever its bags.
   **Asking and saying why** (the owner, 2026-10-30, word for word: "If
   the buddy-bots inventory is full, they ask if they can go. when the
   party hears "go sell" then they can say like "my inventory is 65%
   full, and it's pretty close, so I'm just gonna go sell" and only take
   longer trips if it's full or near to it."; and on the threshold's
   shape: "sorry yes I meant continuous."). A buddy with full bags asks
   whether it may go and sell. On "go sell", each buddy that hears it
   decides by how full its bags are against how far its vendor is, on a
   continuous scale (no steps, no fixed boundary: about half full is
   enough when the vendor is close, and the farther the vendor the
   nearer to full it must be), and says what it decided and why in its
   own words ("my inventory is 65% full, and it's pretty close, so I'm
   just gonna go sell"). The looting-rate rule proposed the same day
   (go when carried sellables match what the trip would cost in loot)
   was declined: "um that "when to go sell" rule isn't a good idea."
   **Too dangerous to go alone** (the owner, 2026-10-30, word for word:
   "keep in mind that if we're in the depths of Outland or similar, a
   buddy-bot might not be able to make it back alone to go sell. So they
   might refuse, if they're the only one, and say "I'm scared" and then
   sufficient buddy-bots can join them until they feel safe enough to
   make it. Prioritizing those with the fewest remaining inventory slots,
   or rather, those who have the most to sell."). A buddy whose way to
   the vendor is too dangerous for it alone refuses and says so ("I'm
   scared"). Other buddies then join it, the ones with the most to sell
   first, until the group feels safe enough for the way (danger judged
   live, as a road's, 617e4c), and they go together.
   **How safe is judged, and the trip there and back** (the owner,
   2026-10-30, word for word). On safe enough: "they should, always, have
   a general conception of what kinds of foes they alone can defeat. We
   will use this mental model. They should also note who would be
   travelling back with them, and build up an impromptu party so they
   walk together. They should try and generally walk in formation for
   this but it's okay if they drift apart, so long as they are able to
   help each other when needed." On who stays with the owner: "they
   might leave you in the dust." On the hearthstone: "a scared buddy will
   be scared on the return trip as well. They should return together. If
   one hearths, they should all hearth, and ride back to you if needed.
   This also isn't just outland, a player could be level 30 and questing
   in the hinterlands if they want." So:
   - each buddy always carries a sense of which foes it alone can beat;
     the way's live danger is weighed against that, and against what the
     buddies going with it could beat together;
   - those going form an impromptu party and walk together, loosely in
     formation, drifting apart only as far as still lets them help each
     other;
   - nobody is held back for the owner: they may all go;
   - the same party comes back together, as scared on the way back as on
     the way there; if one of them uses its hearthstone, they all do,
     and ride back to the owner when needed;
   - anywhere the owner is above the buddies' strength, not only Outland
     (a level 30 owner questing in the Hinterlands).
   With full bags and no trip possible, a buddy keeps looting and leaves
   the items behind (617j).
6. **The inventory economy.** A full inventory pushes a buddy to give
   things away: to the owner (above) or to another buddy in range that
   wants them (an upgrade, a consumable). Between buddies no trade
   window opens: they walk to each other, face each other, each starts
   the talking emote after a random 0 to 1 second delay, the items move
   by script (the buddy module or Lua), and they go their separate ways.
7. **The owner's side.** The owner can still open a trade with any buddy
   at any time.
8. **Other players** (the owner, 2026-10-30, word for word: "buddy-bots
   can talk to others, but they should be polite and curt in general,
   and never give them anything, even if it'd save their life."). A
   buddy talks with players who aren't its clan, politely and briefly,
   and gives them nothing, ever: no trade from them is accepted with
   anything in the buddy's side, whatever the need.
## Suggested Implementation Steps

1. Try the player-to-buddy trade in game as it is; write down what the
   bot module does with what is put in the window.
2. The earmark: a per-buddy list of items meant for the owner, filled
   when loot or a purchase would be an upgrade for the owner; kept on the
   buddy (its own state, freed when it logs out, rebuilt from its bags at
   login).
3. Mailing at a mailbox: a mailbox in range (any game object of the
   mailbox kind, wherever it stands) sends the earmarked items to the
   owner.
4. Accepting the owner's trade: earmarked items placed in the buddy's
   slots; food or water when asked, a stack split so the buddy keeps
   some.
5. Full bags: the line, then following in the arcs until combat or
   room; "go sell" heard by each buddy, the threshold of sellable bag
   spaces deciding who goes.
6. Buddy to buddy: walk together, face, talking emote after a random
   0 to 1 second delay, items moved by script, part.
7. In game: a buddy with an upgrade for the owner mails it at the
   Razor Hill mailbox and at the Scarlet Enclave's mailbox; a trade opened by
   the owner hands it over; "go sell" sends only the fuller buddies.

## Open Questions

1. (Answered 2026-10-30, the redesign above) What does a buddy put in
   its offer: earmarked items (upgrades for the owner), and food or water
   when asked; buddies never open trades.
2. (Answered 2026-10-30) How long is "standing still too long": no
   longer asked; nothing opens on standing still.
3. (Answered 2026-10-30) Should a buddy say something as it opens the
   window: it never opens one; with full bags it says "my bags are full,
   can I give you something".
4. When a player puts an item in a buddy's window: does the buddy always
   accept, or judge it (it would accept an upgrade, refuse junk)?
   **Answered 2026-10-30** (the owner, word for word): "the buddy-bot, if
   given stuff, should not give it back. Eventually we can request
   things, but that requires LLM capability we don't have the hardware
   for yet. Not at scale, at least." It keeps whatever it is given.
   Asking a buddy for things waits on language-model capability.
5. The "go sell" threshold: what share of a buddy's bag spaces taken by
   sellable things sends it to sell (half? three quarters?) **Answered
   2026-10-30:** by the vendor's distance, 50% near to 80-90% far;
   "everyone go sell" sends all (above, word for word).
6. Where does "near" end and "far" begin for the threshold (yards to the
   vendor, or minutes of walking)? **Answered 2026-10-30** (the owner,
   word for word): ""near" should be discrete, instead of relying on
   breakpoints and magic numbers, it should scale and be dynamically
   calculatable at any time with any conditions." Then, asked whether
   "discrete" meant continuous: "sorry yes I meant continuous." No
   boundary: how full is full enough slides with the vendor's distance
   (Intended Behavior 5). A looting-rate rule proposed the same day was
   declined.
7. Where does a buddy's sense of "foes I can beat" come from: worked out
   from levels, gear and the foe's rank, learned from its own fights, or
   both? Asked back by the owner, 2026-10-30: "tell me, how are it's
   fights being written down? Maybe we can use some of that machinery."
   Explained in conversation: nothing writes fights down yet; 625e's
   fight log is designed (raw in RAM, distilled to disk after each
   fight), and the world positions recorder (617e14a) is built but
   records only where everyone is every 5 seconds. Proposed: the same
   fight log also notes, per foe, what it was and how the fight went, and
   each buddy's sense is a starting guess from levels and rank firmed up
   by those notes. **Answered 2026-10-30** (the owner, word for word):
   "well this doesn't really help us in determining fighting
   capabilities. How about whenever a buddy-bot defeats a foe on their
   own entirely with no help at all, we record the conditions that the
   fight had, and they can estimate based on that? Things like... enemy
   health, enemy dps, how much health we lost in the fight, how much mana
   we spent, how long it took, if we used consumables (gold cost to
   fight), etc. Then, if we ever have a fight that is "more" or "better"
   in each of the parameters, we can replace the old record with the new
   one. Whenever the bot is changed in level, it should forget these
   datas, and whenever they change class, they forget the datas. If they
   go into storage they should remember, and stand-ins should never
   remember this stuff - they always are brave and vigilant. The bot is
   weighing several different economies for their abilities and stuff,
   so if we can provide them useful information about the various costs
   a particular monster would require to defeat, then we should try and
   generate that information without being wasteful. We don't need to
   track arcs or curves in the statistics for this, just what they can
   reasonably handle themselves." So, the **solo record**:
   - written only when a buddy kills a foe entirely alone, with no help;
   - it holds the fight's conditions: the foe's health and damage per
     second, the health the buddy lost, the mana it spent, how long it
     took, the gold cost of consumables used, and the like;
   - a later solo win that is more or better in each of those replaces
     it; no curves or histories are kept, only what it can handle;
   - forgotten when Sargobras changes the buddy's level or its class
     changes (ordinary levelling keeps it; details below); kept
     while it is in storage (dormant); stand-ins never keep one (they are
     always brave);
   - read in two places: "safe enough" for a selling trip (above), and
     the ability economies (625's family), as the costs a foe would ask
     of it; worked out cheaply, from what the fight already counts.
   **Its details, answered 2026-10-30** (the owner, word for word, each
   to the question asked):
   - replacing: "the record is only updated when something is more
     developed in every dimension that it records. The decisionmaking
     that comes *from* the records will be more dynamic. A decision only
     lasts as long as it's needed, and it informs the bot's economies."
   - kinds: "should have categories for player classes, and we sort NPCs
     into them. So a spellcasting NPC would be similar to a mage or
     something." One record per player class; every creature is sorted
     into the class it fights like (a spellcasting creature as a mage).
   - a foe never fought: "yes. It should also feel emboldened with allies
     nearby, but it shouldn't calculate exactly - it should simply
     multiple it's own value by 3 if it has 3 allies, 4 if it has 4
     allies, etc." The foe's health and damage (game data) are compared
     with the record of its class; with allies near, the buddy's own
     value is multiplied by their number (3 allies, times 3).
   - help: "buffs don't count. This is only for monsters that they've
     fought on their own entirely. But buffs are fine." A buff before the
     fight leaves it solo; any help during the fight doesn't.
   - forgetting: "only when Sargobras changes your level. Levelling up
     via normal means shouldn't affect it." Forgotten only when Sargobras
     sets the buddy's level (a re-made tier, a rebirth) or its class
     changes; ordinary levelling keeps it.
   - stand-ins: "yes": never scared, never refusing a trip.
   **The record's core built 2026-10-30** (`roam/buddy_solo_core.h`, plain
   arithmetic, checked by `scripts/test-buddy-solo-record`, 18 checks):
   the kinds come from the game's own creature classes (warrior, paladin,
   rogue, mage: `unit_class`), the record per kind, replaced only by a fight
   more in every one of its six numbers, judging by the record times the
   allies near, forgetting all at once, stand-ins keeping none and always
   brave. **Wired in 2026-10-31, compiled the same day, not yet seen in game** (syntax-checked;
   `buddies_solo.cpp`, its table `buddy_solo_record` from install step
   E076): twice a second a buddy's fight is watched from its first blow;
   anyone but the buddy and its pets on the foe's threat list (a heal, a
   friend's blow), or a second foe on the buddy, spoils it; the foe dying
   with the buddy standing is a solo win, its numbers (the foe's health at
   the start; the buddy's health lost, resource spent and seconds; the foe's
   damage per second as health lost over seconds; gold cost 0, since
   buddies use no paid consumables in fights yet) handed to the record and
   saved when they became it; read back at login; forgotten when a buddy is
   made again at its owner's level (`buddies_stage.cpp`, the remake); a
   stand-in keeps none. `BuddySoloCanTake(buddy, foe, allies)` answers for
   a foe never fought (its weapon damage over its attack speed for its
   damage per second). Not yet asked by anything: the selling trip's
   "safe enough" (piece 5) and the ability economies are its readers to
   come. The other session's fight picture (`buddies_fight_state.h`) was
   not used: it is filled only while the forward pass plans a fight.
