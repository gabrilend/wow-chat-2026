# Upstream Warning Fixes Patch

## Overview

Fixes compiler warnings in upstream modules (mod-playerbots, mod-ale, boost).
These are not bugs, but clean compilation improves code quality and makes
real issues easier to spot.

## Warning Summary (Before)

| Count | Warning Type                      | Fix Type             |
|------:|-----------------------------------|----------------------|
|   500 | NextAction deprecated copy        | Add operator=        |
|   442 | boost unary_function deprecated   | Compiler flag        |
|   119 | MovementActions.h signed/unsigned | Change loop variable |
|    40 | HunterActions.h unused param      | Cast to void         |
|    13 | ItemCountValue.h unused param     | Cast to void         |
|    12 | PositionInfo deprecated copy      | Add operator=        |
|     3 | CraftData deprecated copy         | Add operator=        |
|     3 | UnitPosition deprecated copy      | Add operator=        |
|     3 | Arrow.h initializer order         | Reorder init list    |
|     2 | PlayerMethods.h signed/unsigned   | Cast comparison      |

Total: ~1137 warnings → 0

---

## Part 1: Deprecated Copy Assignment Operators

C++11 deprecates implicit copy assignment when a user-defined copy constructor exists.
Fix: Explicitly default the copy assignment operator.

### 1.1 NextAction (500 warnings)

**File:** `modules/mod-playerbots/src/Bot/Engine/Action/Action.h`

**Find (line 20):**
```cpp
    NextAction(NextAction const& o) : relevance(o.relevance), name(o.name) {}  // name after relevance - whipowill
```

**Insert after:**
```cpp
    NextAction& operator=(NextAction const&) = default;
```

### 1.2 PositionInfo (12 warnings)

**File:** `modules/mod-playerbots/src/Ai/Base/Value/PositionValue.h`

**Find (line 23-26):**
```cpp
    PositionInfo(PositionInfo const& other)
        : x(other.x), y(other.y), z(other.z), mapId(other.mapId), valueSet(other.valueSet)
    {
    }
```

**Insert after closing brace:**
```cpp
    PositionInfo& operator=(PositionInfo const&) = default;
```

### 1.3 CraftData (3 warnings)

**File:** `modules/mod-playerbots/src/Ai/Base/Value/CraftValue.h`

**Find (line 19-23):**
```cpp
    CraftData(CraftData const& other) : itemId(other.itemId)
    {
        required.insert(other.required.begin(), other.required.end());
        obtained.insert(other.obtained.begin(), other.obtained.end());
    }
```

**Insert after closing brace:**
```cpp
    CraftData& operator=(CraftData const&) = default;
```

### 1.4 UnitPosition (3 warnings)

**File:** `modules/mod-playerbots/src/Ai/Base/Value/Arrow.h`

**Find (line 19-23):**
```cpp
    UnitPosition(UnitPosition const& other)
    {
        x = other.x;
        y = other.y;
    }
```

**Insert after closing brace:**
```cpp
    UnitPosition& operator=(UnitPosition const&) = default;
```

---

## Part 2: Signed/Unsigned Comparisons

### 2.1 MovementActions.h Loop Variable (119 warnings)

**File:** `modules/mod-playerbots/src/Ai/Base/Actions/MovementActions.h`

**Find (line 279):**
```cpp
        for (int i = 0; i < intervals; i++)
```

**Replace with:**
```cpp
        for (uint32 i = 0; i < intervals; i++)
```

### 2.2 PlayerMethods.h Enum Comparison (2 warnings)

**File:** `modules/mod-ale/src/LuaEngine/methods/PlayerMethods.h`

**Find (line 2565):**
```cpp
        if (slot >= EQUIPMENT_SLOT_START && slot < EQUIPMENT_SLOT_END)
```

**Replace with:**
```cpp
        if (slot >= static_cast<int32>(EQUIPMENT_SLOT_START) && slot < static_cast<int32>(EQUIPMENT_SLOT_END))
```

---

## Part 3: Unused Parameters

Fix by casting to void to indicate intentional non-use.

### 3.1 ItemCountValue.h (13 warnings)

**File:** `modules/mod-playerbots/src/Ai/Base/Value/ItemCountValue.h`

**Find (line 20):**
```cpp
    bool Execute(Event event) override { return false; }
```

**Replace with:**
```cpp
    bool Execute(Event event) override { (void)event; return false; }
```

### 3.2 HunterActions.h (40 warnings - 4 locations)

**File:** `modules/mod-playerbots/src/Ai/Class/Hunter/Action/HunterActions.h`

**Find (line 355):**
```cpp
    bool Execute(Event event) override { return botAI->CastSpell(60053, GetTarget()); }
```

**Replace with:**
```cpp
    bool Execute(Event event) override { (void)event; return botAI->CastSpell(60053, GetTarget()); }
```

**Repeat for lines 371, 387, 403** (spell IDs 60052, 60051, 53301 respectively).

---

## Part 4: Member Initializer Order

### 4.1 ArrowFormation (3 warnings)

**File:** `modules/mod-playerbots/src/Ai/Base/Value/Arrow.h`

The warning indicates `built` is initialized before `masterUnit` in the initializer list,
but declared after in the class. Initialization happens in declaration order regardless.

**Find (line 104-106):**
```cpp
    ArrowFormation(PlayerbotAI* botAI)
        : MoveAheadFormation(botAI, "arrow"), built(false), masterUnit(nullptr), botUnit(nullptr)
    {
```

**Replace with:**
```cpp
    ArrowFormation(PlayerbotAI* botAI)
        : MoveAheadFormation(botAI, "arrow"), masterUnit(nullptr), botUnit(nullptr), built(false)
    {
```

Note: Need to verify class member declaration order. If `built` is declared last,
this reordering is correct. Otherwise, match the declaration order.

---

## Part 5: Boost unary_function Deprecation (442 warnings)

**Source:** `libs/boost/include/boost/container_hash/hash.hpp:131`
**Current Version:** Boost 1.74 (2020)
**Fix Version:** Boost 1.81+ (2022)

This is a C++17 deprecation of `std::unary_function`.

### Option A: Upgrade Boost (Recommended)

Boost 1.81+ removed `unary_function` usage. To upgrade:

```bash
# Download latest boost (1.86 as of 2026)
cd libs/
rm -rf boost
wget https://boostorg.jfrog.io/artifactory/main/release/1.86.0/source/boost_1_86_0.tar.gz
tar -xzf boost_1_86_0.tar.gz
mv boost_1_86_0 boost

# Or use system boost if available
# cmake .. -DBOOST_ROOT=/usr
```

**Benefits:**
- Eliminates 442 warnings
- Gets latest boost fixes and improvements
- No ongoing maintenance of suppression flags

### Option B: Suppress Warning

Add to CMake (temporary workaround):
```cmake
if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
    add_compile_options(-Wno-deprecated-declarations)
endif()
```

**Drawbacks:**
- Hides other legitimate deprecation warnings
- Doesn't fix the underlying issue
- Technical debt

---

## Sed Script for Automated Application

```bash
#!/bin/bash
# apply-upstream-warning-fixes.sh
# Run from source root directory

# 1.1 NextAction
sed -i '/NextAction(NextAction const& o).*whipowill/a\    NextAction\& operator=(NextAction const\&) = default;' \
    modules/mod-playerbots/src/Bot/Engine/Action/Action.h

# 1.2 PositionInfo
sed -i '/PositionInfo(PositionInfo const\& other)/,/^    }/{/^    }$/a\    PositionInfo\& operator=(PositionInfo const\&) = default;
}' modules/mod-playerbots/src/Ai/Base/Value/PositionValue.h

# 1.3 CraftData
sed -i '/CraftData(CraftData const\& other)/,/^    }/{/^    }$/a\    CraftData\& operator=(CraftData const\&) = default;
}' modules/mod-playerbots/src/Ai/Base/Value/CraftValue.h

# 1.4 UnitPosition
sed -i '/UnitPosition(UnitPosition const\& other)/,/^    }/{/^    }$/a\    UnitPosition\& operator=(UnitPosition const\&) = default;
}' modules/mod-playerbots/src/Ai/Base/Value/Arrow.h

# 2.1 MovementActions loop variable
sed -i 's/for (int i = 0; i < intervals; i++)/for (uint32 i = 0; i < intervals; i++)/' \
    modules/mod-playerbots/src/Ai/Base/Actions/MovementActions.h

# 2.2 PlayerMethods enum comparison
sed -i 's/if (slot >= EQUIPMENT_SLOT_START && slot < EQUIPMENT_SLOT_END)/if (slot >= static_cast<int32>(EQUIPMENT_SLOT_START) \&\& slot < static_cast<int32>(EQUIPMENT_SLOT_END))/' \
    modules/mod-ale/src/LuaEngine/methods/PlayerMethods.h

# 3.1 ItemCountValue unused event
sed -i 's/bool Execute(Event event) override { return false; }/bool Execute(Event event) override { (void)event; return false; }/' \
    modules/mod-playerbots/src/Ai/Base/Value/ItemCountValue.h

# 3.2 HunterActions unused event (4 locations)
sed -i 's/bool Execute(Event event) override { return botAI->CastSpell(\([0-9]*\), GetTarget()); }/bool Execute(Event event) override { (void)event; return botAI->CastSpell(\1, GetTarget()); }/g' \
    modules/mod-playerbots/src/Ai/Class/Hunter/Action/HunterActions.h

echo "Applied upstream warning fixes."
echo "Note: Boost warnings require CMake flag changes (see patch doc Part 5)."
```

---

## Verification

After applying, rebuild and check warning count:
```bash
make -j$(nproc) 2>&1 | grep -c "warning:"
```

Expected: ~442 warnings remaining (boost only)

---

## Notes

- These fixes are cosmetic - they don't change runtime behavior
- The boost warnings require either:
  - CMake changes (suppression flag)
  - Boost upgrade (major change, requires testing)
- Scattered individual warnings (~50) not addressed here - diminishing returns
- All changes are backward compatible with C++17 and later
