--------------------------------------------------------------------------------
-- custom-gm-commands.lua - every game master command this project adds
--
-- For a general audience: the game server answers typed commands such as
-- ".buddy bed add cot". The stock commands keep their help text in the world
-- database's `command` table; the ones this project wrote (in the buddy
-- module, in basic's compiled rules, and in Lua scripts) had none. This file
-- is their one written description. Three tools read it:
--
--   scripts/generate-custom-command-help-sql   the `command` table rows for
--       the compiled ones (help for ".help", and the GM level that may run
--       them: a row's level overrides the one in the code, which for the
--       basic rules was a permission number no account reaches)
--   scripts/generate-gm-command-reference      docs/gm-commands.txt
--   scripts/test-gm-command-reference          that every command the code
--       registers is described here, and nothing here is missing from code
--
-- Fields of an entry:
--   name     string   the command without its dot, words separated by spaces
--   args     string   what follows the name: <needed> [optional] a|b choices
--   level    number   who may run it: 0 player, 1 moderator, 2 game master,
--                     3 administrator, 4 console only
--   console  boolean  whether it also runs from the server console (and so
--                     over SOAP, which is how neuron's live channel sends)
--   kind     string   "compiled" (a C++ command table: gets a `command` row)
--                     or "lua" (a Lua script reading typed commands through
--                     the Lua engine's command hook: no row, since the server
--                     would log a row for a command it doesn't know)
--   source   string   the file that declares it (its command table, or the
--                     Lua script that answers it), from the project root
--   profiles table    the profiles whose server has it
--   system   string   the system it belongs to (scripts/generate-gm-command-
--                     reference's SYSTEMS list); placed there beside its
--                     stock relatives
--   beside   string   (optional) a stock command family to list it inside,
--                     in the reference's every-command section, so it is
--                     found where its relatives are (".basic worldboss
--                     respawn" beside ".respawn"); without it, it sits in
--                     its own family (its first word) in its system
--   help     string   what it does, for a game master; plain sentences
--------------------------------------------------------------------------------

local BUDDY_PROFILES = { "basic", "cc-test" }      -- the buddy module is built into both (issue 176)
local BASIC          = { "basic" }

return {
    -- {{{ companions: buddy beds (617e4)
    { name = "buddy bed add", args = "<bed|cot|floor> [note]", level = 2, console = false, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_beds.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Marks the spot you stand on, facing the way you face, as a place buddies sleep, at that comfort (bed 3, cot 2, floor 1). The note is kept with it." },
    { name = "buddy bed list", args = "", level = 2, console = false, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_beds.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Lists the sleeping spots of the area you stand in, nearest first." },
    { name = "buddy bed remove", args = "", level = 2, console = false, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_beds.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Removes the nearest sleeping spot within 10 yards." },
    { name = "buddy bed link", args = "", level = 2, console = false, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_beds.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Joins the nearest sleeping spot to the next nearest, as one shared bed; both must be within 5 yards. A third spot is joined by standing between it and one of the pair." },
    { name = "buddy bed unlink", args = "", level = 2, console = false, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_beds.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "The nearest sleeping spot within 5 yards stands alone again." },
    -- }}}
    -- {{{ companions: the buddy module's other commands
    { name = "buddy explore", args = "<pinwheel|paint|rooms|disc|mixed>", level = 0, console = false, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_beds.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Chooses how your own buddies explore a town (the work is in buddies_explore.cpp): the pinwheel, least paint, the room orbit, the squished circle, or each buddy a different one in turn (mixed). Any player may set it for their own buddies." },
    { name = "buddy path", args = "[orbit|flow|astar|potential|learn|paint|mesh]", level = 0, console = false, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_path.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Chooses how your own buddies find their way to each roaming waypoint (617o7, 617o8): orbit (straight at it; stuck, back out and walk round), flow (downhill on the walking distance), astar (a whole route, pulled tight), potential (pulled by the point, pushed by walls), learn (a route over what they have bumped into), paint (the painted map: one map a region, shared, learned from every step and every refusal, keeping space from walls, in lanes), or mesh (the server's own path search, the default). Alone: the way chosen, and a table of how each way has done since the server started. Any player may set it for their own buddies." },
    { name = "buddy wider", args = "", level = 0, console = false, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_follow.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Widens the ring your buddies stand in round you when told \"circle me\" (the close follow, 617s2, 617s4): a step out of 5 yards, up to 25. Kept while the server runs." },
    { name = "buddy closer", args = "", level = 0, console = false, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_follow.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Brings the ring your buddies stand in round you back in to its smallest, 5 yards, at once (617s4)." },
    { name = "buddy weather", args = "", level = 2, console = true, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_weather.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Alterac Valley's shared sky (921a): the kind of weather now, its strength, how far into its six-minute turn, and the rest of the shuffled deck. Shared by every match only while Buddies.AlteracWeather is 1." },
    { name = "buddy fight", args = "", level = 2, console = false, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_forward_pass.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Your party's latest fight verdict, worked out every half second while it fights (625n): boss or trash, the time left, how much health the party is short of seeing the end, what comes at each member and how long it lasts, whom each enemy attacks, and which tank should hold the hardest hitter. Only while Buddies.ForwardPass is 1." },
    { name = "buddy scene", args = "[duel|party60|party30|party15|stop] [redraw]", level = 2, console = false, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_scenes.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Fight scenes (176a3): stand-ins against one monster where you stand, round after round; every half second of a fight each combatant's state (health, power, place, targets, cast, auras, threat, running damage and healing, the spells it cast, the forward pass's view of it) is written to LogsDir/buddies-scenes/<scene>-frames.tsv, a line per combatant, and each round's end to <scene>.tsv; nothing is told in game. duel: two level-40 damage stand-ins against a level-45 monster, one the bot module's way, one with the forward pass; party60, party30, party15: tank, healer and damage at 60, 30 or 15 against an elite five levels above, counted as a boss. The fallen wait for the round's end. \"redraw\": new stand-ins each round. Alone: how it stands; stop: ends it." },
    { name = "buddy reset", args = "<buddy name>", level = 2, console = true, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_reset.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Resets a buddy so its owner can choose its class again at Sargobras (617a7): the buddy, which must be in the world, mails everything it wears and carries and its money to itself (\"Kept for you\") and leaves; its slot is owed again with its race kept. Sargobras then offers only the classes that race can play, and the new buddy comes with the same name and looks and is handed the old one's mail. From a shell: scripts/gm-command \".buddy reset <name>\"." },
    { name = "levelto", args = "<name> <level>", level = 2, console = true, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_levelup.cpp", profiles = BUDDY_PROFILES, system = "Characters",
      help = "Brings a character in the world, and their buddies, to a level as if they had played there (185): every weapon skill, defence and profession keeps its share of its maximum (80% of the way stays 80%), up or down; what they wear is replaced by fresh white gear for the level, gemmed by their talents (white and grey items dropped, the rest mailed to them, \"Kept for you\"); each buddy in the world moves by the same number of kills ahead of (or behind) its owner. Not the server's own .levelup, which only adds levels. From a shell: scripts/gm-command \".levelto <name> <level>\"." },
    { name = "buddy army", args = "[count|dismiss]", level = 2, console = false, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_army.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "On a test realm only (a realm branch, which sets Buddies.TestRealm): raises an army round you of 64 (or the count, 1 to 200), your own buddies in the world first and random stand-ins of your side and level for the rest, which roam where you are as your buddies (617e17). Asked again with no count: how it stands. \"dismiss\": every stand-in sent out, kept for the next asker." },
    { name = "shoulders", args = "", level = 0, console = false, kind = "compiled",
      source = "src/cpp-basic/basic_rules.cpp", profiles = BASIC, system = "Characters",
      help = "Hides your shoulders from everyone, yourself included, or shows them again (a toggle). They stay worn, stats and all. Remembered per character." },
    { name = "buddy kit", args = "[buddy name]", level = 2, console = true, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_kit.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Re-dresses a buddy in the world for its level: the kit's gear by its talent shape (gray where no white fills a slot), its class tools (totems, poisons, ammunition), and from level 18 the PvP necklace, rings and trinkets (the second ring and trinket another item than the first, from another battleground where there is one), then gems its sockets as .buddy gems does. No name: the selected buddy. What it wore is replaced." },
    { name = "buddy spec", args = "[buddy name]", level = 2, console = true, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_kit.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Brings a buddy in the world up to the gear spec (docs/buddy-gear-spec.md) without taking off what it earned: every lesson up to its level, weapon skills and defence at their maximum, the kit's gear only in empty slots, its class tools, PvP jewellery when a jewellery slot is empty, its sockets gemmed. No name: the selected buddy." },
    { name = "buddy gems", args = "[buddy name]", level = 2, console = true, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_gems.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Gems every socket of what a buddy in the world wears again: each socket a random colour that fits it, then the best gem of that colour for the buddy's talents. No name: the selected buddy. What was socketed is replaced; free." },
    { name = "buddy area show", args = "", level = 2, console = false, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_show.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Names the roaming part you stand in (its named area, how many parts the area was cut into, its levels and leading monsters) and draws its border in wisps for 30 seconds, along the edges it shares with other parts within 250 yards." },
    { name = "buddy area spawns", args = "<creature id or name>", level = 2, console = false, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_show.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Puts a wisp for 30 seconds on every spawn point of that creature (every creature of that name) within 300 yards of you." },
    { name = "buddy standin make", args = "<alliance|horde> <tank|healer|damage> <level> [race] [class]", level = 2, console = false, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_stand_ins.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Brings a stand-in in beside you: a character that belongs to nobody, of that side and role at that level, race and class drawn at random unless named. A kept one that fits is used first (raised to the level if below it); otherwise a new one is made, all its talents in one tree that takes its role." },
    { name = "buddy standin at", args = "<alliance|horde> <tank|healer|damage> <level> <map> <x> <y> <z> [race] [class]", level = 2, console = true, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_stand_ins.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Brings a stand-in in at a place, as standin make does beside you. Scenes ask for theirs this way." },
    { name = "buddy standin list", args = "", level = 2, console = true, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_stand_ins.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Lists every kept stand-in: race, class, role, talent tree, level, times used, and whether it is in the world." },
    { name = "buddy standin dismiss", args = "<name|all>", level = 2, console = true, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_stand_ins.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Takes a stand-in (or every one) out of the world. It is kept for the next asker." },
    { name = "buddy look", args = "<skin|face|hair|haircolor|beard> <number>", level = 2, console = true, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_outfits.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Changes one part of Sargobras's look until the server restarts. The client asks for a creature's look when it first sees it: walk out of sight and back, or log out and in, to see the change." },
    { name = "buddy record start", args = "", level = 2, console = false, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_recorder.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Starts recording your movements at a boat or zeppelin stop, for buddies to replay when they board or leave a ship." },
    { name = "buddy record stop", args = "[note]", level = 2, console = false, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_recorder.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Ends the recording, checks it is one boarding or one leaving at one stop of one ship's route, and keeps it with the note." },
    { name = "buddy record discard", args = "", level = 2, console = false, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_recorder.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Throws away the recording in progress." },
    { name = "buddy record list", args = "", level = 2, console = false, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_recorder.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Lists the recordings of every ship stop near you, with their numbers." },
    { name = "buddy record delete", args = "<number>", level = 2, console = false, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_recorder.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Deletes one recording by the number the list shows." },
    { name = "buddy town here", args = "<radius>", level = 2, console = false, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_town_circles.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Places a town circle of that radius, in yards, where you stand: inside it buddies behave as in town. It is written to the world database at once." },
    { name = "buddy town show", args = "", level = 2, console = false, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_town_circles.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Draws the nearest town circle in wisps standing on its edge, for 15 seconds." },
    { name = "buddy town remove", args = "", level = 2, console = false, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_town_circles.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Removes the nearest town circle that was placed by hand." },
    { name = "buddy trace", args = "<buddy name|off>", level = 2, console = true, kind = "compiled",
      source = "patches/B036-mod-buddies/mod-buddies/src/buddies_trace.cpp", profiles = BUDDY_PROFILES, system = "Companions",
      help = "Starts writing a log of what that buddy decides and does (it must be online). \"off\" stops every trace. The reply says where the lines go." },
    -- }}}
    -- {{{ companions: buddy-gm.lua (617e)
    { name = "buddies to partner", args = "[name] [ring|centre]", level = 2, console = true, kind = "lua",
      source = "src/lua-basic/buddy-gm.lua", profiles = BASIC, system = "Companions",
      help = "Brings every one of a player's buddies in the world to that player. No name: your selected target, the player or one of their buddies. They are placed on a ring or an arc round the player (a ring three times in four unless asked)." },
    { name = "buddies summon", args = "[name] [ring|centre]", level = 2, console = true, kind = "lua",
      source = "src/lua-basic/buddy-gm.lua", profiles = BASIC, system = "Companions",
      help = "Short for \".buddies to partner\": every one of a player's buddies in the world is summoned to that player, placed round them as the hearthstone places them. Into a dungeon, raid or battleground only the buddies in that player's party or raid come; each one left out is named. No name: your selected target." },
    { name = "buddies to me", args = "[name] [ring|centre]", level = 2, console = false, kind = "lua",
      source = "src/lua-basic/buddy-gm.lua", profiles = BASIC, system = "Companions",
      help = "Brings every one of a player's buddies in the world to you, the game master, placed round you as above." },
    { name = "buddies revive", args = "[name] at <me|partner|graveyard> [ring|centre]", level = 2, console = true, kind = "lua",
      source = "src/lua-basic/buddy-gm.lua", profiles = BASIC, system = "Companions",
      help = "Brings every dead buddy of a player back to life at you, at the player, or at the graveyard nearest the player that their side may use." },
    -- }}}
    -- {{{ companions: levers (638)
    { name = "lever", args = "<name|target> <lever> | <name|target> random [word] | find <word>", level = 1, console = true, kind = "lua",
      source = "src/lua-basic/buddy-lever-command.lua", profiles = BASIC, system = "Companions",
      help = "Pulls one of a buddy's some fourteen hundred levers (small things it does with its body: an emote, a pose, a hop, a step, a turn) on the buddy of that name, or your selected buddy (\"target\"). \"random\" pulls a random one, with a word only among the levers whose name or sentence holds it; \"find\" lists the levers whose name or sentence holds the word (the first twenty, and how many). Refused in a fight, while the buddy is being moved, or with no one to aim at." },
    -- }}}
    -- {{{ items: gearsets (617r)
    { name = "gearset", beside = "gear", args = "<profile> <character> | <profile> buddies <partner>", level = 2, console = true, kind = "lua",
      source = "src/lua-basic/gearset-command.lua", profiles = BASIC, system = "Items and mail",
      help = "Dresses a character, or every buddy of a player in the world (the \"buddies\" form), in a gearset profile (src/lua-basic/data/gearsets/<profile>.lua), by spec or class and race: each slot's item is replaced, proficiencies it needs are taught, bags go into empty bag slots, ammunition is added. Shirt and tabard are never touched. Anyone with no record in the profile is named and left as they are." },
    -- }}}
    -- {{{ world: basic's rules (155i, 155j)
    { name = "basic reload multipliers", beside = "reload", args = "", level = 3, console = true, kind = "compiled",
      source = "src/cpp-basic/basic_rules.cpp", profiles = BASIC, system = "Server and messages",
      help = "Reads the per-creature damage, healing and health multipliers again without a restart. Health changes apply to creatures as they next spawn." },
    { name = "basic worldboss respawn", beside = "respawn", args = "<spawn number>", level = 2, console = true, kind = "compiled",
      source = "src/cpp-basic/basic_rules.cpp", profiles = BASIC, system = "Creatures and world objects",
      help = "Brings a world boss back now, by its spawn number. The world bosses' Lua countdown calls this when a boss is due." },
    { name = "basic worldboss status", beside = "respawn", args = "", level = 2, console = true, kind = "compiled",
      source = "src/cpp-basic/basic_rules.cpp", profiles = BASIC, system = "Creatures and world objects",
      help = "Lists every world boss spawn, its creature and whether it is alive or dead, and whether the world boss battle bonus is on." },
    -- }}}
    -- {{{ test harnesses
    { name = "arena start", args = "", level = 2, console = false, kind = "lua",
      source = "src/lua-basic/arena-trial.lua", profiles = BASIC, system = "Groups, guilds and PvP",
      help = "A monster ring for watching buddies fight: stand in the Gurubashi Arena ring and three groups of three monsters near your level appear at the places farthest from your party; each one that dies is replaced at a far place." },
    { name = "arena stop", args = "", level = 2, console = false, kind = "lua",
      source = "src/lua-basic/arena-trial.lua", profiles = BASIC, system = "Groups, guilds and PvP",
      help = "Ends the arena trial and removes its monsters." },
    { name = "redirect", args = "<address> <port> [host|net] [host|net] | key", level = 3, console = false, kind = "lua",
      source = "src/lua-vanilla/redirect-probe.lua", profiles = { "vanilla" }, system = "Server and messages",
      help = "An experiment: tells your own client to hang up and connect to another address, using the client's built-in redirect message, signed with your login's session key. The two optional words choose the byte order of the address and the port. \"key\" prints this login's session key on the server console only." },
    -- }}}
}
