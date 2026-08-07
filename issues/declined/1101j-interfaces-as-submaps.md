# 1101j - Interfaces as Sub-Maps

## Status
- Created: 2026-08-01
- Parent: Issue 1101 (Bellwether — attended play)
- Phase: 11
- Priority: High (the text interface gates development of everything else)
- Depends on: 1101e (the map to attach to)

## Overview

User directive, 2026-08-01: *the interface can be designed on a per-user
and per-session basis — however they want to interact with it.*

So the interface is not a feature of the pipeline; it's a parameter of
the session. This issue defines the boundary that makes that true, and
ships the first few.

## Current Behavior

1101e writes utterances to a text file because it needed somewhere to
put them.

## Intended Behavior

### An interface is a sub-map

SoraMech supports encapsulated sub-maps — a whole sub-graph appearing as
one box on the parent canvas. An interface is one of those, and it has a
fixed shape so the pipeline above it never changes:

**Inputs (from the pipeline):**

| Port | Carries |
|------|---------|
| `utterance` | the text to deliver |
| `ward` | who it's about, for interfaces that group or colour by ward |
| `urgency` | so an interface can interrupt itself (see 1101f) |
| `cancel` | pre-empt whatever is currently being delivered |

**Outputs (back to the pipeline):**

| Port | Carries |
|------|---------|
| `guidance` | raw player input, in whatever form the interface collects |
| `attention` | the listener's current attention level, if the interface knows |
| `attached` | whether anyone is actually receiving |

### The view is over independent connections

Per the parent: each ward is its own connection, and the family is the
view assembled over them. An interface is that view, so it inherits the
consequences directly. It may not assume the wards are co-located, in
one party, on one map, or even on one continent. It may not assume there
are five of them. A ward that goes quiet is a connection that stopped
reporting, not a member who wandered off — and the difference is
something the view has to be able to show.

The view is also the only place the family exists. In the world these
are unrelated people. Anything that makes them look like a set — a
shared header, an ordering, a colour per ward — is the interface's
invention, and it should be a good one, because it is doing all the work
of making five separate connections feel like a family.

An interface that can't do something declares it rather than faking it.
A text file has no cancel and no attention; it says so, and 1101f's
interrupt path degrades to "the next line is the alarm" instead of
pretending it cut in.

### The first three

**Text stream.** Appends to a file under the RAM tier
(`tmp/shared-memory/`), one line per utterance. Read with `tail -f`. No
guidance path — read-only attendance. Ships first because everything
else is developed by watching it.

**Speech.** The utterance goes to a text-to-speech engine and out the
speakers. Supports cancel. Guidance comes back either from a keyboard
elsewhere or from speech recognition, which is its own unsolved problem
— see open questions. This is the interface the request is really
about: *listening on the other end of a generation pipeline.*

**In-client panel.** AIO to the WoW addon (1101k). The player is at the
screen but not driving. Highest bandwidth, lowest need.

### Later

- **rmail** — asynchronous attendance. Digests out, guidance back as
  replies. Reuses issue 1004's bridge rather than inventing a second
  mail path.
- **Web page** — a browser on the LAN. Reads the family, plays generated
  audio, takes typed guidance.
- **Anything the player writes.** The shape above is the whole contract.
  A sub-map that satisfies it is a valid interface, and a player who
  wants their family narrated to an IRC channel or a smart speaker or a
  line printer should be able to have that without touching the
  pipeline.

### Session binding

A session names its interface sub-map at start. Several may be attached
at once — `plain` routing fans one utterance to every attached
interface, so speech and the text log can run together, which is exactly
what debugging wants.

## Implementation Steps

1. Define the sub-map port contract above and write it down where a
   sub-map author will find it — a doc under `docs/`, added to the
   table of contents.
2. Build the text-stream interface. Confirm the RAM-tier symlink scheme
   is created before writing, per house rules.
3. Wire interface selection into the map: session setting → which
   sub-map box is attached.
4. Build the speech interface, output side only. Decide the engine, and
   whether it runs on the worldserver host, the cluster, or the
   listener's own machine — the answer changes what "attended from
   anywhere" means.
5. Implement `cancel`, and the declaration mechanism for interfaces that
   can't.
6. Multiple attachment via `plain` routing, tested with text plus
   speech.
7. The in-client panel, once 1101k exists.
8. Latency measurement per interface, published as the numbers 1101f's
   budget table refers to.

## Files to Create

- `docs/bellwether-interface-contract.md` — the sub-map port contract
  (add to `docs/table-of-contents.md`)
- `maps/bellwether/interfaces/text/`
- `maps/bellwether/interfaces/speech/`
- `maps/bellwether/interfaces/panel/`

## Open Questions

- **Which speech engine, and where does it run?** If it runs on the
  worldserver host, attendance means being within earshot of the server
  — which is not attendance at all. If it runs on the listener's device,
  the interface sub-map is emitting to something across a network, and
  the contract needs a transport.
- **Speech recognition for the return path** is the parent's open
  question and it lands here. Without it, the speech interface is
  output-only and the player answers by some other channel — which is
  fine, but it means one session may have two interfaces attached for
  the two directions, and the contract above assumes one.
- Should `attention` be something the interface reports, something the
  player sets, or something inferred from response latency? Inferring it
  is attractive and is the kind of quiet self-adjustment the house rules
  are suspicious of.
- Can an interface be swapped mid-session — desk to car? That's the
  common case, not the exotic one, and SoraMech has no runtime graph
  mutation, so swapping a sub-map means restarting the run. Does the
  session survive a runner restart?
- Does the text-stream interface belong in the RAM tier at all? Logs
  do, per house rules. But a listener who wants to scroll back through
  yesterday's session wants it on disk.

## Related

- Parent: [1101 - Bellwether](1101-bellwether-attended-play.md)
- [1101k - The Bellwether addon](1101k-bellwether-aio-addon.md) — the
  in-client interface's client half
- [1101f - Urgency branch](1101f-urgency-branch-and-interrupt-path.md) —
  sets the cancellation requirement
- [1101l - Guidance capture](1101l-guidance-capture-and-standing-orders.md)
  — consumes the `guidance` port
- [1004 - rmail in-game bridge](1004-rmail-ingame-bridge) — the rmail
  interface should be a client of this, not a parallel implementation
- SoraMech `docs/002-map-model.md`, the encapsulation section
</content>
