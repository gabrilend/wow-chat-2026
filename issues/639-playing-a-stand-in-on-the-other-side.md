# 639 - Playing a Stand-in on the Other Side

## Status
- Created: 2026-11-03 (from a note the owner left in the project root,
  `new-issue-please-sort`, written 2026-10-10)
- Phase: 6
- Priority: Low
- State: idea; open questions first
- Blocked by: 617t (stand-ins: the bodies a player would step into),
  617i (buddies in battlegrounds)
- Related: 629 (battleground fronts: the lines a spy would walk behind),
  176a1 (Alterac Valley fought by stand-ins), 176a2 (Arathi Basin squads),
  617e16l (battlegrounds, two sides)

## Origin

Verbatim, the note `new-issue-please-sort` (2026-10-10):

> players in BGs should be able to play as stand-ins on the opponent's side - evil betrayal magic. If you ever say anything in the wrong
> language, you can be outed as a spy - but that'd require y'know, a fantasy language actually being built, like tolkien.
> like a crystal orb that lets you view one enemy as they fight, so you can learn from them with your wicked magic eye. Warlocks can
> summon one for free, everyone else needs an artifact that degrades by one use each time. Comes in packages of 3.

## Current Behavior

Nothing of this exists. Battlegrounds are fought by players, their buddies
(617i) and stand-ins (617t, 176a1, 176a2); every stand-in is a bot on its
own side, and no player can take one over.

## Intended Behavior

Two pieces, both "evil betrayal magic" in a battleground:

1. **A stand-in on the enemy's side.** A player in a battleground can take
   the place of one of the opposing side's stand-ins and fight from inside
   their lines. They can be found out: saying anything in the wrong
   language outs them as a spy. That second half needs a real fantasy
   language (one built the way Tolkien built his), so it waits on that.
2. **The crystal orb.** An orb that shows one enemy as they fight, so the
   player can watch and learn from them. Warlocks can summon one for free.
   Everyone else uses an artifact that loses one use each time, sold in
   packages of 3.

## Suggested Implementation Steps

1. Answer the open questions below; they decide the shape of both parts.
2. The orb first: it needs no new language and no change of side. A
   watching view on one chosen enemy (the client's own view of another
   unit), the warlock's summon as a spell, and the artifact as an item
   with 3 charges.
3. The stand-in swap: the player's character is set aside and the player
   drives a stand-in body of the other faction for the match, with the
   stand-in's gear and spells, and is returned to their own body at the
   match's end or on being outed.
4. Being outed: whatever the open questions settle as the "wrong
   language" test, a caught spy is revealed to both sides.

## Open Questions

1. The stand-in swap: is the player's own body hidden somewhere for the
   match, or does it stand in their own side's base as a statue?
2. "Saying anything in the wrong language": until a fantasy language
   exists, should the game's own Common and Orcish (which the other
   faction sees garbled) be the test — a spy who speaks their own
   faction's tongue in /say is outed?
3. The orb: does it show the enemy's view (what they see), or a camera
   that follows them from outside?
4. The artifact: who sells the packages of 3, and does using one up
   leave anything behind?
