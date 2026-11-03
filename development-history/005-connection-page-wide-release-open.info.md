# 005-connection-page-wide-release-open

## What made it
- Tool: `scripts/write-connection-page --preview --screenshot release`
- Commit: 653156b (the working tree may hold uncommitted changes)
- Window: 900 x 2200, headless Firefox
- Sources fingerprint (BLAKE2b of the script and docs/profiles/*.md): fbc106bd3e3d6dcda3b95c613be2a0cb0f48e1da10cc3cb9a01e38b30e512dae7a69ce6fa041c219caabaa49fc4bca8127e6234297d25e6f237f2db068fffae7

## What changed since the previous picture
Compare the fingerprint above with the previous picture's.

## What it shows
900 px wide, Release open. Each realm row now starts with a small game box turned on its left edge: a blue-to-green glass front (no cover yet) with the realm's name in small white capitals at the top, its number in a gel orb at the bottom, a darker spine at its left, and a glossy sheen. Release's box has turned almost face-on; below its summary is the box's back, a deep blue panel with the yellow capital headline "THE WORLD IS EMPTY. UNTIL YOU SHOW UP." and four lines in the kid's voice, then the realm page's own intro, "What is here" with four points, and the "Connect to Release" gel button. Beta, Vanilla, Alpha, Basic and cc-test follow closed, then the start of "Side by side".

## The story so far
The owner (2026-10-28) asked for each realm to be a game box, in the voice of a kid finding it in an electronics shop after a long car ride, with cover art by Stable Diffusion that never uses the original game's names or peoples: off-brand peoples, each one token of its own. The off-brand tokens are made (eight embedding files from plain words), the covers' prompts and the box backs are written, and the cover painter is ready, but ComfyUI will not start until its installation's update is run, so these boxes have plain glass fronts (allowed only in a --preview page, each with a warning).
