# 131 - Randomized Login Screen with Freddi Fish Background

## Status: Open (Design Phase)

## Vision

Transform the WoW login screen into a dynamic, playful experience where:
1. A different intro cinematic plays each day, cycling through all options
2. The background is an animated Freddi Fish scene from a virtualized game
3. Clicking on the background triggers fish reactions and interactions

## Current Behavior

- Static login screen with single cinematic
- Same background every time
- No interactive elements on the login screen

## Intended Behavior

### Daily Rotating Cinematics
```
Day 1: Classic WoW intro
Day 2: Burning Crusade intro
Day 3: Wrath intro
Day 4: Custom Everland Ghostsong intro
Day 5: (back to Day 1)

Tracking: Store last_cinematic_index in client config
Rotation: Increment on each new calendar day
No repeats: Cycle through ALL before repeating
```

### Freddi Fish Animated Background
```
┌─────────────────────────────────────────────────────┐
│  ~~~  ~~~  ~~~  ~~~  ~~~  ~~~  ~~~  ~~~  ~~~  ~~~  │
│     🐟 ←(click me!)                                │
│  ~~~        ~~~  ~~~  ~~~  ~~~  ~~~  ~~~  ~~~      │
│       🐠                    🦀                      │
│  ~~~  ~~~  ~~~  ~~~  ~~~  ~~~  ~~~  ~~~  ~~~       │
│            🐡        🦑                             │
│  ~~~  ~~~  ~~~  ~~~  ~~~  ~~~  ~~~  ~~~  ~~~  ~~~  │
│     ════════════════════════════════════════       │
│     ║  USERNAME: [_______________]        ║        │
│     ║  PASSWORD: [_______________]        ║        │
│     ║           [ ENTER WORLD ]           ║        │
│     ════════════════════════════════════════       │
└─────────────────────────────────────────────────────┘
```

### Interactive Fish Reactions
```lua
-- When player clicks on background region:
ON_CLICK(x, y):
    fish = find_nearest_fish(x, y)
    if fish then
        fish:play_animation("surprised")
        fish:swim_away(random_direction())
        play_sound("blub_blub.ogg")
    else
        spawn_bubbles(x, y)
        play_sound("water_splash.ogg")
    end
```

## Implementation Approach

### Option A: Client Addon + GIF Overlay
```
1. WoW addon hooks login screen frame
2. Creates transparent frame over background
3. Plays animated texture (converted from GIF)
4. Lua handles click detection and reactions

Files needed:
- Interface/AddOns/FreddiLogin/FreddiLogin.toc
- Interface/AddOns/FreddiLogin/FreddiLogin.lua
- Interface/AddOns/FreddiLogin/Textures/*.blp (animated frames)
```

### Option B: Replace Login Background Entirely
```
1. Extract Freddi Fish frames via emulator screenshot tool
2. Convert to WoW texture format (.blp)
3. Replace Interface/GLUES/CREDITS/Underwater*.blp
4. Patch client to use custom animation sequence

Pros: Native performance
Cons: Requires client patching
```

### Option C: External Window Compositor
```
1. Run Freddi Fish in DOSBox/ScummVM
2. Capture window to texture in real-time
3. Overlay on WoW login screen

"Why wouldn't it be possible to let binaries run binaries?"
- Because the real question is: can we make them talk to each other?
- Shared memory, named pipes, or socket communication
- DOSBox outputs frames → WoW addon reads frames → Display
```

## Freddi Fish Source Material

### Games to Extract From
- Freddi Fish 1: The Case of the Missing Kelp Seeds (1994)
- Freddi Fish 2: The Case of the Haunted Schoolhouse (1996)
- Freddi Fish 3: The Case of the Stolen Conch Shell (1998)

### Key Animations to Capture
- Idle fish swimming
- Fish reacting to clicks
- Bubbles rising
- Seaweed swaying
- Luther (the fish sidekick) doing silly things
- Background ambient animations

### Virtualization Setup
```bash
# Run Freddi Fish in ScummVM (recommended)
scummvm --path=/path/to/freddi-fish --fullscreen=false

# Capture frames using ffmpeg
ffmpeg -f x11grab -video_size 640x480 -i :0.0+100,200 \
    -vf fps=10 -t 30 freddi_bg_%04d.png
```

## Cinematic Rotation Logic

```lua
-- {{{ get_todays_cinematic
local function get_todays_cinematic()
    local cinematics = {
        "Interface/Cinematics/Logo.avi",
        "Interface/Cinematics/WOW_Intro.avi",
        "Interface/Cinematics/WOW_Intro_BC.avi",
        "Interface/Cinematics/WOW_Intro_LK.avi",
        "Interface/Cinematics/Everland_Intro.avi",  -- custom
    }

    local day_of_year = tonumber(date("%j"))
    local index = ((day_of_year - 1) % #cinematics) + 1

    return cinematics[index]
end
-- }}}
```

## Related Issues

- **129 - Portal Dimension System**: Similar "make existing content feel new" philosophy
- **128 - Embedding-Based Selection**: Could use similar randomization patterns

## Open Questions

1. Can WoW 3.3.5a addons hook the login screen? (pre-character-select)
2. What's the frame rate limit for animated textures in glue screens?
3. Legal considerations for using Freddi Fish assets?
4. Could we procedurally generate fish instead of capturing?

## Files to Create

- `client/Interface/AddOns/FreddiLogin/` - Login screen addon
- `assets/freddi-frames/` - Extracted animation frames
- `scripts/capture-freddi.sh` - ScummVM frame capture script
- `tools/gif-to-blp.py` - Convert GIF animations to BLP sequence

## Fun Factor: 10/10

This feature exists purely for joy. Imagine logging in and seeing
little fish swim around behind your password field, clicking on them
and watching them scatter. It sets the tone: this isn't retail WoW,
this is something playful and weird and wonderful.

