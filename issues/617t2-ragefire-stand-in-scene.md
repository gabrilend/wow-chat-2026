# 617t2 - Trying the Stand-ins at Ragefire Chasm

## Status
- Created: 2026-10-12
- Phase: 6
- Parent: 617t (dungeon stand-ins)
- Blocked by: 617t1 (the stand-in maker: written, not yet built into a
  server), 185 (the level-up command)
- Related: 176a (test scenes: this is a hand-run one, in the basic
  profile), 617a4 (the kit's white gear), 617z (tank-paced pulls: tried
  here once written)
- Priority: High (the first time stand-ins meet a player)
- State: planned; open questions first

## Origin

Verbatim, 2026-10-12:

> can we test the stand-in system by levelling birth to the right level
> and putting her in front of Ragefire Chasm with her buddy bots nearby,
> all equipped with white gear? She can be leatherworking.

Answer, 2026-10-12 (verbatim), on Birth's second buddy slot (opened at
level 10): fill it with a new buddy, or leave it for a stand-in?

> Sargobras. Until she's picked for the first time at that tier.

Read as: the slot is left for Birth to fill through Sargobras (who walks
beside an owner owed a buddy, from level 10); until she has picked her
buddy of that tier the first time, a stand-in takes the seat.

## Current Behavior

Nothing set up. Birth (basic profile, account RITZ) is a level-2 tauren
shaman, offline, with one buddy: Danaendu, a level-4 troll warrior. The
stand-in maker and its commands (`.buddy standin at`, `list`, `dismiss`)
are written but not built; its table (`buddy_stand_in`, install step
E056) is not in `acore_characters_basic` yet. Nothing brings stand-ins
into a dungeon's empty seats by itself yet (617t).

## Intended Behavior

One script sets the scene, run against the running basic server through
the game-master console (`scripts/gm-command`, which sends each command
to the server so nothing it holds in memory is overwritten):
- Birth raised to Ragefire's level, every spell her level allows taught,
  her talents spent;
- Birth a leatherworker (apprentice, skill raised to what her level
  allows);
- Birth and her buddies in white gear for their level (the existing
  white gearsets, `src/lua-basic/data/gearsets/buddy-white-<N>.lua`, put
  on by the `.gearset` console command; the level-raising, gear and
  professions done together by 185's level-up command);
- Birth's second slot (level 10) left unchosen: Sargobras comes to her,
  and a stand-in takes the seat until she picks;
- Birth placed just outside Ragefire Chasm's entrance in Orgrimmar's Cleft
  of Shadow (map 1, x 1813.5, y -4418.6, z -18.6: where the dungeon's exit
  puts a player, from `areatrigger_teleport` 2226), her buddies beside
  her;
- the seats her buddies don't fill taken by stand-ins
  (`.buddy standin at horde <role> <level> 1 <x> <y> <z>`), one tank and
  one healer first (617t's strict roles), then damage.

The script prints each step with what the server answered, and stops at
the first refusal, naming it.

## Suggested Implementation Steps

1. Answer the open questions.
2. Wait for the build with the stand-in maker in it, promoted and running.
3. `scripts/scene-ragefire-stand-ins`: the steps above as console
   commands, in order, each answer checked.
4. Run it; log in as Birth; walk in; watch.
5. Record what the stand-ins did right and wrong in 617t / 617t1.

## Open Questions

1. Which level: 15 (the middle of Ragefire's 13 to 18)?
2. (Answered 2026-10-12: left for Sargobras; a stand-in sits in until
   she picks.) Does the stand-in sitting in for an unpicked slot belong
   to 617t (the dungeon seats by themselves), or does the scene bring it
   in by command for now?
3. "test the stand-in system": the stand-ins brought in by the console
   command, as the scene's own step (possible once the build is in)? Or
   the dungeon seats filled by themselves on entering (617t's own
   behaviour, not written yet)?
4. Birth is a shaman, so she can heal. Is she the group's healer, so the
   stand-ins are a tank and damage?
5. Her leatherworking skill: just learned (1), or raised to what her
   level allows?
