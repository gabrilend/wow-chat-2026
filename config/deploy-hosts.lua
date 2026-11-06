--------------------------------------------------------------------------------
-- deploy-hosts.lua - which machine does each of the server's jobs (issue 157a)
--
-- For a general audience: the game runs as three jobs ("roles"): the
-- database, the login server (auth) and the world server. Today all three
-- run on the development machine itself, written here as "local". When a
-- role moves to a machine of its own on the home network, its line becomes
-- a table describing that machine:
--
--   world = {
--       lan_address = "192.168.1.20",       -- dotted IPv4 on the home network
--       ssh_user    = "wow",                -- the account the deploy tool logs in as
--       install_dir = "/srv/wow-chat-2026", -- where the project lives there
--       arch        = "x86_64",             -- checked against the build machine
--   },
--
-- Two roles may share a machine (the same address); they must then agree
-- on its architecture. Nothing else reads this file directly: bash scripts
-- ask `scripts/deploy-host <role> <field>`, which checks the file first
-- (`scripts/deploy-host --check` checks it alone). The rules are in
-- scripts/lib/deploy-hosts.lua.
--
-- The machines' addresses and users are the owner's to fill in (157a's
-- open question); until then every role is "local".
--------------------------------------------------------------------------------

return {
    database = "local",
    auth     = "local",
    world    = "local",
}
