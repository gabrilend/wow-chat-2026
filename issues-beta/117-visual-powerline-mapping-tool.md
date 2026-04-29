# 117 - Visual Powerline Mapping Tool

## Status: Open

## Current Behavior
- Source code is read linearly or searched via grep
- Semantic relationships between files are implicit
- Vertical alignment within files, but no cross-file visual mapping
- Developer must hold datastructure flow in memory

## Intended Behavior
- Screenshot code / terminal output to .png
- Draw semantic connection lines between related concepts
- "Powerlines" rendered by editor for same-datastructure references across files
- Vertical alignment where possible, powerlines as stop-gap when not
- Arrows connect separate statements (not internal connections unless interesting)
- Visual map informs refactoring: "skooch" code to make semantic flow apparent

## Suggested Implementation Steps
1. Parse all source files in src/ directory tree
2. Build identifier index: functions, globals, constants, datastructures
3. Detect cross-file references (same identifier appears in multiple files)
4. Detect cross-statement references (same identifier in separate statements)
5. Render source code to .png with syntax highlighting
6. Procedurally draw powerlines between detected references
7. Output to parallel pngs/ directory structure automatically
8. User opens generated .png to enhance/edit meanings as desired

## Auto-Detection Rules
- Same function name called from multiple files → powerline
- Same constant/global referenced across files → powerline
- Same datastructure (table name) accessed in separate statements → powerline
- require() / module dependencies → powerline
- Event registrations sharing same event constant → powerline

## Generation Workflow
```
src/lua/behaviors/*.lua
        ↓
    [parser]
        ↓
    [index identifiers]
        ↓
    [detect cross-references]
        ↓
    [render to png with powerlines]
        ↓
pngs/lua/behaviors/*.png
        ↓
    [user enhances as needed]
```

## Design Principles

### Semantic Over Syntactic
Connect things that are RELATED IN MEANING, not just syntactically adjacent.
The line from `discuss-with-npc → travel.lua → waypoint data` is semantic dependency.

### Powerlines for Datastructure Flow
When `AvoidMonsters` appears in multiple files, draw the circuit.
When `PLAYER_EVENT_ON_LOGIN` registers across behaviors, that's a powerline.

### Vertical Alignment First
If you can align it vertically in source, do that.
Powerlines are for when vertical alignment isn't possible (cross-file, different contexts).

### Editor-Rendered, Not Source-Embedded
The powerlines exist in the viewing layer, not the source code.
Source code maintains its own internal alignment; powerlines are the meta-view.

## Example Powerline Map

```
find-monsters.lua ──┬── Movement.squaredDistance ──┬── movement.lua
avoid-monsters.lua ─┤                              │
orbit-player.lua ───┘                              │
                                                   │
sit-and-rest.lua ───┬── AvoidMonsters.shouldFlee ──┼── avoid-monsters.lua
orbit-player.lua ───┘                              │
                                                   │
all behaviors ──────── PLAYER_EVENT_ON_LOGIN ──────┴── (shared constant)
```

## Notes

### 2026-03-31 - Concept Documented
- Non-LLM-generated, procedurally calcuformatulated visual paradigm
- Maps created by screenshotting then drawing between automated chunks
- "Skooch" = adjust alignment so visual connections become cleaner
- "Wave" = align config points to create flow across files

## Related Files
- src/lua/behaviors/*.lua (demonstration case)
- src/lua/movement.lua (shared datastructure)
- docs/architecture.md (could include powerline maps)
