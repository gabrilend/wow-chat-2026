# 718a - Allegiance After the Story: Horde, Alliance, or Acherus

## Status
- Created: 2026-10-12
- Phase: 7
- Parent: 718 (the death knight sacrifice)
- Related: 617x (prestige: the reborn become buddies), 617b (buddies of
  any class), 617a (buddy creation)
- Priority: Medium
- State: planned; the open questions decide what can be built server-side
  and what needs the custom client

## Origin

Verbatim, 2026-10-12, after "They should get a completely random
race/class" (a death knight player's buddies, built in 718):

> Is it possible to double the number of "race" slots in the game, well
> slightly less than increase by half... that way we can say that the lich
> king and his death knights (who haven't fought to be freed) can be any
> class, and will fight for any master. Those who complete the
> quest-story-line have a choice to swear their allegiance to the Horde or
> Alliance at will, and they also have the choice to swear to Acherus, in
> which case they can prestige their character to become among the next
> level 60 buddy-bots given to players on the server. If a player chooses
> to swear allegience to an off-race master, then they must wear the
> tabards of their new master at all times. If the player is ever not
> wearing a tabard, one gets swapped in automatically. Alternatively, if
> they take it off without having a replacement tabard in their backpack
> or bank (while the bank is open on their screen), then they instantly
> die and have it replaced when they resurrect. Which happens immediately
> because a Val'Kyr appears to resurrect them (cooldown of 60 minutes, to
> parallel the Paladin "Divine Intervention" spell) and says "please be
> more careful" because the loyalty tabard is enmeshed with their soul.

Answers, 2026-10-12 (verbatim):

> you don't have to have changes to the client I think if we just say DK's
> are allowed and also they're the "orange" relationship with all of
> their new faction members because nobody trusts them, a double
> turncoat. But it should have no real modifications to behavior.

On "serve the other faction, keep your race (server only)": "I think so?"
On a death knight's buddies: "same faction as the DK. They can be any race
though." And: "essentially, we want to give DK's the same option as
Pandaren." (In the later game the Pandaren, one race, choose the Horde or
the Alliance after their starting story.)

## Current Behavior

- A death knight is of its race's faction, like any character; nothing
  is sworn at the story's end.
- A death knight player's buddies are of any class and race of its own
  faction (718, 2026-10-12).
- The server keeps the factions apart: on basic, grouping, chat, guilds,
  the auction house and the calendar across factions are all off
  (`AllowTwoSide.Interaction.*` = 0 in worldserver.conf; only accounts
  may hold both).

## Intended Behavior

**The Lich King's servants, any class, any master.** Death knights who
have not fought free (the buddies of death knight players, and those
reborn into the buddy pool) can be of any class, and serve a master of
either faction.

**No new races: a death knight chooses its side, as the Pandaren do.**
Answered 2026-10-12: no client changes. A death knight keeps its race and
may swear to either faction after its story; one sworn to the other
faction is shown as "orange" (unfriendly, the colour of a name and
reputation the client draws below neutral) to the members of its new
faction, "a double turncoat" whom nobody trusts, but this changes nothing
about how they act together: they group, trade and fight side by side as
faction-mates do. Its buddies are of its sworn faction, any race of it.

**"Race slots" (answered: not needed).** A character's race is the
client's own data: the race table (ChrRaces.dbc), which faction it
belongs to, its models, and the character-creation screen are all read
by the game client, and the server has a matching table per race. Adding
races (the owner's "slightly less than increase by half", about five more
on top of ten) means new rows the stock client doesn't know: a patched
client or the custom client (173). What the server can do alone is let a
character act for the other faction (a faction override: what it is
hostile to, which cities and vendors serve it, who it may group with),
keeping its race. Open question 1.

**The oath, at the story's end.** A death knight that completes the story
chooses, at will, one of:
- **the Horde** or **the Alliance**: it fights for that faction from then
  on. Sworn to a faction that is not its race's own ("an off-race
  master"), it must wear that master's tabard at all times;
- **Acherus**: it may prestige (617x) and become one of the level-60
  buddies given to other players on the server.

**The loyalty tabard.** For a death knight sworn to an off-race master:
- not wearing the tabard: one is put on automatically, from its bags;
- taking it off with no other such tabard in its backpack, or in its bank
  while the bank window is open: it dies at once, and a Val'kyr appears
  and raises it straight away, saying "please be more careful" (the
  tabard is enmeshed with its soul), with the tabard back on. The Val'kyr
  comes at most once an hour, as a paladin's Divine Intervention (owner:
  "cooldown of 60 minutes"); what happens inside that hour is open
  question 4.

## Suggested Implementation Steps

1. Answer the open questions.
2. The oath: a choice at the story's end (an NPC menu, or the last quest's
   reward), written into the soul ledger (`basic_718_souls`, a new
   allegiance column).
3. A faction override for death knights sworn to the other faction
   (server source patch: the player's faction template and team as seen
   by others, groups, cities), or the custom client's way if races are
   added there.
4. The loyalty tabard: a Lua watch on equipment changes (the tabard slot);
   the swap from the bags; the death, the Val'kyr's rise (as Sargobras's
   rise, 718) and its hour-long cooldown, kept per character.
5. Acherus's oath into prestige (617x): the character offered as a level-60
   buddy for other players.
6. Tests offline, then in game.

## Open Questions

1. (Answered 2026-10-12: server only, no new races; "the same option as
   Pandaren".) How is "orange" shown with no change in behaviour: a
   reputation the new faction's members read as unfriendly (a cosmetic
   standing), or only the name colour?
2. Which tabards count for each master (any Horde or Alliance city tabard,
   or one made for the oath)?
3. Can the oath be changed later, and how?
4. The Val'kyr's hour: if the tabard comes off again within the hour, does
   the death knight stay dead (released to a graveyard as usual)?
5. (Answered 2026-10-12: "same faction as the DK. They can be any race
   though.") After an oath to the other faction, are its buddies drawn
   anew in the new faction, or do the old ones swear with it?
- (Answered 2026-10-23) **Which tabards count:** "any tabard that clearly
  has the Horde or Alliance symbols displayed." A list of such tabards is
  drawn from the game's items (the city and faction tabards bearing the
  Horde or Alliance crest), one list per side. (Question 2 above.)
- (Answered 2026-10-23) **The oath is for good:** asked whether it can be
  changed later: "never. the Horde and Alliance remember your character
  and will not tolerate traitors." (Question 3 above.)
- (2026-10-23) **The eligible tabards, listed:** `scripts/generate-oath-tabards-page`
  writes `docs/HTML/oath-tabards.html`: the tabards whose picture shows a
  side's own crest (nine when made: the old honor-rank tabards of both
  sides, both Tabards of Conquest, Stormwind's and Orgrimmar's, and the old
  Tabard of Stormwind), then every other tabard, each linked to its picture
  on Wowhead. Which show the crest is a judgment about the pictures, kept
  in the generator's list, for the owner to correct by eye.
- (2026-10-23) **The tabard page needs pictures:** "I will need icons on
  the tabard HTML page. Maybe also a render of the tabard as it's being
  worn?" The project has no copy of the game's art, but the custom client
  (`/mnt/kaun/custom-client/`) reads the game's archive files
  (`src/015-mpq.c`) and draws characters (`025-character`): the icons
  (each item's picture, from the game's icon files) and a character
  wearing each tabard can be made there, saved as pictures, and the page
  generator embeds them. Done 2026-10-23 by the custom client's dressing
  room; `scripts/make-oath-tabard-pictures` remakes the pictures and the
  page.
- (Answered 2026-10-23) **The game's side marker is enough:** after
  seeing the pictures, "any of the ones that are "Horde only" or
  "Alliance only" are valid." So the oath accepts every tabard the game
  marks as one side's only (the item's Horde-only or Alliance-only flag),
  whatever emblem it shows (a city's, a faction's, a battleground's), plus
  the old Tabard of Stormwind, which shows the lion but carries no flag.
  This replaces the crest judgment above as the rule; the crest list now
  only adds unflagged tabards and gives the crest ones their note. The
  page counts the accepted tabards each time it is made.
