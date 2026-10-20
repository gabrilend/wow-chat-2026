
CustomClasses = CustomClasses or {}
if not CustomClasses.definitions then
    CustomClasses.definitions = {}
    print("[custom-classes] Knight (1004) defined, but the custom-class framework is not running "
          .. "(custom-classes.lua is disabled): no selector, trainer or talent window offers it yet")
end

CustomClasses.definitions[1004] = {
    name = "Knight",
    baseClass = 2,


    abilities = {
        [3127]  = { level = 6,  cost = 1000 },
        [1152]  = { level = 6,  cost = 1000 },
        [20217] = { level = 4,  cost = 500 },
        [19750] = { level = 20, cost = 5000 },
        [53601] = { level = 20, cost = 10000 },

        [585]   = { level = 1,  cost = 100 },
        [591]   = { level = 6,  cost = 500 },
        [598]   = { level = 14, cost = 2000 },

        [588]   = { level = 12, cost = 1500 },
        [7128]  = { level = 20, cost = 5000 },
        [14751] = { level = 16, cost = 3000 },
        [19236] = { level = 10, cost = 1500 },

        [1459]  = { level = 1,  cost = 100 },
        [1460]  = { level = 14, cost = 2000 },

        [57330] = { level = 6,  cost = 1000 },

        [2983]  = { level = 10, cost = 1500 },

        [50720] = { level = 16, cost = 3000 },
        [694]   = { level = 14, cost = 2000 },
    },


    talents = {

        [13852] = { tree = 1, tier = 1 },
        [13853] = { tree = 1, tier = 1 },
        [13854] = { tree = 1, tier = 1 },

        [16462] = { tree = 1, tier = 1 },
        [16463] = { tree = 1, tier = 1 },
        [16464] = { tree = 1, tier = 1 },
        [16465] = { tree = 1, tier = 1 },
        [16466] = { tree = 1, tier = 1 },

        [20060] = { tree = 1, tier = 1 },
        [20061] = { tree = 1, tier = 1 },
        [20062] = { tree = 1, tier = 1 },
        [20063] = { tree = 1, tier = 1 },
        [20064] = { tree = 1, tier = 1 },

        [19295] = { tree = 1, tier = 1 },
        [19296] = { tree = 1, tier = 1 },
        [19297] = { tree = 1, tier = 1 },

        [49145] = { tree = 1, tier = 2 },
        [49496] = { tree = 1, tier = 2 },
        [49497] = { tree = 1, tier = 2 },

        [29441] = { tree = 1, tier = 2 },
        [29444] = { tree = 1, tier = 2 },

        [9799]  = { tree = 1, tier = 2 },
        [9800]  = { tree = 1, tier = 2 },

        [50150] = { tree = 1, tier = 2 },
        [50151] = { tree = 1, tier = 2 },
        [50152] = { tree = 1, tier = 2 },

        [20177] = { tree = 1, tier = 3 },

        [31850] = { tree = 1, tier = 3 },
        [31851] = { tree = 1, tier = 3 },
        [31852] = { tree = 1, tier = 3 },


        [20257] = { tree = 2, tier = 1 },
        [20258] = { tree = 2, tier = 1 },
        [20259] = { tree = 2, tier = 1 },
        [20260] = { tree = 2, tier = 1 },
        [20261] = { tree = 2, tier = 1 },

        [20205] = { tree = 2, tier = 1 },
        [20206] = { tree = 2, tier = 1 },
        [20207] = { tree = 2, tier = 1 },
        [20208] = { tree = 2, tier = 1 },
        [20209] = { tree = 2, tier = 1 },

        [18551] = { tree = 2, tier = 1 },
        [18552] = { tree = 2, tier = 1 },
        [18553] = { tree = 2, tier = 1 },
        [18554] = { tree = 2, tier = 1 },
        [18555] = { tree = 2, tier = 1 },

        [27789] = { tree = 2, tier = 1 },
        [27790] = { tree = 2, tier = 1 },

        [47509] = { tree = 2, tier = 2 },
        [47511] = { tree = 2, tier = 2 },
        [47515] = { tree = 2, tier = 2 },

        [33142] = { tree = 2, tier = 2 },
        [33145] = { tree = 2, tier = 2 },
        [33146] = { tree = 2, tier = 2 },

        [33872] = { tree = 2, tier = 2 },
        [33873] = { tree = 2, tier = 2 },

        [33150] = { tree = 2, tier = 2 },
        [33154] = { tree = 2, tier = 2 },

        [33597] = { tree = 2, tier = 3 },
        [33599] = { tree = 2, tier = 3 },
        [33956] = { tree = 2, tier = 3 },

        [33589] = { tree = 2, tier = 3 },
        [33590] = { tree = 2, tier = 3 },
        [33591] = { tree = 2, tier = 3 },

        [53486] = { tree = 2, tier = 3 },
        [59578] = { tree = 2, tier = 3 },


        [19168] = { tree = 3, tier = 1 },
        [19180] = { tree = 3, tier = 1 },
        [24294] = { tree = 3, tier = 1 },
        [24296] = { tree = 3, tier = 1 },
        [24297] = { tree = 3, tier = 1 },

        [13787] = { tree = 3, tier = 1 },
        [13788] = { tree = 3, tier = 1 },
        [13789] = { tree = 3, tier = 1 },

        [34475] = { tree = 3, tier = 1 },
        [34476] = { tree = 3, tier = 1 },

        [45234] = { tree = 3, tier = 1 },
        [45243] = { tree = 3, tier = 1 },
        [45244] = { tree = 3, tier = 1 },

        [12319] = { tree = 3, tier = 2 },
        [12967] = { tree = 3, tier = 2 },
        [12968] = { tree = 3, tier = 2 },
        [12969] = { tree = 3, tier = 2 },
        [12974] = { tree = 3, tier = 2 },

        [16256] = { tree = 3, tier = 2 },
        [16281] = { tree = 3, tier = 2 },
        [16282] = { tree = 3, tier = 2 },
        [16283] = { tree = 3, tier = 2 },
        [16284] = { tree = 3, tier = 2 },

        [19290] = { tree = 3, tier = 2 },
        [19294] = { tree = 3, tier = 2 },
        [24283] = { tree = 3, tier = 2 },

        [31822] = { tree = 3, tier = 2 },
        [31823] = { tree = 3, tier = 2 },

        [53501] = { tree = 3, tier = 3 },
        [53502] = { tree = 3, tier = 3 },
        [53503] = { tree = 3, tier = 3 },

        [19306] = { tree = 3, tier = 3 },
    },


    treeNames = {
        [1] = "Protection",
        [2] = "Holy",
        [3] = "Combat",
    },

    permanentGlyphs = {
        [63326] = true,
    },

    tomeClasses = { 2, 5, 4, 6, 1, 8, 3, 11, 7 },
}

return CustomClasses
