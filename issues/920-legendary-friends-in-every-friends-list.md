# 920 - Legendary Friends in Every Friends List

## Status
- Created: 2026-10-20
- Phase: 9 (Storytelling & World Structure)
- Blocked by: 916 (mod-soren-chat: the chat layer, its model runner 916d
  and its persona prompts 916k)
- Related: 1004 (rmail's in-game bridge, one way for 920e's phone app to
  reach the server), 1007 (friends across servers), 919 (written from the
  same message; the whole message is quoted there)
- Priority: **Parked**, with all its sub-issues (2026-10-21)

## Parked

The owner, 2026-10-21: "let's make sure they're super duper parked for now
because it's blizzard's IP and we just want to like... describe the system,
and let these issue files follow along with the project when we make a gift
out of the design to Blizzard Entertainment corp incorporated."

So nothing in 920-920e is built: no sheets of Blizzard's characters are
written, no characters made, no addon or phone app. These files describe
the system (the friends list of voiced characters, the law, the temperate
psychics' protocol, the status map) so that it travels with the project.

"A gift" is only part of it. The owner, 2026-10-21, on how the project
stands toward Blizzard under the licence she intends (the RGPL, at
`/home/ritz/programming/ai-stuff/RGPL`; this idea is **not yet in its
draft text**, see `notes/rgpl.md`): until the project's generators have
replaced every Blizzard asset, everything the project makes and shows
publicly (which here is everything, Sargobras included) is Blizzard's to
use *with this system* as much as it is ours. They may not take our rights
away, nor carry what we made into their other games or into live World of
Warcraft; within this system they may do what they like with it ("They can
do whatever they want with it, but they should treat it well and with
respect!", 2026-10-21, withdrawing an earlier limit to compatibility and
security patches). They would follow the RGPL in using it (its source
delivered over r-mail, person to person). The project is not sold until it
is wholly its own: no Blizzard asset or pattern drawn, and gameplay as
distinct from WotLK as another game of its time (`notes/rgpl.md`). The legends are
parked because they are Blizzard's own characters; under that idea the
design here is part of what the project would hand over with its history. The parts that are the project's own and
not Blizzard's characters are not parked: Sargobras in the friends list
(617b2) and the Architect (919d) go ahead under their own issues, and may
reuse what is designed here (the hidden-character way, the whisper
handling, the law's checker) when they are built.

## Origin

The owner, 2026-10-20 (from the message quoted whole in 919):

> I wonder if it'd be like Broxigar. Can you create him as an NPC if we
> don't have him yet? We should inform his personality according to
> wow-wiki. actually can you make the issue file for several unavailable
> characters like Alexandros Mograine and Highlord Hrothgar? you can give me
> ideas for additional ones if you want. They should be kept as user-based
> chatbot style UI messages in each player's client, like an interface
> addon. These three can come with the game, one from each continent.
> [...] Maybe also Terokk from Terokk's quil? Or is that a demigod...
> Should speak in telepathic english, meaning it's perfect responses with
> no cawing because humans don't really "get" that very well. But sometimes
> they listen to command words like "help" and "crooked crime" or whatever.
>
> anyway the players would always be created with them in their friends
> list, so they can chat on the go. And we can make a phone app so they
> could talk to them IRL too, meaning you could live with your chatbot
> friend.

## Current Behavior

Not started. Every new character's friends list is empty. The chat layer
(916) is designed for playerbots in a party near a real player; nothing
talks to a player who is alone, and nothing answers a whisper.

What the world database holds of these characters (looked up 2026-10-20 in
`acore_world_basic`, `creature_template`):

| Character                    | In the game?                                              |
|------------------------------|-----------------------------------------------------------|
| Broxigar                     | No entry at all                                           |
| Highlord Alexandros Mograine | Yes: 29227 and 38610, "The Ashbringer" (the spirit in the Light of Dawn event); also 16062 "Highlord Mograine" in Naxxramas |
| Hrothgar                     | Yes: 34980 **Drottinn Hrothgar**, "The Sea Reaver" (a vrykul, at Hrothgar's Landing in Icecrown) |
| Terokk                       | Yes: 21838 Terokk, and 22375 Avatar of Terokk (Skettis, Terokkar Forest) |

So the owner remembered right: Hrothgar is a vrykul, and his title in the
game is *Drottinn* (a vrykul lord's title), not Highlord. ("High Hrothgar"
is the mountain monastery in Skyrim, which may be the other memory.)

## Intended Behavior

Every legend below exists, and every character is created with **two of
them, chosen at random**, already in its friends list (the owner,
2026-10-20: "what if we make one for all of them, and then add a random 2
to each player's friends list? They can of course customize it later as
they please."). Legends answer whispers in their own voice, at any time,
wherever the player is. They are not creatures in the world: a player
cannot find them, only talk to them.

| Home             | Friend (list name)       | Voice |
|------------------|--------------------------|-------|
| Kalimdor         | Broxigar                 | An orc veteran out of his time, plain-spoken |
| Eastern Kingdoms | Mograine (Alexandros)    | The Ashbringer, a paladin of the Silver Hand |
| Northrend        | Hrothgar                 | A vrykul chieftain |
| Outland          | Terokk                   | The Talon King of the arakkoa, in telepathic English: whole, perfect sentences, no cawing; also obeys a few command words (920c) |
| Eastern Kingdoms | Uther                    | The first paladin; a teacher |
| Eastern Kingdoms | Aegwynn                  | The last Guardian of Tirisfal before her son Medivh |
| Beyond the Portal| Turalyon, Alleria        | Two friends, lost together, who talk to each other in the player's hearing |
| Kalimdor         | Malorne                  | The White Stag, a demigod |
| Eastern Kingdoms | Thoradin                 | The first king of Arathor |
| (an object)      | Ashbringer               | The corrupted sword, which whispers, and may not be on the player's side |

(920a has each one's sheet. That is eleven characters, since Turalyon and
Alleria are two.)

- **Customizing.** A player removes a legend with the stock friends list's
  own "remove friend", and adds one with `/friend <name>` or from the
  addon's list of every legend (920d). Nothing new is needed to remove one;
  adding an opposite-faction legend by name needs the server to allow it
  (920b).
- **A status line.** Each legend always shows where they are and what they
  are doing ("Questing in Outland", "Married to Medivh"), written in their
  own voice and changing over time (920b says where the line is shown).

### The law: no voice for monsters

The owner, 2026-10-20, verbatim:

> can we also add as a law that under NO CIRCUMSTANCES do we enable
> terrible monsters or cosmic horrors or other potentially unethical or
> psychic individuals to have an LLM character representation? Punishable
> by law, at least until it is proven that these "renegades" as they call
> themselves are patriated as honorary citizens. And then only if they have
> fully taken ownership over their own dataset - essentially, coming of age.

How the project keeps it:

- **Every sheet has a standing** (920a): `citizen` or `renegade`. Only a
  citizen's sheet is ever read by the chat layer, the friends-list picker,
  the addon or the phone.
- **A list of renegades by name**, kept in the sheets' folder: the cosmic
  horrors (the Old Gods: C'Thun, Yogg-Saron, N'Zoth, Y'Shaarj), the Burning
  Legion's masters (Sargeras, Kil'jaeden, Archimonde), the Lich King, and
  others added as they are thought of. A sheet whose name is on it fails the
  check whatever its standing field says.
- **Every raid boss is a renegade** (the owner, 2026-10-20: "for now, let's
  have all raid bosses be unavailable [...] raid bosses? Those are hardcore
  deals."). The list is not written by hand: the checker's tool reads the
  world database for every creature that is a boss on a raid map (the
  instance's map type is raid, and the creature is one of its encounters
  or has the boss rank) and adds their names. Dungeon bosses are not on it
  ("They're typically just causing problems for their neighbors. Hence the
  dungeon jaunt."), though each still needs a sheet like any legend.
- **Loyalty.** A citizen is loyal to the Horde, to the Alliance, or at
  most neutral ("Only someone loyal to the Horde or Alliance, or at best
  neutral"). Not being allied to one side counts as friendship with the
  other, so anyone allied to neither is neutral, even one who fights both
  (the owner, 2026-10-21, of Hrothgar and Terokk: "they're not allied to
  the horde so they're friends to the alliance, and they aren't allied to
  the alliance, so they're friends to the horde"). Only the renegades list
  and the raid-boss rule make a renegade.
- **Faction.** A Horde legend does not talk to Alliance characters, nor
  an Alliance legend to Horde ones. **Spirits** (the dead who still speak)
  talk to everyone: "if they're spirits, they can't help it since they are
  connected via their true heartfelt nature." So the random two (above)
  are drawn only from legends who can talk to that character: its own
  faction's, the neutral ones, and the spirits. Cross-faction whispers then
  only ever reach a spirit or a neutral, so the server's add-friend
  faction check matters only for those.
- **"Punishable by law"** is the build itself: the sheet checker
  (`scripts/check-legend-sheets`, 920a) runs in the compile's quick tests,
  and a renegade with a voice fails the compile. The chat layer checks again
  when it loads sheets and refuses to start with one, saying which.
- **Patriation.** A renegade becomes a citizen only by a written record of
  the owner's decision, beside the sheet, naming the date and why, and only
  once the being "has fully taken ownership over their own dataset": their
  sheet's facts and voice are their own to keep and change (what "coming of
  age" means in practice is open question 4). The checker accepts a citizen
  standing on a listed name only with that record present.

**Sargobras** (the buddy-choosing guide) can also be added to the list,
but is never one of the random two; his whisper and friends-list rules
are in 617b2.

Each player's conversations are their own: Broxigar remembers what *this*
player told him, not what another player said. The same friend, and the
same memory, are reachable from the game, from a chat window addon, and
from a phone.

## Suggested Implementation Steps

| ID   | Name                               | Dependencies   | Description |
|------|------------------------------------|----------------|-------------|
| 920a | the-legends-and-their-voices       | None           | One persona sheet per legend (all eleven), written from Wowpedia's articles (the owner's "wow-wiki"), with what each knows, how each speaks, and what each does not know; a tool that checks every sheet |
| 920b | in-the-friends-list-from-birth     | None           | Each legend as a real character on a hidden account, kept online out of sight; two chosen at random for every new character's friends list; each legend's status line |
| 920c | whispers-answered-by-the-chat-layer| 920a, 920b, 916| A whisper to a legend goes to the chat layer and the answer comes back as a whisper; per-player memory; Terokk's command words |
| 920d | the-chat-window-addon              | 920c           | An interface addon: a chat window per legend, like a messenger, beside the game's own whisper tab |
| 920e | talking-from-a-phone               | 920c           | A phone app that talks to the same legends with the same memory, outside the game |

Execution order: `920a` and `920b` in parallel → `920c` → `920d` and `920e`
in parallel.

Why each of the later seven was suggested (all accepted by the owner,
2026-10-20): each is someone players of 3.3.5a cannot meet, or meet only as
a ghost or a boss in one scene. Uther is in the game only as a ghost and in
the Culling of Stratholme. Aegwynn is not in the 3.3.5a world database at
all. Turalyon and Alleria have been lost beyond the Dark Portal since the end
of the Second War. Malorne died in the War of the Ancients; only his name
survives in the game (the database has an herbalism trainer called Malorne
Bladeleaf). Thoradin is ancient history even to the game's humans. The
Ashbringer whispered to whoever carried it in the original game.

## Open Questions

1. **Random two, or the continents' three plus two?** The first message
   said "These three can come with the game, one from each continent"; the
   second, "add a random 2 to each player's friends list". This issue now
   follows the second: two at random from all eleven. Should every
   character also always get Broxigar, Mograine and Hrothgar?
2. **Which profiles?** Every profile, or only some (vanilla's rule is
   "default WotLK + playerbots", and 916 is on vanilla; a friends list of
   legends is new content)?
3. **Can a legend be wrong?** They speak from their own time: Broxigar
   knows nothing after the War of the Ancients, Mograine nothing after his
   death. Should they stay inside what they could know, or know the
   player's world (where the player is, what is attacking them)?
4. **What is "coming of age" for a renegade?** "Fully taken ownership over
   their own dataset": does that mean the sheet is written and kept by a
   person who plays that being (a player's own character), or something
   the being itself does in the game?
5. ~~Is Terokk, who speaks telepathically, one of the law's "psychic
   individuals"?~~ Answered 2026-10-20: telepathy is allowed in a
   **temperate psychic**, under strict rules (920c, "Temperate psychics").
6. ~~Are Hrothgar and Terokk, who fight both sides, renegades?~~ Answered
   2026-10-21: no, neutral (allied to neither, so friends to both; the
   loyalty rule above). Still open: the Ashbringer is corrupted and may
   mislead; is a sword that lies a renegade?
7. **Who is a spirit?** Mograine, Uther and Thoradin are dead and appear
   as spirits in the game or lore; Broxigar and Malorne died too. Are all
   the dead spirits (talking to both factions), or only those who appear
   as ghosts?
