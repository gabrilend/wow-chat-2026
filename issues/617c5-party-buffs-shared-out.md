# 617c5 - Party Buffs Shared Out

## Status
- Created: 2026-10-26
- Phase: 6
- Parent: 617c (buddy login and the proximity party)
- Related: 617c2 (the proximity party: who is grouped with whom), 617g
  (buddy talent plans: what a paladin's or shaman's talents improve),
  617n (spell learning: which blessings, auras and totems a buddy knows),
  the playerbots module's paladin and shaman strategies
  (`Ai/Class/Paladin/Strategy/`, `Ai/Class/Shaman/Strategy/`)
- Priority: Medium
- State: plan only; nothing built

## Origin

The owner, 2026-10-26:

> can we make sure that paladins prioritize different judgement spells if
> they're missing on the target? Also, they and shamans with their totems
> are the main classes whose buffs are specific to the party they're with.
> Can you ensure that we tailor our buff usage to the ones who need certain
> things? If a healer usually does kings, which we can message btw and the
> bots can message each other btw, then if they're low on mana we might
> throw out a Blessing of Wisdom if they need it, and swap back for the
> next fight.
>
> though, if we have a rare one like in prot, then we might give that with
> priority. It's mentioned in our talents after all. But, receiver's
> preference always wins, even if you have the improved Blessing of Might
> or whatever. Though, since it's a talent, you'd prefer it when not
> specified and when the recipient can properly use it. Same for shaman
> totems.

> oh also, three paladins in my group. Me, and two buddy-bots. And we only
> have two auras, because they're doubling up.

## Current Behavior

Each paladin and shaman buddy chooses its own blessings, aura and totems
from the playerbots module's class strategies, alone: it does not look at
what the others in its party already give. Seen 2026-10-26: three paladins
in one party (the owner and two buddies) and two auras up, two of them on
the same one. Judgements are chosen per paladin, not per target, so two
paladins can keep the same judgement on a monster while another is
missing.

## Intended Behavior

**One plan per party, per kind of party buff.** For a party's paladins
(auras, blessings, judgements) and shamans (one totem of each element),
the buffs are shared out so that no two give the same one while another is
missing, and each given buff goes to whoever needs it most.

**Who wants what, in this order** (first that applies wins):
1. **The receiver's stated preference** always wins, even over a talented
   blessing (the owner: "receiver's preference always wins, even if you have
   the improved Blessing of Might or whatever"). A preference is stated by
   message: a player whispers or says it in party chat, and buddies tell
   each other the same way (the owner: "which we can message btw and the
   bots can message each other btw").
2. **A buff the giver's talents make rare or improved** (Blessing of
   Sanctuary from protection, Improved Blessing of Might, Improved
   Devotion Aura, a shaman's improved totems): given first when nobody
   asked otherwise, and only to a receiver who can properly use it (Might
   to those who fight with weapons, not to a caster).
3. **What the receiver needs right now**: a healer who usually takes Kings
   and is low on mana gets Wisdom for the next stretch, and Kings again
   for the next fight (the owner: "swap back for the next fight").
4. **The usual by role**: Kings or Wisdom for healers and casters, Might
   or Kings for weapon users, Sanctuary or Kings for tanks.

**Auras**: one paladin per aura; with three paladins, three different
auras. A talented aura goes to the paladin who has the talent.

**Judgements**: on a target, each paladin judges with one the target lacks
(Light, Wisdom, Justice), so a target carries as many different judgements
as there are paladins on it.

**Totems**: one shaman per element is not needed (each shaman has all
four), but two shamans put down different totems of an element when the
party benefits from both (Windfury for weapon users beside Wrath of Air
for casters, if there are two shamans), and never the same one twice.

## Suggested Implementation Steps

1. Read how the playerbots module chooses blessings, auras, judgements and
   totems today (`Ai/Class/Paladin/Strategy/PaladinBuffStrategies.cpp`,
   `DpsPaladinStrategy.cpp` for auras, the shaman's totem strategies), and
   whether it has any per-party sharing (some versions have a "blessing
   manager"); name what is there before adding to it.
2. The party plan: a pure function (C++ beside the buddy module's other
   pure cores, with a Lua model and a test, as the roaming core has):
   given the party's paladins and shamans (each with what it knows and its
   talents) and the receivers (each with role, mana, stated preference),
   it returns who casts which aura, blessing per receiver, judgement per
   target and totem per element. Tests: three paladins give three auras;
   a stated preference beats a talent; Sanctuary goes to a tank first;
   Might never to a caster; a low-mana healer gets Wisdom and goes back to
   Kings after the fight.
3. Preferences by message: a few words in a whisper or party chat ("Kings
   please", "Wisdom", "no Might") stored per receiver for the session;
   buddies say theirs the same way, so the owner can read them.
4. In game: the buddy's buff actions ask the plan instead of choosing
   alone (a patch to the playerbots module, or a buddy strategy placed
   before the stock ones).
5. Seen in game: three paladins, three auras; two shamans, no doubled
   totems; a mana-starved healer given Wisdom.

## Open Questions

1. **Players as paladins in the plan.** The owner is a paladin too: should
   buddies plan around the auras and blessings the owner gives (read from
   what is on the party), and leave the owner's choice alone?
2. **How a preference is said.** Which words, in which channel, and does it
   last until logout or until changed?
3. **Judgement order** when there are fewer paladins than judgements:
   which one first (Wisdom for a mana-using party, Light for a melee one)?
