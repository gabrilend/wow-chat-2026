# 161 - Faction by Reputation

## Status
- Created: 2026-09-26
- Phase: 1 (profile model: a rule that changes what a faction is)
- Blocked by: none for the planning; which profile it belongs to is open
- Priority: Low (planned only)
- Planned only: the owner framed it as "issue files for a different
  profile or patch".

## Origin

Verbatim, 2026-09-26:

> what if (issue files for a different profile or patch) what if you could
> pick a faction by just... having a reputation bar for each faction, and
> being able to select the "at war" button if you wanted to be able to
> attack them. And their guards and such would be levelled just about to
> the level of monsters in the area, plus 4, just like in Outland. It gave
> you reputation for the other faction, but it gives less than it takes.
> if you are hated by both your character loses their hearthstone
> permanently even if the reputation climbs up again.
>
> your "faction" is just whichever one likes you the most. Oh and you can't
> get reputation any other way, the "reputation" becomes a "how much are
> you doing to fight our foes directly" score. World of WARcraft.
>
> battleground PvP doesn't give reputation because allies didn't see you do
> it. Sometimes when you attack enemy towns, they'll spawn and fight with
> you. Each playerbot sometimes gets a spawn too, same rules as the player.
> Something like... entering the area, you get an even levelled spawn. The
> enemies are always +4 levels above, so you team up with some orc grunts /
> footmen. also, if you're in your own villages, near equivalent enemy
> heroes (within +/- 5 levels from the grunt / footmen in question) will
> give reputation to slay, and they're the only ones who can gain
> reputation for slaying your guys. If your guys see you killing enemy
> players in their bases, they'll reward you. They see you, they know you,
> they appreciate you. But like, if you're out and about and afar, then
> they don't even know. so they have to take your word, which is worth
> half. Therefore, if you vigilantly defend your own provinces, you'll be
> able to develop positive relations with them, and possibly, even the
> other faction. because you can stand on your own, you are a respected peer
> - a hero of legend.

Answers, verbatim, 2026-09-26:

> [which profile:] unclear. Build it as a patch file for now.
> [start liked by the race's side:] yes. But only just, racial sentiment.
> But that's all you need, there's no real benefit. It's just... how much
> the people like you.
> [exchange rate:] like, 20 and 10 maybe.

## Current Behavior

Nothing built. How the stock game works, for the design (read 2026-09-26):

- **A character's side is fixed by its race** (the server sets the
  character's faction template from the race at creation and login). Who
  may attack whom, which guards are hostile, which auction house, mail,
  chat language and battleground team apply, all follow from it.
- **Reputation** is a separate per-faction score shown in the client's
  reputation panel; the panel has an "at war" box, which the client
  greys out for some factions (a flag in the client's faction data),
  including a character's own side.
- **Reputation comes from** quests, kills of a faction's enemies,
  turn-ins and tabards; the server can switch off or rescale gains by
  faction (the reputation rate settings and the reputation reward tables).
- **Guards and town NPCs** have fixed levels in the world database.
- **Hearthstone**: an item in the bags; the bind is stored on the
  character.

## Intended Behavior

As read from the owner's words; every point is still open to correction.

- **Your side is whichever side likes you most**: the Alliance and the
  Horde each keep a reputation for you; the higher one is your faction.
  Being "at war" with a side (the reputation panel's box) is what lets you
  attack its people.
- **Reputation is only earned by fighting that side's foes, directly**:
  no quests, turn-ins or tabards give it. Gaining reputation with one side
  also takes some from the other, and "it gives less than it takes".
- **Witnesses count**: killing an enemy player in or near a side's own
  towns, where its people see it, pays full reputation; a kill far away is
  taken on your word and pays half; battleground kills pay none ("allies
  didn't see you do it").
- **Home defence**: in your own villages, enemy heroes close in level
  (within 5 of the local grunts or footmen) are worth reputation to slay,
  and only they gain reputation for slaying your people.
- **Hated by both sides**: the character loses its hearthstone for good,
  even if the reputation later recovers.
- **Towns fight back and help**: the enemy's guards and townsfolk are
  raised to about the level of the area's monsters plus 4, as Outland's
  are on basic (155k). Attacking an enemy town sometimes brings help: on
  entering the area you (and each buddy, by the same rule) get an
  even-level ally, an orc grunt or a human footman, against enemies that
  are always 4 levels higher.
- **Battlegrounds** pay gold bars (155u), not reputation.

## Suggested Implementation Steps

Not planned in detail until the profile is chosen. What each part would
take, so the size is visible:

1. **Side from reputation**: switching a character's faction template when
   its higher reputation changes (a server hook at reputation change) and
   everything that follows from the side (auction house, mail, chat
   language, battleground team, guards): the largest part, likely a
   source patch.
2. **"At war" with your own side**: the client greys the box for some
   factions; which ones it allows, and whether the server can grant the
   same effect otherwise, needs reading in the client's faction data.
3. **Reputation only from direct fighting**: switch off stock gains for
   the two sides; award reputation from kills in a script, with the
   witness rule (is the kill inside or near a town of that side).
4. **Guards at area level + 4**: the method basic uses for Outland's
   monsters (155k, a generator over the world database).
5. **Allied spawns in enemy towns**: a script on entering an enemy town
   area.
6. **The lost hearthstone**: a flag on the character, checked at login and
   when a hearthstone would be given.

## Related Issues

- **155u** battleground rewards (gold bars; no reputation from
  battlegrounds)
- **155k** Outland world levels (the +4 method for guards)
- **617** buddies (each buddy gets its own ally spawn, same rules)
- **156** the expert profile, a possible home for this

## Open Questions

- (Answered 2026-09-26) Profile: none yet; built as patch files (B/C/E)
  that no profile's list includes until one is chosen. Start: liked by the
  race's side, only just ("racial sentiment"), with no benefit beyond
  deciding the side. Exchange rate: 20 and 10.
- (Answered 2026-09-26) A deed gains 10 with the side it helps and costs
  20 with the side it hurts; slaying an enemy player in one of your own
  side's bases gains 20.
- **"At war" with your own side's people**: attacking members of the side
  that likes you most, allowed at all?
- **Allied spawns**: how often ("sometimes"), and do they leave when you
  leave the town?
