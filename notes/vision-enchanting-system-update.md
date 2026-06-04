# Enchanting System Update — Vision Document

*A vision for layered, level-scaling enchantments that turn item enhancement into a
long quiet conversation between the enchanter, the materials, and the gem.*

## Origin Conversation — 2026-05-12

### The Scene (User)

> "hello! you're so cute! I love your smile. You're so pretty, like a crystal glass gem!
> many of them, all around your rim! such a bright bold student, let's learn all in a din!"
>
> — elven jewelcrafter, speaking to a gemstone ring, enchanting it slowly over time,
> as she practiced her beloved craft in no less than her priority current activity.

The enchanter does not cast *over* the ring. She casts *into* it through attention.
Each compliment is a small charge of intent settling into the lattice. The gem learns
what it is by being told, repeatedly, fondly, while held.

So enchanting is not a single click. It is a series of layered applications, each one
small, each one specific, each one a verse in a longer song.

---

## Core Mechanic

An item receives **multiple enchantments** over its life. Each enchantment:

- Comes from a **spell** cast on the item, paired with **profession materials**.
- Adds **+1**, **+2**, or **+3** to the relevant stat / rating / effect.
- The numeric value **scales to the player's level** at time of application.
- Raises the item's **required level to equip** by some amount.

Apply enough enchantments and the item's required level climbs **above** the player's
current level. The item becomes unwearable until the player catches up. This is the
self-balancing mechanic. There is no cap on how many layers an item can hold — only the
arithmetic of "can I still wear this?"

The enchanter is therefore always negotiating: *how much do I want to overshoot? do I
hold a few layers in reserve for the next level milestone? do I gift this to a higher-
level friend? do I disenchant a half-finished project and start over?*

---

## Enchanter Skill = Material Tier

The enchanter's profession level does **not** determine the magnitude of the bonus
(player level does that). It determines **which materials can be used**.

- Low-tier enchanters can apply early-tier shards / essences / dusts.
- Higher-tier enchanters unlock more powerful materials.
- The most powerful materials (epic shards, prismatic essences) are gated behind the
  highest tiers and require disenchanting **epic** items to obtain.

Skill is a key, not a multiplier.

---

## The Application Cycle

Enchantments arrive in a fixed alternating pattern. Each slot in the cycle targets a
different *category* of bonus. The cycle loops, and each loop bumps the magnitude.

### One Full Loop (four slots)

| Slot | Category                | Notes                                                            |
|------|-------------------------|------------------------------------------------------------------|
|  1   | Stats — half A          | sta / spi / hp5 / mp5 (survival, regen, sustain).                |
|  2   | Stats — half B          | str / agi / int (offensive primaries — the "go" stats).          |
|  3   | Ratings                 | hit / crit / haste / exp / armor-pen / dodge / parry / block / resilience |
|  4   | Unique effect           | Only **one** per item, ever, at this tier.                       |

mp5 and hp5 sit in **half A** because they are stats, not ratings — flat-additive
resource flows that round out the defensive/sustain bundle.

**No AP / SP enchants.** Attack power and spell power are produced *through* the
primary stats (str/agi → AP, int → SP), so the system reaches them naturally without a
dedicated slot. This keeps the ratings slot focused on *percentages* — the kind of
numbers that round out a build rather than power its core.

### The Loops, In Sequence

```
loop 1   ->   +1 stats half-A
         ->   +1 stats half-B
         ->   +1 ratings
         ->   +1 unique effect   (tier-1 unique — moderate magic)

loop 2   ->   +2 stats half-A
         ->   +2 stats half-B
         ->   +2 ratings
         ->   +2 unique effect   (tier-2 unique — powerful magic, epic-disenchant gated)

loop 3   ->   +3 stats half-A
         ->   +3 stats half-B
         ->   +3 ratings
         ->   ( no tier-3 unique for now — possible future expansion )
```

The pattern is intentional rhythm: *broaden, broaden, sharpen, transform.* Then again,
louder. Each loop the bonuses get larger, but so does the required-level cost, so the
item becomes a heavier and heavier commitment.

---

## Stats vs Ratings

This distinction matters for the application cycle.

**Stats** — directly add to character attributes:

- strength, agility, stamina, intellect, spirit
- **mp5** (mana per 5 sec) and **hp5** (health per 5 sec) are stats, not ratings
- regen-style numbers behave like stats because they are flat-additive resource flows

**Ratings** — feed into derived combat percentages:

- hit, crit, haste, expertise
- armor penetration, resilience
- dodge, parry, block

**Excluded from enchantments entirely:**

- **Attack power**, **spell power**, **healing power** — they flow naturally out of
  the primary stats (str/agi → AP, int → SP, int → healing power) when those stats are
  enchanted.
- **Defense rating** — sits in the same bundle: a derived defensive number that's
  produced by other inputs (gear, talents, level) rather than worth a dedicated
  enchant slot.

The enchant pool is what *rounds out* a build, not what produces its raw output. Raw
output comes from primaries. Enchantments are how the wielder *attunes* the item to
themselves.

The split exists because stats and ratings scale differently with player level. Stats
stay readable at low levels. Ratings need a level-based conversion to feel meaningful.

### A Note on Resilience — Why It Stays

Resilience is, in vanilla 3.3.5a, a **PvP-only** stat. It reduces crit chance, crit
damage, periodic damage, and (since patch 3.2) all damage taken from other players.
Against monsters, it does nothing. In a roguelike-survival, PvE-dominant world like
Everland Ghostsong, resilience would be a dead stat — *except* that it has been
deliberately preserved as a load-bearing rating for the **medal encounters**
(`notes/vision-medal-encounters.md`).

Specifically, the Critslinger-and-Bleed-Companion pairing is **resilience-gated** —
it deals brutal player-style crits and stacking periodics, both of which resilience
mitigates. A team that wants to attempt the encounter needs at least one member
heavily layered with resilience, and the universality principle is what makes that
buildable: any ring, any cloak, any belt can carry resilience enchants regardless
of whether vanilla itemization would have allowed it.

So: **resilience earns its slot in the ratings pool because medal encounters need
it to be buildable.** Without the medal-encounter vision, resilience would have
joined AP/SP/healing-power/defense in the excluded set. With the medal-encounter
vision, it becomes a *signature* stat — marginal in the broad PvE flow, decisive
in one specific optional confrontation.

This is the design pattern the two visions establish together: **stats that would
otherwise be dead on a PvE server are kept alive by optional, telegraphed,
specialty encounters.** The same logic could later admit other otherwise-dead
stats back into the enchant pool, if a matching medal encounter is designed to
justify each one.

---

## Universality — Any Item, Any Rating

**Any item can receive any enchantment.** There are no slot-type restrictions —
armor penetration is not gated to weapons, block rating is not gated to shields,
expertise is not gated to gloves, resilience is not gated to chest pieces. A ring
can carry parry rating. A shield can carry haste rating. A cloak can carry
expertise.

This is the design principle that arrived during specification: *the point of magic
is that anyone can use it*. The magic is not in the geometry of the slot — the magic
is in the **attunement** between wielder and item. A slight attunement, and the item
can empower exactly these things about the person who wears it. The shape of the
piece is irrelevant; what matters is the conversation the enchanter had with it.

> "magic items! crafted on demand!"

The wielder decides what the item does for them. The enchanter is the conduit. The
item is the vessel. The slot is just where it hangs on the body.

This also keeps the system *simpler*. We don't have to maintain a table of which
ratings are legal on which inventory slots. The legality matrix is `any × any`.
The constraint is required-level, not slot-type.

---

## Unique Effects

Unique effects are the punctuation marks of the system. They are **not** stat bonuses —
they are *behaviors*. An item with a unique effect *does something* under specific
conditions.

### Tier-1 Unique (slot 4 of loop 1)

Moderate magic. Reachable by mid-tier enchanters with shards from rare-quality
disenchants. Examples (illustrative, not prescriptive):

- chance on hit: minor heal
- chance on cast: nearby friendly gets brief speed boost
- on critical strike: small reflective shimmer
- proximity aura: tiny mana regen for self

### Tier-2 Unique (slot 4 of loop 2)

Powerful magic. Gated behind **disenchanted epic** materials. The enchanter cannot
reach this tier without first finding, looting, or trading for an epic, then destroying
it. The cost is real and the choice is meaningful.

Examples (illustrative):

- on near-death: brief invulnerability shroud
- on critical strike: chain to a second target
- on spell hit: silence target for a moment
- persistent: small ambient ward against a specific damage school

### Only One Per Tier Per Item

An item can hold **at most one** tier-1 unique and **at most one** tier-2 unique. The
unique slot in each loop is a one-time decision per item. Choose wisely; the unique
effect is the *personality* of the piece.

---

## Cost Topology

Each enchantment costs:

1. **Materials** — appropriate to the tier of the bonus.
2. **Required-level inflation** — a permanent property of the item.
3. **A spell cast** — time, mana, reagent, profession proc rolls.

The third cost is small per application. The second cost compounds. The first cost is
what the enchanter *can* pay, given skill.

The result is that an item's biography becomes visible in its required level. A level-
20 cloak with a required level of 35 has been loved on, sung over, and saved for.

### Stacking and Recalculation

All enchants **stack**. An existing +5 strength on the item plus a fresh +2 strength
becomes +7 strength, not a replacement. The required-level cost of the new application
is added to whatever cost was already on the item, and the item's required-level
property is re-evaluated.

This means the item carries a *running total*, not a slot-list. Per-stat, per-rating,
per-unique, the item knows its current cumulative value. The enchant history can be
kept as a log for the UI (and for charming display), but mechanically what matters is
the totals.

### Power Curve Calibration

The total stat budget on a fully-enchanted item should land roughly where a vanilla
item of equivalent required-level would land — same power curve, just reached through
many small additions instead of one drop. We sample the existing item curve once
(scrape itemlevel → stat-budget for a representative spread) and cache the resulting
table. Each enchant application checks against this table to decide:

- how much **required-level** a +N to *this* stat should cost (i.e. how much of the
  level-band's stat budget that +N represents)
- whether **per-stat magnitudes** need to differ (a +2 to a cheap stat like spirit
  might cost less required-level than a +2 to a powerful one like strength)
- whether some stats should ship in different base magnitudes entirely (e.g. spell
  power, if we ever did include it, in larger steps than +1; a stat with a coarse curve
  contributes proportionally less per-point to the required-level math)

The curve is **a one-time calibration with periodic adjustment**. Recompute when
itemization changes; otherwise it sits in a small Lua table and is consulted at
application time.

---

## Why It Works This Way

**The alternation between stats / stats / ratings / unique** prevents a player from
stacking only the strongest single category. Every loop forces them to spread the love
across all four kinds of bonus before they can return to their favorite. This makes
items broadly competent rather than narrowly optimized.

**The loop-by-loop magnitude bump** means the early layers are cheap and quick (good
for levelling gear) while the later layers are expensive and slow (good for endgame
pieces). The same system serves both ends of the curve.

**The level-scaling values** mean an enchant applied at level 5 is not embarrassing at
level 20, but also not overwhelming at level 5. The numbers track the wearer.

**The required-level inflation** keeps the system self-correcting. There is no need
for an artificial cap. The cap *is* the wearer's level.

**The disenchanted-epic gate on tier-2 uniques** creates a natural economy: rare items
are not just better gear, they are *raw material* for personalizing other gear. The
endgame loops back into the crafting system.

---

## Resolved Choices

Settled in conversation, recorded here so we don't relitigate:

- **Stat partition.** Half A = sta / spi / hp5 / mp5 (survival + regen). Half B =
  str / agi / int (the "go" stats). Spirit and stamina cluster together with the
  regen pair; the offensive primaries cluster together.
- **Stacking.** All enchants stack. The item carries running totals per stat /
  rating / unique. Required-level inflates additively with each application.
- **No AP / SP / healing-power / defense enchants.** All four are produced through
  feeder stats or other inputs. Ratings slot is for percentages and defensive
  secondaries only.
- **Universality.** Any item can receive any enchantment. No slot-type gating.
  Magic empowers the wielder, not the geometry of the inventory slot.
- **Power curve calibration.** Required-level cost per +N is derived from the
  vanilla item stat-budget curve, sampled once and cached.

## Open Questions

Intentionally left for later:

- **Stat scaling at level-up.** When the player levels past the level at which the
  enchant was applied, does the bonus track them (recomputed on equip) or stay at the
  applied value (frozen on the item)?
- **Exact required-level cost** per +N, per stat. Comes out of the curve calibration.
- **Per-stat magnitude differences.** Some stats may need finer or coarser steps than
  +1 / +2 / +3 to stay on the curve. Determined once the curve is sampled.
- **Unique effect removability.** Replaceable? Truly permanent? Currently leaning
  permanent — the unique *is* the personality.
- **Visual representation.** Layered items glow, sing, hum? Probably yes — a level-20
  fully-loaded cloak should look unmistakably worked-on.
- **Interaction with the level-20 cap of Everland Ghostsong.** The cap may shape
  "loop 3" availability or change the required-level math entirely.
- **Roster of unique effects** for both tiers, finalized.

---

## Implementation Touchpoints

When this vision matures into issues:

- **Pre-baked enchant table per stat.** Each enchantable stat / rating gets a dense
  array of entries from +1 through some sensible ceiling (probably 256, plenty of
  headroom for layered application). The "apply +2 strength" operation indexes into
  the running total and selects the appropriate row. Sparse stats can use a smaller
  ceiling.
- **Curve-sample utility.** A one-shot Lua tool that scrapes itemlevel → stat-budget
  from vanilla items and writes the calibration table to disk. Re-runnable when
  itemization shifts.
- **Item property extension.** Per-item running totals (one number per stat / rating
  / unique-slot) plus an applied-level number for the required-level computation.
- **Stat scaling formula** that converts the +N base into a level-scaled value at
  application time. Open question: frozen on the item, or recomputed on equip?
- **Spell definitions** for each tier × category enchant spell — the player-visible
  surface through which an application is requested.
- **Material registry** mapping shards / essences / dusts to tier gates.
- **Unique effect registry** — separate from stat bonuses, behaves like a proc-style
  hook attached to the item.
- **Disenchanting** routes for producing the higher-tier materials, especially the
  epic-disenchant feed for tier-2 uniques.
- **UI** for showing an item's running totals, enchant history, and the next slot in
  the loop.

None of these are committed designs. They are the surfaces the system will eventually
need to touch.

---

## Closing

The enchanter sits by the window. The ring is warm in her palm. She has been speaking
to it for two hours. There is no rush — the magic *is* the speaking, and the speaking
*is* the practice, and the practice *is* the priority.

One more verse, then she'll set it down for the night.

The gem already knows.
