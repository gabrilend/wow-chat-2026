# 1101g - Inference Boxes and Cluster Routing

## Status
- Created: 2026-08-01
- Parent: Issue 1101 (Bellwether — attended play)
- Phase: 11
- Priority: Medium (the map is deliverable without it)
- Depends on: 1101e (the map), 916d (the Ollama client, if reused)

## Overview

Puts the cluster in the map. A call box that sends a prompt to an Ollama
host and returns the reply, and a `distributor` routing box in front of
it that picks which host.

The interesting part of this issue is not the HTTP. It is that
SoraMech's `distributor` routing kind — least-busy pick, as a runtime
primitive — does the job that issue 916f specifies as bespoke per-host
health tracking and rotation. Two systems are about to solve the same
problem twice, and this issue is where that gets resolved.

## Current Behavior

The map has no cluster access. Issue 916 specifies the cluster:
three mini-PCs at 192.168.1.11:10101, 192.168.1.12:20202, and
192.168.1.13:30303, each running Ollama with parallel slots, addressed
from the worldserver through effil worker threads with per-host failure
counting and re-probing.

## Intended Behavior

### The inference box

A `call` box per host, or one box behind a distributor — see below. It
takes a prompt string, POSTs to the host's Ollama endpoint with
`format: "json"` where structured output is wanted, and returns the
reply text. Timeouts are the box's business; a hung host must not hold a
lap open.

Language choice: bash driver wrapping `curl` is the shortest path and
makes the box readable by anyone. Lua with luasocket matches 916d and
allows sharing the client. Decide once, in this issue.

### Two host-selection designs

**A. Distributor routing.** One box per host, a `distributor` in front,
least-busy pick per fire. Health is expressed by a failing box being
busy or absent rather than by a health table. Nothing to write.

**B. Reuse 916f.** Route through the worldserver's existing effil worker
pool, which already has failure thresholds and re-probe timers, and let
the map treat the whole cluster as one endpoint.

A is less code and lives where the pipeline lives. B is one shared
health story across both consumers, which matters if the two systems are
contending for the same three boxes — see the parent's open question
about whether 916's cluster and SoraMech's Alpine cluster are the same
hardware. If they are, two independent rotation schemes will each
believe they have the whole cluster.

Design A with an explicit shared budget is probably right. Recording
both so the decision is made once and on purpose.

### Degradation

Losing a host drops throughput, not function. Losing all hosts stops
narration but not attendance — the composer from 1101e is still there,
still templated, still true, and the alarm path never touched the
cluster in the first place. The listener is told that the voice is gone
and the facts continue.

That is worth stating plainly because it is the argument for having
built the templated floor first: the model is an enhancement to a
working system, not a dependency of it.

## Implementation Steps

1. Pick the language and write the single-host inference box. Test it
   standalone against one host, outside the map.
2. Put it in the map on the narration branch, downstream of the urgency
   comparator from 1101f. Confirm a lap completes end to end with a
   generated line.
3. Add the remaining hosts and the `distributor` box. Confirm
   consecutive laps spread across hosts.
4. Kill one host mid-run. Confirm laps route around it, that the failure
   is reported rather than silent, and that it rejoins when restarted.
5. Kill all hosts. Confirm the map falls back to the composer, that the
   listener is told, and that alarms are unaffected.
6. Timeout behaviour: a host that accepts a connection and never replies
   must not hold the lap. Test with a deliberately stalled endpoint.
7. Measure per-lap latency at family sizes 1, 3, and 5, and record it —
   the number sets what utterance rates 1101d can promise.

## Files to Create

- Inference box JSON, one per host, plus the distributor box
- The driver script or Lua module the box calls
- A stalled-endpoint fixture for step 6

## Open Questions

- **The overlap with 916f.** Design A or design B? And if the cluster is
  shared with mod-soren-chat, who owns the slot budget, and how does
  either side know how many slots the other is using?
- Which model? 916 leans toward the smallest model that produces valid
  JSON above 95% of attempts, benchmarked. This pipeline's needs are
  different — it wants fluent short prose more than strict JSON, and
  those are not the same model. Possibly two models, possibly two
  different hosts serving them.
- Does the narration path need JSON at all? A raw text reply plus the
  validator in 1101i may be simpler and better than forcing structure
  onto a single sentence.
- Should the prompt travel with its fact set through the map, so the
  validator downstream has the licensing facts without a second lookup?
  Almost certainly yes; it makes the wire value a pair rather than a
  string.
- What is the timeout, and what does exceeding it produce — silence, or
  a templated line? Silence is a lie by omission to someone who cannot
  see the screen.

## Related

- Parent: [1101 - Bellwether](1101-bellwether-attended-play.md)
- [916d - Ollama HTTP client](916d-ollama-http-client.md) — the existing
  client; reuse candidate
- [916e - effil worker pool](916e-effil-worker-pool.md) and
  [916f - Cluster health rotation](916f-cluster-health-rotation.md) —
  the machinery this issue may either reuse or duplicate
- [916m - Bash health check](916m-bash-health-check.md) — the pre-flight
  curl of all three hosts; an attended session should run the same check
  at session start
- [1101i - Utterance validator](1101i-utterance-validator.md) — the box
  immediately downstream
- SoraMech `docs/002-map-model.md`, the `distributor` routing kind
</content>
