# 718 - Death Knight: The Sacrifice, and Acherus as an Open Zone

## Status
- Created: 2026-09-23
- Phase: 7 (Custom class / race-class infrastructure)
- Priority: Medium
- Related: 617b (Sargobras, the chooser here), 617g (death knight buddy
  clans)
- Blocked by: nothing (unblocked 2026-09-25, Ritz: "sure, let's unblock it
  and write it"). It had waited on the custom-class infrastructure for
  the skipped-intro ability schedule, which is gone now the intro is kept.
- First profile: basic (155)

## Origin

Verbatim, 2026-09-23, answering "what should basic do with death knights":

> allow stock DKs, but there are no bot DKs allowed and level 55 is required.
> When you create a DK it deletes that level 55 character that you leveled to
> that level. This is the replacement mechanic. It might need a special custom
> NPC or something, with newly created DKs who don't choose being unable to
> leave acherus until they choose. Alternatively, we can just skip the DK intro
> zone and teach them all the abilities they would have gained from quests at
> the level when they should have gained it. The DK starting zone becomes a
> normal leveling zone, with whichever area being unlocked (within a level
> range) is randomized. So for example the first area will always be pretty
> easy because it needs low level noobs to learn there (level 55) but the later
> parts like in the city can be low level coded. And the parts by the chapel
> and the distant docks can be starting areas that can be flight path flown
> to. But each one is different at different times, they cycle around in the
> most fair way possible. I can describe better if you don't have ideas,
> especially with some context provided about how the level zones are
> distributed in terms of phases and geographic location in the DK starting
> zone.

And, on scheduling:

> but the DK issue file could come after the custom classes start being
> implemented, it could be the second or fourth one after we've developed the
> custom-class infrastructure

## Current Behavior

Three different death-knight arrangements exist, one per profile family:

- **Stock (release, alpha):** a new death knight is created at level 55 in
  Acherus, the floating necropolis above the Scarlet Enclave, and plays a
  scripted quest chain there before being released into Eastern
  Plaguelands. An account needs a level-55 character on the realm first
  (`CharacterCreating.MinLevelForHeroicCharacter = 55`, the upstream
  default).
- **Beta (issue 206, completed):** death knights start at **level 1**, still
  inside Acherus. A Lua script auto-completes the exit quests so they can
  step on the teleport pads and leave immediately. Stats were generated
  for levels 1–20 and custom trainers teach a streamlined ability kit at
  levels 2–20. It covers 1–20 only, so it does not fit a 1–60 profile.
- **Vanilla (148a, completed):** death knights are disabled. 148a's reason
  was that the client hard-codes the Acherus start and a client patch would
  be needed. 206 shows otherwise: beta starts death knights at level 1
  with no client patch. The start location is the server's
  `playercreateinfo` table, not the client.
- **Basic:** stock death knights (an account needs a level-55 character;
  no death knight bots), plus **layer 1, the sacrifice, built 2026-09-25**
  and not yet tried in game:
  - `sql/basic/db_world.src/25-death-knight-sargobras.apply.sql` (E040):
    Sargobras (creature 7180001) twice, every phase, three texts (owed,
    given, anyone else); model a stand-in (Lord Gregor Lescovar's) until
    617f. Spawn 7180002 stands in the Heart of Acherus (map 609), between
    where a new death knight appears and the Lich King, who withholds the
    first quest (12593) while a soul is owed (Ritz, 2026-09-29: "acherus
    shouldn't be left at all until they comply. The Lich King just,
    shouldn't give the player the first quest until Sargobras is dealt
    with"). Spawn 7180001 stays between the Ebon Hold's portals on map 0,
    so the undo is still reachable after the chain. The gate holds an
    owing death knight to the necropolis alone (map 609, area 4342),
    checked on login, zone change and area change. While owed, no
    creature but Sargobras can be selected by the death knight (164).
    Both Sargobras texts pools are riddles now (2026-09-29: "The options
    the player can pick should explain").
  - `sql/basic/db_characters.src/03-death-knight-souls.apply.sql` (E041):
    the soul ledger `basic_718_souls`; its revert hands every held soul
    back to its own account before dropping the table.
  - `src/lua-basic/death-knight-souls.lua`: the ledger row at a death
    knight's first login, the gate (Acherus and the Ebon Hold only while a
    soul is owed), the trade and the undo as planned below. Characters move
    between accounts with the server's own `.character changeaccount` and
    are removed with `.character erase`, which keep its cache right; each
    player account gets its own holding account (`SOULS<account id>`,
    random password nobody keeps). The Lua engine's console call does not
    run a command, it queues it for the server's next update, so each
    step waits a second before reading what its command did (make the
    holding account, wait, check; move the soul, wait, check; then the
    ledger). Until 2026-10-08 the trade checked at once and could never
    succeed (the owner: "I tried to give a soul to the lich king and it
    didn't work"); `scripts/test-dk-soul-trade` plays the trade against a
    stand-in console that runs commands only on the next tick.
  - `scripts/generate-basic-death-knight-soul-data` writes
    `src/lua-basic/data/death-knight-soul-data.lua`: 3,702 profession
    spells over 14 skills (SkillLineAbility.dbc) and each race and sex's
    death knight skins with their faces (CharSections.dbc; undead have none
    and return unchanged).
  - Tested: the RAM database test (apply, re-apply, revert, apply) including
    a held soul returned by the ledger's revert; the post-install checker
    (Sargobras's spawn and texts, the ledger); the script loads with the
    engine stubbed and registers its five hooks. In game: everything else.

### What Acherus is made of (from the server's own data, 2026-09-23)

Acherus is **map 609**, zone "Plaguelands: The Scarlet Enclave". Numbers
below come from `source-beta/data/sql/base/db_world/`; re-derive rather than
trust them if upstream changes.

**Every one of its 59 quests is level 55, minimum level 55.** There is no
level gradient anywhere in the data, so "easy area" and "hard area" would
be something this issue creates, not something it reads out of the zone.

**Four quests teach a spell or grant one directly**, and these are the
abilities a skipped intro would have to hand out another way:

| Quest | Grants |
|---|---|
| The Emblazoned Runeblade | Runeforging (weapon enchanting unique to the class) |
| The Might Of The Scourge | a display-only reward spell (51721); needs identifying |
| Into the Realm of Shadows | the Acherus Deathcharger mount |
| The Light of Dawn | Death Gate (the class teleport home) |

Several other class features (the Ghoul, presences, Death Grip's use on
the Scarlet line) are introduced by the chain's scripting rather than by a
reward field. They have to be found by reading the quest scripts before
the "teach abilities at the right level" alternative can be specified.

**The zone changes shape as the chain progresses.** The world is phased: a
quest's completion swaps the player into a different copy of the same
ground. The transitions, keyed to quest completions:

| After completing | The world becomes |
|---|---|
| Victory At Death's Breach | the Scarlet line is broken; the assault on New Avalon opens |
| The Plaguebringer's Request | the Crypt of Remembrance plague stage |
| Bloody Breakout | the prisoner-escape stage |
| A Meeting With Fate / The Scarlet Onslaught Emerges | the Scarlet counter-attack |
| Scarlet Armies Approach | the siege; lasts until An End To All Things |
| An End To All Things | the frost-wyrm razing of New Avalon; the final state |

**Geography**, as named in the quest titles, runs roughly: Death's Breach
(the landing under Acherus) → Havenshire (farms, stables, mine, lumber mill
— "The Scarlet Harvest", "Tonight We Dine In Havenshire", "Grand Theft
Palomino") → Light's Point (the tower overlook, "Massacre At Light's Point",
"Ambush At The Overlook") → New Avalon (the city: town hall, forge, orchard,
the Crypt of Remembrance) → the Chapel of the Crimson Flame → King's Harbor
(the distant docks and the Scarlet fleet) → Light's Hope Chapel, just
outside the map, where the chain ends ("The Light of Dawn"). Creature spawns
per phase cover x 1284–2838, y −6193 to −5125; the exact centre and radius
of each named place should be measured from spawn clusters, not recalled
from memory.

## Intended Behavior

Two layers, one per half of the user's design.

### Layer 1 — the price of a death knight

- A death knight can only be created by an account that owns a level-55
  character on the realm (stock knob, already in place).
- **Creating the death knight consumes that character.** The level-55-or-higher
  character is deleted as part of the creation: the new death knight is
  what that character became, and it keeps that character's professions
  (2026-09-25).
- Bots never play death knights (`AiPlayerbot.DisableDeathKnightLogin`),
  except a death knight owner's buddies, which are all death knights
  (617b, 2026-09-25). That setting stops every death knight bot from
  logging in, so the buddy module will need its own exception (or the
  setting off, with random bots already off on basic, 155b).
- **Any race and class** (owner, 2026-10-12: "Sargobras doesn't need to
  appear to level 56-60 death knights. They should get a completely random
  race/class."): a death knight player's buddies are drawn from every
  class of its faction but the death knight, each of a race of the faction
  that plays it, with a shape drawn as for any buddy (pick "any",
  `lib/buddy-choice.lua`); death knights of random races until then (those
  already made stay as they are). The bigger picture the owner set out the
  same day (the Lich King's servants of any class and any master, and an
  allegiance chosen after the story) is issue 718a.
- **Four buddies from the trade, by level** (owner, 2026-09-26; by level
  since 2026-10-12: "55 = 1 buddy-bot, 57 = 2, 59 = 3, 60 = 4"): a death
  knight that has given its soul gets four buddies in all, death knights
  of random races, and never more; one at 55, the second at 57, the third
  at 59, the fourth at 60. A buddy is chosen when its level is reached;
  one the death knight already had and is below the level of again waits
  aside ("set aside", roster stage 5, which the buddy module neither logs
  in nor re-stages) and comes back at its level, made again at the owner's
  level. Built in `patches/E066-sargobras/sargobras.lua`, called from the trade in
  `death-knight-souls.lua` and at every level. Taking the soul back
  erases the death knight with a command that fires no character-delete
  event, so the take-back also deletes its companion account (and with it
  the four) and its roster rows.
- **Buddies owe no soul** (2026-09-26, found building 617a3): the first-
  login rule that makes a new death knight owe a soul skips any character
  named in `buddy_roster`, so a death-knight owner's buddies follow it out
  of Acherus instead of being held there.
- The user named two ways to make the choice of *which* level-55 character is
  consumed:
  - **(a) a chooser NPC in Acherus.** A freshly created death knight cannot
    leave Acherus until it has named its former self. The character is
    deleted when the choice is made.
  - **(b) skip the intro.** Dropped 2026-09-25: the intro chain is kept,
    and the chooser is (a), Sargobras. (Was: handled by Layer 2, with the choice made some
    other way.)

### Layer 2 — Acherus as a leveling zone

- The scripted intro chain no longer gates anything. Abilities the chain
  would have taught are taught at the level at which the chain would have
  taught them.
- The Scarlet Enclave becomes an ordinary leveling area with **level bands
  per region**, which the data does not provide and this issue assigns.
  The landing area (Death's Breach, and Havenshire's near edge) is always
  the gentlest band, because every new death knight arrives there at 55.
- **Unlocks rotate.** Which region holds which band is shuffled over time,
  "in the most fair way possible". The Chapel of the Crimson Flame and the
  King's Harbor docks can serve as alternative arrival points reached by
  flight path, so the rotation also moves where the rest of the zone is
  entered from.
- Basic's flight paths are otherwise removed (155c); the Enclave's internal
  flight paths are an exception that has to be carved out of that removal.

### Decision, 2026-09-25 (Ritz): Sargobras at the gate of Acherus

Asked "I vaguely remember that we had a system where if you created a
death knight, you had to sacrifice one of your characters in order to
leave Acherus. Is that true?" (it is this issue, designed and not built),
Ritz chose the chooser NPC, option (a), and gave it a face:

> Can we have a static Sargobras who offers to help them leave Acherus in
> exchange for a powerful soul? One hero for the Lich King, one death
> knight for the living...

- **Sargobras (617b), standing still in Acherus**, is the chooser. A new
  death knight can't leave Acherus until it trades him a soul: one of the
  account's level-55 characters, given to the Lich King. Then Sargobras
  lets the death knight go to the living.
- For death knights he is only this: he never wanders to them at every
  10th level, and they choose nothing for their buddies (617b).

**Acherus's own travel stays** (Ritz, 2026-09-25: "the Acherus flight
paths / portals should remain"). As of 2026-09-25 nothing on basic touches
it: the Scourge Gryphons between Acherus and Death's Breach are creatures
you click to ride (29488, 29501), not flight masters, so the flight-path
removal (E008, flight-master flags only) leaves them; the teleport pads
between Acherus's floors are the core's scripts; the Ebon Hold's portals to
Stormwind and Orgrimmar (193052, 193053) are not Outland portals, so the
Dark Portal rule (155l, E038) leaves them; Death Gate is a class spell.
718's rotating arrival points (below) would add flights inside the
Enclave on top.

## Suggested Implementation Steps

**Layer 1, the sacrifice** (being built 2026-09-25):

1. **Sargobras in the Ebon Hold** (world database step, basic): a gossip
   NPC standing between the Ebon Hold's two portals to the capitals (map 0,
   area 4281 "Acherus: The Ebon Hold"), the last step out of Acherus and
   where Death Gate brings a death knight home. Visible in every phase. His
   model is a stand-in (a Stormwind noble's) until his outfit is chosen
   (617f).
2. **The soul ledger** (characters database step): one row per death
   knight created on basic: its soul (0 while owed), the soul's own
   account, the holding account, the state (owed, given, being returned).
3. **The Lua** (`src/lua-basic/death-knight-souls.lua`):
   - a new death knight's first login writes its "owed" row (death knights
     from before this rule have no row and are never held);
   - **the gate**: an owing death knight who reaches any place but Acherus
     (map 609) or the Ebon Hold (map 0, area 4281) is sent back to
     Sargobras with a line from him;
   - **the trade**: Sargobras lists the account's characters at level 55
     or higher (not death knights); choosing one (with a confirmation box)
     moves it to the player account's own holding account
     (`.character changeaccount`, one holding account per player account,
     because an account holds at most 10 characters per realm), teaches
     the death knight that character's professions (skills and recipes)
     and lifts the gate;
   - **the undo**: for a death knight who gave a soul, Sargobras offers it
     back (with a confirmation box): the death knight is erased
     (`.character erase`), the soul returns to the player's account, and
     its skin and face are set to its race's death knight options.
4. **Generated data** (`scripts/generate-basic-death-knight-soul-data`,
   from the client's SkillLineAbility.dbc and CharSections.dbc): every
   profession recipe and rank spell (what may be carried over), and each
   race and sex's death knight skins and faces.
5. Tests: the database steps in the RAM test; the Lua load check; in game:
   create a death knight, try to leave, give a soul, check professions,
   take it back, check the returned look.

**Layer 2, the Enclave as a zone** (after the chain; not started):

6. Measure each named region's centre and radius from spawn clusters on
   map 609, per phase, and write the table into this issue.
7. Region level bands; the rotation, shifting after a set number of
   sacrificed characters (count to choose); later, enemies scaled the
   Outland way (parked).

## Related Issues

- **155** the basic profile — first home for this design
- **206** (completed) beta's level-1 death knight — proves the start location
  is server-side; its auto-complete and teleport-pad handling is prior art
- **148a** (completed) vanilla's death-knight disablement — its client-patch
  premise needs correcting in light of 206
- the 700s custom-class cluster (**702** custom spells, **705** class
  selection NPC, **709** class Lua format, **711** class configuration
  schema, **716** class combinations) — the infrastructure this waits on

### Decision, 2026-10-04 (Ritz): the story may be skipped, at Sargobras

Verbatim: "can we make a patch based on the one we have already that
makes death knights have an option when talking to Sargobras to skip the
death knight story? They otherwise can talk to Arthas for the first DK
quest." (2026-09-25 kept the story for everyone; it is now kept by
default and skippable.)

**The menu** (built 2026-10-04 in `death-knight-souls.lua`): while a
soul is owed, Sargobras in Acherus also offers "I'd rather skip the
story."; once asked, each soul in his list reads "Give X (level N) to the
Lich King, and skip the story." and its confirmation says so. Asked for
and not traded yet is kept in memory (a relog asks again). Once asked,
the menu also offers "I changed my mind, I want to follow the Lich King
for a time." (owner, 2026-10-04: "there should also be a second option
... which undoes it"), which takes the asking back: the souls read plain
again and the story is played. Without asking, nothing changes: the Lich
King gives the first quest once the soul is paid.

**First try in game, 2026-10-12** (Gabrubre, giving Karson). The skip
then rewarded every quest of the story the server's own way. Verbatim:

> alright I just raised Gabrubre to the living, and the coolest thing
> happened - we spawned UNDER Acherus, and fell to our deaths, Sargobras
> and I. Except, Sargobras didn't die, which is fine. I love that so
> much. However, there were a bunch of log errors, and now when I mouse
> over the items added to my inventory it says "retrieving item
> information..." - can you make it so we ONLY get the runesword? And
> only the first one you get. And we should rejoin the living at level
> 55, in the plaguelands, perfect.

What the rewards had done (read from the database afterwards): the
story's experience took Gabrubre from 55 to 60, basic's cap, and past the
cap the experience was paid as money, which with the quests' own money
came to 284 gold ("my character spawned with 284 gold? that seems like a
lot. I didn't even do any questing."); 19 reward items, a letter (News
From The North), Runeforging, the Deathcharger, Journeyman Riding, Death
Gate, 4,563 reputation with the Knights of the Ebon Blade and two riding
achievements. One quest was reported as refused ("it said that one of
the quests couldn't complete except manually"): the console line naming
it was not kept, and afterwards all 46 of the orc's story quests read as
rewarded. The likeliest cause, from the server code: the Lua engine's
"add quest" gives up silently when the quest log is full or a quest's
starting item can't be put in the bags, and the rewards had filled the
backpack by the second half of the story (eight story quests hand an item
at the start). The new skip rewards no quest, so it no longer arises.

**The skip, as of 2026-10-12** (owner's words, same message):

- **Only the runeblade, but everything the story teaches.** "can you make
  it so we ONLY get the runesword? And only the first one you get." The
  first sword of the story is the Runed Soulblade (item 38707, the reward
  of The Emblazoned Runeblade, 12619); the skip gives that one item, once
  (not again if the death knight already has one, bank included). Then,
  same day: "They should have the talent points and abilities gained from
  the quests. They just shouldn't get the equipment or gold or experience
  from them." So every quest of the story is still rewarded the server's
  own way (its talent points, Runeforging, the Deathcharger and riding,
  Death Gate, reputation), with the server's "no experience" flag held on
  for the length of it, the money put back as it was, and each quest's
  items taken back as soon as it is rewarded, so the bags never fill.
- **Level 55, in the Plaguelands.** No experience is given, so the death
  knight leaves at the level it was made at.
- **The fall stays.** The skip places the death knight at the Ebon Hold's
  spot on map 0 (2336, -5678, 382, between its portals). On 2026-10-12
  the floor was not there for the client and the death knight fell to
  the ground of Eastern Plaguelands (z 154) and died. The owner loved it;
  it is now the way the living are rejoined. Why the floor was missing
  is not known (open question below).
- **A small random radius.** "we should spawn in a small random radius,
  so when we fall to our deaths our bones don't pile up on the EXACT same
  spot." The spot is moved by up to 6 yards in a random direction.
- **The rise.** "after we land and the character dies, Sargobras should
  point at you, pause his animation if possible while pointing, and
  there should be a red circle of demon light that appears under you and
  then you can respawn with a resurrection effect on both you and
  Sargobras and he should disappear by the time the effect completes."
  And: "the Sargobras that spawns for this (and then disappears rapidly)
  should be un-talkable, it should be a new Sargobras. Also he should be
  level 100." Played in order, from the moment the death knight is dead:
  1. a new Sargobras (creature 7180002: no menu, level 100, friendly,
     immune to players) appears a few yards from the body, facing it;
  2. he points at the body (the held point emote) and his animation is
     frozen mid-point (the "Freeze Anim" aura);
  3. a red circle of light appears under the body (an invisible marker
     carrying the "Spotlight (Red)" aura, since a dead body can't carry
     auras itself);
  4. the death knight is raised with full health where it fell (the body
     becomes bones there), and the resurrection effect plays on the
     death knight and on Sargobras;
  5. Sargobras and the circle are gone by the time the effect ends.
  A death knight that released its spirit meanwhile is brought back to
  the body first. One that survived the fall (still alive 45 seconds
  after the step off, loading screen included) gets no scene and its
  buddies at once, and that is logged as an error.
- **Buddies by level** (applies to every death knight player, skipping or
  not): "I think we should give one buddy-bot every other level, so: 55 =
  1 buddy-bot, 57 = 2, 59 = 3, 60 = 4." Still four in all, chosen at the
  trade as before (617b), but brought in by level. Buddies the death
  knight already has and is not yet level for are set aside: "make sure
  that the buddy-bots are placed to the side for Gabrubre to recollect
  when she hits level 60 again". A set-aside buddy keeps its character
  and comes back at its level, made again at the owner's level (617a6's
  re-making). For a skipping death knight the buddies are brought in
  after the rise, in the Plaguelands, so they never have to follow it out
  of Acherus (the 2026-10-12 log: four buddies left on map 609 trying
  every minute to cross to map 0, "no way to the owner's map was found").
- **The buddies' gear** (`src/lua-basic/death-knight-buddy-gear.lua`,
  `scripts/test-dk-buddy-gear`): "I noticed the death-knight buddy-bots are
  spawning with a white quality Draenic Warblade? They should spawn with a
  runeblade. [...] the level 55 one should spawn with a runeblade and so
  should the level 57 one, but 59 and 60 will need a random green quality
  item from the right item range. If the player completed the DK intro
  quests, then when the buddy-bots spawn they should have the same
  equipment that the player has unlocked from the questline so far, and as
  the player proceeds to 58 (which is when the DK quests end) they'll get
  more of the itemset from the quests as the player does. After the quests
  are done, if the final one is complete, then we can skip all that and
  just spawn them in the full set, with a random choice between capes and
  final weapons." Each buddy wears every item of every story quest its
  owner has been rewarded (a choice quest's pick random per buddy, but the
  same each time). The weapon: the 55 and 57 buddies always carry the
  Runed Soulblade; the 59 and 60 ones the final quest's great weapon once
  the owner has it ("If you've completed the quests, then the 59 and 60
  buddies should get the blue two hander from the final quest"), until then
  a random green two-hander a death knight can wear, needing a level from 4
  below theirs to theirs. A
  skipper's buddies get the weapon rule only (the skipper's quests are
  rewarded, their gear isn't). Applied 10 seconds after a buddy appears
  and 3 seconds after its owner is rewarded a story quest; what it
  replaces is destroyed.
- **Taking the soul back.** A skipper never finishes the story, so the
  ledger records the skip, and the Ebon Hold Sargobras offers "I want my
  old life back" to a skipper as to one who played the story.

**Testing it again: `scripts/reset-dk-soul-trade`.** "Can you... Undo
everything that we did exactly, so we can test it a couple times". The
tool puts a death knight that has given its soul back to owing it: the
soul returns to its own account ("Don't forget to switch Karson back"),
the ledger reads owed, the story's quests, items, letter, spells,
riding, reputation, achievements and experience come off, level and
money go back to a new death knight's (55; basic's starting money for
death knights), talents are reset at next login, its buddies are set
aside, and it stands where new death knights appear in Acherus. Run with
the server up (the account move goes through the server's console) and
with the death knight logged out.

The story's quests come from `scripts/generate-basic-dk-skip-quests`
(writes `src/lua-basic/data/death-knight-skip-quests.lua`): every quest
given by a creature or object in Acherus (map 609) plus the last, The
Battle For The Ebon Hold (13166), ordered after the quests they follow on
from: 55 quests. "A Special Surprise" is ten quests, one per race (the
prisoner of your own people); the world database marks them only by
faction, so the generator pins each to its race from the scene's server
script (`ScarletEnclave/chapter2.cpp`), and a death knight gets only its
own. Since 2026-10-12 the skip rewards none of them; the reset tool reads
the list to know what to take off.

### Proposal, 2026-10-17 (Ritz): the story in the past, through Chromie

Asked during the beta audit what beta's death knights can do (they start
at level 1 there, in an Acherus emptied of its people, with no trainer),
verbatim:

> what's the status on their abilities? What starting zone do they start
> in? Can we make it specific to their race? or do we already have a plan
> for the DK starting zone to downlevel it to... level 1? that doesn't seem
> right, the NPCs are too powerful. How about we make it so level 55 DK's
> can play the story by teleporting themselves into the past with Chromie?
> She can hang out at Light's Hope Chapel. You should only be able to do it
> at level 55, so it's a rite of passage, and if you miss it... Oh well.
> Either that, or we temporarily down-level you using the basic profile's
> tools. But I don't like that idea because it means there's no stakes or
> reason for you to do it. How about we lock DK exp at 55 until they
> complete that quest? Making it forced... Though they should be able to
> talk to Chromie (who spawns and follows them Sargobras style) and say "I
> want to skip the DK intro story" or "Can you teleport me to the DK intro
> story?" etc. They should be able to use their current gear or request a
> different set, maybe with a second level to the Chromie menu?

As understood (to be confirmed, questions below):
- A death knight starts outside Acherus. Chromie (168) appears and follows
  it, Sargobras-style, and waits at Light's Hope Chapel.
- At level 55, and only then, Chromie can send it into the past: into
  Acherus to play the story ("a rite of passage, and if you miss it... Oh
  well").
- Its experience is held at 55 until the story's last quest is done, so
  the story is the way on; or it tells Chromie "I want to skip the DK intro
  story", which releases the hold.
- Into the past with its own gear, or a different set asked for in a
  second Chromie menu.

Questions this raises (asked 2026-10-17):
1. Which profile? Beta caps at 20 and starts death knights at 1, so no
   beta death knight reaches 55. Basic (cap 60) starts them at 55, in
   Acherus, with Sargobras's soul trade at the door and his story skip
   (above). Is Chromie for basic, replacing or beside Sargobras's skip; for
   beta with a different level; or for a profile yet to come?
2. "Only at level 55 ... if you miss it, oh well" and "lock DK exp at 55
   until they complete that quest" pull two ways: if experience is held at
   55 until the story is done or skipped, nobody can miss it. Which one?
3. "Into the past": does the death knight stay a level-55 death knight
   in Acherus while there (the story's quests are tuned for 55-58), and
   come back to Light's Hope when the story ends?
4. Starting zone by race (the beta question): a death knight could start
   in its race's own starting zone (vanilla did this for every class,
   148n, through the server's start-position table) rather than Acherus.
   Wanted for beta's level-1 death knights?

## Open Questions

- (Answered 2026-10-04) Skipping and the story's gear choices: "isn't
  there a way to have a quest appear to everyone in a zone? ... Anyway, if
  that's not an option, we can let an NPC in Acherus give a quest that
  rewards those items. Maybe even Sargobras. The quest should be
  auto-completed, so they can choose." In 3.3.5a a quest window without
  an NPC is shown only for quests an item starts, and completing one away
  from its giver with a reward choice came later (Cataclysm); so the
  NPC way. Two story quests offer a choice: Tonight We Dine In Havenshire
  (12679: one of three cloaks) and The Light of Dawn (12801: Greatsword or
  Greataxe of the Ebon Blade). Changed the same day: "we should just sell
  those quest items at a vendor in Acherus. They should be unsellable,
  nobody wants to handle them because they know that Acherus wants them
  back." Planned: a vendor in Acherus sells the five choice items (the
  three cloaks of 12679, the two two-handers of 12801); none of the five
  can be sold to any vendor (no sell price); the skip keeps the item the
  server picks. Vendors (owner, 2026-10-04: "Pick someone noble for the
  capes, and someone vicious for the weapons"): Lady Alistra (28471, a
  death knight trainer in the upper hall) sells the three cloaks;
  Instructor Razuvious (28357, the drillmaster beside the Lich King) the
  two two-handers; each gains a vendor flag and its list. Price 1 gold each,
  and they sell for nothing ("1g each, they sell for no gold. Or 1c if we
  need to.").
  Built 2026-10-05 as install step E051
  (`sql/basic/db_world.src/32-acherus-choice-vendors.{apply,revert}.sql`):
  the vendor flag (128) is OR-ed onto both creatures so their training and
  quests stay; the five items cost 10000 copper with a sell price of 0;
  the revert puts the stock prices back (cloaks 42/8, two-handers 184/36
  copper). `scripts/test-acherus-vendors` applies and reverts inside one
  rolled-back transaction (4 checks). Not yet installed or seen in game.
  Anyone who reaches Acherus may buy them; the owner named no limit.

- (Answered 2026-09-25, no longer blocking) **Which issues are "the custom-class infrastructure"?** This issue was
  scheduled second-to-fourth after it. The owner's description (recorded
  verbatim in 705, 2026-09-23): a middle-ground class learns chosen abilities
  from other classes' trainers, with borrowed abilities re-costed in its own
  resource by cast tempo. That points at 705 (selection and trainers), 709 and
  711 (the class format and schema) and 710 (resources). Note the existing Lua
  for it is disabled (`src/lua-beta/custom-classes.lua.disabled`) and
  beta-only, so on basic the infrastructure starts from a port, not a switch.
  Ritz, 2026-09-25: "what about the DK's rest on custom-class
  infrastructure?" Read against the design as it now stands: the only part
  that leaned on it was teaching the chain's abilities at the right
  levels if the intro were skipped (step 5 below, "level-gated ability
  grants"). The intro is kept, so that part is gone. What is left needs no
  custom-class machinery: the sacrifice (a creation hook, the holding
  account, Sargobras's menu and its undo, the professions carried over),
  and Layer 2 (region bands, the rotation by sacrifice count, later the
  scaling). Proposed: drop the block on the custom-class infrastructure.
  (Answered 2026-09-25: unblocked, "sure, let's unblock it and write it".)
- (Answered 2026-09-25) The chooser, (a): a static Sargobras in Acherus
  who lets a death knight leave for a soul. The intro chain is **not**
  skipped (Ritz: "We shouldn't skip the intro quest chain."), so (b) is
  dropped.
- (Answered 2026-09-25) Professions: a death knight **inherits the
  professions of the character it sacrificed**, "what that character
  became"; and death knight buddies start with maxed professions (300 on
  basic), "the professions they knew in life" (Ritz: "also death knight
  buddies start with maxed professions as well. They are the professions
  they knew in life.").
- (Answered 2026-09-25) Which characters can be given: any of the
  account's characters at level 55 **or higher** ("level 55 or
  greater"); the player picks one from Sargobras's list.
- (Answered 2026-09-25) Layer 2 applies **after the chain**: once a death
  knight has finished the intro, the Scarlet Enclave becomes a zone to come
  back to and level in, with the rotating regions.
  Its enemies should probably be scaled the way Outland's are (155k, 155m)
  ("we should also probably consider scaling the enemies like we do in
  Outland. Let's put a pin in that for now..."): parked.
- (Answered 2026-09-25) The intro: other characters skip only the race
  intro cinematic (E019, a trigger that marks every new character's
  cinematic as seen), and that already covers death knights. Ritz: "we
  skip the intro for other characters, right? We should skip it for DKs as
  well, if so." The quest chain stays.
- (Answered 2026-09-25) **Neither deleted nor a gravestone: held.** Ritz:
  "they're removed from the player's account and put into a holding area
  in-case they change their mind. Sargobras in Acherus can reverse this at
  any time, deleting the death knight and returning the player character
  to their account. They will be exactly the same except they will have
  the DK haunted eyes and skin color and such because they are
  canonically undead now. Sucks to be them..."
  - Giving a soul moves the character to a hidden holding account.
  - Sargobras in Acherus can undo it at any time: the death knight is
    deleted and the character comes back to the player's account,
    unchanged except for a death knight's look (glowing eyes, pallid
    skin).
- The returned look, read 2026-09-25 from the client's appearance table
  (CharSections.dbc: skins, faces, hair; flag 0x4 marks a death knight
  option, e.g. a human male's skin colours 12–14 of 0–14): the options
  exist per race and sex, and the server stores and sends a character's
  appearance numbers as they are, with no check against its class. So
  giving the returned character its death knight's skin and face numbers
  should draw correctly; the flag looks like a creation-screen filter.
  To confirm in game once, with one character.
- (Answered 2026-09-25) Rotation clock: a count of sacrificed characters,
  as the starting valleys rotate after a count of new characters (155d,
  B028: every 30). Ritz: "it's like the rotating starter zones [...] a
  certain number of sacrificed characters causes it to shift". How many is
  still to set.
- (Answered 2026-09-25) 148a's premise was wrong; corrected in 148a.
- (Answered 2026-09-29: "yes.") A death knight whose account has no
  character of 55 or higher left (the only one deleted after the death
  knight was made) owes a soul it can't pay, and stays in Acherus. Is that
  right, or does Sargobras let it go?
- A held soul's own buddies (617): they belong to that character, so do
  they wait with it on the holding account, and come back with it?
- (2026-10-12; owner: "I'm guessing we just placed the DK at the wrong
  Acherus, it was the one over EPL ... It's okay, we want to be spawned in
  the EPL") It was the one over the Plaguelands (map 0), on purpose; the
  server's own creatures stand on its floor at z 382 there, so the fall
  is still unexplained. Why was the Ebon Hold's floor missing on map 0? Its
  creatures and portals stand at z 382 there, the skip placed the death
  knight at z 382, and the client fell through to z 154. If the floor is
  missing for every death knight, the Ebon Hold Sargobras (who gives a
  soul back) and the portals to the capitals are unreachable too. The
  fall is now wanted for the skip; should the Ebon Hold itself be
  looked into?
- (Answered 2026-10-12) The skipper keeps what the story teaches
  (Death Gate included, so the Ebon Hold Sargobras can be reached), not
  its gear, gold or experience.
- (2026-10-12) The red circle (Spotlight (Red), spell 62296), the frozen
  point (Freeze Anim, 16245) and the resurrection effect (Resurrection
  Impact Visual, 24171) are chosen from the spell list by name; none has
  been seen in game. If one looks wrong, the spell ids sit together at
  the top of `death-knight-souls.lua`.
- (2026-10-12) Until the next compile the rising Sargobras wears the
  stand-in model (the outfit list that dresses Sargobras is C++,
  `buddies_outfits.cpp`, and gains the new creature only when built).
