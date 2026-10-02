# Conversation Summary: agent-a7efacfffba116407

Generated on: 2026-10-02 16:41:23
Models: claude-opus-5-5

--------------------------------------------------------------------------------

### User Request 1

Your directive: Build the four new Intended Behavior bullets just added to
issues/617e8-following-across-maps.md (read it fresh): "No dwell, a human beat"
(drop the 8 s dwell: owner on a dock → buddies go at once, owner aboard →
they board at once, each after its own random 1–3 s); "Straight to a starting
spot" (as soon as the owner is on the dock, each buddy goes to an unheld
recording start of the nearest stop's ship and waits there; owner leaves the
dock → back to normal behavior); "Jump when the owner jumps" (owner leaves a
moving ship by jumping — zeppelin mid-air or boat into water — buddies
aboard jump off from where they stand after their own 1–3 s beat, using the
server's jump move, then follow as usual from where they land; if they land in
water, swimming to the owner is the bot module's normal behavior — check it is
not suppressed); "Missed the window: ride it round" (a buddy aboard a ship its
owner isn't on takes the fastest route to the owner's zone, usually staying
aboard until the ship docks on the owner's side; compare staying aboard vs
getting off at the next stop and walking/sailing, using the travel graph or
route timing). Where a dock has no recording, waiting near the owner remains, as
the existing fallback (logged).

Files you may edit: modules/mod-buddies/src/buddies_crossing.cpp/.h,
buddies_recorder.cpp/.h (only if needed), buddies_town.cpp/.h (only if needed),
docs/balance-updates.md (append an entry: the 8 s dwell removed and the 1–3 s
beat, with the owner's quote as the reason), issues 617e8 and 617e9 (Current
Behavior to true state; keep Intended Behavior as written). Nothing else is
being edited concurrently.

Style: match module code (vim folds, vertical alignment, why-comments, comment
per branch, dispatch tables). No nil fallbacks; loud errors per house rules.
Verification: no builds/compile/install. -fsyntax-only each changed .cpp with
buddies_login.cpp's command from build-shadow/compile_commands.json (file
swapped, no cd); logs under tmp/shared-memory/. Do not commit. Report: what
players see, files, test results (full output on failure), unbuilt parts, open
questions.

--------------------------------------------------------------------------------

