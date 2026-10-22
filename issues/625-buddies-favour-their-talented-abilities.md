# 625 - Buddies Favour the Abilities Their Talents Touch

## Status
- Created: 2026-10-15
- Phase: 6
- Related: 617g (talent shapes), 622 (a buddy's own record of what works),
  309 (monsters that choose their attacks)
- Priority: Medium
- State: an idea; the design is open

## Origin

Verbatim, 2026-10-15:

> would it be possible to cause buddy-bots to be more likely to use the
> abilities that are mentioned or affected by the spec talents they are
> slotted? Just... in general.

Then, the same day, on stat weights (verbatim): "stat weights for spec
profiles must be modified by the current status of the character. The
profile has the defaults, and whatever the character's spec ends up being
determines which stats are preferred. We can do this by checking the
talents they actually pick, and then evaluating the stat weights for each
of the abilities mentioned, and how large and important of a discrepancy
the modification of the talent is, then we prefer that more or less
depending on how much it changed, and how often we are likely to use that
talent's mentioned abilities. Keep in mind we will always use some of
them sometime." And on the hunter asking for Trueshot Aura forty
thousand times: "we probably shouldn't be doing things in a loop if we're
just... standing around. Everything like that should be triggered by
something else, to keep it a game focused on user input and not a
simulation focused on backgrounds."

## Current Behavior

A buddy fights by the bot module's strategies for its class and the tree
the module guesses from its talents; each action has a fixed priority.
A talent that improves an ability (more damage, less cost, a shorter
cooldown) changes nothing about how often that ability is chosen. Seen
the same day: the hunter Montahmu's strategy asked 41,000 times for
Trueshot Aura, a talent it does not have.

## Intended Behavior

**Stat weights from the talents taken.** A talent shape's weights are the
starting point; the talents a buddy actually took move them: for each
ability a talent names, the stats that ability scales with count for
more, by how much the talent changes the ability and how often the buddy
uses it (and every ability is used sometimes). Gems (617j2), gear choice
and loot all read these weights.

**No idle asking.** The bot module checks each of its triggers every
moment ("does it have Trueshot Aura? no: cast it"), so an ability it can't
use (a talent not taken) is tried forever. An action for an unknown spell
should be dropped once, when the buddy's spells change, not checked
again every moment.

Every ability a buddy's talents name or change counts for more when the
buddy chooses what to do: the more talent points spent on it, the more
it is favoured. Abilities its talents never mention keep their ordinary
weight, and an ability it does not know is never asked for.

**Set bonuses count too** (owner, 2026-10-22: "in the issue files where
we make bots more likely to use abilities that are mentioned in the
talents that they picked, can we also do that for set bonuses on items?
It's rare, but a bot should be more likely to use an ability if it's
specifically mentioned on their super special useful gear."). An item
set bonus the buddy has earned (enough pieces worn) that names or changes
an ability favours that ability the same way a talent does: the bonus's
spell (the client's ItemSet.dbc lists each set's bonus spells and how
many pieces each needs) is read for the abilities it affects (its spell
class mask, as a talent's is). Re-read when the buddy's equipment
changes, not every moment.

## Sub-issues

- 625a: what each talent (and set bonus) touches, read from the game's
  own tables (step 2 below).
- 625b: buddies wear the weapons their talents are for.

## Suggested Implementation Steps

1. Answer the open questions.
2. (625a) From the client's tables, for each talent, the abilities it affects
   (its spell's effects that modify another spell's family flags, or that
   teach one), gathered once.
3. For a buddy, a weight per ability from the talent points it has in
   talents that touch it.
4. Those weights raise the priority of the bot module's matching actions
   (a source patch to the bot module's action choice, or the buddy
   module's own strategy), and an action for an unknown spell is dropped.

## Open Questions

1. How much more: a fixed raise per talent point, or as much as the
   talent's own effect (a talent adding 15% damage raises it by 15%)?
2. Should this live in the bot module (a patch, every bot) or only for
   buddies?
