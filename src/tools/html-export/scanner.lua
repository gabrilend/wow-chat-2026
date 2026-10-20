#!/usr/bin/env luajit

local M = {}


local function parse_gitignore(gitignore_path)
    local patterns = {}

    local handle = io.open(gitignore_path, "r")
    if not handle then return patterns end

    for line in handle:lines() do
        line = line:gsub("^%s+", ""):gsub("%s+$", "")

        if #line > 0 and not line:match("^#") then
            local pattern = line
                :gsub("%.", "%%.")
                :gsub("%*", ".*")
                :gsub("%?", ".")
                :gsub("/$", "")

            table.insert(patterns, pattern)
        end
    end

    handle:close()
    return patterns
end


local function matches_gitignore(path, patterns)
    for _, pattern in ipairs(patterns) do
        if path:match(pattern) then
            return true
        end
    end
    return false
end


local function get_file_info(filepath)
    local cmd = string.format("stat -c %%Y %q 2>/dev/null", filepath)
    local handle = io.popen(cmd)
    local mtime = 0
    if handle then
        local result = handle:read("*a"):gsub("%s+", "")
        handle:close()
        mtime = tonumber(result) or 0
    end

    cmd = string.format("stat -c %%s %q 2>/dev/null", filepath)
    handle = io.popen(cmd)
    local size = 0
    if handle then
        local result = handle:read("*a"):gsub("%s+", "")
        handle:close()
        size = tonumber(result) or 0
    end

    local ext = filepath:match("%.([^.]+)$")
    local file_type = ext or "unknown"

    local filename = filepath:match("([^/]+)$")

    return {
        path      = filepath,
        name      = filename,
        extension = ext,
        type      = file_type,
        size      = size,
        mtime     = mtime,
    }
end


local function scan_directory(root_dir, gitignore_patterns, include_dirs, exclude_patterns)
    local files = {}

    local exclude_args = {}
    for _, pattern in ipairs(exclude_patterns) do
        table.insert(exclude_args, string.format("-not -path '*/%s/*'", pattern))
    end

    local exclude_clause = ""
    if #exclude_args > 0 then
        exclude_clause = table.concat(exclude_args, " ")
    end

    for _, include_dir in ipairs(include_dirs) do
        local search_path = root_dir .. "/" .. include_dir

        local cmd = string.format(
            "find %q -type f %s 2>/dev/null",
            search_path,
            exclude_clause
        )

        local handle = io.popen(cmd)
        if handle then
            for filepath in handle:lines() do
                local rel_path = filepath:gsub("^" .. root_dir:gsub("([^%w])", "%%%1") .. "/", "")

                if not matches_gitignore(rel_path, gitignore_patterns) then
                    local info = get_file_info(filepath)
                    info.relative_path = rel_path
                    table.insert(files, info)
                end
            end
            handle:close()
        end
    end

    table.sort(files, function(a, b)
        return a.relative_path < b.relative_path
    end)

    return files
end


function M.scan_project(config)
    local root_dir        = config.root_dir or "."
    local gitignore_path  = config.gitignore_path or (root_dir .. "/.gitignore")
    local include_dirs    = config.include_dirs or { "src", "issues", "docs", "scripts" }
    local exclude_patterns = config.exclude_patterns or {
        "build",
        "build-beta",
        "build-release",
        "installed-files-beta",
        "installed-files-release",
        "config",
        "tmp",
        "mysql",
        "libs/boost",
        "modules",
        "source-beta",
        "source-release",
        "llm-transcripts",
        ".git",
    }

    local gitignore_patterns = parse_gitignore(gitignore_path)

    local all_patterns = {}
    for _, p in ipairs(gitignore_patterns) do
        table.insert(all_patterns, p)
    end
    for _, p in ipairs(exclude_patterns) do
        table.insert(all_patterns, p)
    end

    local files = scan_directory(root_dir, all_patterns, include_dirs, exclude_patterns)

    local stats = {
        total_files = #files,
        total_size  = 0,
        by_type     = {},
    }

    for _, file in ipairs(files) do
        stats.total_size = stats.total_size + file.size

        local ftype = file.type
        if not stats.by_type[ftype] then
            stats.by_type[ftype] = { count = 0, size = 0 }
        end
        stats.by_type[ftype].count = stats.by_type[ftype].count + 1
        stats.by_type[ftype].size  = stats.by_type[ftype].size + file.size
    end

    return {
        files = files,
        stats = stats,
    }
end


return M
