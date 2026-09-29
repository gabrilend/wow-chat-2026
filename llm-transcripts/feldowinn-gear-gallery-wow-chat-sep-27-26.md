# Conversation Summary: agent-ab4e39d6693a7c5e5

Generated on: 2026-09-27 20:36:53
Models: claude-opus-5-5

--------------------------------------------------------------------------------

### User Request 1

Your directive: You are the fork starting the Feldowinn gear gallery in
wow-chat-2026 (the owner: "wow-chat. world-edit-to-execute came later, but was
built first."; and "comfyUI stuff can be built, or at least maximally described,
before the ability to test it is measured to completion. But testing is
important for end-user results."). Read notes/owner-perspective.md ("Feldowinn,
the healing fairy") and the status report findings: ComfyUI builds at
/mnt/kaun/stable-diffusion/ (not yet installed; GTX 1080 Ti, CUDA 12.6, no
cuDNN), the asset-forge design in
/home/ritz/programming/ai-stuff/world-edit-to-execute/issues/W05-asset-forge-find-or-generate-a-replacement-model.md
and docs/datapath-asset-forge.md (read, don't edit that project).

1. Issue first: a new wow-chat issue (search for duplicates first, incl. 159
   equipment portrait grid; take the number from
   /home/ritz/programming/ai-stuff/scripts/validate-issues
   /mnt/mtwo/games/azeroth-core/wow-chat-2026 --next <phase> — choose the
   phase by what it builds on and explain) for the Feldowinn gear gallery:
   profiles of Retribution Paladin gear pieces (helm, shoulders, chest, gloves,
   belt, legs, boots, weapon, shield... as a fairy warrior friend, a legendary
   hero, "a link to time"), generated as design variations; an HTML gallery; the
   developer votes each up or down over time; generation favours design
   questions not yet answered; when a design that persists is voted down,
   variation widens. Sub-issues if the work streams separate (profile generator;
   image generation through ComfyUI; image-to-3D through ComfyUI; gallery and
   votes), with the table/rationale/order per the issue-lifecycle skill.
2. Build what can be built without ComfyUI running, and describe the rest
   maximally: (a) a profile generator (Lua; per CLAUDE.md script rules)
   producing design profiles — structured records (piece, silhouette,
   materials, palette, motifs, the design question each answers) from a
   design-question list, weighted toward unanswered questions and widened after
   downvotes, reading the votes file; (b) the ComfyUI side as
   runnable-but-untested clients: workflow JSON(s) for text-to-image concept art
   of a profile (SD1.5-era models the install has: Dreamshaper-8, ControlNet,
   IP-Adapter), and a described image-to-3D stage (Hunyuan3D-2 / TRELLIS nodes,
   with the 1080 Ti compatibility risk stated and how to check it), plus a small
   client script that submits a workflow to ComfyUI's HTTP API and saves results
   — each clearly marked untested, with the exact test to run once ComfyUI is
   up; (c) the gallery page generated from the profiles (and images when they
   exist; placeholders drawn from the profile otherwise) with up/down votes —
   load the artifact-design skill (Skill tool, skill "artifact-design") before
   writing the page; votes must persist for the developer over time and be
   readable back by the generator: use an artifact runtime capability for shared
   state if appropriate (load the artifact-capabilities skill before using any),
   otherwise a votes file the page exports; publish it as a new artifact and
   give the link.
3. Tests for what can be tested now (the profile generator's weighting and
   widening; the workflow JSON validates against the node names the install has,
   if the node list can be read without running ComfyUI — else say). Add docs
   to docs/table-of-contents.md. Claim script-written files. Absolute paths,
   never cd, don't commit, don't start the ComfyUI build or any long GPU job.
   Report: the issue(s), files, the gallery link, what is untested and the exact
   steps to test it.

--------------------------------------------------------------------------------

### Assistant Response 1

Task: start the Feldowinn gear gallery in wow-chat. That covers the issue(s), a
profile generator, untested ComfyUI clients, and a voting gallery artifact.

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

Votes need to persist and be readable back, so I'm loading the capabilities
skill:

--------------------------------------------------------------------------------

### User Request 3

Base directory for this skill:
/tmp/claude-1000/bundled-skills/2.1.280/f5bcb6eafcda0d93e95165e9c33f752d/artifact-capabilities

# Artifact runtime capabilities

A published Artifact page can declare **runtime capabilities** — abilities the
claude.ai viewer grants the page at open time — by passing `capabilities:
{name: config}` to the Artifact tool. The control plane is the authority on
valid names and config shapes. Declaration gestures: **omitting** `capabilities`
on a redeploy carries the stored declaration forward unchanged (and preserves
the artifact's stored contract pin); an **empty object** `{}` is the explicit
clear-all; a **non-empty object** is a full-set declaration (anything stored but
not restated is revoked). Moving a republished artifact's runtime version is a
deliberate gesture — pass `contract: 'latest'` to upgrade, or a specific
version to pin or roll back — never a side effect of editing.

**Available capabilities:** `artifact`, `assets`, `comments`, `db`, `downloads`,
`files`, `mcp`, `room`, `sample`, `self`, `user` — the complete set of
capability names you may declare; built in on every page, called without
declaring (never pass these in `capabilities`): `permissions`. Anything not
listed is unavailable to this user.

> Tool spelling in this session: the `Artifact` tool's `action: "read_db"` /
> `"write_db"` with a `db_op` are the `ArtifactData` tool, whose `action` is
> that `db_op` ("get", "list", "query", "set", "update", "str_replace",
> "delete", "batch") with the other fields unchanged — load it with ToolSearch
> when you first need it. Read the steps below with that substitution.

Runtime contract 0.2.61


Capability namespaces live behind `claude.use(name)`: `const db = await
claude.use("db")` resolves the capability's namespace, or `null` when this view
cannot run it (not served, not granted, or failed to load — indistinguishable
by design). Branch on `null` and design for absence. `window.claude` carries
only `use`: no `window.claude.db`, `.room`, or `.artifact` member is ever
promised, so never read one — render the page without them and light features
up when the promise resolves (later, never within your script's first run, and
unordered with DOMContentLoaded; `null` after 10 s when no viewer answers). The
resolved namespace is frozen and platform-owned: call its functions and keep the
reference; never assign to it, `defineProperty` on it, or replace a member (wrap
it for your own helpers). Permission stays on the calls: a consent prompt, rate
limit, or policy refusal arrives on the first call, never from `use()`. Awaiting
`use("db")` again is free (memoized); an unknown name resolves `null`.


--- capability: artifact ---

Use `artifact` for pages that should remember what people do with them: polls,
sign-up sheets, checklists, trackers, boards — the page is the record; data
kept server-side, or seeded or read back by Claude, is `db`. Declare
`capabilities: {artifact: {}}`; `const artifact = await claude.use("artifact")`,
then `await artifact.publish(html)` saves `html` (a complete document, doctype
first) as the new version, and every open view, this one included, reloads to
it. Nothing a viewer types, ticks or drags is kept unless the page publishes it.
So embed the shared state as data in the HTML you publish and render the page
from it; when an interaction completes, update the state, regenerate the
document and publish it — never serialize the live DOM; batch rapid edits into
one publish; publish only after a viewer acts, never on load. `conflict` is
routine (every view reloads to the winner, dropping this edit): no retry. For
read-only viewers publish rejects `not_granted`/`not_writer` — render a
read-only view.


--- capability: assets ---

`assets` stores uploaded assets for this artifact: `const assets = await
claude.use("assets")`; `await assets.upload(blob)` (image, SVG, video, PDF,
font, CSS/JS, or CSV/Markdown/JSON/text data; 20 MiB cap, CSS/JS 16 MiB, SVG 2
MiB and sanitized on upload) resolves `{id, url, sizeBytes, contentType}`;
`assets.list()` resolves `{assets, usage}` (storage meter, orphan pruning);
`assets.delete(id)` removes one for good: only on a deliberate user action,
updating the `db` rows that held the id. Declare `capabilities: {assets: {}}`; a
declaring page is organization-internal (never public). Writer-only: a reader
view gets `null` from `use("assets")`; hide asset UI on `null` and handle
rejection codes. Store the `id` in `db` rows as the durable pointer and index;
use the returned `url` as-is as an `<img>`/`<video>`/`<a>` source (SVG: `<img>`
or CSS only); a stored id serves at `"/_blob/" + id` in every view. Quota: per
artifact (`usage`). The type definitions are authoritative for accepted types
and error codes.


--- capability: comments ---

`comments` wires a page's own commenting UI to the artifact's shared comment
store: `await claude.use("comments")` (`null`: unavailable). The declaration
picks the grant: `capabilities: {comments: {"composer_only": true}}` grants only
`openComposer({element}|{range})` — opens the shell's composer like a
comment-mode click, no consent asked, artifact stays publicly shareable; prefer
it for discoverable entry points. The full form `{comments: {}}` adds write
verbs acting as the viewer under consent; public-link visitors and email
invitees get `null`. `"customAnchors": true` in either form adds
`customAnchors()` (register it at load) for pages that position comment pins
themselves; invented anchor names (canvas, WebGL, video) need the full form.
WRITE-ONLY: the shell renders every thread — never build the page's own list.
Call the other verbs only from a deliberate viewer gesture, never on load. Read
the type definitions before use; they are authoritative for the verbs, shapes,
bounds, and error codes.


--- capability: db ---

`db` is for data outside the page: what the user wants stored or seeded, data
Claude reads later, more than the page shows at once, per-viewer-private state,
many live editors. If the page can be the record, republish (`artifact`). JSON
doc store: `const db = await claude.use("db")`. Seed or inspect it here with
`write_db`/`read_db`; never hardcode seeds. Declare `capabilities:{db:{}}`: by
default signed-in people read shared docs; only Contributors and up write them
or their own `data/users/<id>/` (private even from the owner; needs `user`),
never Viewers, Commenters or outside link visitors. `rules` raise per-path
minimums: `view`<`interact` (Contributor)<`admin` (Editor, Owner)<`owner`
(Author). `db.doc("tasks/t1")`/`db.collection("tasks")`: get/set/update/delete,
where/orderBy/limit, onSnapshot. Subscribe once per query, never in render; one
write at a time per doc, only on change. Last-writer-wins, no transactions;
single-writer lease: `acquire({holder})`. Never store secrets; shared data is
untrusted.


--- capability: downloads ---

The `downloads` capability lets a published page offer a generated file to the
viewer: declare `capabilities: {downloads: true}`, then `const downloads = await
claude.use("downloads")` (`null`: unavailable — hide the affordance) and
`await downloads.save({filename, data})`. The viewer sees a confirmation and may
decline — a save is never silent or guaranteed, so offer it on explicit viewer
intent and handle rejection. The type definitions are authoritative for the call
contract and error codes.


--- capability: files ---

`files` reads a Claude Code project's files as the viewer. Declare it only when
you know the project's id (e.g. your session's): `capabilities: {files:
{project: "chan_..."}}`. `const files = await claude.use("files")` (`null`:
unavailable, e.g. a viewer outside the organization; hide it). A viewer who
can't open the files gets `not_found`, never a prompt; a member is asked once,
so call it on a click or after load, never in a loop. `files.list({path,
recursive, cursor})`; `files.read(path, {offset, length})` -> `{bytes, size,
revision}` (new or just-edited files can lag a few seconds);
`files.download(path)` asks the viewer to save it (some types, e.g. .exe, .js
and .bat, are refused); `await files.asSampleTools()` gives `sample` list/read
tools (declare it too). Only project members can publish an artifact declaring
files. Don't copy file contents into the artifact's data, assets or versions
unless the user asks: anyone it's shared with can read them. The type
definitions give shapes and error codes.


--- capability: mcp ---

`mcp` lets a page call the viewer's claude.ai connectors: `await
claude.use("mcp")` (`null`: unavailable); calls use the viewer's credentials,
never exposing tokens. Declare `capabilities: {mcp: {servers: [{server,
tools}]}}`; `server` is a connector's display name, or `host:<name>` for a local
MCP server on the viewer's device (Claude app only; else
`server_not_connected`). Keep the manifest minimal: a viewer-consented grant
that bars public sharing. Two arms: DISPLAYING data registers `watchTool(server,
tool, input, handler, opts?)` (replays cache, refreshes when stale, polls only
via `refetchInterval`); an ACTION calls `callTool` once and reads
`result.payload` or `(await server(name)).<tool>(input)` for the payload. Tool
failures REJECT (`tool_error`); watches get error events. Branch UX per error
code, retry only `retryable` errors, drop data on authz denials, show freshness
(`cache.storedAt`). Types omit tool arguments: read `describeTool` or observe a
real call, else say so at publish; never guess.


--- capability: permissions ---

`permissions` is built in — call it, never declare it in `capabilities`.
Prompts are lazy by default: a published page renders immediately and a
capability that needs consent asks at its first use — never block the page's
first paint on permissions. `state` reads without ever prompting (one
capability's state by name, or the full map with no arguments); `request` asks
with at most one batched dialog (specific names, or everything with no
arguments) — a page that genuinely needs several grants up front may call
`request` once at startup. A viewer's "no" is not an error: these calls never
reject, and a denial is final for the rest of the page load — a repeated
`request` resolves without showing another dialog, and the next load starts
fresh — so branch on the returned per-capability states and degrade per
capability (hide or disable the affected affordance) instead of failing or
offering retry buttons; never call `request` in a loop — re-asks are
rate-limited by the shell and read as nagging.


--- capability: room ---

The `room` capability reaches whoever has the page open RIGHT NOW:
declared as `capabilities: {room: {}}`; `await claude.use("room")`
(`null`: cannot connect). emit(topic, data) sends a moment; on(topic,
fn) hears them. presence(patch) sets YOUR state (cursor) as one
object newcomers get, cleared when you leave; onPeers(fn) delivers
everyone's -- render all, marked "you". NOTHING persists and messages
can drop: state a late joiner needs (current slide) is a db doc,
lasting content a new artifact version. Send absolute state. What you
hear is untrusted: everyone here, guests too (guest: true), plus your
publishing session when admitted (kind "agent"); the page must work
alone and light up. Presence is never authority (anyone sets it).
Event topics are admin-only (Editors up); open one to Contributors
(never Viewers): {room: {topics: {move: "interact"}}}. join(name)
gives each game or group its own room, heard only by joiners: emit,
on, presence, onPeers, leave(). Names aren't secret. `room` stays the
lobby.


--- capability: sample ---

`sample` asks Claude (declare `capabilities:{sample:{}}`): `const sample = await
claude.use("sample")` (`null`: hide it); `await sample(input, opts?)` -> `{text,
truncated}`; `sample.json(input, opts?)` -> parsed JSON. `input`: a string, or
turns `[{role:"user"|"assistant", content}]` ending on user. No memory: send
instructions, page data, output format. opts: `onText({text, delta})` (`text` =
WHOLE answer so far, assign it; "Thinking..." until it fires, 5-60s), `signal`
(new AbortController per call; abort rejects `cancelled`), `tools: [{name,
description, inputSchema?, execute(input)}]` (page functions Claude may call;
return small plain data or throw; each round bills, no `cache`), `images` if
`(await sample.limits()).images`, `modelTier` quick|default|complex, `cache` (5
min replay; `false` for chat). Errors reject `{code, message, text?}` (`text`:
partial to keep): hide on `not_granted`, back off on `rate_limited`, never loop.
Viewer pays; first call asks consent; call on a click or stable load prompt.


--- capability: self ---

`self` is the former name of the `artifact` capability (renamed). It remains for
compatibility: published pages and previously generated code that declare
`capabilities: {self: {}}` or call `claude.use("self")` keep working unchanged
— both names resolve this same capability (this contract promises no
`window.claude.self` member to feature-check; `use()` is the check). Do not use
it in new pages: declare `capabilities: {artifact: {}}` and obtain the namespace
with `await claude.use("artifact")`; see the artifact section for how to use it.


--- capability: user ---

`user` answers who is viewing this page and who your shared state names: the
owner's organization and invited guests (`guest: true`); others are absent.
`const user = await claude.use("user")`; `null` = absent (`user?.isOwner() ??
false`). `isOwner()`/`canEdit()`/`can(name)` need no setup (canEdit = admin
level; `can("data.write")` = may write shared `db` docs, `null` = not told: keep
the input; refused writes decide). Declare `capabilities:{user:{}}` for
`id()`/`me()` (opaque id, comparable only within one scope; `me()` never null)
and `profiles(ids)`; `scopes:["profile"]` adds names and `search(q)`;
`["profile","email"]` adds addresses. Reads never reject. Store only ids (`id()`
or `hit.id`), never a name, avatar, or Profile: names differ per viewer and go
stale. Resolve in render, every time: `const ps = await
user.profiles(idsOnScreen)` then `ps[id].name || 'Someone'` (cached: call again
freely). `name` is `""` if unresolvable: use `||` not `??`. Call `search('')` on
focus; set names with textContent.


**Your connectors this session.** Connector tools appear in your tool list as
`mcp__<connector>__<toolName>`. Set `server` to the `<connector>` segment —
everything between `mcp__` and the next `__` (for
`mcp__claude_ai_Slack_beta__search`, the `server` is `claude_ai_Slack_beta`).
Copy the segment exactly, case included; when publishing, it is resolved to the
connector's display name automatically. In the page's own `callTool`/`watchTool`
calls, pass the connector's display name (its name as shown in claude.ai), not
that segment — viewers resolve connectors by name only. The publish result
states the exact display name for each segment it resolves; if the page's calls
do not match it, fix them and publish again. Only claude.ai connectors are valid
— locally-configured MCP servers are not. The manifest's `tools` array takes
the connector's upstream tool names (as returned by `listTools()` /
`/v1/mcp_servers`), which can differ from the normalized `<toolName>` segment
when an upstream name contains `.` or spaces. Every `servers[]` entry needs a
non-empty `tools` array naming the tools the page calls — an empty or omitted
`tools` list is refused and never means "all tools"; to publish without
connector access, leave `mcp` out of `capabilities` (pass `capabilities: {}` to
clear a stored declaration) rather than declaring an empty `servers` list. In
hermetic/CI sessions where connectors aren't loaded but
`$CLAUDE_CODE_OAUTH_TOKEN` is set, fetch the list via Bash: `curl -H
'anthropic-version: 2023-06-01' -H 'anthropic-beta: mcp-servers-2025-12-04' -H
"Authorization: Bearer $CLAUDE_CODE_OAUTH_TOKEN"
https://api.anthropic.com/v1/mcp_servers?limit=1000`; in that case use each
entry's `display_name` as the `server` value (exact display names are always
accepted alongside tool-prefix segments).

**Call contract** (runtime contract 0.2.61). The platform-served `window.claude`
type definitions for this contract are extracted under
`/tmp/claude-1000/bundled-skills/2.1.280/f5bcb6eafcda0d93e95165e9c33f752d/artifact-capabilities`:
`0.2.61/artifact.d.ts`, `0.2.61/assets.d.ts`, `0.2.61/claude.d.ts`,
`0.2.61/comments.d.ts`, `0.2.61/db.d.ts`, `0.2.61/downloads.d.ts`,
`0.2.61/files.d.ts`, `0.2.61/mcp.d.ts`, `0.2.61/permissions.d.ts`,
`0.2.61/room.d.ts`, `0.2.61/sample.d.ts`, `0.2.61/self.d.ts`,
`0.2.61/user.d.ts`. Read
`/tmp/claude-1000/bundled-skills/2.1.280/f5bcb6eafcda0d93e95165e9c33f752d/artifact-capabilities/0.2.61/claude.d.ts`
(how a page reaches any capability on this contract) and
`/tmp/claude-1000/bundled-skills/2.1.280/f5bcb6eafcda0d93e95165e9c33f752d/artifact-capabilities/0.2.61/mcp.d.ts`
before writing any code that calls the `mcp` capability — they are
authoritative for this contract version over any remembered API shape. Open
these files with the Read tool rather than `cat`: a file past the Bash tool's
inline output limit does not come back in full. The type definitions cover only
the call envelope, not a connector tool's argument names or result shape. Take
argument names from the tool's input schema in this session's own definition of
that connector tool, when it is loaded here. Learn a result's shape from one
real call of a tool that is safe to run — never run a write only to learn its
result. The published page may also read a connector tool's schema itself with
`describeTool(server, tool)` at view time, once the viewer has allowed that
connector for the page (viewers without that support reject it — treat any
rejection as no schema available); this session cannot read that answer before
publishing, so it is no substitute for a schema read here. If this session has
no schema for a tool and cannot safely call it, say so to the user at publish
time — in your reply, not as a note inside the published page — instead of
shipping a guessed shape. Observed response payloads are the user's real data:
learn the shape from them, but never embed the observed values in the published
page as sample or placeholder data.

## Where a page keeps its state — this session

- A per-viewer convenience (a remembered tab, a draft): browser storage; it
  never reaches other viewers or Claude.
- The page itself is the record (a poll, a sign-up sheet, a checklist): the
  `artifact` capability — a viewer who can write republishes the whole page
  from its state; every open view reloads to the winner, a concurrent save
  rejects `conflict`, and read-only viewers cannot save. Such a page regenerates
  the whole document from its state: keep the head, tokens and structure and
  change only the content.
- Data outside the page (Claude seeds or reads it, more than the page shows,
  private per viewer, many writers at once): the `db` capability — documents
  under access rules, live through `onSnapshot`, kept across republishes.

## Verify before you hand over the link — this session

A page whose `capabilities` you declared in this session gets one functional
pass, not a render loop: after the first publish, one `ArtifactData` `list` of
each collection the page writes, and, where its rules hide something from
ordinary viewers, the same read with a lower `as_level`, which must not show
what the rules hide from such a viewer. Then tell the user in one line what you
exercised and what you could not. An Artifact made from an Artifact type is not
such a page: its capabilities come from the type, and the type's instructions
govern any checking.

--------------------------------------------------------------------------------

### Assistant Response 3

> Writing the issue and its sub-issues. It goes in phase 5 (Content Generation)
> as issue 506, since it builds generated content, not server systems.

> Issues validate. Now the design questions, the source data the generator
> reads:

> Writing the profile logic as a library, so the generator and the test share
> it:

> The leader-and-runner-up loop I wrote is muddled. Rewriting it plainly:

> Now the command that writes a round, reading earlier rounds and the votes
> file:

> The generator works. Checking how the installation points ComfyUI at its model
> folders, and that Dreamshaper-8 is a complete diffusers folder the loader node
> will list:

> Both names exist. Writing the three workflows in ComfyUI's API format:

> Now the client that sends a profile to ComfyUI and saves what comes back:

> Handling the owner's addition: first, where the installation puts generated
> images.

> Two stale lines in the header (a doubled "the", and the old default image
> path). Fixing them and checking the file's end:

> The client is fixed. Before writing the gallery page, reading the exact
> database and download call shapes:

> One messy line in the tally loop. Cleaning it up:

> Now the gallery generator. It reads the profiles, votes and ComfyUI's output
> folder, makes web-sized copies of the pictures, and writes the page:

The test caught both planted bugs, and the scratch copy is deleted. Taking the
one allowed look at the page before publishing:

--------------------------------------------------------------------------------

### User Request 4

[Image: original 1200x2400, displayed at 1000x2000. Multiply coordinates by 1.20
to map to original image.]

--------------------------------------------------------------------------------

### Assistant Response 4

> Publishing the gallery. Votes are kept in the page's own database, and the
> export uses the page's download ability:

> Doing the one functional check on the page's store: listing the votes
> collection.

> Adding the new documents to the table of contents:

> Recording the files I wrote through scripts, which the edit ledger can't see:

Task: start the Feldowinn gear gallery in wow-chat — the issues, a profile
generator, ComfyUI clients (not yet runnable), and a voting gallery page. All of
it is built and published; the ComfyUI side is untested because ComfyUI can't
run yet. Nothing is committed.

**Gallery:** https://claude.ai/artifact/4BuF6CdpRvtUqkPE1pQ1RF, published
privately. Votes save to the page's own database; the page's export button
writes `votes.tsv`.

**Issues**, in phase 5 (Content Generation), because this generates content
rather than changing the server:
- 506 Feldowinn gear gallery (parent; holds your words verbatim, including the
  output-folder request)
- 506a design profiles
- 506b concept art
- 506c image to 3D
- 506d gallery and votes

Build order: 506a → 506d and 506b side by side → 506c. All five pass the
issue validator.

**Files:**
- `assets/feldowinn/design-questions.lua`: 9 open design questions over 9
  pieces; the shield is weighted low.
- `src/tools/feldowinn/profiles.lua`, with its `.info.md`: the profile rules.
  - A question is settled when one answer leads with at least 3 net votes and a
    2-vote margin.
  - Each profile explores 1–2 questions, favouring unsettled ones.
  - Its other answers usually repeat the current leader. Each downvote on a
    design that repeated the leader lowers that chance by 0.1, from 0.85 down to
    a floor of 0.2.
- `scripts/generate-feldowinn-profiles`: writes
  `assets/feldowinn/profiles/round-NNN.lua`. Round 1 is made (24 profiles, seed
  1). It reads `assets/feldowinn/votes.tsv`, and a malformed line stops it with
  the line named.
- `assets/feldowinn/comfyui/`: `concept.json` (text to image with
  Dreamshaper-8), `concept-scribble.json` (the same, steered by a sketch through
  the installed scribble ControlNet), `to-3d.json` (ComfyUI's built-in
  Hunyuan3D-2 nodes; no add-on nodes needed), and a `README.md`.
  - IP-Adapter isn't used: the weights are installed, but stock ComfyUI has no
    nodes for it.
- `scripts/feldowinn-comfy-submit`: fills a workflow from a profile, sends it to
  ComfyUI's `/prompt`, waits on `/history`, and appends prompt, seed and
  workflow fingerprint to `assets/feldowinn/generated.tsv`. Running out of time
  is reported as a failure.
- `scripts/generate-feldowinn-gallery` and
  `scripts/templates/feldowinn-gallery.html`: build
  `docs/HTML/feldowinn-gallery.html`, plus
  `docs/HTML/feldowinn/publish-files.txt` listing the picture copies to publish.
- `scripts/test-feldowinn`: the test.
- `docs/table-of-contents.md` has the new entries. The files written through
  scripts are claimed.

**Output folder hookup and the seam for later stages:**
- ComfyUI's output is `/mnt/kaun/stable-diffusion/output` (its config's
  `output-directory`).
- Every generated file for a design goes in one folder,
  `output/feldowinn/<design id>/`: concept views as `view_*.png`, meshes as
  `model_*.glb`.
- The folder name alone ties each file to its design, so pictures made by hand
  in ComfyUI with that prefix count too. Future multi-view, animation or
  game-model stages add their files to the same folder.
- The gallery copies each view as a 480-pixel WebP and shows it on the card. A
  folder named for no design is reported.
- The published page can only show pictures published with it: 255 files and 64
  MB per version. Past that, the pictures should move to the page's
  uploaded-assets store.

**Votes:**
- One document per design, `votes/<id>` = `{vote: 1 | -1 | 0, ...}`: your
  current verdict, which can change over time, not a click count. The database
  docs forbid counting clicks with read-then-write updates, since writes are
  last-writer-wins.
- This allows one voter's verdict per design, so it's built for a single
  developer. Several voters would each overwrite the same verdict.
- Votes reach the generator through the page's export, or through Claude reading
  the `votes` collection.

**Tests:**
- `scripts/test-feldowinn`: 183 passed, 0 failed. It covers:
  - the settled and leader rules;
  - a settled question explored about 0.15 times as often as an open one;
  - the leader repeated about 0.89 of the time with no downvotes, and under 0.55
    after 6;
  - the same seed giving the same round;
  - both generators end to end in scratch, including a fake picture in a fake
    output folder;
  - every workflow node, input, link and placeholder checked against the
    installed ComfyUI's source, without running it.
- Two planted bugs (downvotes no longer lowering the leader's chance, and a
  mistyped workflow input) each failed the test, 4 failures, exit 1.
- The page was screenshotted once. Cards overflowing their columns were fixed,
  then it was published.
- The page's store was checked: the votes collection lists as reachable and
  empty.

**Untested, and how to test it:**
1. **Concept art (506b):** once ComfyUI serves on 127.0.0.1:8188, run
   `scripts/feldowinn-comfy-submit --profile e5b4e007 --workflow concept`.
   - Pass: `output/feldowinn/e5b4e007/view_00001_.png` exists, and
     `generated.tsv` has a line for it.
   - Run it again with the same seed: the image should be the same.
   - Then run `scripts/generate-feldowinn-gallery` and republish the page,
     adding each line of `publish-files.txt` to `files`. The picture should
     replace the sketch.
2. **Image to 3D (506c):** first put the Hunyuan3D-2 mini checkpoint in the
   checkpoints folder. Then check the 1080 Ti can run it:
   - Load the model alone and read the memory it reports. The 1080 Ti has no
     bfloat16 and slow half precision, so ComfyUI runs these models in full
     precision, which doubles their memory; the full model may not fit in 11 GB.
   - Run `--workflow to-3d` with octree resolution 128.
   - Raise it toward 256 while it fits.
   - Pass: a `model_*.glb` appears beside the views and opens in a viewer.
3. **Live voting and export:** check these in the published page by clicking.
   This session couldn't click.

--------------------------------------------------------------------------------

