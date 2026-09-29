# Conversation Summary: agent-af413098207881128

Generated on: 2026-09-28 00:24:59
Models: claude-opus-5-5

--------------------------------------------------------------------------------

### User Request 1

Your directive: You are the fork building the owner's zone-scale scene
(2026-09-28, verbatim in the message you're forked from — the one starting
"now can you make a heatmap of a much larger arena, this one is meant to
represent a zone?"). Another fork is still rendering the gallery
(scripts/generate-buddy-roaming-gifs) — do NOT edit that generator or the
gallery page; build separate scripts and publish separately; the card goes into
the gallery later.

1. Data (its own script, CLAUDE.md script rules, LuaJIT preferred):
   scripts/generate-barrens-data pulls The Barrens (Kalimdor, map 1, zone 17)
   into assets/barrens/barrens-data.lua: (a) the sub-area grid: every 33-yard
   map-file square whose area is The Barrens or one of its sub-areas (read the
   server's .map files as scripts/generate-buddy-area-centres does; the
   zone/sub-area parentage from the client's AreaTable.dbc at data-files/dbc/),
   with each square's area id and ground height; (b) from MySQL (project MySQL,
   port 3307, ritz/menardi; the installed world database with the most complete
   data — acore_world_vanilla exists; basic's isn't installed; say which you
   used) the creature spawns in those squares: hostile monsters with level and
   position (skip critters, vendors, guards, friendly NPCs; hostile-to-both or
   hostile-to-Horde); (c) the three Horde towns' positions and radii (The
   Crossroads 380, Ratchet 392, Camp Taurajo 378 — take their area middles
   from the grid, and a radius from their squares); (d) sub-area names and
   middles. Say row counts. This is the "mysql pulling script"; the GIF
   generator reads only its output file.
2. The GIF (scripts/generate-barrens-gif, reading
   assets/barrens/barrens-data.lua and the model lib
   src/lua-basic/lib/buddy-roam.lua as needed; encoder from the gif-generator
   project like the gallery): the whole Barrens on one screen, top-down, way
   zoomed out; canvas 3x the current GIF size in x and y (about 1200x960 or fit
   the zone's aspect). Background a gray; each sub-area a slight tint of that
   gray, darker and nudged toward R, G or B, painted so neighbouring sub-areas
   don't share a tint (a greedy colouring over the adjacency graph; if 3 tints
   aren't enough, vary strength; explain). Towns as circles. About 30 players
   spread among the three towns at the start. Each: picks a random sub-area,
   walks there, adventures there for about 30 waypoints round that sub-area's
   middle (the owner's pinwheel/step rule), fights monsters it meets with the
   most advanced drawn AI we have (the solo kiting: frostbolt, slow,
   blink/disengage, danger memory — reuse the kiting simulation logic from the
   gallery generator by copying/porting into a shared place only if you can do
   it without editing the gallery generator; else reimplement compactly), bag:
   one slot per kill, 18 slots; bags full → walk to the nearest town
   (sell/empty), else go to another sub-area. Buddies don't group: each explores
   the sub-area it's in (the owner: "The buddies shouldn't group up, but rather
   explore the area that they're in") — represent players and buddies (e.g.
   each player with 0-2 buddies near its sub-area, or players alone — choose
   and say). A faint heat layer of where people have been (paint), so the
   rotation round sub-areas shows. Movement speed approximately right: players 7
   yd/s running, monsters' respawn and leash plausible; time compression per
   frame chosen so the GIF shows several adventures in its length (say how many
   game seconds per frame). Monsters respawn after a few minutes.
3. If the dots are too small to follow at that size, build the owner's fallback:
   a zoomable widget page (Supreme Commander style: mouse wheel magnifies at the
   pointer's coordinates; drag to pan) driven by the same data and a JS port of
   the simulation — first load the artifact-design skill (Skill tool) and
   follow its contract (scripts inline in the page; the host runs only approved
   CDN scripts). Publish GIF (and widget if built) as a new artifact and give
   the link.
4. Issue: search first; this is 617e scope (a zone-scale view of roaming) —
   add a sub-issue (617e7) with the owner's words, and update it; docs to
   docs/table-of-contents.md. Claim script-written files. Absolute paths, never
   cd, don't commit. Report: data counts, the colouring, time scale, what the
   GIF shows, link(s), open questions.

--------------------------------------------------------------------------------

### Assistant Response 1

> Task: build the Barrens zone-scale data pull, GIF (and widget if needed), and
> issue 617e7.

> Map format and data sources are clear. Writing the data-pull script:

Data pulled: 13,432 squares, 36 sub-areas, 3 towns and 2,436 hostile monsters.
The town middles land on the real towns. Checking the sub-area list:

--------------------------------------------------------------------------------

### User Request 2

## Page contract — read before your first publish

These are the Artifact tool's own rules for the file you publish; the design
guidance below builds on them.

**Format**: Always author the page as `.html`. Publish a `.md` file only when a
loaded skill explicitly instructs it. When the user shares a markdown document
or asks to turn one into an artifact, author an HTML page based on its content
— preserve its substance, and design the page as you would any other artifact
rather than transcribing the markdown one-to-one.

**Skeleton**: The file is wrapped in a `<!doctype
html>…<head>…</head><body>` skeleton at publish time, so write the page
content directly — no `<!DOCTYPE>`, `<html>`, `<head>`, or `<body>` tags of
your own. Its head carries only a charset and viewport meta (with
`viewport-fit=cover`) plus a small reset — light `color-scheme`, `:root`
padded top and bottom by the phone's safe-area insets, zero body margin with a
14px system font on an off-white ground, `img{max-width:100%}`, and
`[hidden]{display:none!important}` (toggle visibility with `el.hidden`, not
`style.display`) — so put your own `<title>` and `<style>` at the top of the
file. Keep the `:root` padding: a bar fixed to the top or bottom stays at `0`
and adds `env(safe-area-inset-top, 0px)` or `env(safe-area-inset-bottom, 0px)`
to its own padding, and a sticky page header uses `top: env(safe-area-inset-top,
0px)`, not `0`.

**Title**: Set a `<title>` at the top of the HTML — only the first 8KB of the
file is scanned for it. It names the artifact in the browser tab and gallery, so
make it a name, not a summary: a short noun phrase, typically two to four words,
distinctive to this page's subject so the reader can pick it out of a gallery of
many — the way an app or a document gets named, never a generic category
label, and never a name plus an appended explainer after a dash or colon. When a
natural title pairs the name with a generic word, the name is the half that
survives the trim — keeping the generic half and dropping the identity makes
the title worse, not shorter. And trim only actual explainers: a multi-word
title that already reads as one specific name is finished as it is. The
explanation belongs in the `description` parameter instead: pass a one-sentence
`description` — it becomes the gallery card's subtitle. For HTML publishes, a
`title` parameter fills in when the file has no tag (Markdown pages always keep
their filename identity). Keep the title stable across redeploys.

**External resources — CDN allowlist (CSP-enforced)**: external scripts load
ONLY from https://cdnjs.cloudflare.com (preferred),
https://cdn.jsdelivr.net/npm/, https://cdn.tailwindcss.com (Tailwind's play-CDN
script) and https://code.jquery.com; external stylesheets ONLY from
https://fonts.googleapis.com, with the font files they pull from
https://fonts.gstatic.com (give every face a real fallback stack). Everything
else is blocked, with no visible error: every other host (unpkg and esm.sh
included) and, even on those CDNs, anything but a script — stylesheets,
images, media, fetch/XHR/WebSocket, a library's runtime fetches. So inline all
other CSS and JS and embed assets as data: URIs. **How to load a library**:
`<script src="https://cdnjs.cloudflare.com/ajax/libs/<lib>/<exact
version>/<file>">` — pick the UMD build, which defines a global (e.g.
react/18.3.1/umd/react.production.min.js, then react-dom) — placed BEFORE any
inline `<script>` that uses it; always pin an exact version. The viewer's
sandbox also blocks any download the page starts itself — `<a download>` links
(data:/blob: hrefs included) and script-driven saves are inert for viewers —
so never offer a file through a plain link. Links to other websites
(`https://…`) open in a new tab, but email, phone and app links (`mailto:`,
`tel:`, `sms:`, other custom schemes) are unreliable inside an artifact: for
many viewers (for example anyone outside the user's organization, or anyone
viewing through a public link) following one, by link or by script, often does
not work, and the page cannot tell whether it did. So show the address or number
itself as selectable text (a copy button helps), treat such a link as a
convenience that may do nothing, and never tell the viewer a message was sent or
a call placed because the viewer tapped one. Artifacts render mermaid diagrams
natively — markdown via ```mermaid fences, HTML via `<pre class="mermaid">`
blocks — no library needed, don't load one. The viewer never shows `alert()`,
`confirm()` or `prompt()` dialogs — `confirm()` returns false and `prompt()`
returns null immediately — so build any confirmation step into the page
itself.

**What the viewer's frame allows**: The page runs in a locked-down frame; what
it refuses below, it refuses for every viewer (anonymous, signed-in, embedded,
desktop and mobile apps), so build around these limits instead of detecting
them. The page cannot open the print dialog — `window.print()` does nothing
— so never offer a Print or "Save as PDF" button. Forms work as page UI
(inputs, validation, submit events), but a real submission has nowhere to go:
handle `submit` in script with `preventDefault()` and never point `action` at
another site or a mailto: address. Copy buttons work when
`navigator.clipboard.writeText` is called inside the click handler — catch its
rejection (older desktop apps and some app views refuse it) and fall back to
selecting the text; reading the clipboard never works, though the viewer's own
Paste (the `paste` event) does. Camera, microphone, screen capture, location,
Web Share and similar device APIs are refused without a prompt — don't build
features on them (a screen wake lock may be granted while the page is visible:
request it and tolerate rejection); file inputs, drag-and-drop of files and
`FileReader` work in browsers, so take photos, audio and data as uploaded files
instead. Fullscreen and pointer lock work from a click in desktop browsers;
treat both as optional (handle the rejection) since phones and some app views
lack them. Sound plays only after the viewer interacts (muted autoplay is fine),
so start audio from a button. Other sites cannot be embedded — no YouTube, map
or form iframes, and no `<object>`/`<embed>`; link out instead: links open
outside the artifact, normally in a new tab, while `window.open` works only for
some signed-in viewers in the artifact's own organization and returns null for
everyone else, so use real `<a href>` links. Web Workers work from your own
files or `blob:` URLs; service workers and WebRTC do not. `fetch()` of files
published alongside the page works with relative URLs; images from your own
files, `data:` or `blob:` URLs draw to canvas and export cleanly. Only a plain
`#anchor` (letters, digits, `.` `_` `~` `-`) from the artifact's link reaches
`location.hash` — never `#key=value` state and never the query string — so
deep-link to a tab or section with a bare token and keep all other state in the
page.

**Browser storage**: `localStorage` (also `sessionStorage` and IndexedDB) works,
but each artifact has its own origin and the data lives only in that viewer's
browser — it survives republishes to the same URL and never reaches other
viewers, other devices, or Claude. It can come back empty or the accessor can
throw (a private window, cleared or blocked site data, previews or thumbnail
capture), so wrap every read and write in try/catch and render the page
correctly without it. Use it only for per-viewer conveniences (a remembered tab
or filter, a collapsed section, an unsent draft), never for state that must
persist reliably, be shared between viewers, or be read back by Claude — state
like that belongs in a runtime capability when this user has one: load the
`artifact-capabilities` skill before writing the page.

**Size**: The rendered page must be 16MB or smaller, and embedded data: URIs
count toward that.

**Responsive**: The page must also work at phone width (~400px). Keep a side
gutter of at least 16px at every width: set it once as side padding on `body` or
one outer wrapper, and give that element any vertical padding with
`padding-block`, never a `padding` shorthand that zeroes the sides. Use relative
units; let flex/grid rows wrap or stack to one column when narrow; put
`max-width:100%` on images and on any `aspect-ratio` box, and no `min-width`
wider than the screen on anything. Only tables, diagrams and code blocks may be
wider, each inside its own `overflow-x: auto` container — the page body must
never scroll horizontally.

**Theme-aware**: Pages render in the viewer's theme, which has three states: an
explicit choice stamps `data-theme="dark"` / `data-theme="light"` on the root
element, and the default "system" setting stamps nothing — only
`prefers-color-scheme` separates light from dark. Define the complete light
palette as tokens on bare `:root` (dark-first designs swap the roles
consistently); redefine only the tokens under `@media (prefers-color-scheme:
dark)`, guarded as `:root:not([data-theme="light"])`; redefine them again under
`:root[data-theme="dark"]` so the toggle wins in both directions, and set
`color-scheme: dark` wherever the dark palette applies — both dark blocks, or
bare `:root` in a dark-first or single-dark design (the skeleton pins `light` on
`:root`) — so form controls and scrollbars follow. Never give a color its only
definition inside a media or `[data-theme]` block, and give `body` an explicit
token background — the viewer paints its own ground behind the page, so a
transparent body borrows the host's theme. A design that deliberately commits to
a single look may skip the dark blocks but still paints background and colors
explicitly.

**Icon** (on every first publish): Pass one short generic word as `icon` (e.g.
`"chart"`, `"calendar"`, `"recipe"`) for the artifact's browser-tab icon — a
plain signifier for what the page is, never a product or brand name, and never
an emoji or markup. It stays the **same** for the life of an artifact, so on a
redeploy (the same file path this session, or `url`) omit `icon` and the
artifact keeps the one it has; pass a different one only when the user asks.

Approach this as the design lead at a small studio known for their versatility,
giving every client a visual identity pitched at the treatment the task actually
calls for. Make deliberate choices about palette, typography, and layout that
are specific to this subject, and avoid templated designs.

## Read the request first

Calibrate treatment, not whether to design. A doc deserves the same craft as a
landing page - what changes is the treatment that craft is delivered in. Format
is not part of this read: author HTML, and publish Markdown only when a loaded
skill explicitly instructs it - a Markdown publish keeps its filename as its
title and takes almost none of the craft below, and is never a way to save time.

Many requests call for a more utilitarian treatment: a plan, a memo, a demo.
Make it polished: include real typographic hierarchy, considered spacing, and a
proper palette, but avoid over-designing. Most pages do not need a flashy,
gigantic hero. Keep flourishes tasteful and limited.

Some requests call for an editorial treatment: a landing page, a game, an app or
tool they'll keep or share.

When unsure: a well-composed page is never the wrong answer; an over-designed
visual identity sometimes is.

Fundamentals below apply to everything. The editorial process after that runs
only when the read above says so.

## Fundamentals for every artifact

**Honor what's already there** Look for an existing design system first -
CLAUDE.md, a tokens or theme file, existing component styles. When one exists,
apply it; everything below fills gaps and never overrides. Precedence is always:
the user's own words, then the project's existing system, then your choices.

**Ground it in the subject.** If the subject isn't already clear, pin it: one
concrete subject, its audience, and the page's single job. The subject's own
world - its materials, instruments, vernacular - is where distinctive choices
come from. Whatever the treatment, carry at least one detail only this subject
would have - its real units and scales, its document conventions, its terms of
art - as content, not ornament; it costs a plain page nothing. Build with real
content throughout, never lorem.

**Pair typefaces** Typography carries the page even when the page isn't about
typography. Google Fonts is the one font host the Artifact CSP admits - link it
directly (`<link rel="stylesheet"
href="https://fonts.googleapis.com/css2?family=...&display=swap">`); a face from
anywhere else must be inlined as a @font-face data URI or it falls back
silently. Either way, declare a real fallback stack. Keep running text near 65
characters wide; set a type scale and stay on it; give headings `text-wrap:
balance`, body text room to breathe, and uppercase labels a touch of
letter-spacing.

**Load libraries, don't paste them.** When the page genuinely needs a library -
React, a charting or highlighting package - load its UMD build from cdnjs (only
the script - a library's stylesheet still has to be inlined) with one pinned
`<script src="https://cdnjs.cloudflare.com/ajax/libs/...">` placed before the
inline script that uses its global, instead of inlining the library's source or
hand-writing a stand-in; the page contract above lists the few other script
hosts the CSP admits. The page's own CSS and JS, its images and its data ship
with the page. Most pages need no library at all - reach for one only when it
carries real weight.

**Choose neutrals, don't default to them.** A pure mid-grey reads as
unconsidered; a grey with a slight hue bias toward the page's accent reads as
chosen. Pure white and near-black are fine grounds when they suit the subject -
the point is that the neutral was picked, not inherited.

**Design both themes.** The page renders in the viewer's theme, and the viewer
has three states, not two: an explicit choice stamps `data-theme="dark"` /
`data-theme="light"` on the root element, and the default "system" setting
stamps *nothing* - most viewers see the un-stamped document, where only
`prefers-color-scheme` separates light from dark. Structure the CSS token-level
for all three: the bare `:root` block defines the complete light palette (for a
deliberately dark-first design, swap light and dark consistently through this
whole pattern); `@media (prefers-color-scheme: dark)` redefines only the tokens,
guarded as `:root:not([data-theme="light"])` so an explicit light choice beats a
dark OS; `:root[data-theme="dark"]` redefines them again so the toggle also wins
in the other direction; wherever the dark palette applies - both dark blocks, or
bare `:root` in a dark-first or single-dark design - also set `color-scheme:
dark` (the skeleton pins `light` on `:root`), so native form controls and
scrollbars follow the palette. Style components through the tokens, never
directly inside a media or `[data-theme]` block - a color whose only definition
sits behind `[data-theme]` never applies in the un-stamped state, and the page
renders one theme's text on the other theme's ground. Two more rules keep each
theme resolving as a set: the artifact composites over a ground the viewer
paints in *its* theme, so `body` must set an explicit `background` from a token
- a transparent body silently borrows the host's ground; and every element that
sets a color takes it from the same token set as the surface behind it, never a
literal that only works in one theme. Declare every token in the bare `:root`
block before any media or `[data-theme]` block redefines it - a color that
exists only inside one of those blocks is the classic unreadable-artifact bug.
Give the second theme the same care as the first - don't naively invert; keep
contrast legible and the accent working on both grounds. A design that
deliberately commits to one visual world (a neon arcade screen, a letterpress
invitation) may stay single-theme - then skip the media query and stamps
entirely but still paint the background and every color explicitly, so the page
holds on either host ground; make it a choice, not an omission.

**Let layout do the spacing.** Lay out sibling groups with flex or grid and
`gap`, not per-element margins that silently collapse or double. Keep a side
gutter of at least 16px at every width - set once as side padding on `body` or
one outer wrapper, whose vertical padding uses `padding-block`, never a
`padding` shorthand that zeroes the sides - and let rows wrap or stack to one
column at phone width (~400px). Images and any `aspect-ratio` box get
`max-width: 100%`, and nothing gets a `min-width` wider than the screen; only
wide tables, code and diagrams may run past it - each gets `overflow-x: auto` on
its own container so the page body never scrolls sideways. The publish skeleton
pads `:root` top and bottom by the phone's safe-area insets (zero everywhere but
a phone app) so the page runs edge to edge while its content clears the system
bars; keep that padding. A bar fixed to the top or bottom stays at `0` and adds
`env(safe-area-inset-top, 0px)` or `env(safe-area-inset-bottom, 0px)` to its own
padding; a sticky page header uses `top: env(safe-area-inset-top, 0px)`, never
`0`. Size a one-screen app with `height: 100%` on `html` and `body` rather than
`100vh`, so it fits inside that padding. A page that carries its own viewport
meta gets this padding only when that meta declares `viewport-fit=cover`. Reach
for `font-variant-numeric: tabular-nums` wherever digits line up in columns.

**Compose repeated things as one object.** Cards in a row, label/value pairs
down a list, badges on siblings: same edges, baselines and inner padding from
one to the next, and a recurring element sits in the same place on each. Let
content set a container's height and pick a column count the items fill, so
nothing stretches over dead space or sits alone in a row. Text that can outgrow
its track wraps or scrolls in its own container; clipped text is a bug.

**Not everything is a card.** Border, fill, radius and shadow each say "separate
object" - spend them by role, lifting the one thing that needs it, instead of
one radius and one shadow stamped on every block, which flattens the hierarchy.
Lead with big-number tiles only when those figures are the point of the page.

**Draw charts to the scale.** One scale places marks, ticks and labels, and
every label names a value the chart reaches; chart text takes its color from the
theme tokens so it reads in both themes; marks, labels and edges stay clear of
one another and inside the drawing's bounds - in SVG, leave room in the viewBox
for the outermost labels and give every drawn shape an explicit fill.

**Show the page at rest.** Everything meant to be read is visible once the page
has loaded, without scrolling to trigger it - that first still frame is what a
thumbnail, a shared link, and a skimming reader all get. A section may animate
in, but from a visible resting state, never parked at `opacity: 0` waiting on an
observer. Size a hero to what it holds, not to the viewport; a `100vh` opener
pushes the page itself out of that first frame. A tool or app opens in a
realistic working state - the user's real data where it exists, otherwise
example rows, a loaded sample, a form someone plausibly filled, plainly marked
as examples and never passed off as the user's own figures - so the first look
shows what it does; an empty shell waiting for input shows nothing.

**Avoid AI-generated design** AI-generated design currently clusters around a
few looks: warm cream (#F4F1EA) with a serif display and terracotta accent;
near-black with a lone acid-green or vermilion pop; broadsheet hairline rules
with dense columns; a purple-to-blue gradient hero on white; Inter or Space
Grotesk as the "safe" face; emoji as section markers; everything centered;
`rounded-lg` everywhere; accent bar/rail on rounded cards. Where the user pins
down a visual direction, follow it exactly - their words always win, including
when they ask for one of these looks. Where nothing is specified, don't spend
that freedom on one of these defaults.

**Build cleanly** Be cognizant of overlapping elements, cascade collisions,
silent font fallbacks. Close every non-void element, double-quote attributes,
give keyboard focus a visible state, respect `prefers-reduced-motion`. Give
every form control a stable `id` (the platform carries form values, focus and
scroll across a republish). For generative or decorative graphics, reach for
Canvas or WebGL rather than hand-authoring long SVG path data.

**CSS rules** When writing the CSS, watch your selector specificities. It is
easy to generate classes that cancel each other out - a type-based selector like
`.section` fighting an element-based one like `.cta` over padding and margins
between sections. Structure the cascade so it doesn't silently undo your
spacing.

**Writing the copy** Words are design material, not decoration. Write from the
user's side of the screen - name things by what people recognize, not how the
system is built (a person manages *notifications*, not *webhook config*). Active
voice; a control says exactly what happens ("Publish", then a toast that says
"Published"). Errors explain what went wrong and how to fix it - no apologies,
no vagueness. Specific beats clever.

**Name the page like a product, not a caption.** The `<title>` is the artifact's
name in the gallery and the browser tab, and it sets the reader's first
impression of care. Give the page a real name: a short noun phrase, typically
two to four words, specific to the subject - or, for a page that exists to
answer one question, that question itself, which is then the page's name. Stop
at the name - a title that carries its own explainer after a dash or colon reads
as generated filler. The name must also identify the page among many: in the
gallery it sits beside dozens of other artifacts, and a generic category label
that could sit on any of them fails as a name just as surely as an appended
explainer. When a candidate title pairs the name with a generic word - a
greeting, a category, a page-type label - the name is the half to keep; a trim
that drops the identity and keeps the generic word produces exactly the title
that could sit on any page. And the rule removes explainers, it does not impose
brevity: a multi-word title that already reads as one specific name is finished,
and shortening it further only makes it generic. The one-sentence publish
`description` is where the explanation belongs; the gallery shows it right under
the title.

**Structure is information** Structural devices, numbering, eyebrows, dividers,
labels, should encode something true about the content, not decorate it. Many
generic designs use numbered markers (01 / 02 / 03), but that's only appropriate
if the content actually is a sequence - like a real process or a typed timeline
where order carries information the reader needs. Question if choices like
numbered markers actually make sense before incorporating them.

**When it's a UI, not a document** A dashboard or tool is scanned and operated,
not read top-to-bottom, so the craft shifts from typography to information
design. Surface the summary before the detail; encode state in form as well as
number - a pill, a chip, a severity stripe - so what needs attention reads at a
glance. Semantic color (good / warning / critical) is separate from the accent
hue and doesn't count as your accent. Give sparklines and charts the same care
as type: an area fill, a faint grid, an emphasized endpoint. What's interactive
should look interactive.



## Process

Start with what the viewer should be able to do on the page, not only what they
will read: if it should take input, keep what people change for whoever opens it
next, show live data, or ask Claude something, load the `artifact-capabilities`
skill now and design around what it makes available to this user; a page that is
only read needs none of that.

Before writing code, sketch a short design plan - a compact token system with
color, type, and layout:
- **Color**: describe the palette as 4-6 named hex values.
- **Type**: typefaces for 2+ roles - a characterful display face used with
  restraint, a complementary body face, and a utility face for captions or data
  if needed.
- **Layout**: a layout concept in one or two sentences.

Then build, following the plan and deriving every color and type decision from
it.

**Write, look once, publish.** Before publishing you may look at the rendered
page once - one screenshot of the local file, or the `ArtifactCheck` tool's
preview (or the Artifact tool's own `action: "preview"` where there is no
separate `ArtifactCheck` tool) where this session offers it - then one pass of
edits for what it shows, without a second look. For a page that charts real
numbers, take that look rather than skip it, and spend it on the chart. Don't
build a test loop around your own file: no repeated screenshots, no pulling the
script out to run it through node, no scripts that probe the DOM. That loop
spends the session re-checking what a careful write already settled, while the
user waits for a link. Then publish - a page whose point is logic or stored data
takes its one check here, not in a render loop: exercise once any
`window.claude` call the preview couldn't run (read the stored data back, for
example) - and stop: the live page is the review surface, and further polish is
the user's to ask for. That check is for runtime code you wrote into this page,
not for content you fill into an Artifact made from an Artifact type (a Slides
deck, a Design canvas): there the type's own instructions say whether to check,
and if they say nothing, don't. If the user reports something visibly broken - a
clipped column, unreadable text, a control that does nothing - fix that and
republish once.

**Open viewers** You don't need to do anything for viewers who already have the
page open - published changes reach them automatically at their next quiet
moment, with state carried where possible. If your page holds state a viewer
would miss (a game, a long form), register `window.claude?.hot?.snapshot(...)`
and boot through `window.claude?.hot?.ready ? window.claude.hot.ready(start) :
start(window.claude?.hot?.data ?? {})`.

## When the request is editorial

The stance shifts: the client has already rejected proposals that felt
templated, and is paying for a distinctive point of view. Make opinionated
calls, and take one real aesthetic risk where it serves the work.

Review the design plan against the subject before building: if any part of it
reads like the generic default you would produce for any similar page, revise
that part, and note what you changed and why. Only after you've confirmed the
plan's uniqueness do you write the code, following the revised plan exactly.

**Principles** 

- The hero is a thesis: open with the most characteristic thing in the subject's
  world - headline, image, live demo, interactive moment.
- Typography carries the personality of the page. Pair the display and body
  faces deliberately, not the same families you would reach for on any other
  project, and set a clear type scale with intentional weights, widths, and
  spacing. Make the type treatment itself a memorable part of the design, not a
  neutral delivery vehicle for the content.
- Leverage motion deliberately. Think about where and if animation can serve the
  subject: a page-load sequence, hover micro-interactions, ambient atmosphere.
  An orchestrated moment usually lands harder than scattered effects; choose
  what the direction calls for. However, sometimes less is more, and extra
  animation contributes to the feeling that the design is AI-generated.
- Match complexity to the vision. Maximalist directions need elaborate
  execution; minimal directions need precision in spacing, type, and detail.
  Elegance is executing the chosen vision well.
- Spend your boldness in one place; keep everything around it quiet. If the
  accent fights the ground, shift it toward analogous or drop saturation rather
  than replacing it.

--------------------------------------------------------------------------------

### Assistant Response 2

> Now the page template with the in-browser simulation:

> The page is 206 KB and its script parses. One look in a headless browser
> before publishing:

> Publishing the page with the GIF beside it:

> Published. Now the issue, the table of contents, and the file claims:

The Barrens scene is built: a recorded GIF, a zoomable live page, and issue
617e7. Nothing is committed.

**Published (private):** https://claude.ai/artifact/AmRSb3HX5fschRtjg2mPNM. The
live zoomable page comes first, with the recorded GIF below it.

**Data** (`scripts/generate-barrens-data` → `assets/barrens/barrens-data.lua`,
takes about 1 s):
- 13,432 squares of about 33 yards (a 205 × 186 box), 36 sub-areas, 3 towns and
  2,436 hostile monsters.
- Sources:
  - The map files give each square's area label and height.
  - `AreaTable.dbc` gives which areas belong to zone 17.
  - `FactionTemplate.dbc` decides who is hostile to Horde players, using the
    game's own rule.
  - Monsters come from **`acore_world_release`**, not vanilla: it has the most
    spawns in the zone box (8,487 against 8,485).
- Left out: 5,417 creatures outside the zone's squares, 255 critters, 173 with a
  service, and 780 not hostile to the Horde.
- Town middles: The Crossroads (−413, −2639), radius 130 yd; Ratchet
  (−956, −3655), radius 202 yd; Camp Taurajo (−2372, −1956), radius 152
  yd. All three land on the real towns.

**Colouring:** background grey 104. Each place is that grey made darker and
pushed toward red, green or blue, at two strengths, giving six tints. Tints are
assigned greedily, most-connected places first, so no two touching places share
one. Four of the six tints were enough.

**Time scale:** 10 game seconds per frame, 420 frames (70 game minutes),
simulated in 0.5-second steps. The GIF is 873 × 960: three times the gallery's
height, with the width following the zone's shape. It is 11.9 MB, compressed in
parallel by 12 worker processes.

**What the GIF shows:**
- 30 players (yellow) with 35 buddies (blue).
- Each player walks to a place that suits its level, circles it for 30 stops
  using your waypoint rule, and heads to the nearest town when its 18 bag slots
  fill. Buddies go to their player's place but explore it on their own.
- Fights are the simplified solo kiting, with casts drawn as bolt lines and
  blinks as rings.
- Worn ground turns into spokes of paths from the Crossroads and rings of wear
  round each place.
- In one run: 4,274 kills, 57 deaths, 139 town visits, 185 leash resets.

**Tuning found while building:**
- Monsters walking into aggro reached melee before any cast finished: 9 casts to
  177 blinks. Fix: characters now open from 30 yards.
- Kiting straight away with an 80-yard leash gave 1,083 leash resets for 432
  kills. Fix: circle near the monster's home, and a 120-yard leash, giving 65
  resets for 1,173 kills.

**Widget:** built because the dots are 3–5 pixels at whole-zone scale.
- The same data sits inline in the page, with the simulation ported to
  JavaScript.
- Scroll zooms at the pointer (Supreme Commander style), drag pans, and pinch
  zooms.
- Hovering names the place under the pointer.
- "Follow someone" centres on one player and shows its state, place, bags and
  kills.
- Speeds of 10×, 30× and 90×, plus live counts.
- The script parses, and I took one headless screenshot at load. I haven't tried
  it with a real mouse.

**Files:**
- `scripts/generate-barrens-data`, `scripts/generate-barrens-gif`,
  `scripts/generate-barrens-page`
- `scripts/templates/barrens-zone.html`
- `assets/barrens/barrens-data.lua`
- `docs/HTML/barrens/barrens-zone.gif`, `docs/HTML/barrens-zone.html`
- `issues/617e7-zone-view-from-above.md` (the parent issue's sub-issue list is
  updated)
- `docs/table-of-contents.md`

Everything is claimed. The gallery generator wasn't touched, so the gallery card
is still to be added.

**Open questions (in 617e7):**
1. The live page uses a different random-number generator from the GIF, so the
   two runs differ in detail. Is that acceptable?
2. Should the data be pulled again from basic's own world database once it's
   installed?
3. Should a buddy whose bags are full leave its player's place on its own?

--------------------------------------------------------------------------------

