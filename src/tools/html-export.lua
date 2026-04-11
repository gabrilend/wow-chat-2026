#!/usr/bin/env luajit
-- html-export.lua - Main HTML export orchestrator
--
-- Generates a static HTML site from project source tree, including:
-- - Directory navigation
-- - Syntax-highlighted source code
-- - Issue files as narrative
-- - Phase progress tracking

-- {{{ DIR Configuration
local DIR = "/mnt/mtwo/games/azeroth-core/wow-chat-2026"

if arg[1] and arg[1]:match("^%-%-dir=") then
    DIR = arg[1]:gsub("^%-%-dir=", "")
    table.remove(arg, 1)
end
-- }}}


-- {{{ Load modules
local scanner   = require("html-export.scanner")
local renderer  = require("html-export.renderer")
local narrative = require("html-export.narrative")
-- }}}


-- {{{ Utility functions

-- {{{ read_file
local function read_file(path)
    local handle = io.open(path, "r")
    if not handle then return nil end
    local content = handle:read("*a")
    handle:close()
    return content
end
-- }}}

-- {{{ write_file
local function write_file(path, content)
    -- Ensure directory exists
    local dir = path:match("(.+)/[^/]+$")
    if dir then
        os.execute(string.format("mkdir -p %q", dir))
    end

    local handle = io.open(path, "w")
    if not handle then
        error("Could not write to: " .. path)
    end
    handle:write(content)
    handle:close()
end
-- }}}

-- {{{ template_replace
local function template_replace(template, replacements)
    local output = template
    for key, value in pairs(replacements) do
        -- Escape % in replacement value to prevent gsub capture issues
        local escaped = value:gsub("%%", "%%%%")
        output = output:gsub("{{" .. key .. "}}", escaped)
    end
    return output
end
-- }}}

-- {{{ format_bytes
local function format_bytes(bytes)
    if bytes < 1024 then
        return string.format("%d B", bytes)
    elseif bytes < 1024 * 1024 then
        return string.format("%.1f KB", bytes / 1024)
    else
        return string.format("%.1f MB", bytes / (1024 * 1024))
    end
end
-- }}}

-- {{{ format_date
local function format_date(timestamp)
    return os.date("%Y-%m-%d %H:%M", timestamp)
end
-- }}}

-- }}}


-- {{{ build_tree_html
-- Builds HTML for directory tree navigation
local function build_tree_html(files, root_dir)
    -- Group files by directory
    local tree = {}

    for _, file in ipairs(files) do
        local parts = {}
        for part in file.relative_path:gmatch("[^/]+") do
            table.insert(parts, part)
        end

        local current = tree
        for i = 1, #parts - 1 do
            local dir_name = parts[i]
            if not current[dir_name] then
                current[dir_name] = { _type = "directory", _children = {} }
            end
            current = current[dir_name]._children
        end

        local filename = parts[#parts]
        current[filename] = {
            _type = "file",
            _path = file.relative_path,
        }
    end

    -- Render tree recursively
    local function render_node(name, node, depth)
        local indent = string.rep("  ", depth)
        local lines = {}

        if node._type == "directory" then
            -- Collapse directories deeper than first level (depth >= 1)
            local is_collapsed = depth >= 1
            local icon = is_collapsed and "▶" or "▼"
            local collapsed_class = is_collapsed and " collapsed" or ""

            table.insert(lines, string.format(
                '%s<div class="tree-node directory"><span class="icon">%s</span> %s</div>',
                indent, icon, name
            ))
            table.insert(lines, string.format(
                '%s<div class="tree-children%s">',
                indent, collapsed_class
            ))

            -- Sort children: directories first, then files
            local children = {}
            for child_name, child_node in pairs(node._children) do
                table.insert(children, { name = child_name, node = child_node })
            end
            table.sort(children, function(a, b)
                if a.node._type == b.node._type then
                    return a.name < b.name
                end
                return a.node._type == "directory"
            end)

            for _, child in ipairs(children) do
                for _, line in ipairs(render_node(child.name, child.node, depth + 1)) do
                    table.insert(lines, line)
                end
            end

            table.insert(lines, indent .. '</div>')

        else
            -- File node - convert extension to .html, preserve directory structure
            local html_path = node._path
            -- Replace common extensions with .html
            html_path = html_path:gsub("%.lua$", ".html")
            html_path = html_path:gsub("%.md$", ".html")
            html_path = html_path:gsub("%.sh$", ".html")
            html_path = html_path:gsub("%.c$", ".html")
            html_path = html_path:gsub("%.h$", ".html")
            html_path = html_path:gsub("%.cpp$", ".html")
            html_path = html_path:gsub("%.sql$", ".html")
            html_path = html_path:gsub("%.conf$", ".html")
            html_path = html_path:gsub("%.json$", ".html")
            -- If no extension matched, add .html
            if not html_path:match("%.html$") then
                html_path = html_path .. ".html"
            end

            table.insert(lines, string.format(
                '%s<div class="tree-node file"><span class="icon">📄</span> <a href="%s">%s</a></div>',
                indent, html_path, name
            ))
        end

        return lines
    end

    -- Render root directories
    local output = {}
    local roots = {}
    for name, node in pairs(tree) do
        table.insert(roots, { name = name, node = node })
    end
    table.sort(roots, function(a, b)
        if a.node._type == b.node._type then
            return a.name < b.name
        end
        return a.node._type == "directory"
    end)

    for _, root in ipairs(roots) do
        for _, line in ipairs(render_node(root.name, root.node, 0)) do
            table.insert(output, line)
        end
    end

    return table.concat(output, "\n")
end
-- }}}


-- {{{ generate_index
-- Generates index.html
local function generate_index(config, scan_result, narrative_data, output_dir)
    local template_path = config.root_dir .. "/src/tools/html-export/templates/index.html"
    local template = read_file(template_path)
    if not template then
        error("Could not read index template: " .. template_path)
    end

    -- Build tree HTML
    local tree_html = build_tree_html(scan_result.files, config.root_dir)

    -- Build stats HTML
    local stats_lines = {}
    table.insert(stats_lines, string.format("<li>Total files: %d</li>", scan_result.stats.total_files))
    table.insert(stats_lines, string.format("<li>Total size: %s</li>", format_bytes(scan_result.stats.total_size)))
    table.insert(stats_lines, "<li>Issues: " .. #narrative_data.issues .. "</li>")
    table.insert(stats_lines, "<li>Phases: " .. #narrative_data.phases .. "</li>")

    local replacements = {
        PROJECT_NAME        = config.project_name,
        PROJECT_DESCRIPTION = config.project_description or "Source tree export",
        TREE_CONTENT        = tree_html,
        STATS_CONTENT       = table.concat(stats_lines, "\n                "),
        CUSTOM_CSS          = renderer.get_css(),
    }

    local html = template_replace(template, replacements)
    write_file(output_dir .. "/index.html", html)

    print("Generated: index.html")
end
-- }}}


-- {{{ generate_source_file
-- Generates HTML for a source file
local function generate_source_file(file, config, output_dir)
    local template_path = config.root_dir .. "/src/tools/html-export/templates/source-file.html"
    local template = read_file(template_path)
    if not template then
        error("Could not read source-file template: " .. template_path)
    end

    -- Read file content
    local content = read_file(file.path)
    if not content then
        content = "[Could not read file]"
    end

    -- Render content
    local rendered = renderer.render_file(file.path, content)

    -- Determine output path - replace extension with .html
    local rel_path = file.relative_path
    -- Remove common extensions and add .html
    rel_path = rel_path:gsub("%.lua$", ".html")
    rel_path = rel_path:gsub("%.md$", ".html")
    rel_path = rel_path:gsub("%.sh$", ".html")
    rel_path = rel_path:gsub("%.c$", ".html")
    rel_path = rel_path:gsub("%.h$", ".html")
    rel_path = rel_path:gsub("%.cpp$", ".html")
    rel_path = rel_path:gsub("%.sql$", ".html")
    rel_path = rel_path:gsub("%.conf$", ".html")
    rel_path = rel_path:gsub("%.json$", ".html")
    -- If no extension was replaced, add .html
    if not rel_path:match("%.html$") then
        rel_path = rel_path .. ".html"
    end
    local output_path = output_dir .. "/" .. rel_path

    local replacements = {
        PROJECT_NAME  = config.project_name,
        FILE_NAME     = file.name,
        FILE_PATH     = file.relative_path,
        FILE_TYPE     = file.type,
        FILE_SIZE     = tostring(file.size),
        FILE_MTIME    = format_date(file.mtime),
        FILE_CONTENT  = rendered,
        RELATED_LINKS = "",
        CUSTOM_CSS    = renderer.get_css(),
    }

    local html = template_replace(template, replacements)
    write_file(output_path, html)
end
-- }}}


-- {{{ generate_issue_file
-- Generates HTML for an issue file
local function generate_issue_file(issue, config, output_dir)
    local template_path = config.root_dir .. "/src/tools/html-export/templates/issue-file.html"
    local template = read_file(template_path)
    if not template then
        error("Could not read issue-file template: " .. template_path)
    end

    -- Read issue content
    local content = read_file(issue.filepath)
    if not content then
        content = "[Could not read issue file]"
    end

    -- Render markdown
    local rendered = renderer.render_file(issue.filepath, content)

    -- Determine output path
    local output_path = output_dir .. "/issues/" .. issue.id .. ".html"

    local status_text  = issue.completed and "✅ Completed" or "⏳ Active"
    local status_class = issue.completed and "completed" or "active"

    local replacements = {
        PROJECT_NAME  = config.project_name,
        ISSUE_ID      = issue.id,
        ISSUE_PHASE   = tostring(issue.phase),
        ISSUE_TITLE   = issue.title,
        ISSUE_CONTENT = rendered,
        STATUS_TEXT   = status_text,
        STATUS_CLASS  = status_class,
        CUSTOM_CSS    = renderer.get_css(),
    }

    local html = template_replace(template, replacements)
    write_file(output_path, html)
end
-- }}}


-- {{{ main
local function main()
    -- Parse arguments
    local root_dir   = arg[1] or DIR
    local output_dir = arg[2] or (root_dir .. "/output/html-export")

    print("HTML Export")
    print("===========")
    print("Root:   " .. root_dir)
    print("Output: " .. output_dir)
    print()

    -- Configuration
    local config = {
        root_dir            = root_dir,
        project_name        = root_dir:match("([^/]+)$") or "Project",
        project_description = "Everland Ghostsong - WoW private server source tree",
        gitignore_path      = root_dir .. "/.gitignore",
        include_dirs        = { "src", "issues", "docs", "scripts" },
    }

    -- Scan project
    print("Scanning project...")
    local scan_result = scanner.scan_project(config)
    print(string.format("  Found %d files (%s)",
        scan_result.stats.total_files,
        format_bytes(scan_result.stats.total_size)
    ))

    -- Build narrative
    print("Building narrative...")
    local narrative_data = narrative.build_narrative(root_dir)
    print(string.format("  Found %d issues across %d phases",
        #narrative_data.issues,
        #narrative_data.phases
    ))

    -- Generate output
    print("Generating HTML...")

    -- Index
    generate_index(config, scan_result, narrative_data, output_dir)

    -- Source files
    local source_count = 0
    for _, file in ipairs(scan_result.files) do
        if file.relative_path:match("^src/") or file.relative_path:match("^docs/") then
            generate_source_file(file, config, output_dir)
            source_count = source_count + 1
        end
    end
    print(string.format("  Generated %d source file pages", source_count))

    -- Issue files
    for _, issue in ipairs(narrative_data.issues) do
        generate_issue_file(issue, config, output_dir)
    end
    print(string.format("  Generated %d issue pages", #narrative_data.issues))

    print()
    print("Done!")
    print("View: file://" .. output_dir .. "/index.html")
end
-- }}}


-- Run
main()
