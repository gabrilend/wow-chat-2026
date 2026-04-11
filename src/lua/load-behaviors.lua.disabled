-- {{{ Everland Ghostsong - Behavior Loader
-- ALE auto-loads ALL .lua files from subdirectories (including behaviors/).
-- This file is now just a marker that confirms behaviors loaded correctly.
--
-- Issue: 134-ale-behavior-scripts-not-loading
-- Issue: 332 - Removed require() calls that caused double-loading
-- Concept Catalog: 001-010
-- }}}

-- Register in package.loaded so require() is a no-op after ALE loads this
package.loaded["load-behaviors"] = true

-- ALE loads scripts alphabetically within each directory.
-- By the time this file runs, behaviors/ scripts have already executed.
-- We just verify the Behaviors global exists.

if Behaviors and Behaviors.loaded then
    local count = 0
    for _ in pairs(Behaviors.loaded) do count = count + 1 end
    print("[LoadBehaviors] Behavior system verified - " .. count .. " behaviors registered")
else
    print("[LoadBehaviors] WARNING: Behaviors table not found - check behavior scripts for errors")
end
-- }}}
