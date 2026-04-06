-- Knight Custom Class Definition
-- A holy bodyguard who protects one ally at a time through shields and focused healing.
-- Base class: Paladin (2)
-- Definition ID: 1004
--
-- Core loop: Melee crit -> Art of War -> instant Flash -> (if crit) Surge of Light -> instant Smite
-- Healing: Flash of Light only (Desperate Prayer as emergency tank cooldown)
-- Damage: Smite (holy) + melee auto-attacks

local CustomClasses = CustomClasses or {}

-- {{{ Knight Definition
CustomClasses.definitions[1004] = {
    name = "Knight",
    baseClass = 2,  -- Paladin

    -- =========================================================================
    -- ABILITIES (Trainer-Learned)
    -- =========================================================================
    -- Visit NPC, pay gold to learn these spells
    -- Cost in copper: 100 = 1 silver, 10000 = 1 gold

    abilities = {
        -- Paladin (class 2)
        [3127]  = { level = 6,  cost = 1000 },   -- Parry
        [1152]  = { level = 6,  cost = 1000 },   -- Purify (poison + disease)
        [20217] = { level = 4,  cost = 500 },    -- Blessing of Kings
        [19750] = { level = 20, cost = 5000 },   -- Flash of Light (primary heal)
        [53601] = { level = 20, cost = 10000 },  -- Sacred Shield (core identity)

        -- Priest (class 5) - Smite
        [585]   = { level = 1,  cost = 100 },    -- Smite R1
        [591]   = { level = 6,  cost = 500 },    -- Smite R2
        [598]   = { level = 14, cost = 2000 },   -- Smite R3

        -- Priest (class 5) - Other
        [588]   = { level = 12, cost = 1500 },   -- Inner Fire R1
        [7128]  = { level = 20, cost = 5000 },   -- Inner Fire R2
        [14751] = { level = 16, cost = 3000 },   -- Inner Focus
        [19236] = { level = 10, cost = 1500 },   -- Desperate Prayer (tank cooldown)

        -- Mage (class 8)
        [1459]  = { level = 1,  cost = 100 },    -- Arcane Intellect R1
        [1460]  = { level = 14, cost = 2000 },   -- Arcane Intellect R2

        -- Death Knight (class 6)
        [57330] = { level = 6,  cost = 1000 },   -- Horn of Winter

        -- Rogue (class 4)
        [2983]  = { level = 10, cost = 1500 },   -- Sprint

        -- Warrior (class 1)
        [50720] = { level = 16, cost = 3000 },   -- Vigilance
        [694]   = { level = 14, cost = 2000 },   -- Mocking Blow
    },

    -- =========================================================================
    -- TALENTS (AIO Talent Interface)
    -- =========================================================================
    -- Spend talent points in custom AIO talent interface
    -- Players get 3 points per level = 60 points at level 20
    -- Total available: 97 points across 30 families (61.9% coverage)

    talents = {
        -- =====================================================================
        -- PROTECTION TREE (tree = 1) - 30 points, 10 families
        -- =====================================================================

        -- Tier 1: Deflection variants (16 points, 4 families)
        -- Rogue Deflection: +2/4/6% parry
        [13852] = { tree = 1, tier = 1 },  -- R1
        [13853] = { tree = 1, tier = 1 },  -- R2
        [13854] = { tree = 1, tier = 1 },  -- R3

        -- Warrior Deflection: +1/2/3/4/5% parry
        [16462] = { tree = 1, tier = 1 },  -- R1
        [16463] = { tree = 1, tier = 1 },  -- R2
        [16464] = { tree = 1, tier = 1 },  -- R3
        [16465] = { tree = 1, tier = 1 },  -- R4
        [16466] = { tree = 1, tier = 1 },  -- R5

        -- Paladin Deflection: +1/2/3/4/5% parry
        [20060] = { tree = 1, tier = 1 },  -- R1
        [20061] = { tree = 1, tier = 1 },  -- R2
        [20062] = { tree = 1, tier = 1 },  -- R3
        [20063] = { tree = 1, tier = 1 },  -- R4
        [20064] = { tree = 1, tier = 1 },  -- R5

        -- Hunter Deflection: +1/2/3% parry
        [19295] = { tree = 1, tier = 1 },  -- R1
        [19296] = { tree = 1, tier = 1 },  -- R2
        [19297] = { tree = 1, tier = 1 },  -- R3

        -- Tier 2: Spell defense (10 points, 4 families)
        -- Spell Deflection: Parry = 15/30/45% spell damage reduction
        [49145] = { tree = 1, tier = 2 },  -- R1
        [49496] = { tree = 1, tier = 2 },  -- R2
        [49497] = { tree = 1, tier = 2 },  -- R3

        -- Magic Absorption: +resist per level, mana on resist
        [29441] = { tree = 1, tier = 2 },  -- R1
        [29444] = { tree = 1, tier = 2 },  -- R2

        -- Eye for an Eye: Reflect 5/10% crit damage
        [9799]  = { tree = 1, tier = 2 },  -- R1
        [9800]  = { tree = 1, tier = 2 },  -- R2

        -- Acclimation: 10/20/30% resist stack on spell hit
        [50150] = { tree = 1, tier = 2 },  -- R1
        [50151] = { tree = 1, tier = 2 },  -- R2
        [50152] = { tree = 1, tier = 2 },  -- R3

        -- Tier 3: Defensive capstones (4 points, 2 families)
        -- Reckoning: Extra attacks after being hit
        [20177] = { tree = 1, tier = 3 },

        -- Ardent Defender: 7/13/20% damage reduction below 35% HP
        [31850] = { tree = 1, tier = 3 },  -- R1
        [31851] = { tree = 1, tier = 3 },  -- R2
        [31852] = { tree = 1, tier = 3 },  -- R3

        -- =====================================================================
        -- HOLY TREE (tree = 2) - 35 points, 10 families
        -- =====================================================================

        -- Tier 1: Int scaling (17 points, 4 families)
        -- Divine Intellect: +2/4/6/8/10% Int
        [20257] = { tree = 2, tier = 1 },  -- R1
        [20258] = { tree = 2, tier = 1 },  -- R2
        [20259] = { tree = 2, tier = 1 },  -- R3
        [20260] = { tree = 2, tier = 1 },  -- R4
        [20261] = { tree = 2, tier = 1 },  -- R5

        -- Spiritual Focus: 14-70% pushback reduction on heals
        [20205] = { tree = 2, tier = 1 },  -- R1
        [20206] = { tree = 2, tier = 1 },  -- R2
        [20207] = { tree = 2, tier = 1 },  -- R3
        [20208] = { tree = 2, tier = 1 },  -- R4
        [20209] = { tree = 2, tier = 1 },  -- R5

        -- Mental Strength: +3/6/9/12/15% Int
        [18551] = { tree = 2, tier = 1 },  -- R1
        [18552] = { tree = 2, tier = 1 },  -- R2
        [18553] = { tree = 2, tier = 1 },  -- R3
        [18554] = { tree = 2, tier = 1 },  -- R4
        [18555] = { tree = 2, tier = 1 },  -- R5

        -- Holy Reach: +10/20% Smite range
        [27789] = { tree = 2, tier = 1 },  -- R1
        [27790] = { tree = 2, tier = 1 },  -- R2

        -- Tier 2: Crit healing (10 points, 4 families)
        -- Divine Aegis: Crit heal = 10/20/30% absorb shield
        [47509] = { tree = 2, tier = 2 },  -- R1
        [47511] = { tree = 2, tier = 2 },  -- R2
        [47515] = { tree = 2, tier = 2 },  -- R3

        -- Blessed Resilience: +1/2/3% healing, crit immunity proc
        [33142] = { tree = 2, tier = 2 },  -- R1
        [33145] = { tree = 2, tier = 2 },  -- R2
        [33146] = { tree = 2, tier = 2 },  -- R3

        -- Nurturing Instinct: +50/100% Agi -> healing
        [33872] = { tree = 2, tier = 2 },  -- R1
        [33873] = { tree = 2, tier = 2 },  -- R2

        -- Surge of Light: 25/50% spell crit -> instant Smite/Flash (can't crit)
        [33150] = { tree = 2, tier = 2 },  -- R1
        [33154] = { tree = 2, tier = 2 },  -- R2

        -- Tier 3: Mana recovery & capstones (8 points, 3 families)
        -- Dreamstate: 4/7/10% Int as MP5
        [33597] = { tree = 2, tier = 3 },  -- R1
        [33599] = { tree = 2, tier = 3 },  -- R2
        [33956] = { tree = 2, tier = 3 },  -- R3

        -- Lunar Guidance: 4/8/12% Int -> Spell Power
        [33589] = { tree = 2, tier = 3 },  -- R1
        [33590] = { tree = 2, tier = 3 },  -- R2
        [33591] = { tree = 2, tier = 3 },  -- R3

        -- Art of War: Melee crit -> instant Flash of Light
        [53486] = { tree = 2, tier = 3 },  -- R1
        [59578] = { tree = 2, tier = 3 },  -- R2

        -- =====================================================================
        -- COMBAT TREE (tree = 3) - 32 points, 10 families
        -- =====================================================================

        -- Tier 1: Stat scaling (13 points, 4 families)
        -- Hunter Lightning Reflexes: +3/6/9/12/15% Agi
        [19168] = { tree = 3, tier = 1 },  -- R1
        [19180] = { tree = 3, tier = 1 },  -- R2
        [24294] = { tree = 3, tier = 1 },  -- R3
        [24296] = { tree = 3, tier = 1 },  -- R4
        [24297] = { tree = 3, tier = 1 },  -- R5

        -- Rogue Lightning Reflexes: +2/4/6% dodge, +4/7/10% melee haste
        [13787] = { tree = 3, tier = 1 },  -- R1
        [13788] = { tree = 3, tier = 1 },  -- R2
        [13789] = { tree = 3, tier = 1 },  -- R3

        -- Combat Experience: +2/4% Agi and Int
        [34475] = { tree = 3, tier = 1 },  -- R1
        [34476] = { tree = 3, tier = 1 },  -- R2

        -- Focused Will: +3% spell crit, damage reduction on crit taken
        [45234] = { tree = 3, tier = 1 },  -- R1
        [45243] = { tree = 3, tier = 1 },  -- R2
        [45244] = { tree = 3, tier = 1 },  -- R3

        -- Tier 2: Attack speed (15 points, 4 families)
        -- Warrior Flurry: +5/10/15/20/25% attack speed for 3 swings after crit
        [12319] = { tree = 3, tier = 2 },  -- R1
        [12967] = { tree = 3, tier = 2 },  -- R2
        [12968] = { tree = 3, tier = 2 },  -- R3
        [12969] = { tree = 3, tier = 2 },  -- R4
        [12974] = { tree = 3, tier = 2 },  -- R5

        -- Shaman Flurry: +10/15/20/25/30% attack speed for 3 swings after crit
        [16256] = { tree = 3, tier = 2 },  -- R1
        [16281] = { tree = 3, tier = 2 },  -- R2
        [16282] = { tree = 3, tier = 2 },  -- R3
        [16283] = { tree = 3, tier = 2 },  -- R4
        [16284] = { tree = 3, tier = 2 },  -- R5

        -- Surefooted: -10/20/30% slow duration
        [19290] = { tree = 3, tier = 2 },  -- R1
        [19294] = { tree = 3, tier = 2 },  -- R2
        [24283] = { tree = 3, tier = 2 },  -- R3

        -- Pure of Heart: -15/30% curse/disease/poison duration
        [31822] = { tree = 3, tier = 2 },  -- R1
        [31823] = { tree = 3, tier = 2 },  -- R2

        -- Tier 3: Proc abilities (4 points, 2 families)
        -- Sheath of Light: 30% AP -> SP, crit heals add HoT
        [53501] = { tree = 3, tier = 3 },  -- R1
        [53502] = { tree = 3, tier = 3 },  -- R2
        [53503] = { tree = 3, tier = 3 },  -- R3

        -- Counterattack: Parry -> damage + 5s root
        [19306] = { tree = 3, tier = 3 },
    },

    -- =========================================================================
    -- METADATA
    -- =========================================================================

    treeNames = {
        [1] = "Protection",
        [2] = "Holy",
        [3] = "Combat",
    },

    -- Glyphs always active for this class (no inscription needed)
    permanentGlyphs = {
        [63326] = true,  -- Glyph of Vigilance (threat transfer)
    },

    -- Classes that drop tomes for this custom class
    tomeClasses = { 2, 5, 4, 6, 1, 8, 3, 11, 7 },
    -- Paladin, Priest, Rogue, DK, Warrior, Mage, Hunter, Druid, Shaman
} -- }}}

return CustomClasses
