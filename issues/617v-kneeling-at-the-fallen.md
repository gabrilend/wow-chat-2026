# 617v - Kneeling at the Fallen

## Status
- Created: 2026-10-04
- Phase: 6
- Parent: 617 (buddy bots)
- Blocked by: None
- Priority: Medium

## Origin

Verbatim, 2026-10-04:

> also buddy-bots shouldn't loot corpses. The items that are on them when
> the creature despawns (if you left it behind) gets added to an
> appropriate buddy-bot's inventory. We'll need an event that's emitted
> when creatures despawn, and only if they had an inventory item.
> appropriate goods should be given to other buddy-bots and the player.
>
> but, how about, a nearby buddy-bot still walks up to every corpse and
> kneels before it, randomly, once per corpse. The items are left on the
> body so the player can grab them if they want, otherwise they'll get
> sorted into the buddy-bot's inventory first based on need, then based on
> bag space. If someone's low on bag space they can re-distribute, but
> only while kneeling around a campfire, facing 45 degrees from the fire a
> yard or two away.
>
> we should choose which buddy-bot to select with a random select without
> replacement. But prioritizing the nearest buddy-bot by 2x. They'll have
> to transfer items though - oh I guess I should say the items that
> despawn get put into the inventory of the person who kneeled to grab
> them, or the player if they checked and pulled the items before they
> despawned. The nearest buddy bot is a "with replacement" shuffled in
> extra draw choice. Essentially guaranteeing it. This means the tank does
> a lot of looting, but everyone else has just as much of an even chance.
> It all depends on who's closest when the monster is slain. Keep track of
> who should be assigned to who, and only go kneel when there's no
> fighting going on. Visit all the corpses assigned to you, then move
> forward and continue on.

## Current Behavior

Not built. Buddies loot corpses the bot module's way (the "loot"
strategy).

## Intended Behavior

- **No looting**: buddies never open a corpse.
- **Who kneels**: when a monster dies, one buddy is assigned to it: a
  draw from a bag of the party's buddies without replacement, plus the
  buddy nearest the kill as an extra entry drawn with replacement (so the
  nearest is nearly sure, everyone else as likely as each other).
- **Kneeling**: when no fight is on, each buddy walks to every corpse
  assigned to it, kneels once, and moves on with the group.
- **The items stay on the body** for the player to take. When the corpse
  despawns with items still on it, they go to the buddy that knelt there
  (or to the player, if the player opened the corpse first): first to
  whoever needs an item (by the loot judgement, 617j), then by bag space.
- **Despawn event**: the server announces a corpse leaving the world with
  items still in its loot (a source patch or a script hook).
- **Rearranging bags**: buddies short of bag space pass items to each
  other only while kneeling round a campfire, a yard or two from it,
  facing 45 degrees off the fire.

## Suggested Implementation Steps

1. The despawn-with-loot event.
2. The draw and the per-buddy corpse list.
3. The kneel errand (walk, kneel, rise) when no fight is on.
4. The handing out on despawn; the campfire rearranging.

## Open Questions

1. A buddy's kneeling when the player has already emptied the corpse: still kneel, or skip?
