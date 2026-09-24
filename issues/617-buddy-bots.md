# 617 - Buddy Bots: Every Character Brings Companions

## Status
- Created: 2026-09-23
- Phase: 6 (Companions — bot behaviors)
- Priority: High for basic (155): "players always have at least one buddy"
- First profile: basic
- Sub-issues: 617a–617g

## Origin

Verbatim, 2026-09-23, on the note that bots skip the starting-valley
rotation because the bot module creates them through its own path:

> we should modify that path so that whenever a player character is created,
> a bot is created as well, so players always have at least one buddy.

And, answering what the buddy is:

> Dedicated to your character, and every 10 levels another one joins your
> party. They don't join other people's party, and they do quests and stuff
> that are in the same regions as you. They instantly receive every quest that
> you do and complete it automatically whenever you do. They try and fight the
> same creatures in the same area that you do, but they might be on the other
> side of the patch of mobs and that's okay. You only share exp when you're
> close, and they don't try to stay near - they just attack mobs as if the NPC
> bot was fighting in that particular area on their own.

And on the buddy's class: **the player chooses.**

Answers to the design questions, verbatim, 2026-09-23:

> we should dynamically adjust which ones are in a party as you based on which
> are closest. Remember, they're just adventuring in the same zone as you.
> Same areas too. If you enter a dungeon, then enough join to make a dungeon
> party. We can choose them randomly, without replacement, cycling through to
> make sure everyone gets a chance to go.

> they arrive at your level.
>
> they are on a hidden linked account. Playerbots.

> an NPC menu, there should be one at the starting zone, and one that spawns
> near you and walks around, sits by a fire, tells jokes... But stays in the
> same area as you were when you leveled up. If you log out, then when you log
> back in they'll appear where you logged back in at. If there's more than two
> in an area (maybe 30 yards or so) then they won't spawn. I'm thinking it
> should be a suave human male with pale, almost ashen skin, black hair parted
> down the middle and chin length, with a black and white shirt on (not
> tuxedo, more like inverted, white shirt with black accents) and pale green
> pants. No cloak, helmet, weapon, or shoulderpads, but we can pick belts and
> boots. No gloves probably either. Though maybe he levels up with you idk not
> sure yet. We'll pick the exact outfit later. See the immortal issue files
> for a reference implementation about how to do the idle behavior, we want to
> be a little distinct from them but there might be some good ideas you can
> use in there.

> yes it comes back to life. It'll move to the areas that the player is in
> when it can. Also, deleting your character does delete it's buddies.

## Current Behavior

Nothing like this exists. What the bot module offers today, and why none of
it is the buddy:

- **Random bots** (`RandomPlayerbotMgr`): an ambient population on bot
  accounts, created by the module's own factory at startup, levelled and
  moved around the world by the module. Not tied to any player.
- **Add-class bots** (the `addclass` command in `PlayerbotMgr.cpp`): a pool
  of pre-made characters on reserved accounts. The command takes the first
  free one of a class, levels it to the player, and adds it to the player's
  group. It is shared, not persistent: a different character each time, and
  it goes back to the pool on logout.
- **Alt bots**: a player's own other characters, logged in as bots with
  `.playerbots bot add <name>`. Persistent and owned, but the player has to
  create them by hand, and they use the player's own character slots.

New characters on basic are created through the character-creation
handler, which B028 (155d) now patches. Bots never pass through it.

## Intended Behavior

- **One buddy at creation, one more every 10 levels**, each arriving **at
  the owner's level**. Each belongs to exactly one player character and
  persists with it. Buddies live on a **hidden account linked to the owner**
  and run as playerbots. **Deleting the owner deletes its buddies.**
- **The player chooses each buddy's class** at an NPC (617b), one choice per
  buddy.
- **Party by proximity.** The group holds the owner and up to four buddies,
  and which four is re-chosen continually: the closest. Others keep
  adventuring nearby, ungrouped. **Entering a dungeon** fills a dungeon
  party. Buddies are drawn at random without replacement, cycling, so every
  buddy gets turns. Buddies refuse every other player's group.
- **Same zone, same areas, not following.** Buddies fight the same kinds of
  creatures in the owner's area on their own, maybe across the camp.
  Experience is shared only when close enough, which is the stock group
  rule: group members out of range get no share.
- **Quests mirror the owner.** When the owner accepts a quest, every buddy
  has it; when the owner turns it in, every buddy completes it and gets the
  reward.
- **Death**: a buddy resurrects like a player and makes its way back to the
  owner's areas when it can.

## Suggested Implementation Steps

| ID | Name | Dependencies | Description |
|---|---|---|---|
| 617a | buddy-roster-and-creation | None | The hidden linked account, the owner→buddies table, creating a buddy of a chosen class at the owner's level, deleting buddies with the owner |
| 617b | buddy-class-selector-npc | 617a | The NPC where a buddy's class is chosen: one at each starting valley, and a wandering one that appears near the owner at each 10th level and idles there |
| 617c | buddy-login-and-proximity-party | 617a | Buddies log in with the owner; the group is re-formed from the closest four; dungeon entry draws a party without replacement; other groups refused |
| 617d | buddy-quest-mirroring | 617c | Quest accept and turn-in mirror from owner to every buddy |
| 617e | buddy-area-adventuring | 617c | Buddies fight in the owner's zone and area independently, resurrect, and travel to the owner's area |
| 617f | buddy-selector-appearance | 617b | The selector NPC's look (the suave human) and whether his outfit levels with the owner |
| 617g | buddy-talent-plans | 155g | Generated talent plans (2/3–1/3 and thirds) for capped trees, balanced to equilibrium; a buddy keeps its plan for life |

Execution order: `617a → (617b ∥ 617c) → (617d ∥ 617e); 617b → 617f`.

Rationale for the split: 617a is data and the bot module's character
factory. 617b is a world NPC with its own idle behavior. 617c and 617e are
bot strategy (module C++), 617d is quest hooks, and 617f is art direction.
Each can be built and tested alone, and 617b/617f can proceed before any
bot code works.

## Related Issues

- **155** / **155d** basic and its creation-handler patch (B028), where
  the first buddy is born
- **601** find-monsters, **611** wandering, **613** orchestrator — beta's
  Lua bot behaviors; 617e may reuse their ideas
- **153e** rare naturalist companions (explore) — a different kind of
  companion on a different profile

## Open Questions

- (Answered 2026-09-23) Group cap: proximity party of four, dungeon draws
  without replacement. Arrival level: the owner's. Home: a hidden linked
  playerbot account. Class choice: an NPC. Death: resurrect and return.
  Owner deleted: buddies deleted.
- Remaining questions live in the sub-issues.
