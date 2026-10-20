# 193 - Beta's Two Factions Trade, Mail, See and Befriend Each Other

## Status
- Created: 2026-10-20
- Phase: 2 (The Empty World: getting around it together)
- Related: `docs/wow-chat-1-settings.md` (wow-chat-1's settings, where this
  was found), C037 (beta's other cross-faction settings), 718a (death
  knights who change sides: they don't need this, see below)
- Priority: Medium
- State: built and tested offline; not yet installed on beta

## Origin

wow-chat-1 let the factions trade, mail, see each other in `/who` and add
each other as friends, by five settings today's server no longer has. Told
they are now permissions in the accounts database, the owner, 2026-10-20:

> yes, make sure it's one for each of cross-faction trade, mail, /who, and
> friends. though, I thought you said they were account database
> permissions? So, it'd be an authserver patch. Do we have a patch section
> for those? Also, for beta can we turn them on for everyone via sql or
> something, and keep them isolated to the servers that have them enabled
> for everyone? If a player somehow (death knights I think) can be
> friendly to both factions (we had a plan with deathknights where they
> could join the other faction, can you find that and give me a report on
> it?) they'll need that applied to... hang on, their account? That seems
> wrong if it's a per-character thing.

## Current Behavior

Built 2026-10-20, not yet installed. Four install steps, E062 trade, E063
mail, E064 `/who`, E065 friends, each with its own pair of SQL files in
`sql/beta/db_auth.src/` (apply and revert), written by
`scripts/generate-beta-two-side-sql` (beta's realm number read from C019,
each permission's number checked against the server's `RBAC.h`). Each
apply adds four rows to `acore_auth.rbac_default_permissions`: the
permission for account levels 0 to 3 (player, moderator, game master,
administrator) on realm 2, beta's; each revert removes that permission's
rows for realm 2. The steps share `_beta_two_side_step` in
`patches/E-patches.sh` and are on beta's list in `patches/patches.sh`.
`scripts/test-beta-two-side-permissions` (9 checks, a quick test of the
compile) checks the files against the generator and C019, runs the steps,
and applies and reverts the SQL on a scratch copy of the table.

Before this, every realm kept the factions apart in these four ways.

## Intended Behavior

- On beta, every account's characters can trade, mail, see in `/who` and
  add as friends the players of the other faction. Nowhere else changes.
- Each of the four is its own install step, so any one can be turned off
  (its revert) without the others.

**Not an authserver patch.** The authserver logs accounts in; it never
reads these permissions. The world server reads them from the accounts
database at start (with each account's level and the realm it serves) and
checks them when a player trades, mails, looks up `/who` or adds a friend
(`TradeHandler.cpp`, `MailHandler.cpp`, `MiscHandler.cpp`,
`CharacterHandler.cpp`). The steps are ordinary install steps writing SQL,
the same idiom as every other: the world server's database updater
already applies updates to the accounts database (`Updates.EnableDatabases
= 7`), so the folder is registered there. This is the first install step
to write to the accounts database. Because that database is shared by
every realm, it is registered by its own name (`acore_auth`, never a
per-profile name); every realm's server applies the same rows, and the
realm number in them keeps them beta's.

**"Everyone, isolated to the servers that have it": the default
permissions table.** It grants a permission to every account of a level,
on one realm or all (`realmId`, -1 for all). Rows for each level on realm
2 are "everyone on beta" and nothing else.

**Per account, not per character.** Permissions belong to accounts (per
realm), never to characters: the game has no per-character permission.
For beta that doesn't matter, since every account has them there. For a
single character on another realm to cross the factions, the permission
route can't do it; that would be a source patch to the faction checks.

**Death knights who change sides don't need it (issue 718a).** The plan:
a death knight who finishes its story may swear to the Horde, the Alliance
or Acherus. Sworn to the faction that isn't its race's, it keeps its race
but fights for its new side, shown "orange" (unfriendly) to its new
faction-mates, "a double turncoat" whom nobody trusts, with no change in
how they act together: it groups, trades and fights beside them as a
faction-mate. Its buddies are of its sworn faction, any race; it must wear
its new master's tabard (a Val'kyr raises it, once an hour, if it takes it
off with no spare). It is on one side at a time, not both, so trading and
mailing its new side are same-faction actions. Still open there: how the
"orange" is shown, which tabards count, whether the oath can change, and
the Val'kyr's hour.

## Suggested Implementation Steps

1. `scripts/generate-beta-two-side-sql`: the four permissions, beta's realm
   from C019, numbers checked against `RBAC.h`.
2. `_beta_two_side_step` and E062-E065 in `patches/E-patches.sh`; beta's
   list in `patches/patches.sh`.
3. `scripts/test-beta-two-side-permissions`, in the compile's quick tests.
4. In game, on beta: two players of opposite factions trade, mail, find
   each other in `/who` and add each other as friends.

## Open Questions

None. (The per-character case is answered above: not possible as a
permission; a source patch if it is ever wanted.)
