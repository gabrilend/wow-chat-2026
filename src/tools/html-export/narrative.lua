#!/usr/bin/env luajit

local M = {}


local function parse_issue_id(filename)
    local issue_id, descr = filename:match("^(%d+[a-z]?)%-(.+)%.md$")

    if not issue_id then
        return nil
    end

    local num_part = issue_id:match("^(%d+)")
    local phase = math.floor(tonumber(num_part) / 100)

    return {
        id = issue_id,
        phase = phase,
        description = descr:gsub("%-", " "),
    }
end


local function read_issue_title(filepath)
    local handle = io.open(filepath, "r")
    if not handle then return nil end

    for line in handle:lines() do
        local title = line:match("^#%s+(.+)$")
        if title then
            handle:close()
            return title:gsub("^%d+%s*%-?%s*", ""):gsub("^Issue%s+%d+:%s*", "")
        end
    end

    handle:close()
    return nil
end


local function scan_issues(issues_dir)
    local issues = {}

    local search_dirs = {
        issues_dir,
        issues_dir .. "/completed",
    }

    for _, search_dir in ipairs(search_dirs) do
        local cmd = string.format("find %q -maxdepth 1 -name '[0-9]*.md' -type f 2>/dev/null", search_dir)
        local handle = io.popen(cmd)

        if handle then
            for filepath in handle:lines() do
                local filename = filepath:match("([^/]+)$")
                local parsed = parse_issue_id(filename)

                if parsed then
                    local title = read_issue_title(filepath) or parsed.description
                    local is_completed = filepath:match("/completed/") ~= nil

                    table.insert(issues, {
                        id          = parsed.id,
                        phase       = parsed.phase,
                        title       = title,
                        description = parsed.description,
                        filepath    = filepath,
                        filename    = filename,
                        completed   = is_completed,
                    })
                end
            end
            handle:close()
        end
    end

    table.sort(issues, function(a, b)
        local a_num = tonumber(a.id:match("^(%d+)")) or 0
        local b_num = tonumber(b.id:match("^(%d+)")) or 0
        if a_num ~= b_num then
            return a_num < b_num
        end
        local a_suffix = a.id:match("^%d+([a-z]*)$") or ""
        local b_suffix = b.id:match("^%d+([a-z]*)$") or ""
        return a_suffix < b_suffix
    end)

    return issues
end


local function scan_phase_progress(issues_dir)
    local progress_files = {}

    local cmd = string.format("find %q -maxdepth 1 -name 'phase-*-progress.md' -type f 2>/dev/null", issues_dir)
    local handle = io.popen(cmd)

    if handle then
        for filepath in handle:lines() do
            local filename = filepath:match("([^/]+)$")
            local phase_num = filename:match("phase%-(%d+)%-progress%.md")

            if phase_num then
                table.insert(progress_files, {
                    phase = tonumber(phase_num),
                    filepath = filepath,
                    filename = filename,
                })
            end
        end
        handle:close()
    end

    table.sort(progress_files, function(a, b)
        return a.phase < b.phase
    end)

    return progress_files
end


local function group_issues_by_phase(issues)
    local by_phase = {}

    for _, issue in ipairs(issues) do
        local phase = issue.phase
        if not by_phase[phase] then
            by_phase[phase] = {}
        end
        table.insert(by_phase[phase], issue)
    end

    return by_phase
end


function M.build_narrative(root_dir)
    local issues_dir = root_dir .. "/issues"

    local issues = scan_issues(issues_dir)

    local phases = scan_phase_progress(issues_dir)

    local by_phase = group_issues_by_phase(issues)

    return {
        issues   = issues,
        phases   = phases,
        by_phase = by_phase,
    }
end


function M.find_issue_references(issue_filepath, root_dir)
    local references = {}

    local handle = io.open(issue_filepath, "r")
    if not handle then return references end

    local content = handle:read("*a")
    handle:close()

    for path in content:gmatch("([%w/-]+%.[%w]+)") do
        if path:match("^src/") or path:match("^issues/") or path:match("^docs/") then
            table.insert(references, path)
        end
    end

    return references
end


function M.generate_phase_toc(phase_num, issues)
    local lines = {}

    table.insert(lines, string.format('<h3>Phase %d Issues</h3>', phase_num))
    table.insert(lines, '<ul class="issue-list">')

    for _, issue in ipairs(issues) do
        local status_class = issue.completed and "completed" or "active"
        local status_icon  = issue.completed and "✅" or "⏳"

        table.insert(lines, string.format(
            '  <li class="%s"><span class="status">%s</span> <a href="issues/%s.html">%s - %s</a></li>',
            status_class,
            status_icon,
            issue.id,
            issue.id,
            issue.title
        ))
    end

    table.insert(lines, '</ul>')

    return table.concat(lines, "\n")
end


return M
