# 506d - Feldowinn Gallery and Votes

## Status
- Created: 2026-09-27
- Phase: 5
- Parent: 506
- Blocked by: 506a
- Priority: High

## Current Behavior

**First votes, 2026-09-28**: the owner kept two designs and dropped one;
all three verdicts were in the page's store (collection `votes`, one
document per design) and correct. The delivery had a gap: the generator
reads only `assets/feldowinn/votes.tsv`, and the page's Export saves to the
browser's download folder, so the votes never reached it. Fixed: Claude
pulled the three verdicts into `assets/feldowinn/votes.tsv`; the generator
takes `--votes PATH`, and stops (naming the file) when a votes file in
~/Downloads is newer than the project's, instead of making a round from
stale votes. Checked: a scratch round 2 read the 3 votes; a newer
downloaded file stopped it; `scripts/test-feldowinn` still passes. Also
seen: the page stamps each vote with the viewer's clock, which ran 36
minutes 35 seconds off the store's; the store's own time is the one to
trust.

**Built and published 2026-09-27**:
https://claude.ai/artifact/4BuF6CdpRvtUqkPE1pQ1RF, made by
`scripts/generate-feldowinn-gallery` from `scripts/templates/feldowinn-gallery.html`.
- Pictures: read from ComfyUI's output folder, one folder per design
  (`/mnt/kaun/stable-diffusion/output/feldowinn/<design id>/view_*.png`,
  the installation's `output-directory`); the folder name ties a picture to
  its design, so pictures made by hand in ComfyUI with that prefix count
  too; a folder named for no design is reported. Each picture is copied
  480 pixels wide as WebP to `docs/HTML/feldowinn/views/<id>/`, and listed
  in `docs/HTML/feldowinn/publish-files.txt` ("published path<TAB>source")
  for publishing beside the page (the published page can only show
  pictures published with it). Past 255 files per version or 64 MB, move
  to the page's uploaded-assets store.
- Votes: the page's shared database, one document per design,
  `votes/<design id>` = `{vote: 1 | -1 | 0, piece, round, at}`: the
  developer's current verdict, changed by clicking (the store is
  last-writer-wins, so a click count would drift; a verdict doesn't).
  Readable by Claude (`ArtifactData list votes`), and exported by the page
  as `votes.tsv` for `assets/feldowinn/votes.tsv`.
- Without the live store (an old view, a local file) the page shows the
  votes baked in when it was made, read-only.

## Intended Behavior

- A page showing every profile of every round: its piece, its answers,
  its focus questions, and its concept image once one exists (a drawn
  placeholder from its palette and silhouette until then), with up and
  down votes.
- Votes persist for the developer over time: kept in the published
  page's shared database (one document per profile: ups, downs, when),
  not in the browser.
- Votes get back to the generator: the page exports `votes.tsv` (a
  download the developer saves as `assets/feldowinn/votes.tsv`), and
  Claude can read the database and write the same file.
- The page also shows, per design question, which option is ahead and
  whether the question counts as answered (the generator's rule).
- `scripts/generate-feldowinn-gallery` writes the page from the profiles
  (data generation and viewing kept apart).

## Suggested Implementation Steps

1. The page generator; publish; vote; export; regenerate a round from the
   votes.

## Related Issues

- **506** parent; **506a** reads the votes
