# 617c5 - Party Buffs Shared Out

## Status
- Created: 2026-10-26
- Phase: 6
- Parent: 617c (buddy login and the proximity party)
- Related: 617c2 (the proximity party: who is grouped with whom), 617g
  (buddy talent plans: what a paladin's or shaman's talents improve),
  617n (spell learning: which blessings, auras and totems a buddy knows),
  the playerbots module's paladin and shaman strategies
  (`Ai/Class/Paladin/Strategy/`, `Ai/Class/Shaman/Strategy/`)
- Priority: Medium
- State: step 2's Lua model and step 3's wish words built 2026-11-06
  (`src/lua-basic/lib/buddy-party-buffs.lua`), rebuilt 2026-11-05 on the
  owner's answers as one checklist of buff categories across paladins,
  shamans, hunters and priests; the C++ core and steps 1, 4 and 5 not

## Origin

The owner, 2026-10-26:

> can we make sure that paladins prioritize different judgement spells if
> they're missing on the target? Also, they and shamans with their totems
> are the main classes whose buffs are specific to the party they're with.
> Can you ensure that we tailor our buff usage to the ones who need certain
> things? If a healer usually does kings, which we can message btw and the
> bots can message each other btw, then if they're low on mana we might
> throw out a Blessing of Wisdom if they need it, and swap back for the
> next fight.
>
> though, if we have a rare one like in prot, then we might give that with
> priority. It's mentioned in our talents after all. But, receiver's
> preference always wins, even if you have the improved Blessing of Might
> or whatever. Though, since it's a talent, you'd prefer it when not
> specified and when the recipient can properly use it. Same for shaman
> totems.

> oh also, three paladins in my group. Me, and two buddy-bots. And we only
> have two auras, because they're doubling up.

## Current Behavior

Each paladin and shaman buddy chooses its own blessings, aura and totems
from the playerbots module's class strategies, alone: it does not look at
what the others in its party already give. Seen 2026-10-26: three paladins
in one party (the owner and two buddies) and two auras up, two of them on
the same one. Judgements are chosen per paladin, not per target, so two
paladins can keep the same judgement on a monster while another is
missing.

## Intended Behavior

**One plan per party, per kind of party buff.** For a party's paladins
(auras, blessings, judgements) and shamans (one totem of each element),
the buffs are shared out so that no two give the same one while another is
missing, and each given buff goes to whoever needs it most.

**Who wants what, in this order** (first that applies wins):
1. **The receiver's stated preference** always wins, even over a talented
   blessing (the owner: "receiver's preference always wins, even if you have
   the improved Blessing of Might or whatever"). A preference is stated by
   message: a player whispers or says it in party chat, and buddies tell
   each other the same way (the owner: "which we can message btw and the
   bots can message each other btw").
2. **A buff the giver's talents make rare or improved** (Blessing of
   Sanctuary from protection, Improved Blessing of Might, Improved
   Devotion Aura, a shaman's improved totems): given first when nobody
   asked otherwise, and only to a receiver who can properly use it (Might
   to those who fight with weapons, not to a caster).
3. **What the receiver needs right now**: a healer who usually takes Kings
   and is low on mana gets Wisdom for the next stretch, and Kings again
   for the next fight (the owner: "swap back for the next fight").
4. **The usual by role**: Kings or Wisdom for healers and casters, Might
   or Kings for weapon users, Sanctuary or Kings for tanks.

**Auras**: one paladin per aura; with three paladins, three different
auras. A talented aura goes to the paladin who has the talent.

**Judgements**: on a target, each paladin judges with one the target lacks
(Light, Wisdom, Justice), so a target carries as many different judgements
as there are paladins on it.

**Totems**: one shaman per element is not needed (each shaman has all
four), but two shamans put down different totems of an element when the
party benefits from both (Windfury for weapon users beside Wrath of Air
for casters, if there are two shamans), and never the same one twice.

**One checklist across classes** (the owner, 2026-11-05: "treat each buff
type as a separate category, and keep a checklist to see when we're
missing one. if we can apply one, we should."): each kind of effect is
one line, whoever gives it, and two buffs the game won't stack are one
line. Which they are is the game's own data, not a guess: its stacking
groups (`spell_group`, `spell_group_stack_rules` in the world database)
put Mana Spring Totem with Blessing of Wisdom ("MP5 Buffs", 1105),
Totem of Wrath with Flametongue Totem ("Spell Power Buffs", 1048),
Windfury Totem with Improved Icy Talons (1022), but Devotion Aura and
Stoneskin Totem in different groups; and every resistance buff (a
paladin's aura, a shaman's totem, a hunter's Aspect of the Wild, a
priest's Shadow Protection) is the same "exclusive resistance" aura in
the spell data, so only the strongest of a school counts. What players
give ticks lines off; buddies fill the rest, most needed first.

## Suggested Implementation Steps

1. Read how the playerbots module chooses blessings, auras, judgements and
   totems today (`Ai/Class/Paladin/Strategy/PaladinBuffStrategies.cpp`,
   `DpsPaladinStrategy.cpp` for auras, the shaman's totem strategies), and
   whether it has any per-party sharing (some versions have a "blessing
   manager"); name what is there before adding to it.
2. The party plan: a pure function (C++ beside the buddy module's other
   pure cores, with a Lua model and a test, as the roaming core has):
   given the party's paladins and shamans (each with what it knows and its
   talents) and the receivers (each with role, mana, stated preference),
   it returns who casts which aura, blessing per receiver, judgement per
   target and totem per element. Tests: three paladins give three auras;
   a stated preference beats a talent; Sanctuary goes to a tank first;
   Might never to a caster; a low-mana healer gets Wisdom and goes back to
   Kings after the fight.
3. Preferences by message: a few words in a whisper or party chat ("Kings
   please", "Wisdom", "no Might") stored per receiver for the session;
   buddies say theirs the same way, so the owner can read them.
4. In game: the buddy's buff actions ask the plan instead of choosing
   alone (a patch to the playerbots module, or a buddy strategy placed
   before the stock ones).
5. Seen in game: three paladins, three auras; two shamans, no doubled
   totems; a mana-starved healer given Wisdom.

## Open Questions

Gathered 2026-10-28 into 617's own list (question 20), merged with the
same questions from other sub-issues; answers are written back here.

- **Answered 2026-10-28** (617's question 20, judgement order): "We should
  dynamically evaluate this as the fight goes on. Light if the party needs
  health, wisdom if the party needs mana." Judged again through the fight.

- **Answered 2026-10-28** (617's question 20): a wish is whispered to one
  buddy, and holds for that buddy until logout.

- **Answered 2026-10-28** (617's question 20, its planning part): "Buddies
  plan around any player in the group. They should send each other a
  message if they have an improved version of the aura, and the other
  person if a buddy will switch to a different one. They need to have
  awareness of the current buffs and try to fill them, with stuff relevant
  to the party or if we start for example taking fire damage, they might
  resist a fire aura. Or shadow for shadow aura. If we're fighting a mage
  primarily there's no need for stone wall totem. Etc. Plan your auras and
  totems and such around the team you have and the threats you face." So:
  every player in the group counts (not only the owner); buddies say when
  one has the improved version (a talented aura) or will switch; the plan
  reads what is already on the party and fills gaps; and it answers the
  threats: the damage schools the party has taken lately choose the
  resistance aura or totem, and the enemy's kind (casters) rules out
  answers that don't help (Stoneskin Totem against a mage). Still open:
  the words for a preference, and judgement order.

- **Answered 2026-11-05** (the owner, reviewing the model's pull request;
  word for word):
  - Judgements and resistances: "paladins don't get totems but I think
    there are resist totems that don't stack with the paladin aura so...
    and yeah we only should have as available options the judgements that
    they know, same as any class."
  - Hunters: "okay don't hunters also have auras with their aspects?
    Nature resistance or something?" (Yes: Aspect of the Wild, the same
    kind of resistance as the Nature Resistance Totem.) Then: "a shaman
    also loses utility from using that particular totem, so it's okay. We
    should only have nature resist auras if we are experiencing
    significant nature damage. Significant not as in "a lot" but rather
    "enough to matter" which we can assess using the dynamic combat system
    we're developing."
  - The checklist: "yeah so I think we should treat each buff type as a
    separate category, and keep a checklist to see when we're missing
    one. if we can apply one, we should. I think this is pretty simple."
  - Wishes: "for the whispers, we probably should just have a single
    "command" that the bots use. We're going to implement llm
    functionality eventually in the custom-client so when we have that, we
    should be able to dynamically assess the intention of the message."
    Then, on "bless kings" as that command: "these are not natural. The
    natural way is for the paladin to pick a buff and if the receiver
    wants something else they say something like "kings" or "can you do
    might instead?" or similar. Sometimes, if there are multiple paladins,
    the player won't know who to ask - that's alright. They'll say it in
    party / raid instead like "can I get wisdom" and then the paladins
    figure it out. We have to keep in mind that sometimes for buffs, one
    player might have the talent that buffs that buff, in which case they
    should have priority for placing it."
  - Kings and Sanctuary: "it does stack. I think. Can we find out through
    the game data somehow?" Found in the game data: they stack in part.
    Stacking group 1038 ("All Stats Percentage with Sanctuary") holds
    Kings and Sanctuary's +10% strength and stamina, and only the larger
    counts; that is one 10%, not two. Kings' agility, intellect and
    spirit, and Sanctuary's 3% less damage and mana returned, still
    count. So a tank given both gets more than from either, but not
    twice the strength and stamina.

1. **Players as paladins in the plan.** The owner is a paladin too: should
   buddies plan around the auras and blessings the owner gives (read from
   what is on the party), and leave the owner's choice alone?
2. **How a preference is said.** Which words, in which channel, and does it
   last until logout or until changed?
3. **Judgement order** when there are fewer paladins than judgements:
   which one first (Wisdom for a mana-using party, Light for a melee one)?

## Decisions, 2026-11-06 (an agent, answering what was still open)

Built: the Lua model of the party plan (step 2) and the words of a wish
(step 3's parsing), in `src/lua-basic/lib/buddy-party-buffs.lua` (page
`buddy-party-buffs.info.md`), tested by `scripts/test-buddy-party-buffs`
(the step-2 tests named above, the checklist across classes, players
planned around, judgements only of the ones a paladin knows, the ways a
wish is said and sentences that are not wishes, and 600 random parties
checked against a referee written from this issue: every line that can be
filled is, in order, and no other way of filling them has more talented
givers or best spells. Of 22 deliberate breaks of the 2026-11-05 rebuild,
20 are caught. The other 2 change nothing the plan promises: the planner
stopping at a path that gains nothing rather than one that loses, and the
slot a player's buff is matched by, which no spell name in two slots of
one class can tell apart). Not built: step 1 (the bot module's buff
strategies: its source isn't on this host), the C++ core beside the buddy
module's other cores, step 4 (the buff actions asking the plan) and step 5
(seen in game).

1. **Players as paladins** (question 1): yes, planned around. What a
   player gives (aura, a blessing on a member, a judgement) is read and
   left alone, and buddies fill what is missing; a player shaman's totems
   likewise. This follows the 2026-10-28 answer ("Buddies plan around any
   player in the group ... awareness of the current buffs and try to fill
   them").
2. **How a wish is said** (question 2, rebuilt on the owner's 2026-11-05
   answer): the way players say it, whispered to a buddy paladin or said
   in party or raid chat by the receiver; which paladin gives it is the
   plan's, a talented one first. A message counts as a wish only when it
   plainly is one:
   - the blessing alone ("kings", "Wisdom please", "BoW?"), or at the end
     with "please" ("not now, kings please");
   - right after a request ("can you do might instead?", "can I get
     wisdom", "could I get blessing of kings?", "give me", "switch to"), or
     before "instead";
   - "no", "not" or "don't give me" right before it, as the whole message,
     says no to it;
   - "anything" or "no preference", alone, clears both.

   The short forms (BoK, BoM, BoW, BoS, Sanc) count only as the whole
   message or right after a request. So "you might want to heal", "I need
   a new bow" and "anything but might" are not wishes. This rule-based
   reader stands in until the custom client's language model reads what a
   message means (the owner, 2026-11-05). A new wish replaces the last; it
   holds until logout (2026-10-28).
3. **Judgement order** (question 3): by the 2026-10-28 answer, Light
   first when the party's average health shortfall is larger than its mana
   users' average mana shortfall, Wisdom first otherwise, then the other,
   then Justice; worked out again whenever the plan is.
4. **Low on mana** means under 35%; Wisdom then comes before the usual,
   and the next plan made with its mana back gives Kings again (the
   owner's "swap back for the next fight").
5. **A resistance is called for** only when its school's damage is enough
   to matter, which is the combat system's judgement (the owner,
   2026-11-05), passed in as `party.resist` (true, or a number for how
   much it matters: the larger first). The earlier 40%-share threshold is
   gone. It is one line per school, filled by whoever can: fire by a
   paladin's aura or a shaman's water totem; frost by an aura or a fire
   totem; shadow by an aura or a priest's Shadow Protection; nature by a
   shaman's air totem or a hunter's Aspect of the Wild. What the giver
   loses by it (a hunter's damage aspect, a shaman's other totem of that
   element) is accepted ("so it's okay").
6. **What helps whom**: Might to tanks, melee and hunters; Wisdom to
   healers, casters and hunters; Sanctuary to tanks, first; Kings to all.
   Concentration Aura, spell power (Totem of Wrath, else Flametongue) and
   Wrath of Air only with a healer or caster in the party; Windfury and
   Strength of Earth only with weapon users; Mana Spring only with mana
   users; no Devotion Aura or Stoneskin Totem against casters; Grounding
   only against them. With Mana Spring down (a buddy's or a player's),
   Wisdom is not given unless asked for. A second shaman puts down the
   next totem that helps, or none.
7. **Improved buffs**: among the ways to fill the checklist's lines (or a
   member's blessings), the one that hands the most to the givers whose
   talents improve them, then the most given with a line's best spell
   (the owner, 2026-11-05: the talented one has "priority for placing
   it"). A paladin with an improved aura says so, and a paladin changing
   aura says it is switching.
8. **Judgements** are handed out only from what each paladin knows; with
   too few known, the target carries fewer (the owner, 2026-11-05).
9. **The checklist is part of the plan** (`checklist`): every line the
   party wants, most needed first, and who gives it, nil where nobody can,
   so a missing buff can be seen.
