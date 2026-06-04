# Medal Encounters — Strange Bosses for Strange Builds

*A vision for optional bosses that demand otherwise-marginal stats — turning resilience,
magic resistance, sustain throughput, and other niche specializations into the
signature of specific encounters. The medals you win are worn into the next charge.*

## Origin Conversation — 2026-05-12

### The Spark (User)

> can we make a vision file, of a monster that needs large amounts of resilience?
> because it deals powerful crit attacks, and it's companion deals periodics galore.
> they travel together. there's another pairing of mordaunts that require small amounts
> of resilience but high ratings of magic resistance — usually, because they're chromatic,
> and can cast many types of powerful magics at once. These types of bosses, the kind
> that require a certain type of gear or class combo or rating, must always be optional.
> they signify that someone on your team went the distance — they are medals worn into a
> charge. there might be others for other types of fights, like long sustain battles
> where you need to have high output of healing like patchwerk for a long time. at times
> like these, the most resilient, stable, and stalwart are those that last the longest.
> Not those that were aged in 2017. anyway the odd ones, the strange ones that require
> different strategies, these can be remembered and planned for. helpful, even.

The line worth holding: **"medals worn into a charge."** The reward is not a trophy
sitting on a shelf. The trophy *is the next attack*. You won this fight, and the next
fight you walk into wearing the proof. The story rides with you.

---

## Core Concept

Some bosses cannot be brute-forced with general-purpose gear. They are gated by a
**specific stat or stat-cluster** that the rest of the game does not pressure you to
build. To beat them, *someone on the team has to specialize* — to deliberately walk
away from the optimization curve and pick up a weird build.

The encounters are **always optional**. You can finish the game — full leveling, full
ambient threat, full progression arc — without ever fighting them. They sit beside the
main path, not on it.

When a team beats one, the participants earn a **mark**. A title, a visible buff aura,
a transmog adornment, an inventory keepsake. The mark says *we went and got the strange
one.* It is worn into the next fight — visible, lasting, recognizable.

These are the **medal encounters**.

---

## The Two Established Pairings

### Pair I — The Critslinger and the Bleed-Companion (Resilience-Gated)

Two monsters that travel together. They are rarely seen apart, and engaging one always
draws the other within seconds.

- **The Critslinger** — Heavy single-strike attacker. Every attack rolls with a high
  base critical-strike chance and a brutal crit multiplier. Unmitigated, a single hit
  one-shots most gear. Against resilient targets, the crit chance collapses and the
  crit damage gets shaved into something survivable.

- **The Bleed-Companion** — Applies stacking periodic effects. Bleeds, poisons, mana
  burns over time. Individually each tick is small; in aggregate they shred. Resilience
  in 3.3.5a reduces periodic damage as well as crit damage, so the same stat handles
  both threats.

**The lesson:** The pair is a *single problem* dressed as two creatures. One stat
solves both. A team that brings even one heavily-resilient member can carry the others
through. A team with zero resilience dies in seconds.

**Required investment:** roughly one party member with resilience as their dominant
secondary, achieved through enchant-stacking on chest/cloak/jewelry (the enchanting
system's universality makes this buildable).

### Pair II — The Chromatic Mordaunts (Magic-Resistance-Gated)

A second travelling pair, of a different make. Where Pair I is physical, Pair II is
arcane. The mordaunts are *chromatic* — they cast across multiple schools of magic
simultaneously, fire bleeding into frost into arcane into shadow.

- They require **small** amounts of resilience (their crits and DoTs are modest).
- They require **high** ratings of magic resistance, across multiple schools at once.

The challenge is that no single resistance covers all their casts. The team needs a
*broad* resistance profile, not a deep one. A frost-resist set won't save you when the
shadow-bolt lands.

**The lesson:** Specialization can mean **breadth** as well as depth. A character built
"thinly across many schools" beats this fight; a character built "deeply in one school"
gets murdered by the other four colors.

**Required investment:** one or more party members with multi-school resist gear or
buffs. Paladin auras, shaman totems, druid resist HoTs — the buff-stacking utility
classes shine here.

---

## Other Pairings (Proposals — Brainstormed, Not Committed)

These extend the principle. Each maps a marginal stat to a memorable fight:

- **The Patchwerk-Type Sustain Boss (Throughput-Gated).** A single boss with a huge
  health pool and steady, predictable, *high* incoming damage. No spikes, no gimmicks
  — just relentless pressure for a long time. Rewards healers with sustained mp5,
  spirit, and healing throughput rather than burst clutch saves. The team that beats
  this is the team that **lasts**. As the user put it: *the most resilient, stable,
  and stalwart are those that last the longest.*

- **The Plate-Wrapped Warden (Armor-Pen-Gated).** A boss with monstrous armor. Normal
  weapons tickle. Bringing high armor-penetration ratings is the only way to scrape
  through its hide. Rewards rogues, hunters, fury warriors who specced into ArP.

- **The Untouchable (Hit/Expertise-Gated).** A boss with abnormally high dodge and
  parry. Standard melee misses constantly. The team needs to bring overcap hit and
  expertise — usually a "dead" overflow stat — to land the kill.

- **The Wall (Block-Gated, Reverse).** Machine-gun small-hit boss. Many tiny attacks
  per second. Block-rating tanks shine; dodge-parry tanks fall over because their
  avoidance triggers can't keep up with the rate. Rewards the *least-glamorous*
  tank build.

- **The Skating Phantom (Movement-Gated).** A boss whose mechanics demand constant
  repositioning, root immunity, sprint cooldowns. Rewards classes with mobility and
  builds that invested in movement-related uniques (per the enchant system's tier-1
  conditional uniques).

- **The Silent Library (Threat-Gated).** A boss that punishes overaggro with massive
  cleaves. Rewards careful threat management, threat-reducing items, and disciplined
  pull pacing — not raw DPS.

Each pairing or fight gets a name, a story, a fixed location (or roving territory),
and a mark. Each is a vignette of a particular kind of competence.

---

## Design Principles

### Always Optional

The medal encounters live **beside** the main progression arc, never inside it. No
quest requires beating them. No story gate references them. A player can complete the
full level-20 arc, transition into invisible-level progression (issue 804), and reach
the immortality endpoint at invisible level 60 without ever seeing one.

This protects the encounters from becoming *obligations*. They stay strange.

### Telegraphed In Advance

The team must be able to *know* what the fight wants before it starts. Not "guess and
wipe and respec and try again." That is bad design — it converts the medal into a
grinding ritual.

Instead, each encounter is preceded by **lore**. A wandering narrator (per issue 910)
tells the tale of the Critslinger to anyone who sits near them long enough. A scout
NPC near the boss's territory describes the threat. The mordaunts are mentioned in
fragments of ghostsong audible at the right hour. The mechanics are known before the
arrow flies.

When players walk in, they walk in **prepared**. The medal is earned through the
preparation as much as the fight.

### Reward = Memory, Not Power

The mark you wear is **not better gear**. It does not gate the next encounter or feed
into a power treadmill. It is:

- A **title** the player can display.
- A **visual** that other players can see — a faint aura, an icon next to the name, a
  cosmetic effect on a weapon, an extra emote.
- An **inventory keepsake** — a non-equipment trinket that displays the encounter's
  story when inspected.
- A **mention** in lore generated by the narrator system. Other players hear of you.

The medal accrues *reputation*, not stats. The next charge you ride into is *visibly*
ridden by someone who has done the strange thing once before.

### Plannable, Not Punishing

Because the encounters are telegraphed and the marks are reputational, players can
*plan* a build around hunting a specific medal. The enchanting universality (see
notes/vision-enchanting-system-update.md) means a player can deliberately layer
resilience onto an otherwise-resilience-free piece of gear in order to attempt Pair I.
A few weeks of focused enchanting and the build is ready.

This makes the strange bosses **helpful**. They give a reason to vary. They reward
*current* attention to the game — what does this team have? what does this fight want?
how do we close the gap? — rather than rote rotations memorized years ago.

> *Not those that were aged in 2017.*

The encounters refuse to be solved once and forgotten. Every team that tries them
must do the thinking from scratch, because their composition is different from the
last team's. The puzzle stays alive.

---

## Connection to Other Systems

- **Enchanting universality** (`vision-enchanting-system-update.md`). The medal
  encounters are the *justification* for the universality principle: because a ring
  can hold resilience, a player can build for Pair I. Without universal enchanting,
  the gear restrictions of vanilla itemization would make most of these fights
  unbeatable for most classes. The mirror also runs the other way — the enchanting
  vision keeps resilience in its ratings pool **only because** the medal encounters
  exist to make it useful. On a PvE server resilience would otherwise be a dead
  stat. The two visions interlock: medal encounters justify resilience-as-enchant,
  enchanting universality enables resilience-as-build. **This is the general
  pattern** — any otherwise-dead stat can earn its slot in the enchant pool by
  being paired with a specialty encounter that needs it. Each future medal
  encounter is therefore also an *enchanting argument*, and each new enchantable
  stat is a *medal-encounter argument*.

- **Invisible-level progression** (issue 804). Medal encounters might appear primarily
  in invisible-level territory, where the level cap has been crossed and players are
  hunting for *something* to do with their extra progression. Strange bosses fit the
  endgame breath-room well.

- **Narrator system** (issue 910). The telegraphing is delivered through wandering
  narrators who share the lore of each encounter. The narrator-as-teacher pattern.

- **Custom classes** (issues 706, 709). Custom classes can be designed around specific
  medal-fights — a class whose entire identity is *we are the resilience build* or
  *we are the chromatic-resist priest*. The class advertises which fights it makes
  trivial.

- **Embedding-based creature selection** (issue 904). The contextual spawn system can
  ensure the medal-fight monsters appear in thematic locations, not at random — the
  Critslinger in places of historical violence, the chromatic mordaunts in places
  where magic schools collide.

- **Visible cosmetic markers**. May need addon support (AIO) to display titles, auras,
  or icons next to player names. Lightweight client-side rendering of medal markers.

---

## Open Questions

- **How many medal encounters total?** A small handful (4–6 archetypes) gives each one
  weight. A larger roster (15+) dilutes them into a checklist. Tendency: start small,
  expand only as players ask.

- **Solo or group?** Some medals (the chromatic mordaunts) demand group composition
  variety. Others (the sustain boss) could be solo against a long, slow target if
  the player has invested in self-healing throughput. Mix is probably good.

- **Respawn cadence.** Do the mordaunts wander a fixed territory forever, or appear
  on rare schedules? If permanent, the encounter feels like a landmark. If scheduled,
  it feels like an event. Both have appeal.

- **Failure cost.** If a team wipes, do they lose anything? Probably not — these are
  optional and the medal is the reward. Failure is its own teacher.

- **Cross-medal stacking.** Can a single player wear multiple medals at once?
  Probably yes — wearing several is itself a brag, "I went the distance many times."

- **Faction or solo identity.** Do medals belong to *teams* (everyone present at the
  kill earns it) or to *individuals* (only those who contributed meaningfully)?
  Tendency: teams. The medal celebrates the *charge*, not the swing.

- **Are there anti-medal encounters?** Fights that punish over-specialization, where
  the team that brought too much resilience finds itself wanting some other stat?
  This could create natural tension against pure medal-farming.

---

## Implementation Touchpoints

When this vision matures into issues:

- **Encounter definition format.** A Lua table per encounter describing: monsters,
  spawn location/territory, required stat profile (for telegraphing), lore text,
  medal granted, visual marker template.

- **Telegraph delivery.** Lore hooks into the narrator system. Optional scout NPCs
  near the territory.

- **Medal grant on kill.** Detect participation, award mark to participants on death
  of the final boss in the pair.

- **Medal display.** Title-system additions for 3.3.5a, possibly via AIO addon for
  custom visuals.

- **Stat-profile inspector.** A tool (perhaps for player use, perhaps for design
  validation) that checks whether a team's current loadout meets the telegraphed
  threshold for a given encounter. Optional — players may prefer to figure it out
  themselves.

None of these are committed designs. They are the surfaces this system will
eventually need to touch.

---

## Closing

Somewhere in the world, the Critslinger walks his slow walk. The Bleed-Companion
shuffles behind, exhaling poisons. Nobody has fought them in two months. They are
not part of the main story, and they are not waiting impatiently — they are simply
where they are.

A team of four sits in a cave somewhere else, planning. Someone has been quietly
re-enchanting a ring with resilience for three weeks. The shard inventory in the
guildbank has been hoarded carefully. The narrator's story has been listened to twice
through, and notes have been taken.

When they walk out of the cave, they will be walking toward the Critslinger.

And when they come back — if they come back — the next charge they ride into will
be visibly ridden by people who have done the strange thing once before. The medal
will be on them. The story will travel ahead of them.

The strange bosses are not obstacles.

They are *helpful*.
