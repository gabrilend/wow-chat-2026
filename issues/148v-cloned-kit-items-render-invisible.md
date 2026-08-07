# 148v - Cloned Kit Items Render Invisible With a "?" Icon on First Login

## Status
- Created: 2026-08-07
- Phase: 1 (Foundation — vanilla profile kit)
- Parent: 148 (vanilla profile)
- Predecessor: 148h (the clone-to-new-ID kit design this reverses),
  148k (the first-login auto-equip hook that installs the kit)
- Sibling: 148o (the validation pass this was found during)
- Priority: High — it is the first thing a new player sees. A
  level-20 character that renders naked, holding nothing, with red
  question-mark icons in every equipment slot, reads as a broken
  server before the player has taken a step.
- **Resolution decided 2026-08-07:** abandon the clones, edit the
  original item entries in place. See "The Decision" below.

## Source Report (verbatim, 2026-07-22)

> I noticed after creating a mage character and logging in that
> their equipment didn't show up on their character model and had a ? icon.
> We should be more careful about how we implement that.
> I unequipped the items, then re-equipped them, and they properly rendered on
> the character model.
>
> I'm assuming we're creating new items that inherit from the previous items
> somehow? Not idea. We might be unable to change item characteristics. Please
> confirm, and if so, then we should not copy items but instead just modify them
> in place, which is guaranteed to work but is a bit more messy.
>
> I noticed that warrior and paladin characters did not log in with invisible
> equipment. For some reason, their gear properly rendered immediately.

## Confirmation of the Premise

**Yes — we are creating new items that inherit from the previous
items.** 148h's "Item Cloning Procedure" is exactly that. For each kit
item, a new `item_template` row is INSERTed as a copy of the original
with the entry ID computed as `original_entry + 2000000` (Polished
Scale Vest 2153 → 2002153, and so on). The clone is retuned to
`RequiredLevel = 20` with normalized weapon damage, and every
loot/vendor/quest reference in `acore_world_vanilla` is rewritten to
point at the clone.

## Measured 2026-08-07: the Clone Data Is Not the Problem

Run against the live `acore_world_vanilla`:

| Check | Result |
|---|---|
| Total cloned entries (`entry >= 2000000`) | 51 |
| Clones with `displayid = 0` | **0** |
| Clones whose `displayid` differs from their original | **none** |

Every clone carries its original's model. The clone INSERT is correct
and complete. So this is not a dropped column and not a regeneration
problem — the kit SQL is doing exactly what 148h specified.

The failure is on the client side, in how item data reaches it.

## Why It Fails: the Client Is Never Told

The 3.3.5a client keeps item metadata in a local cache,
`WDB/itemcache.wdb`. An entry the client has never seen has no cache
row, so the client has no `displayid` — nothing to hang a model on —
and draws the red "?" placeholder.

The clones live at `original + 2000000`. **No client has ever seen
them.** Every one of the 51 kit entries is cold on every fresh install.

The part that makes this unfixable from our side: **the client only
requests item data when an event prompts it to.** It is not a
background fetch that eventually catches up. Nothing about the
server-side first-login hook silently equipping gear constitutes such
an event, so no query fires, and the paperdoll renders from a cache
that has no rows. The player's manual unequip-and-re-equip *is* the
event — that is why the workaround worked, and why it had to be done by
hand.

This also explains the warrior/paladin observation exactly. Those
characters were rolled on the same client after other rerolls had
already caused their kit entries to be fetched. Their cache was warm.
The mage's was not.

## The Decision: Go Back to the Original IDs

**User direction, 2026-08-07.** Revert to modifying the original item
entries in place. The clones go away.

The reason is that there is no server-side fix. We cannot make the
client fetch data it has not been prompted to fetch, and every
workaround is a variation on "trick the client into generating an
event" — a delayed re-equip, a forced inventory shuffle — which is
timing-dependent, invisible when it fails, and leaves the first
impression of the server riding on a race. Using entries every client
already has cached from retail data is the only approach that is
correct by construction.

### Why the original objection no longer holds

148h moved to clones because in-place editing "leaked": lowering
`item_template.RequiredLevel` on the canonical Polished Scale Vest
changed that item for every creature drop, vendor, quest reward, and
auction listing in the world.

That objection is worth re-reading against what 148h actually built,
because **the clone design did not prevent the leak.** 148h's "Loot
Table Update Procedure" rewrites `creature_loot_template`,
`gameobject_loot_template`, `reference_loot_template`, `npc_vendor`,
`quest_template` rewards, and eight other tables in
`acore_world_vanilla` so they all point at the clones. A Battle Axe
dropped by a Stonetalon centaur in the vanilla world is already the
retuned 15-DPS RL=20 version. The retuning applies world-wide either
way. The clone bought a different entry number for the same outcome —
and that number is precisely what the client cannot render.

And the blast radius is bounded regardless: vanilla reads its own
`acore_world_vanilla` database. Release and beta read different world
databases and are untouched by either approach.

So in-place is not a regression against clones on the leak axis. It is
the same world-wide retune with an entry the client can draw.

## Current Behavior

- Rolling a fresh mage on the vanilla profile produces a character
  whose equipped kit does not appear on the character model. Every
  affected slot shows a red "?" icon in the paperdoll.
- Unequipping and re-equipping each item makes it render correctly
  and permanently.
- Warriors and paladins rolled on the same client did not show the
  symptom, because their kit entries had already been cached.
- `scripts/validate-vanilla-starter-state` does not catch this — it
  validates the database side, and the defect lives entirely in what
  reaches the client.

## Intended Behavior

A character created on the vanilla profile appears on the
character-select screen and at first login wearing its full kit,
rendered on the model, with correct icons — on a cold client cache,
with no unequip/re-equip, and with no dependence on a timing window.

## Suggested Implementation Steps

This reverses a shipped migration, so the order matters — the world
references have to come home before the clones can be dropped.

1. **Restore world references to the originals.** Reverse 148h's Loot
   Table Update Procedure across all thirteen tables: for every row
   pointing at an entry `>= 2000000`, set it back to `entry - 2000000`.
   This is mechanical and should be generated, not hand-written.
2. **Point the kit at the originals.** `UPDATE playercreateinfo_item
   SET itemid = itemid - 2000000` for every row with
   `Note LIKE 'vanilla-148h-%'` and `itemid >= 2000000`.
3. **Apply the tuning to the originals in place.** Set
   `RequiredLevel = 20` and the normalized `dmg_min1`/`dmg_max1` values
   from 148h's weapon table, plus the stat fields (Amani Sacrificial
   Dagger's +1 Spell Power and so on), on the original entries.
4. **Drop the 51 clones.** `DELETE FROM item_template WHERE entry >=
   2000000`. Only after steps 1 and 2 confirm nothing references them —
   a leftover reference to a deleted entry is worse than the bug being
   fixed here.
5. **Update the generator.** `scripts/generate-vanilla-starting-equipment-sql`
   emits the clone SQL today. It has to emit in-place UPDATEs instead,
   or the next regeneration undoes all of the above.
6. **Make the tuning reversible.** In-place edits to canonical entries
   have no natural undo, which is the real cost being accepted here.
   The apply SQL should record each touched entry's original
   `RequiredLevel` and damage values so an unapply can restore them —
   the same discipline the `patches/` system uses. 148h notes that
   E018's unapply was "a soft revert to a guessed floor value and known
   imperfect"; that is the mistake not to repeat.
7. **Verify on a cold cache.** Delete `WDB/itemcache.wdb`, roll one
   character per armor class (cloth, leather, mail, plate), and confirm
   the kit renders on the model at first login with no manual
   intervention.
8. Add a row to 148o's per-character checklist for "kit renders on the
   model," since this is the check that catches regressions here and it
   needs human eyes.

## Cross-References

- `issues/148h-class-specific-starting-equipment.md` — the clone
  procedure being reversed, the entry-ID convention table, and the
  weapon normalization values that in-place editing now applies
  directly. Its Item Cloning Procedure section needs the reversal
  recorded.
- `issues/148k-ale-auto-equip-starter-kit.md` — the first-login hook.
  Unaffected by the entry change; it resolves slots from each item's
  own `InventoryType`, so it follows the kit wherever it points.
- `issues/148o-vanilla-spawn-and-kit-validation-pass.md` — the
  validation pass this was found during.
- `scripts/generate-vanilla-starting-equipment-sql` — the generator
  that has to stop emitting clones.
- `src/lua-vanilla/auto-equip-starter-kit.lua` — the hook's source.

## Open Questions

- **Does the character-select screen behave the same way?** 148k treats
  "kit visible on the select screen" as its acceptance criterion. The
  select screen renders through a different path than the in-world
  model. Worth observing during the cold-cache verification, since it
  may have been failing for the same reason all along.
- **What about the playerbots?** 148s wants bots starting in the 148h
  kit. A bot's appearance renders on *other players'* clients, each with
  its own cache. Original entries fix this for bots too — which is an
  argument for the decision that had not been noticed when it was made.
- **How much of the vanilla world is now retuned?** With in-place
  editing, every drop, vendor listing, and quest reward of the 46 kit
  items across `acore_world_vanilla` carries level-20 tuning. That was
  already true under clones, but it is now visible in the canonical
  entries where someone reading the database will actually notice it.
  Worth a deliberate look at whether the tuned values are right for
  the whole world and not just for a starting kit.
