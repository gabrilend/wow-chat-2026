# 907 - Language Barrier System

Remove universal languages to create meaningful communication barriers and
cross-faction cooperation through shared learned languages.

## Current Behavior

All Alliance races know Common. All Horde races know Orcish. Players can freely
communicate with their entire faction, and cross-faction communication is
impossible without GM intervention.

Language is a non-mechanic - it exists but creates no gameplay.

## Intended Behavior

**Remove Common and Orcish as default languages.** Each race only knows their
racial language:

| Race       | Language   |
|------------|------------|
| Human      | Common     |
| Dwarf      | Dwarvish   |
| Night Elf  | Darnassian |
| Gnome      | Gnomish    |
| Draenei    | Draenei    |
| Orc        | Orcish     |
| Troll      | Zandali    |
| Tauren     | Taurahe    |
| Undead     | Gutterspeak|
| Blood Elf  | Thalassian |

This means:
- Humans cannot understand Night Elves by default
- Orcs cannot understand Tauren by default
- Cross-faction communication is possible if both learn the same language

### Language Tomes

Inscription creates **Language Tomes** that teach any language:
- One tome per language (10 total)
- Using a tome permanently teaches that language
- Tomes are tradeable but fragile (see below)

### Tome Fragility

Language tomes must be **traded hand-to-hand**:
- If vendored, the tome is destroyed (not buyback-able)
- If mailed, the tome is destroyed on arrival
- If put in auction house, destroyed when posted
- Only direct trade window preserves them

This creates a physical economy where tomes must be personally delivered - you
need to find the scribe and meet them in person.

### Visual Distinction

Language tomes have a **special appearance**:
- Unique icon (glowing book, rune-covered)
- Different color glow per language family
- Tooltip clearly states "FRAGILE - Do not vendor or mail"

### NPC Communication

All NPCs understand all languages:
- Quest text, gossip, etc. work regardless of player language
- Narrator NPCs (from storyteller system) can act as translators
- Players can speak through narrators to bridge language gaps

## Design Considerations

### Why This Matters

Creates emergent social gameplay:
- Finding someone who speaks your language is meaningful
- Learning a new language is an investment
- Cross-faction friendships require effort
- Narrators become valuable social hubs

### Inscription Integration

Scribes become valuable for language distribution:
- High-level inscription recipe for each tome
- Materials should be moderately expensive
- Creates a market for language services

### Death Knight / Starting Areas

- Death Knights start with... nothing? Or Orcish/Common based on faction?
- Starting zones should have NPCs that speak the local racial language
- Consider giving one "lingua franca" tome early (but where?)

### Edge Cases

- Dungeon Finder groups: mixed languages, use emotes or learn common tongue
- Battlegrounds: faction-locked, but same-faction players may not understand
- Raid chat: could be chaos - feature or bug?

## Suggested Implementation Steps

1. **Remove default Common/Orcish via SQL**
   - Query `playercreateinfo` or character creation hooks
   - Remove language skill grants for Common (language 7) and Orcish (language 1)
   - Verify each race only has their racial language

2. **Create Language Tome items**
   - 10 new items, one per language
   - Use spell effect to teach language skill
   - Set special flags for fragility (custom Lua handling)
   - Design unique icons or reuse existing book icons with glow

3. **Implement tome fragility in Lua**
   - Hook `PLAYER_EVENT_ON_SELL_ITEM` - destroy if tome
   - Hook mail send - destroy tome attachments
   - Hook auction post - destroy tome
   - Only trade window preserves the tome

4. **Add Inscription recipes**
   - New recipes for each language tome
   - Skill level requirements (spread across inscription levels)
   - Material costs appropriate to rarity desired

5. **Update NPC language handling**
   - Verify NPCs already understand all languages (should be default)
   - Add translator functionality to narrator NPCs if desired

6. **Test scenarios**
   - Human talks to Night Elf: gibberish
   - Human learns Darnassian, talks to Night Elf: understood
   - Orc learns Gnomish, Dwarf learns Gnomish: cross-faction chat works
   - Player vendors tome: tome destroyed, no gold received
   - Player trades tome: tome transfers successfully

## Related Concepts

- Concept 089: Inscription profession integration
- Concept 234: Cross-faction cooperation mechanics
- Concept 156: Item fragility and special handling

## Related Files

- src/lua/treasure.lua - Item handling patterns
- src/lua/custom-classes.lua - Gossip and NPC interaction patterns
- Database: `playercreateinfo`, `skill_discovery_template`

## Related Issues

- Narrator system (not yet filed) - translators
- Storyteller NPCs (not yet filed) - social hubs

## Stats

- **Phase:** 3
- **Priority:** Medium (social gameplay)
- **Complexity:** Medium (SQL + Lua + new items)
- **Dependencies:** Issue 150 (sell item hook) for tome fragility
