# 123 - HTML Source Tree Export

## Status
- Created: 2026-04-08
- Phase: 3
- Priority: Medium
- Related: 328-wimmelbilder-embedding-artwork (pending creation)

## Current Behavior

Project source exists only as raw files in the repository. To understand how the project was built:
- Read issue files manually via editor/terminal
- Navigate directory structure via `ls` or file browser
- No unified presentation layer
- No way to share the "story of construction" with others

LLM transcripts exist in `llm-transcripts/` but are not surfaced alongside the issues they implemented.

## Intended Behavior

A script generates a static HTML site from the project:

1. **Directory tree as navigation** - Collapsible folder structure
2. **Source code with syntax highlighting** - Each file becomes an HTML page
3. **Issues as narrative** - The `issues/` directory presented as a build journal
4. **Phase progress as chapters** - `phase-X-progress.md` files structure the narrative
5. **LLM transcripts as appendix** - "Here's the transcript if you don't believe me"
6. **Respects .gitignore** - No config files, build artifacts, or secrets

The output is a directory of static HTML that can be hosted anywhere (rmail, GitHub Pages, local `file://`).

### Visual Layout (MVP)

```
+------------------------------------------+
|  [Tree Nav]  |     Source Code Display   |
|              |                           |
|  issues/     |   -- ambush.lua --        |
|    phase-1/  |                           |
|    phase-2/  |   function spawn(...)     |
|    phase-3/  |       local x = ...       |
|  src/        |                           |
|    lua/      |                           |
|  docs/       |                           |
+------------------------------------------+
```

### Visual Layout (Future - Issue 328)

```
+------------------------------------------+
| [i-spy art] |   Source Code   | [i-spy] |
|   fills     |    Display      |  fills  |
|   black     |                 |  black  |
|   bars      |                 |  bars   |
|             |                 |         |
|  (based on  |                 | (scroll |
|  embeddings |                 |  to     |
|  of words   |                 |  find)  |
|  in file)   |                 |         |
+------------------------------------------+
```

## User Feedback Requested

Before implementation, clarification needed on:

### 1. Output Structure
- Single-page app with dynamic loading?
- Multi-page static site (one HTML per source file)?
- Both? (index.html as SPA, individual pages for direct linking)

### 2. Hosting Target
- rmail integration (how? embedded iframe? direct serve?)
- Self-contained offline viewing (all assets inline)?
- External CDN for syntax highlighting CSS/JS?

### 3. Narrative Priority
- Issues-first (build journal as main attraction, source as reference)?
- Source-first (code browser as main, issues as context)?
- Dual entry points?

### 4. Transcript Integration
- Full transcripts inline (large files)?
- Excerpts with links to full transcripts?
- Just line number references (e.g., "see llm-transcripts/session-042.md:1234")?

## Suggested Implementation

### Phase 1: Directory Scanner

```lua
-- {{{ scan_project_tree
-- Walk project directory, respect .gitignore, build file list
-- Returns table of { path, type, size, mtime }
local function scan_project_tree(root_dir)
```

Key behaviors:
- Parse `.gitignore` patterns
- Exclude: `build/`, `installed-files-*/`, `config/*/`, `tmp/`, `mysql/`
- Include: `src/`, `issues/`, `docs/`, `llm-transcripts/`, `scripts/`
- Sort: directories first, then files alphabetically

### Phase 2: Content Renderer

```lua
-- {{{ render_source_file
-- Read source file, apply syntax highlighting, wrap in HTML template
-- Returns HTML string
local function render_source_file(file_path, template)
```

Syntax highlighting options:
- Lua-native: pattern matching for keywords (simple, no deps)
- highlight.js: external library (prettier, heavier)
- Prism.js: external library (modular, popular)

Recommendation: Start with Lua-native for MVP, add JS library later for polish.

### Phase 3: Issue Narrative Builder

```lua
-- {{{ build_narrative_index
-- Parse phase-X-progress.md files to build chapter structure
-- Cross-reference issues to source files mentioned
-- Returns narrative tree with links
local function build_narrative_index(issues_dir)
```

Structure:
```
Phase 1: Foundation
  ├── 101-initial-setup.md → src/lua/init.lua
  ├── 102-ambush-system.md → src/lua/ambush.lua
  └── ...

Phase 2: Behaviors
  ├── 201-movement-refactor.md
  └── ...
```

### Phase 4: HTML Generator

```lua
-- {{{ generate_html_tree
-- Create output directory structure mirroring source
-- Generate index.html with tree navigation
-- Generate individual page per source file
local function generate_html_tree(file_list, narrative, output_dir)
```

Output structure:
```
output/
  index.html              -- navigation + landing
  issues/
    phase-1-progress.html
    101-initial-setup.html
    ...
  src/
    lua/
      ambush.html
      travel.html
      ...
  docs/
    ...
  llm-transcripts/
    ...
  assets/
    style.css
    tree.js               -- collapse/expand navigation
```

### Phase 5: Script Wrapper

```bash
#!/bin/bash
# scripts/export-html
# Export project source tree to static HTML site

DIR="${1:-/mnt/mtwo/games/azeroth-core/wow-chat-2026}"
OUTPUT="${2:-${DIR}/output/html-export}"

# Run Lua generator
lua "${DIR}/src/tools/html-export.lua" "${DIR}" "${OUTPUT}"

echo "Generated: ${OUTPUT}/index.html"
echo "View: firefox ${OUTPUT}/index.html"
```

## Files to Create

- `src/tools/html-export.lua` - Main generator script
- `src/tools/html-export/scanner.lua` - Directory walker
- `src/tools/html-export/renderer.lua` - Syntax highlighting
- `src/tools/html-export/narrative.lua` - Issue cross-referencer
- `src/tools/html-export/templates/` - HTML templates
- `scripts/export-html` - Bash wrapper

## Files to Reference

- `issues/phase-X-progress.md` - Chapter structure
- `.gitignore` - Exclusion patterns
- `llm-transcripts/` - Session transcripts

## Acceptance Criteria

1. `./scripts/export-html` produces `output/html-export/`
2. Opening `index.html` shows navigable tree
3. Clicking source file shows syntax-highlighted code
4. Issues directory is browsable
5. Phase progress files link to their issues
6. No gitignored files appear in output
7. Output can be served via `python -m http.server` or `file://`

## Future Enhancements (Issue 328)

The high-class version adds:
- AI-generated wimmelbilder artwork in margins
- Artwork generated from word embeddings of each file
- Infinite canvas scrolling (JavaScript)
- Zoom: i-spy image scales to match viewport
- Display ratio variations for different aspect ratios

This is a separate issue because:
- MVP provides immediate value (shareable project documentation)
- AI artwork requires embedding pipeline, image generation
- Canvas/zoom is significant JS complexity
- Can ship MVP while iterating on artwork

## Notes

The source code is not the interesting part. The interesting part is:
- How decisions were made (issues)
- What was tried (transcripts)
- How components connect (docs)

Code is just the residue of problem-solving. This tool surfaces the solving.

"Here's how we built the whole thing, and here's the transcript if you don't believe me."
