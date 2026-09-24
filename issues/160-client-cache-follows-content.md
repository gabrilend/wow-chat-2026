# 160 - The Client's Cache Follows the Server's Content

## Status
- Created: 2026-09-23
- Phase: 1 (Foundation & Tooling)
- Priority: High — every world-database edit this project makes is
  invisible to players with a warm cache until this lands
- Implemented 2026-09-23 as config patch C025; waiting on the owner's
  install run and one in-client check (step 3)

## Origin

Verbatim, 2026-09-23, on hearing that an item's required level is
server-side but the client caches its tooltip:

> big, if true. Can you give me a list of similar information that is stored
> on the server? I think I remember there was a way for the server to force a
> cache reset on users connecting to the server for the first time, is that
> true?

It is true. At login the server sends a single number, the client cache
version (`WorldSession::SendClientCacheVersion`, opcode
`SMSG_CLIENTCACHE_VERSION`). A client whose stored number differs wipes its
`Cache/WDB` files and asks the server again for everything.

## Current Behavior

`ClientCacheVersion = 0` in every profile's `worldserver.conf`, which means
"use the world database's `version.cache_id`". That value changes only with
upstream database releases. None of this project's edits (quest masks,
flight master lines, trainers, creature levels) change it, so a player who
has seen the stock data keeps seeing it. And all profiles share one client
and one cache, so switching realms carries one profile's cached data into
another's.

**Built:** config patch C025 (`config/patches/C025-client-cache-version.sh`,
gated `all`) writes `ClientCacheVersion` as a fingerprint. The fingerprint
is the CRC-32 of the profile name, the source tree's commit, and every file
under `sql/<profile>/*.src/`, following links. It changes exactly when the
profile's database edits or the upstream commit change, and differs between
profiles. `scripts/test-profile-config-gates` checks that it comes out as a
non-zero 32-bit number (basic: passes).

## Intended Behavior

A player never sees stale data from this project's edits: the first login
after an install that changed cached content resets the client's cache
automatically.

### What lives where (3.3.5a)

**Server only: live, no cache, changes take effect at once**
- loot tables and drop chances; vendor stock and prices; trainer lists and
  costs; gossip menus and their options
- creature level, health, damage, faction, flags (sent as live unit fields)
- spawns, movement, AI and scripts; quest *logic* (requirements, credit)
- item rules enforced on use or equip: required level, class and race
  allowances, stats applied to the character
- experience and reputation rates; everything in `worldserver.conf`

**Server data the client caches (`Cache/WDB`; C025 is what refreshes it)**
- items (`itemcache.wdb`): tooltip text and numbers — name, quality, stats
  shown, required level, sell price, bonding, description, "Use:" spells
- creatures (`creaturecache.wdb`): name, subname, type, rank (elite dragon),
  family, the models shown in the tooltip portrait, quest-item list
- game objects (`gameobjectcache.wdb`): name, type, display, data fields
- quests (`questcache.wdb`): titles, texts, objectives, rewards shown
- NPC dialogue text (`npccache.wdb`), book pages (`pagetextcache.wdb`),
  item text, character and pet names

**Client data files only (MPQ; changing them needs a client patch)**
- spells (`Spell.dbc`): power type and cost, cast time, range, icon,
  tooltip. The client pre-checks power before casting, so re-costing a
  spell server-side is not enough (see 710)
- talents and talent trees (`Talent.dbc`, `TalentTab.dbc`)
- item appearance and slot (`Item.dbc`, `ItemDisplayInfo.dbc`): why an item
  id the client has no row for can render invisible (148v)
- character creation: which race/class pairs the screen offers
  (`CharBaseInfo.dbc`) and the preview outfits (`CharStartOutfit.dbc`)
- maps, zones, flight-path map, factions, skill lines, achievements

The server keeps its own copies of the client's data files, plus override
tables (for example `spell_dbc`). A server-side change there alters what the
server does, not what the client shows.

## Suggested Implementation Steps

1. C025 (done).
2. Owner's install run: read back `ClientCacheVersion` in
   `installed-files-<profile>/etc/worldserver.conf`.
3. One in-client check: note a cached item tooltip, change that item's
   required level in the profile's SQL, reinstall, log in. The tooltip
   should show the new value without deleting `Cache/` by hand.

## Related Issues

- **148v** cloned kit items render invisible — client data vs cache;
  a cache reset does not help an id the client has no data-file row for
- **155** basic — its world edits are what makes this matter now
- **710** custom-class resources — the spell-cost pre-check lives in the
  client

## Open Questions

- None.
