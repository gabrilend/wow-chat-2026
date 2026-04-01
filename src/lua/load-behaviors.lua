-- {{{ Everland Ghostsong - Behavior Loader
-- This script is loaded by ALE and initializes all behavior systems
-- ALE auto-loads .lua files from the root script directory
-- Subdirectories require explicit loading
--
-- Issue: 134-ale-behavior-scripts-not-loading
-- Concept Catalog: 001-010
-- }}}

print("[LoadBehaviors] Starting behavior system initialization...")

-- {{{ Setup require paths
-- Add behaviors directory to package path
local script_path = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
if script_path then
    package.path = script_path .. "?.lua;" ..
                   script_path .. "behaviors/?.lua;" ..
                   package.path
end
-- }}}

-- {{{ Load behavior system
local success, err = pcall(function()
    require("behaviors/init")
end)

if not success then
    print("[LoadBehaviors] ERROR: Failed to load behaviors: " .. tostring(err))
else
    print("[LoadBehaviors] Behavior system loaded successfully")
end
-- }}}
