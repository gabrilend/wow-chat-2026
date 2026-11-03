# 920a - The Legends and Their Voices

## Status
- Created: 2026-10-20
- Phase: 9
- Parent: 920 (legendary friends in every friends list)
- Blocked by: nothing
- Priority: Parked (with its parent, 920: the legends are Blizzard's characters; see 920's "Parked")

## Current Behavior

No persona sheets exist. 916k designs the prompt and persona for
playerbots (shaped by race, class and spec); nothing describes a named
character from the lore.

## Intended Behavior

One persona sheet per legend, under `src/legends/` (one file each), that the
chat layer's prompt builder (916h, 916k) reads. A sheet says, in fields:

- **who**: name as shown in the friends list (string, one word: the game
  allows no spaces in character names: `Broxigar`, `Mograine`, `Hrothgar`,
  `Terokk`), full name and title (string), race (string), continent (string).
- **when they are speaking from**: the last event they know of (string),
  and a list of things they do not know (list of strings), so they don't
  speak of what came after them.
- **what they know**: short facts, each with the Wowpedia article it came
  from (list of {fact string, source string}).
- **how they speak**: sentence length, words they use and words they never
  would (list of strings), what they call the player.
- **what they care about**: what makes them talk at length, what makes
  them short.
- **command words** (Terokk only for now): a table of word → behaviour
  (920c reads it).
- **loyalty** (string: `horde`, `alliance` or `neutral`) and **spirit**
  (boolean: one of the dead who still speak). 920's faction rule reads
  these: a spirit or a neutral talks to everyone, a Horde or Alliance legend
  only to its own side.
- **standing** (string, `citizen` or `renegade`): the law in 920. Only a
  citizen speaks. A name on the renegades list (`src/legends/renegades`)
  is a renegade whatever this says, unless a patriation record (the owner's
  dated decision) sits beside its sheet.

Starting knowledge, to be checked against Wowpedia before it goes into a
sheet (these are from memory, and each line is marked so):

- **Broxigar the Red** (Kalimdor). An orc of Draenor, veteran of the
  Second War, brother of Varok Saurfang (from memory). In the War of the
  Ancients novels he is carried ten thousand years into the past, fights
  beside Malfurion and the night elves against the Burning Legion, and dies
  holding the Legion back at the Well of Eternity (from memory). So the
  owner's guess is right both ways: born on Draenor, remembered in Kalimdor.
  There is no entry for him in the world database.
- **Highlord Alexandros Mograine, the Ashbringer** (Eastern Kingdoms).
  Paladin of the Silver Hand; killed by his son Renault with the
  Ashbringer; father of Darion Mograine (from memory). In the game:
  `creature_template` 29227 and 38610, "The Ashbringer".
- **Drottinn Hrothgar, the Sea Reaver** (Northrend). A vrykul; in the game,
  he leads raids on Hrothgar's Landing in Icecrown (`creature_template`
  34980). Whether the Landing is named for him, and what else the lore says
  of him, is not known here (open question 1).
- **Terokk, the Talon King** (Outland). Ancient king of the arakkoa of
  Skettis, summoned in Terokkar Forest (`creature_template` 21838, and the
  Avatar of Terokk, 22375). Whether the lore calls him a god, a demigod or a
  cursed king is to be read (open question 2). He speaks in telepathic
  English: whole, exact sentences with no bird sounds, "because humans
  don't really 'get' that very well".
- **Uther the Lightbringer** (Eastern Kingdoms). First of the paladins of
  the Silver Hand, killed by Arthas (from memory). In the game only as a
  ghost (`creature_template` 17233) and in the Culling of Stratholme
  (26528, 37225, 38608).
- **Aegwynn** (Eastern Kingdoms). Guardian of Tirisfal for a very long
  life, mother of Medivh (from memory). Not in the world database.
- **Turalyon and Alleria Windrunner** (beyond the Dark Portal). The
  Alliance's general and the high elf ranger who went through the Portal
  after the Second War and did not come back (from memory). Not in the
  world database. Two characters, two sheets, each sheet naming the other.
- **Malorne** (Kalimdor). The White Stag, father of Cenarius, killed in the
  War of the Ancients (from memory). Not in the world database.
- **Thoradin** (Eastern Kingdoms). The first king of Arathor, who united the
  human tribes (from memory). Not in the world database.
- **The Ashbringer** (an object). The sword of the Mograines; corrupted, it
  whispered to its wielder in the original game (from memory). The only
  legend who is not a person, and the only one whose sheet says it may
  mislead.

Each sheet also holds a **status pool**: a few dozen short lines in the
legend's voice saying where they are and what they are doing, which 920b
draws the friends list's status line from ("Questing in Outland" for
Terokk, "Lost in the Twisting Nether" for Turalyon).

## Suggested Implementation Steps

1. Read each legend's Wowpedia article (and the articles it links for
   their era) and write the sheet, each fact with its source. Facts only
   from memory stay out until checked.
2. A checker tool (`scripts/check-legend-sheets`, house `${DIR}` header,
   run in the compile's quick tests) that reads every sheet and fails on a
   missing field, a fact with no source, a status line too long for the
   friends list, or a renegade with a voice (920's law: a listed name, or a
   renegade standing, without a patriation record). The renegade list's
   raid-boss part is generated by a second tool,
   `scripts/list-raid-bosses`, from the world database (every boss of a
   raid map), so it follows the database rather than memory. Its tests
   include a renegade sheet planted in a scratch folder, which it must
   refuse, and a raid boss's name on a citizen sheet, likewise. A new legend is then a new sheet file and nothing else:
   the friends-list picker (920b) and the chat layer (920c) find every
   sheet in the folder.
3. Ten test questions per legend (including ones about things they cannot
   know), run through the chat layer once 920c exists, answers kept for the
   owner to rate.

## Open Questions

1. **Hrothgar.** Wowpedia may say little about Drottinn Hrothgar beyond his
   raid on the Landing. If so, the project writes the rest of him (his
   clan, his ship, why he is a chieftain); is invented lore welcome, marked
   as the project's own?
2. **Terokk's "quill".** The owner remembered "Terokk from Terokk's quil".
   Whatever the quill is (an item, a place, a quest) is to be looked up;
   should it shape his sheet?
