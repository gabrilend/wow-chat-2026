# Conversation Summary: 90bf80e4-2922-4058-918c-551568e85c2a

Generated on: 2026-10-17 15:13:35
Models: claude-opus-5-5

--------------------------------------------------------------------------------

### User Request 1

Hi, can you make me a list of the things that we don't currently have plans for
AI generating? I'm thinking landscape, quests, dialogue, and unit types (all
characters should be able to be randomized. We can do this by making NPCs into
players behind the scenes, and "baking" their presets into NPCs that can be
spawned quickly. That way, it's relatively easy to process them all, and also we
can easily change them by simply spawning a player type character with the newly
modified gear and such, and then baking them in the background if we expect to
have them long-term. Otherwise, accept the performance hit on that player
character.) Also spell effects. I think we have something for UI elements? What
else can you think of? Our goal is to transition World of Warcraft to something
that is as distinct to World of Warcraft as any other MMO of the era, such as
Warhammer Online or Wildstar. Unfortunately, there are so few of them still
running... We will have to use our best judgement based on what records we can
find on the internet and such.

--------------------------------------------------------------------------------

### Assistant Response 1

> Still reading what's already planned before I write the list.

No current plan covers AI generation of landscape, quests, quest text and
dialogue, creature models, spell effects, sound, or about a dozen other things.
Here's what is planned, then what isn't, ordered from most to least valuable for
making it feel like a different game.

## Already planned (so you can rule these out)

- **Gear appearance.** The gear gallery pipeline goes from a written design to
  concept art to 3D model to texture, borrows a skeleton, and adds generated
  animations. The design side and the voting page are running. The image-to-3D
  stages are written but untested, because the image generator's install isn't
  finished yet.
- **Interface pieces.** The planned interface-piece image generator draws
  scrollbars, close buttons, frames, tabs, tooltips and so on from a short
  description. Whole windows can be built from those descriptions. Not built
  yet.
- **Bot speech.** The planned LLM chat module has bots talk in character for
  their race, class and spec, and also adjusts their fighting priorities.
  Separately, a planned feature lets you give the buddies orders in plain text.
- **Lore.** One existing idea generates shepherd stories, narrator lines and
  rumors. It's written as an idea, not an implementation plan.
- **Quests, partly.** The class-unlock quests are being redone as a prototype
  for "dynamic quests": the quest-giver arrives as one of your travelers, and
  the quest's monsters join your ambush spawns. The roadmap also lists
  "procedural quest generation" with no plan behind it.
- **Creature choice.** Ambushes would pick monsters by meaning, comparing name
  embeddings instead of picking at random. This selects existing creatures; it
  doesn't create new ones.

## Not planned

1. **Style rules every generator reads.** These would be the palette, silhouette
   rules, how ornate armor is versus how worn, and how the light falls.
   Warhammer looked like Warhammer and Wildstar looked like Wildstar because one
   art direction ran through everything. Without a shared rulebook, each
   generator drifts toward "generic fantasy". I'd build this before any
   generator below.
2. **Characters and creature types.** This is your bake-to-NPC idea, covered
   under the next heading.
3. **Spell effects.** There's no plan for generating them. The particle system
   in our own client already reads and runs the original emitters, so generated
   emitter settings plus generated sprite sheets would slot into it.
4. **Landscape.** Our client already reads and paints the original's ground
   files: heights, holes, up to four ground textures per chunk, blend maps and
   color tints. A generator would write that same tile format, with height and
   texture layers. After that come doodads (rocks, trees, props) and the sky and
   zone light, which are also already read.
5. **Quests as content.** This means objectives, places and monster choices,
   built on the dynamic-quest prototype.
6. **Quest text and NPC dialogue.** The chat module covers bots talking. It
   doesn't cover the gossip text, quest text and books that the world's
   creatures carry.
7. **Creature models and their animations.** The gear pipeline makes items and
   animations for gear. Generating whole new monsters on a borrowed skeleton
   isn't planned.
8. **Buildings and dungeon interiors.** These are large "world model" files with
   rooms and portals between them. This is the hardest format of all.
9. **Icons.** There are thousands of spell and item icons. The interface-piece
   generator could be stretched to cover them, but no plan says so.
10. **Sound:** music, ambient loops, spell sounds, creature voices.
11. **Names and the place map:** zone names, creature names, item names, faction
    names.
12. **Item stats and loot tables.** Gear appearance is planned, but item power
    and drops aren't.
13. **Boss encounters:** fight scripts, ability rotations and telegraphed danger
    zones on the ground (Wildstar's signature).
14. **Abilities and talent trees.** A custom spell and class system exists, but
    nothing generates its content.
15. **Loading screens, the login scene and cinematics.**
16. **Public events.** Warhammer's public quests were zone-wide goals that
    anyone nearby could join, in stages. Nothing is planned for them, and they
    would fit the empty-world, ambush design.

## Your bake-to-NPC idea

Some of this is already built or planned:
- **The stand-in maker** creates player characters run by the bot system, with a
  race, class and gear chosen for their role. It's written but not tried in game
  yet.
- **Dressing a creature from a gear record** is planned. The record holds a race
  and a list of equipped items, and the creature is shown as a player of that
  race wearing those items, the way Sargobras is dressed.

That second piece is the "bake" step. One way to do it at runtime is the packet
the client uses for the Mage's Mirror Image. In it, the server tells every
nearby client "draw this creature as a player of race X, skin Y, face Z, wearing
items A to K". That costs one packet per viewer and needs no client patch. The
other way, a permanent preset, is a row in a client-side file, and every
player's client would then need an updated file.

Two technical problems I can see:
- **Cost.** A player-type character costs far more than a creature. It has a
  full bot "brain" that ticks continuously, about 19 equipment slots plus bags,
  database rows, and talent and spell state. A creature is a template number
  plus a position. "Accept the performance hit" works for a few dozen. With
  hundreds, the server's update loop starts falling behind.
- **Only humanoids can bake.** The dress-as-a-player trick only works for
  playable race bodies. Wolves, dragons and the generated creature models from
  item 7 can't be baked this way, so "all characters randomized" needs a second
  path for non-humanoid creatures.

## Questions back

1. When a baked NPC needs to change, say it picks up a new sword mid-life, what
   decides whether it goes back to being a full player character or just gets
   its gear record edited? Is a gear record enough to make one, or does it also
   need talents and spells?
2. Of the Warhammer and Wildstar features you remember, which one felt most "not
   WoW" to you? Was it the art, the combat, or a system like public quests or
   Wildstar's paths?
3. Should generated content be reviewed by people before it goes live? The lore
   idea currently says "requires no human review", and that's a big choice for
   landscape and quests.

These three questions are open, so I'm counting the list as in progress until
we've gone through them. I haven't written any files; if you want this saved as
a document or issue files, say which.

--------------------------------------------------------------------------------

