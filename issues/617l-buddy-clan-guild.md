# 617l - A Guild for Each Clan

## Status
- Created: 2026-09-25
- Phase: 6
- Parent: 617
- Blocked by: 617a (roster: who is in a clan)
- Related: 617k (professions: buddies hand out crafts and consumables to the
  clan), 617j (the clan's shared gear pool), 916 (buddies' in-character chat)
- Priority: Medium

## Origin

Verbatim, 2026-09-25, while designing buddy professions:

> Each clan gets it's own guild auto-created and named by the player, and
> they will use it to chat with each other.

("Clan": a character and its buddies, as in 617j.)

## Current Behavior

**Naming built 2026-09-26, not yet run**: an owner with no guild picks its
first buddy at Sargobras (617b, `src/lua-basic/sargobras.lua`) through an
option that opens the client's pop-up box, and types the clan's name there
(owner, 2026-09-26: "when the player talks to sargobras to select which
character type they want their first buddy to be, after they select an
option a text-pop-up appears"); a death knight types it in the soul
trade's pop-up in Acherus (`death-knight-souls.lua`). If that name fails,
"Let me name our clan" stays in his menu. A typed name is checked (letters and spaces, 2-24; not taken, else a joke and
another try), and the guild is made with the server's own guild command so
its name rules apply, then checked two seconds later; the guild id is kept
in `buddy_clan.clan_guild` and the buddies made so far are invited (the
invite works for characters not logged in). Each buddy made afterwards
joins 5 seconds after it first appears, silently (`sargobras.lua`, the
owner's 2026-09-26 decision; the buddy module no longer adds it at
creation), and at the owner's login any buddy outside the clan is invited
(the founding and a creation can cross).

**The lock built 2026-09-27, not yet run** (`modules/mod-buddies/src/
buddies_clan_lock.cpp`): the five guild requests that would break a clan
(invite, remove a member, leave, disband, hand over leadership) are turned
back at the server's incoming-request hook, before their handlers run,
when the sender's guild is a clan guild; the owner gets a line saying why.
No server patch was needed (the hook `ServerScript::CanPacketReceive` may
drop a request). Game-master commands go round it, so an administrator can
still repair a clan. Checked to compile against the last beta build's
settings, as are the module's other files.

Not built: the gem vault. Before that: nothing of the clan guild was built. Built 2026-09-25: no guild banks (install step E039, `sql/basic/db_world.src/24-no-guild-banks.apply.sql`: every Guild Vault spawn saved in `basic_617l_guild_vaults` and removed; `scripts/validate-basic-state` checks none is left). The stock server
creates a guild from a charter signed by other players, or by a GM command;
a character belongs to at most one guild.

## Intended Behavior

- Every owner character gets a guild of its own, holding the owner and its
  buddies, created automatically; the owner chooses its name. Sargobras
  asks for it when the first buddy is made (Ritz, 2026-09-25), so the guild
  and the clan start together. The owner types it into a pop-up text box
  opened from his conversation menu (the box the stock client shows for a
  conversation option that asks for a code), so no addon is needed. If
  the name is taken (guild names are unique on the server), he asks again
  with a joke until the owner picks a free one.
- The clan uses guild chat to talk among themselves (buddies' lines are
  in-character once the chat module, 916, reaches basic).
- The owner can't leave it; guild banks are disabled on basic (Ritz,
  2026-09-25). The stock server has no setting to switch guild banks off
  (read 2026-09-25 in worldserver.conf.dist); basic removes the guild
  bank objects from the world instead (Ritz, 2026-09-25: "let's remove the
  objects"): every guild bank chest spawn, saved for the revert.

### Decision, 2026-09-26 (Ritz): the guild bank returns, as a gem vault

Verbatim: "How about we re-enable the guild bank, and all buddies treat it
as theirs to access freely. When deposited, gems can stack up to 20, and
maybe they automatically get sorted? Is that possible? Also, only gems can
be stored in the guild bank. Only gems and gold bars."

This reverses the 2026-09-25 "guild banks are disabled" above (still
in force until this is built: E039 removes the vaults today).
- **Every clan guild has its bank back**; the Guild Vault objects return
  (E039 leaves basic's list, or its revert runs).
- **Buddies use it freely**: their guild rank has full rights to every tab
  and to withdraw.
- **Only gems and gold bars** can be put in: every item of the gem class,
  and the Gold Bar. Anything else is refused.
- **Gems stack to 20.** Read 2026-09-26: raw gems already stack to 20, and
  most cut gems stack to 1. A stack size belongs to the item, the same in
  bags and bank (the client computes stacks from it), so "20 in the bank"
  means every gem stacks to 20 everywhere.
- **Sorted automatically** after each deposit.

Answers, verbatim, 2026-09-26:

> the guild bank should just refuse items that aren't gems or gold bars.
> "if item enters guild bank, then copy item to variable, remove item,
> re-create item in bags."

> [cut gems stacking to 20 in bags:] no they have to be 1 per inventory
> slot. Some of the lower quality ones are smaller, like tigerseye and
> malachite - they can stack to the amount that's in the icon, I forget
> exactly but you can create a libs/ directory for a screen recognition
> utility and then you can give it a .png of the two's icon that you drew
> from the client data. Then you can count them, and I can validate.
> [...] make sure you check all of the gemstone icons, not just tigerseye
> and malachite.

> [sort order:] level determines purity and size, colour determines
> magical effects when crushed into enchantments for enchanting

> I don't think we should exchange honor for gems. I think gems should give
> you honor, because you brought them to a safe place.

Read into the design:
- **Refusal without a server patch**: when anything other than a gem or a
  Gold Bar lands in the bank (the guild hook that sees an item arrive),
  the module copies it, removes it from the bank, and makes it again in
  the depositor's bags.
- **Stacks follow the icon**: a cut gem is one per slot; a raw gem stacks
  to the number of stones its icon shows. All 132 gem icons were counted
  by eye on 2026-09-26 and published for the owner to check ("Stones Per
  Icon", https://claude.ai/artifact/5EZz1VNXe9JUm4q8o5VWPH; built from the
  client's icons and the world database). Raw gems whose icon shows more
  than one stone: Malachite 3, Tigerseye 3, Blood of the Mountain 3,
  Earthsiege Diamond 3, Lesser Moonstone 2, Skyfire Diamond 2, Siren's
  Tear 2, Skyflare Diamond 2. Every other raw gem's icon shows one stone,
  or one crystal cluster (18 icons, the Burning Crusade and Wrath rare
  and epic raw gems).
- **Sort by level, then colour**: level is the stone's purity and size,
  colour its magic (the owner's reading of gems, which also shapes the
  enchanting vision in `notes/vision-enchanting-system-update.md`).
- **Gems pay honor** for being brought somewhere safe (see 155t).

What the server offers, read 2026-09-26: the guild hooks see an item move
into or out of the bank after it happens, but none can refuse one, and a
tab's slots are private to the guild object. So "sort after a deposit" needs a small source patch (a re-order of the
tab after a deposit). "Only gems and gold bars" doesn't: the owner's
move-it-back answer works from the hook that sees the item arrive. The
stack size is a world-database change to the gem items. All possible.

## Suggested Implementation Steps

1. Settle the open questions below with Ritz.
2. Server side, in the buddy module (617a): create the guild through the
   core's guild API (no charter) when the owner names it, add each buddy
   as it is created, remove buddies with their owner.

## Open Questions

- (Answered 2026-09-25) Sargobras asks the owner for the guild's name when
  the first buddy is created, so the guild begins with the clan.
- (Answered 2026-09-25) The name is typed into a pop-up text box from a
  conversation option with Sargobras (the stock client's coded gossip box;
  the Lua engine receives the text). No addon needed.
- (Answered 2026-09-25) The owner can't leave the clan guild, and guild
  banks are disabled (Ritz: "guild banks are disabled and you can't leave
  your guild"). So joining a friend's guild is not possible on basic.
- (Answered 2026-09-25) A taken name: Sargobras asks again, with a joke
  about it, until the owner types a free one (as the stock game treats
  taken character names).
- (Answered 2026-09-25) Other players are never invited: a clan guild is
  one owner and their buddies; friends talk by whisper or custom channels.
- (Answered 2026-09-25) **Conflict, settled**: Ritz, 2026-09-25: "In-game player guilds should exist
  though. They're useful abstractions!" But the stock game allows one
  guild per character, and an owner can't leave the clan guild, so no
  owner could ever join a player guild. Which gives way: clan chat moves
  off the guild (a private chat channel per clan, so the guild slot stays
  free for player guilds); the owner may leave the clan guild for a player
  guild (the buddies stay in theirs); or a source patch lets a character
  hold two guilds? (A server-wide layer above guilds is 1007.)
  Ritz, 2026-09-25: "I said I wanted player guilds to exist, I didn't
  intend to imply that they should be ordinary. Check out rao-chat."
  (`/mnt/mtwo/programs/rao-chat`, Ritz's decentralised chat: a room is a
  label, a shared token and its members' addresses; holding the token is
  being invited; rooms nest in a tree, each child room its own invitation,
  "tiers of trust"; labels belong to the reader; you choose who hears you,
  never who hears anyone else.) Confirmed reading (Ritz, 2026-09-25: "Yep
  that looks right"; parked until rao-chat is further along): the stock
  guild slot stays the clan guild, and **player guilds are rao-chat-style
  rooms**, a layer beside the stock guild, not in it. A character may be
  in any number; a guild's sub-groups (officers, a raid team) are child
  rooms; anyone may start one; the same rooms reach across servers (1007).
- (Answered 2026-09-26) Gem vault: a refused item is moved back to the
  depositor's bags; cut gems one per slot, raw gems to their icon's stone
  count; sorted by level, then colour.
- (Answered 2026-09-26) Stacks: "they stack to the number on their icon",
  cut gems included (Tourmaline 3, Zircon 2, Amber 2, the cut Skyfire
  Diamonds 2, Barbed Deep Peridot 3); single-stone and crystal-cluster
  gems stack to 1. A moved-back item needs no mail: "it came from the bag.
  It must have space." The Gold Bar's icon shows one bar. The counts
  page now lives in the project (`docs/HTML/stones-per-icon.html`, made
  by `scripts/generate-stones-per-icon-page`).
- *(Answered above)* **Gem vault, counts to validate**: the Stones Per Icon page. Three cut
  gems also show several stones (the level-55 Tourmaline 3, Zircon 2 and
  Amber 2, the cut Skyfire Diamonds 2, Barbed Deep Peridot 3); by "cut
  gems are one per slot" they stay 1. Right? And do the single-stone and
  crystal-cluster raw gems stack to 1 (they stack to 20 today)?
- (Answered 2026-09-27) Gem vault, tabs: "one free, the rest bought with
  gold. Only a player can unlock a bank tab. Also, there's only 6 slots in
  the guild bank available, with +4 every time a bank tab is unlocked. Or a
  more sensible number such that unlocking all of them gives the full
  guild bank." Read: the first tab is given at the clan's founding; the
  other five are bought at the stock prices by the owner (buddies never
  buy one: bots don't send the purchase request, and only the guild
  master's rank may buy by default). Usable slots start at 6 and grow with
  each tab; a deposit into a slot beyond the allowance is moved back like
  a refused item. The client still draws every slot of an owned tab (98),
  so the allowance is the first N slots of the vault, counted tab by tab.
  The tab prices are server settings (`Guild.BankTabCost0` to `5`), but a
  price of 0 makes the purchase code refuse the tab outright
  (`Guild::HandleBuyBankTab` returns on a zero price), so the free first
  tab is given by the module when the clan is founded, not priced at 0.
- (Answered 2026-09-27) **The gem vault is dropped for now**: "the guild
  bank doesn't work how I remember it does. Okay so let's nix the guild
  bank options for now, leaving it as just a plain bank with no tabs.
  Future design is that we can put one bag in the guild bank per tab, and
  that bag is how many slots we have access to. Putting a different bag in
  will swap them unless there's no space, and then it'll refuse." Not
  easily built: the client draws a tab as a fixed 98-slot grid and has no
  place to put a bag into a tab, so the "bag per tab" needs either the
  custom client or a stand-in (for example, a tab's usable slots set by a
  bag item handed to a clan NPC). Kept as the intended direction; the
  vaults stay removed (E039).
- *(Superseded by the above)* **Gem vault, how many slots per tab**: "+4 per tab" gives 6, 10, 14, 18,
  22, 26 (all six tabs: 26 of the 588 a full bank holds). Numbers that end
  at the full bank: ×2.5 a tab, 6, 15, 38, 94, 235, 588 (recommended: each
  tab bought is a real step, the last one opens everything); or 6 for the
  first tab and each bought tab adding 116.4, 6, 122, 239, 355, 472, 588
  (even steps). Which?
- (Answered 2026-09-26) Gems give honor when sold on the goblin auction
  houses (155t), not when deposited in the vault.
- (Answered 2026-09-26) The Gold Bar's stack: 6.
- (Answered 2026-09-26) The clan guild "can't be disbanded, can't be quit.
  Can't invite any other characters. It's just for a player and their
  buddy-bots." No hook can refuse these, so it takes a small server patch
  on the guild's disband, leave, invite and hand-over requests, refusing
  them for a clan guild (a guild whose id is in `buddy_clan`). Built
  2026-09-27 without a server patch after all: the incoming-request hook
  can drop the five requests (above).
- (Answered 2026-09-26) The clan's name is typed in the pop-up of the
  first buddy's pick, worded as the pick itself (owner: "not a 'let me
  name our clan' but rather 'I want an arms warrior as my first
  buddy-bot, and I'd like to name our clan [textbox]'"); a name that fails
  is asked again with the next pick. A death knight names only the guild
  (not its buddies), in the soul trade's pop-up. A buddy joins the clan 5
  seconds after it appears (owner, 2026-09-26, "apply one, then the other
  some time later"), and says nothing ("nothing needs to be said, it's
  assumed that it is"), built in `src/lua-basic/sargobras.lua`; the
  buddy module no longer adds it at creation.
