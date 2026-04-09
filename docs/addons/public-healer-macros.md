# Public Healer Mouseover Macros Guide

This guide explains how to set up keyboard-triggered healing while hovering over
Public Healer frames. This is the most responsive healing method and bypasses
combat lockdown limitations.

## How Mouseover Healing Works

1. You hover your mouse over a health bar in Public Healer
2. You press a keybind (e.g., "1" or "F1")
3. The macro casts a spell on whoever is under your cursor
4. If no valid target is under cursor, it casts on your current target

This is faster than click-to-cast because:
- No click required, just hover + keypress
- Works regardless of combat lockdown state
- Can be used on any frame (Public Healer, party frames, nameplates)

## Basic Mouseover Macro Template

```
#showtooltip
/cast [@mouseover,help,nodead] SPELL_NAME; [@target,help,nodead] SPELL_NAME
```

Breakdown:
- `#showtooltip` - Shows the spell icon and tooltip
- `@mouseover` - Target under your cursor
- `help` - Only friendly targets
- `nodead` - Only living targets
- The part after `;` is the fallback if mouseover fails

## Priest Macros

### Flash Heal (Emergency)
```
#showtooltip Flash Heal
/cast [@mouseover,help,nodead] Flash Heal; [@target,help,nodead] Flash Heal
```

### Lesser Heal (Efficient)
```
#showtooltip Lesser Heal
/cast [@mouseover,help,nodead] Lesser Heal; [@target,help,nodead] Lesser Heal
```

### Renew (HoT)
```
#showtooltip Renew
/cast [@mouseover,help,nodead] Renew; [@target,help,nodead] Renew
```

### Greater Heal (Big Heal)
```
#showtooltip Greater Heal
/cast [@mouseover,help,nodead] Greater Heal; [@target,help,nodead] Greater Heal
```

### Power Word: Shield
```
#showtooltip Power Word: Shield
/cast [@mouseover,help,nodead] Power Word: Shield; [@target,help,nodead] Power Word: Shield
```

### Dispel Magic
```
#showtooltip Dispel Magic
/cast [@mouseover,help,nodead] Dispel Magic; [@target,help,nodead] Dispel Magic
```

### Prayer of Mending
```
#showtooltip Prayer of Mending
/cast [@mouseover,help,nodead] Prayer of Mending; [@target,help,nodead] Prayer of Mending
```

## Paladin Macros

### Holy Light
```
#showtooltip Holy Light
/cast [@mouseover,help,nodead] Holy Light; [@target,help,nodead] Holy Light
```

### Flash of Light
```
#showtooltip Flash of Light
/cast [@mouseover,help,nodead] Flash of Light; [@target,help,nodead] Flash of Light
```

### Holy Shock (Heal/Damage)
```
#showtooltip Holy Shock
/cast [@mouseover,help,nodead] Holy Shock; [@target,harm,nodead] Holy Shock; Holy Shock
```

### Hand of Protection
```
#showtooltip Hand of Protection
/cast [@mouseover,help,nodead] Hand of Protection; [@target,help,nodead] Hand of Protection
```

### Cleanse
```
#showtooltip Cleanse
/cast [@mouseover,help,nodead] Cleanse; [@target,help,nodead] Cleanse
```

## Druid Macros

### Rejuvenation
```
#showtooltip Rejuvenation
/cast [@mouseover,help,nodead] Rejuvenation; [@target,help,nodead] Rejuvenation
```

### Regrowth
```
#showtooltip Regrowth
/cast [@mouseover,help,nodead] Regrowth; [@target,help,nodead] Regrowth
```

### Healing Touch
```
#showtooltip Healing Touch
/cast [@mouseover,help,nodead] Healing Touch; [@target,help,nodead] Healing Touch
```

### Lifebloom
```
#showtooltip Lifebloom
/cast [@mouseover,help,nodead] Lifebloom; [@target,help,nodead] Lifebloom
```

### Remove Curse
```
#showtooltip Remove Curse
/cast [@mouseover,help,nodead] Remove Curse; [@target,help,nodead] Remove Curse
```

### Wild Growth (AoE)
```
#showtooltip Wild Growth
/cast [@mouseover,help,nodead] Wild Growth; [@target,help,nodead] Wild Growth
```

## Shaman Macros

### Lesser Healing Wave
```
#showtooltip Lesser Healing Wave
/cast [@mouseover,help,nodead] Lesser Healing Wave; [@target,help,nodead] Lesser Healing Wave
```

### Healing Wave
```
#showtooltip Healing Wave
/cast [@mouseover,help,nodead] Healing Wave; [@target,help,nodead] Healing Wave
```

### Chain Heal
```
#showtooltip Chain Heal
/cast [@mouseover,help,nodead] Chain Heal; [@target,help,nodead] Chain Heal
```

### Riptide
```
#showtooltip Riptide
/cast [@mouseover,help,nodead] Riptide; [@target,help,nodead] Riptide
```

### Cleanse Spirit
```
#showtooltip Cleanse Spirit
/cast [@mouseover,help,nodead] Cleanse Spirit; [@target,help,nodead] Cleanse Spirit
```

## Setting Up Keybinds

### Step 1: Create the Macros
1. Press ESC → Macros
2. Click "New"
3. Name the macro (e.g., "MO_FlashHeal")
4. Paste the macro text
5. Click "Save"

### Step 2: Place on Action Bar
1. Drag the macro icon to an action bar slot
2. Recommended: Use a bar you've dedicated to healing macros

### Step 3: Bind to Keys
1. Press ESC → Key Bindings
2. Scroll to "Action Bar" or the specific bar you used
3. Click the slot where you placed the macro
4. Press the key you want (e.g., F1, F2, or 1, 2, 3)

### Recommended Keybind Layout

For a healer, consider:

| Key | Spell Type | Example |
|-----|------------|---------|
| 1 | Fast heal | Flash Heal |
| 2 | Efficient heal | Lesser Heal |
| 3 | Big heal | Greater Heal |
| 4 | HoT | Renew |
| 5 | Dispel | Dispel Magic |
| F1-F5 | Emergency/utility | Shield, PoM, etc. |

Or use mouse thumb buttons (Mouse4, Mouse5) for instant-cast spells.

## Advanced Macros

### Cast on Mouseover OR Self
If nothing under cursor and no target, heal yourself:
```
#showtooltip Flash Heal
/cast [@mouseover,help,nodead][@target,help,nodead][@player] Flash Heal
```

### Stop Casting + Heal (Emergency)
Interrupt current cast to heal immediately:
```
#showtooltip Flash Heal
/stopcasting
/cast [@mouseover,help,nodead] Flash Heal; [@target,help,nodead] Flash Heal
```

### Target the Mouseover
Just target without casting (useful for inspecting):
```
/target [@mouseover,exists]
```

### Focus the Mouseover (for Tank Watching)
```
/focus [@mouseover,exists]
```

### Cast on Focus if Mouseover Unavailable
```
#showtooltip Flash Heal
/cast [@mouseover,help,nodead][@focus,help,nodead][@target,help,nodead] Flash Heal
```

## Troubleshooting

### Macro Doesn't Cast
- Check if the spell name is exactly correct (case-sensitive)
- Verify you have the spell trained
- Make sure target is friendly (`help` condition)
- Make sure target is alive (`nodead` condition)

### Can't Target Through Public Healer Frames
- Public Healer frames ARE valid mouseover targets
- If not working, check if AIO addon is loaded
- Verify frames are properly created (should see them on screen)

### Macro Casts on Wrong Target
- Make sure you're actually hovering over the desired frame
- The macro prioritizes: mouseover → target → fallback
- If using `@player` fallback, it will heal yourself if no other target

### Keybind Doesn't Work
- Check for keybind conflicts (another addon using the same key)
- Some keys are reserved by the system
- Try a different key to test

## Tips for Efficient Healing

1. **Keep moving your mouse** - Practice smooth cursor movement across frames
2. **Prioritize low HP** - Public Healer can sort by HP percentage
3. **Use HoTs proactively** - Hover over full-health targets to pre-HoT
4. **Watch for class icons** - Tanks (warrior/paladin) may need priority
5. **Party border glow** - Party members have a highlight, prioritize them
6. **Practice in safe areas** - Get muscle memory before combat

## See Also

- [Public Healer User Guide](public-healer-guide.md)
- [Public Healer API](public-healer-api.md)
- Issue 168: Public Healer Frames Addon
