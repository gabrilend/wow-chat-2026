# 328 - Wimmelbilder Embedding Artwork

## Status
- Created: 2026-04-08
- Phase: 3
- Priority: Low (depends on 327)
- Depends: 327-html-source-tree-export

## Current Behavior

Issue 327's MVP produces HTML pages with source code display. The layout has empty margins - wasted visual real estate. No visual interest beyond syntax highlighting.

## Intended Behavior

Each source file gets procedurally generated i-spy/wimmelbilder artwork in the margins:

1. **Embedding-based generation** - Artwork seeded from word embeddings of file contents
2. **Infinite canvas** - User can scroll/pan around the artwork
3. **Zoom coherence** - As user zooms out, artwork scales to fill viewport
4. **Display ratio variations** - Pre-generated for common aspect ratios (16:9, 21:9, 4:3)
5. **i-spy elements** - Hidden objects to find, themed to the code's domain

### Visual Concept

```
+------------------------------------------------------------------+
|  [wimmelbilder left]  |   Source Code   |  [wimmelbilder right]  |
|                       |                 |                        |
|   tiny robot hiding   |  function x()   |   gears and cogs       |
|   in pixel forest     |    local y = 1  |   hidden in machinery  |
|                       |    return y     |                        |
|   (can you find the   |  end            |   (find the 7 screws)  |
|    3 lua logos?)      |                 |                        |
|                       |                 |                        |
|   scroll to explore   |                 |   pan to discover      |
+------------------------------------------------------------------+
```

### Zoom Behavior

```
Zoomed in (100%):
  Code fills center, artwork in margins

Zoomed out (50%):
  Code smaller, more artwork visible
  Artwork "grows" to fill black bars

Zoomed way out (10%):
  Code is tiny center element
  Artwork dominates, full panorama visible
  i-spy game becomes primary experience
```

## User Feedback Requested

### 1. Embedding Source
- Use word2vec/GloVe embeddings of file tokens?
- Use code2vec (code-specific embeddings)?
- Simple bag-of-words frequency → color palette?

### 2. Art Style
- Pixel art (easier to generate, retro aesthetic)?
- Illustrated (Waldo/wimmelbilder style, needs more capability)?
- Abstract (shapes/patterns from embeddings, most feasible)?
- Mix per-file based on content type (lua vs markdown)?

### 3. Generation Pipeline
- Pre-generate all artwork at export time?
- Generate on-demand as user navigates?
- Hybrid (thumbnails pre-gen, full-res on demand)?

### 4. i-spy Integration
- Purely decorative (no game)?
- Actual findable items with checklist?
- Items themed to file content (find the "function" keyword)?

### 5. Hosting Considerations
- Images inline as base64 (large but self-contained)?
- Separate image directory (smaller HTML, needs server)?
- Lazy loading with placeholders?

## Suggested Implementation

### Phase 1: Embedding Pipeline

```lua
-- {{{ extract_file_embeddings
-- Tokenize source file, compute embedding vector
-- Returns normalized vector for art generation seed
local function extract_file_embeddings(file_path)
```

Options:
- Simple: Hash file contents → seed for RNG → colors/shapes
- Medium: Token frequency → weighted color palette
- Complex: word2vec embeddings → high-dimensional seed

Start simple. Complexity can come later.

### Phase 2: Procedural Art Generator

```lua
-- {{{ generate_margin_art
-- Given embedding vector, produce SVG or canvas instructions
-- Returns art definition (not pixels)
local function generate_margin_art(embedding, width, height, style)
```

Generation approaches:
- L-systems for organic patterns
- Voronoi diagrams for cellular structures
- Perlin noise landscapes
- Geometric tiling patterns
- Combination based on embedding values

### Phase 3: JavaScript Canvas Renderer

```javascript
// {{{ InfiniteCanvas
// Handle pan, zoom, render artwork at appropriate detail level
class InfiniteCanvas {
    constructor(container, artDefinition) { ... }

    pan(dx, dy) { ... }
    zoom(factor, centerX, centerY) { ... }
    render() { ... }
}
// }}}
```

Key behaviors:
- Level-of-detail: render less detail when zoomed out
- Chunked rendering: only draw visible portions
- Smooth transitions: ease zoom/pan animations

### Phase 4: Display Ratio Variants

Pre-generate artwork for common ratios:
```
pngs/generated/
  ambush.lua/
    16-9.png   (1920x1080, 3840x2160)
    21-9.png   (2560x1080, 5120x2160)
    4-3.png    (1600x1200, 3200x2400)
    1-1.png    (1080x1080, 2160x2160)
```

Or: single oversized canvas, crop to viewport at runtime.

### Phase 5: i-spy Game Layer

```lua
-- {{{ generate_hidden_items
-- Place findable items in artwork based on file content
-- Returns item list with positions and hints
local function generate_hidden_items(embedding, art_definition, file_tokens)
```

Item types:
- Keywords from the file (literal "function" text hidden in art)
- Thematic objects (gears for machinery code, trees for pathfinding)
- Universal items (3 lua moons in every image)

## Files to Create

- `src/tools/html-export/embeddings.lua` - Embedding extraction
- `src/tools/html-export/art-generator.lua` - Procedural art
- `src/tools/html-export/assets/infinite-canvas.js` - Pan/zoom handler
- `src/tools/html-export/templates/artwork-page.html` - Page with canvas
- `scripts/generate-artwork` - Batch art generation

## Technical Considerations

### Performance
- Canvas rendering must be 60fps for smooth pan/zoom
- Pre-render to off-screen canvas, composite for display
- Use requestAnimationFrame, not setInterval

### File Size
- SVG for vector art (scales perfectly, small files)
- PNG for raster (more detail, larger files)
- WebP for best compression
- Consider: ship SVG, render to canvas at display time

### Accessibility
- Alt text describing artwork theme
- Skip-to-content link for screen readers
- Keyboard navigation for pan/zoom

## Acceptance Criteria

1. Each HTML page has artwork in margins
2. Artwork is deterministic (same file → same art)
3. Pan/zoom works smoothly on desktop browsers
4. Artwork responds to viewport resize
5. At least 3 i-spy items per page
6. Art style is visually cohesive across pages

## Notes

The wimmelbilder serves multiple purposes:

1. **Aesthetic** - Makes the documentation feel crafted, not generated
2. **Exploration** - Encourages lingering, finding hidden things
3. **Memory** - Visual association helps remember which file is which
4. **Delight** - Surprise elements reward thorough readers

"Sorta like i-spy backgrounds, but with artwork generated based on the embedding values."

The embedding connection is key: files about similar topics should have similar art palettes. The art becomes a visual clustering of the codebase.

## Questions for Implementation

When ready to implement:

1. What embedding model is available locally? (word2vec, fasttext, none?)
2. What image generation tools are available? (PIL, ImageMagick, custom?)
3. Target browsers? (Canvas API support, WebGL for performance?)
4. Acceptable page load time? (affects pre-gen vs on-demand decision)

These answers shape whether we go simple (hash-based colors) or complex (neural embeddings).
