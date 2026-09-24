-- sargobras-jokes.lua - the jokes Sargobras tells while he waits by the fire
-- (issue 617b). Plain data: one string per joke, read by the selector NPC's
-- idle loop, which picks one at random when a player is near.
--
-- This list is meant to grow (owner, 2026-09-23: "his jokes should come from a
-- written list, but we have to add to it every once in a while"). Add new
-- jokes at the end; keep each to a line or two so it fits a chat bubble.
-- Sargobras is suave, a little theatrical, and never unkind.
--
-- The Lua engine (ALE) also runs every .lua file under lua_scripts/ once at
-- startup, this one included. It only returns a table, so that run does
-- nothing; the idle loop loads it explicitly (dofile) to use it.

return {
    "I asked a murloc for directions. He said 'mrglglgl'. Honestly, the most useful advice I've had all week.",
    "They say a gnome built this campfire. That's why it's asking me to sign a waiver.",
    "Never lend gold to a goblin. You won't get it back, and he'll charge you for the lesson.",
    "I once met a kobold who wanted a candle. I gave him mine. Now we're both in the dark, but only one of us is happy.",
    "A dwarf walks into a tavern. Then he walks into another tavern. Then another. It's called a pub crawl, and he's winning.",
    "Why did the undead refuse the second helping? He had no stomach for it.",
    "Tauren make excellent friends. Terrible hide-and-seek partners, though.",
    "I asked a night elf how old she was. She said 'older than your kingdom'. I said 'that's not an answer'. She said 'neither was your kingdom'.",
    "The secret to a good campfire is dry wood, a clear sky, and a mage who owes you a favour.",
    "An orc told me 'Lok'tar ogar'. I told him 'likewise'. We've been close ever since.",
    "I'd tell you a joke about the Scourge, but it would just keep coming back.",
    "Companions are like boots. You don't notice the good ones until you're walking without them.",
}
