--------------------------------------------------------------------------------
-- group-hearth.lua (basic) - runs beta's group hearthstone, in place (issue 211)
--
-- For a general audience: when someone in a group starts their
-- hearthstone, the other players are asked whether to come along; saying
-- yes starts their own hearthstone, which brings them to a circle round
-- where the first one lands. Beta has had it since 2026-10-17
-- (src/lua-beta/hearthstone.lua, checked offline by scripts/test-hearthstone);
-- basic runs that very file rather than a copy, so the two never drift
-- apart, the way cc-test runs basic's talent script.
--
-- How it finds it: install step E001 links this folder into the server's
-- lua_scripts as custom/. A path through that link and then ".." climbs from
-- the link's target (this folder, src/lua-basic/), so
-- "<this folder>/../lua-beta/hearthstone.lua" is beta's file however the
-- link is named.
--
-- Basic's one difference: buddies are left out of the invitation (neither
-- asked nor brought). The owner, 2026-10-23: "Only your buddy-bots, not
-- buddy-bots from another player that's in your group. Think about it -
-- buddy-bots have the same hearthstone as you"; the hearther's own buddies
-- come by buddy-hearth.lua (round where the hearther arrives), another
-- player's stay with that player.
--------------------------------------------------------------------------------

local src  = debug.getinfo(1, "S").source
local here = (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
local file = here .. "../lua-beta/hearthstone.lua"
local ok, err = pcall(dofile, file)
if not ok then
    print("[group-hearth] ERROR: basic could not run beta's group hearthstone (" .. file .. "): " .. tostring(err)
        .. "; nobody is invited along on a hearthstone")
else
    -- {{{ GroupHearth.skip (basic)
    -- A buddy (a character on the roster) is left out; see the header.
    function GroupHearth.skip(member, hearther)
        return CharDBQuery("SELECT 1 FROM buddy_roster WHERE buddy = " .. member:GetGUIDLow()) ~= nil
    end
    -- }}}
end
