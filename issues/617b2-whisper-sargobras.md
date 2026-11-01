# 617b2 - Whisper Sargobras

## Status
- Created: 2026-10-14
- Phase: 6
- Parent: 617b (Sargobras)
- Blocks: 620c (bots ask Sargobras by whispering him)
- Related: 617t1 (the stand-in account, a bot account with no owner),
  617a5 (companion accounts hidden from /who, B044), 617y (spoken
  orders, the other chat-driven buddy feature), 617l (the clan's name)
- Priority: Medium

## Origin

The owner, 2026-10-14:

> let's add whisper shortcuts to Sargobras, making him a stand-in or buddy
> account that can be whispered. He should also have a dialogue option -
> the buddy-bot character is invisible, and they always have the same
> location. Any Sargobras will answer so there's exactly one Sargobras that
> you can whisper. But, all of them, specific in that moment, would
> respond. So, the bots, upon logging in or acquiring a Sargobras event,
> will wait ~15-30 seconds while they talk to Sargobras, and then they will
> automatically send a whisper to him and he'll execute the action. The
> player can also whisper Sargobras if they use specific chat commands.
> /whisper Sargobras priest creates a holy priest named felicity for the
> player to adventure with.

## Current Behavior

**Built 2026-10-30, compiled 2026-10-31, not yet tried in game (steps 2 to 5 below):**
- the reader: `patches/E066-sargobras/helpers/lib/sargobras-whisper.lua`
  turns a whisper into one of his menu's choices (a class, a people,
  "flexible", "help", "owed", or unknown), checked offline by
  `scripts/test-sargobras-whisper` (67 checks, a quick test);
- the handler: `sargobras.lua` hears a whisper to the character named
  Sargobras (the whisper event) and does what it asks with the menu's own
  steps and refusals; the one Sargobras creature present for the
  whisperer with the lowest tier answers aloud (a valley Sargobras counts
  lowest), or the character answers by whisper when none is present;
- the faction rule: source patch B063 lets a whisper to Sargobras through
  the cross-faction test (basic), every other one still refused;
- names (step 4): a buddy's name is drawn from every unused name of its
  race and gender in a random order until one passes the server's rules
  (`PickName`, `buddies_create.cpp`), no longer giving up after five
  draws; waiting for the compile.

**The character (step 1), built and compiled 2026-10-31; made and logged in at the first start (guid 3044)**
(syntax-checked; `buddies_sargobras.cpp`): every 10 seconds after the
server starts, the buddy module makes the account SARGOBRAS if missing (a
password nobody is told), then the character Sargobras on it if missing
(a human man, level 1, as a buddy is made), then logs him in as a bot
with no master (asked again after a minute if he hasn't arrived). At his
login he is made invisible, rooted, and sent to the developers' island
(map 1, out of every player's way). His account goes on the companion
list, so he is hidden from /who and add-friend and takes no bot commands
(B044, B045); he is no owner (`BuddyIsNotAPlayer` says so for him, and
the login pass skips him), and a whisper to him gets no buddy's
placeholder answer (`buddies_whisper.cpp`). If a character on another
account already holds the name, the module logs the error once and
makes none. Not yet run: whether the bot module leaves a masterless bot
quite still, and whether his whisper back reaches the other faction.
Known conflict: the add-friend hiding also hides him from `/friend
Sargobras`, which the friends-list idea below wants to allow.

Before this, Sargobras existed only as creatures (the valley one,
6170001; the wandering one, 6170002 and 6170003 with his hat), driven by
dialogue menus in `patches/E066-sargobras/sargobras.lua`. A whisper can
only be sent to a logged-in character, so "/whisper Sargobras" answers "No
player named 'Sargobras' is currently playing." Choosing a buddy means
walking up to one of the creatures and clicking a dialogue line.

Facts that shape the design:

- **Cross-faction whispers are refused** on basic:
  `AllowTwoSide.Interaction.Chat = 0` in `worldserver.conf`. One
  whisperable character belongs to one faction, so the other faction
  could not reach him.
- `sargobras.lua` already listens to player chat (event 18); ALE also has
  a whisper event that names the receiver.
- The buddy module already logs in bot characters on hidden accounts
  (companion accounts, 617a2) and on the stand-in account (617t1, "no
  owner, no placement"), and B044 hides companion accounts from /who and
  add-friend.

## Intended Behavior

**The whisper works his menus, it does not open them** (the owner,
2026-10-30, word for word: "we can interact with the buddy-making menus,
not open them."). A whisper makes the same choices his dialogue lines
make, from afar; it does not put his menu on the player's screen.

**One Sargobras to whisper, on his own account** (the owner, 2026-10-30,
word for word: "Sargobras needs his own account for the functionality
related to him being every guild's guild master. Can you find that and
use that for guidance?"). The unseen guild master (630, step 3) is a
character that belongs to every guild's roster and never visibly logs
in; that character needs an account, and it is this one: the
whisperable Sargobras and the guild master are one character on one
account of his own, not the stand-in account. A character named
Sargobras, logged in as a bot on that account whenever the world server
runs. He is invisible and never
moves: he stands at one fixed spot out of the way, takes no bot commands,
fights nothing, and is hidden from /who and add-friend as buddies are.
He exists only to receive whispers.

**One Sargobras answers, the lowest level first** (the owner,
2026-10-30, word for word: "a single sargobras responds. If there are
Sargobrases from multiple level tiers, then the lowest level one is
utilized first."). Of the Sargobras creatures present for the whisperer,
exactly one speaks the answer aloud in /say, as he does when a dialogue
line is clicked, and the action is done once: where creatures of more
than one level tier are present, the lowest-level one answers. With no
Sargobras creature near, the invisible one answers by whisper.

**Both factions reach the one character** (the owner, 2026-10-30, word
for word: "one character, patched faction rule."): the whisper's faction
check lets a whisper to Sargobras through, and stays as it is for
everyone else.

**The commands** (the same choices the dialogue offers, in words):

| Whisper | Does |
|---|---|
| `priest` (any class name) | chooses a buddy of that class for the lowest owed slot, by the same rules the dialogue line uses (`lib/buddy-choice.lua`), spec included: the buddy is made exactly as one chosen at his menus would be |
| `shadow priest` (spec, then class) | the same as `priest`: spec words are read past, the spec drawn as at his menus (owner, 2026-10-28) |
| `troll priest` (a people and a class) | the class is taken, the people drawn as at the class menu |
| `flexible` (or `any`, `anyone`) | his "I'm flexible." line |
| `troll` (any race name) | chooses by race, as the race dialogue lines do |
| `help` | lists the commands |
| `owed` | says how many buddies the whisperer is owed |

A whisperer owed nothing gets his usual "nothing owed" answer. A
whisper he does not understand gets a joke and the help line. The
menu's refusals hold for whispers too: a death knight is told its
companions come from Acherus, and an owner with no clan yet is told to
find him and name it first (the naming uses the client's own pop-up box,
which only his menu can open).

**In the friends list, by choice only.** The owner, 2026-10-20 (while
designing the legendary friends, 920):

> Sargobras is also an option that never is included with new
> character's friends list. But players can add him, and he'll always be
> offline unless he's currently spawned for a player. If players send him
> any message at all (while he's online of course) it'll open his dialogue
> menu. Even though they're potentially very far away. This is to prevent
> him getting lost on zeppelins causing a problem.

- He is never among 920's two random legends; a player adds him by name
  (`/friend Sargobras`), and B044's add-friend hiding must let his name
  through.
- **Online only while a Sargobras is spawned for that player.** The
  whisperable character is in the world all the time (whispers need it),
  but what each player's friends list shows is sent to that player alone:
  the server's friend-status message (the one it sends when a friend logs
  in or out) is sent per player, "online" while that player has a wandering
  or valley Sargobras present for them, "offline" otherwise. A whisper
  from a player for whom he is "offline" is answered with the client's
  usual "No player named 'Sargobras' is currently playing."
- **Any message opens his dialogue, from any distance.** While he is
  online for a player, any whisper (not only the commands above) opens his
  dialogue menu on that player's screen, built as a menu the player
  object itself sends (ALE's player-sent menus are not refused for
  distance, as a creature's would be), with the same lines as the creature
  beside them. The commands above still work as shortcuts. A Sargobras
  left behind when his owner rode a zeppelin is still reachable this way.
- **Not now:** a way for a separated wandering Sargobras to catch up by
  walking the path his owner took (nearest point on the owner's recorded
  route, then along it), instead of appearing beside them, possibly inside
  the zeppelin. Proposed and set aside by the owner the same day ("actually
  nvm let's skip that for now"); it would suit `docs/roaming-pattern.md` as
  a pattern for other projects when it comes back.

**A dialogue option.** Each Sargobras creature gets one more line,
"Can I call on you from afar?", whose answer explains the whispers.

**Bots use the same door (620c).** A bot owner, at login or when a
Sargobras is summoned for it, walks to the nearest Sargobras, faces him and
"talks" (the talking gesture) for 15 to 30 seconds, then whispers him
its choice; he answers aloud and the buddy is made. One path for humans
and bots: the whisper.

## Suggested Implementation Steps

1. **The character:** make Sargobras on the chosen account at install (an
   E-patch, like the stand-ins' rows, E056); log him in with the buddy
   module at server start, place him at the fixed spot, make him
   invisible to everyone (a permanent invisibility aura or the
   per-player unselectable rule, 164) and inert (no bot strategies).
2. **Cross-faction:** let a whisper whose receiver is Sargobras through
   the faction check while leaving `AllowTwoSide.Interaction.Chat` off
   for everyone else (a small B-patch at the whisper's faction test), or
   two characters, one per faction (see open questions).
3. **The commands:** in `sargobras.lua`, a whisper handler that splits the
   message into words and looks them up in dispatch tables (classes,
   specs, races, keywords), then calls the same choose function the
   dialogue uses. Every Sargobras creature near the whisperer says the
   answer.
4. **Names: none asked for** (the owner, 2026-10-30, word for word: "we
   don't get to pick buddy names. How does the auto-generation already
   handle this? My instinct is that we should just try again until we get
   a valid name."). A whisper never names the buddy. How the name is
   drawn today (read 2026-10-30 in the buddy module's character maker):
   a random name from the bot module's name list for the race and
   gender, among those no character has; drawn again if it fails the
   server's name rules or is reserved, at most five draws, and the buddy
   is not made (an error saying no unused name is left) when all five
   fail. To build, as the owner's instinct says: draw again until a
   valid name comes, ending only when the list holds no unused name for
   that race and gender (then the error, as now), not after a fixed five.
5. **Tests:** an offline test of the word parsing beside
   `scripts/test-buddy-choice`; in game, `/w Sargobras shadow priest`
   from each faction, near a wanderer and far from any, and near two
   Sargobras of different level tiers (the lower answers).
6. Update 617b's Current Behavior.
## Open Questions

Gathered 2026-10-28 into 617's own list (question 32), merged with the
same questions from other sub-issues; answers are written back here.

- **Which account:** answered 2026-10-30: his own, the one the unseen
  guild master (630) needs (above, word for word).
- **Both factions:** answered 2026-10-30: "one character, patched
  faction rule."
- **"All of them respond"**: answered 2026-10-30: a single one, the
  lowest level tier first (above, word for word).
- **A name that is taken:** answered 2026-10-30: buddy names are never
  asked for; the drawing tries again until a valid name comes (above,
  word for word).
- **Default spec:** answered 2026-10-28: "the spec should be picked in the
  same way that any other buddy. This whisper shortcut is just a way to
  interact with him from afar, or in an automated fashion. It should just
  create a priest using the same rules we already have." The whisper is
  his menus from afar; it adds no rules of its own.
- **Opening his menu from the friends list** (raised 2026-10-30): the
  friends-list design above (2026-10-20) says any whisper "will open his
  dialogue menu", while the answer of 2026-10-30 says a whisper works his
  menus and does not open them. Does a whisper that is not a command
  still open his menu, or answer with the help line? **Deferred
  2026-10-30** (the owner, word for word): "oh, um hmmmmmm... let's defer
  that for now. We can just have the players click on him for now."
  Opening his menu from afar is not built; players click on him.
