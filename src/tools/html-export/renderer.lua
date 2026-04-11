#!/usr/bin/env luajit
-- renderer.lua - Syntax highlighting and content rendering for HTML export
--
-- Provides Lua-native syntax highlighting for code files and markdown
-- rendering. Simple pattern-based approach for MVP, can be enhanced later.

local M = {}


-- {{{ HTML escaping
local function escape_html(text)
    return text
        :gsub("&", "&amp;")
        :gsub("<", "&lt;")
        :gsub(">", "&gt;")
        :gsub('"', "&quot;")
        :gsub("'", "&#39;")
end
-- }}}


-- {{{ Lua syntax highlighting
local function highlight_lua(code)
    -- Keywords
    local keywords = {
        "and", "break", "do", "else", "elseif", "end", "false", "for",
        "function", "if", "in", "local", "nil", "not", "or", "repeat",
        "return", "then", "true", "until", "while", "goto"
    }

    local keyword_pattern = "\\b(" .. table.concat(keywords, "|") .. ")\\b"

    -- Escape HTML first
    local output = escape_html(code)

    -- Highlight comments
    output = output:gsub("(%-%-[^\n]*)", '<span class="comment">%1</span>')

    -- Highlight strings
    output = output:gsub('("([^"\\]|\\.)*")', '<span class="string">%1</span>')
    output = output:gsub("('([^'\\]|\\.)*')", '<span class="string">%1</span>')
    output = output:gsub("(%[%[.-%]%])", '<span class="string">%1</span>')

    -- Highlight numbers
    output = output:gsub("(%d+%.?%d*)", '<span class="number">%1</span>')

    -- Highlight keywords
    for _, kw in ipairs(keywords) do
        output = output:gsub("(%f[%a])" .. kw .. "(%f[^%a])", '%1<span class="keyword">' .. kw .. '</span>%2')
    end

    -- Highlight function names
    output = output:gsub("function%s+([%w_%.]+)", 'function <span class="function">%1</span>')

    return output
end
-- }}}


-- {{{ Markdown rendering (simple)
local function render_markdown(md_text)
    local output = escape_html(md_text)

    -- Headers
    output = output:gsub("\n#### ([^\n]+)", '\n<h4>%1</h4>')
    output = output:gsub("\n### ([^\n]+)", '\n<h3>%1</h3>')
    output = output:gsub("\n## ([^\n]+)", '\n<h2>%1</h2>')
    output = output:gsub("\n# ([^\n]+)", '\n<h1>%1</h1>')
    output = output:gsub("^#### ([^\n]+)", '<h4>%1</h4>')
    output = output:gsub("^### ([^\n]+)", '<h3>%1</h3>')
    output = output:gsub("^## ([^\n]+)", '<h2>%1</h2>')
    output = output:gsub("^# ([^\n]+)", '<h1>%1</h1>')

    -- Code blocks
    output = output:gsub("```lua\n(.-)\n```", function(code)
        return '<pre><code class="lua">' .. highlight_lua(code) .. '</code></pre>'
    end)
    output = output:gsub("```bash\n(.-)\n```", function(code)
        return '<pre><code class="bash">' .. escape_html(code) .. '</code></pre>'
    end)
    output = output:gsub("```\n(.-)\n```", function(code)
        return '<pre><code>' .. escape_html(code) .. '</code></pre>'
    end)

    -- Inline code
    output = output:gsub("`([^`]+)`", '<code>%1</code>')

    -- Bold
    output = output:gsub("%*%*([^%*]+)%*%*", '<strong>%1</strong>')

    -- Italic
    output = output:gsub("%*([^%*]+)%*", '<em>%1</em>')

    -- Links
    output = output:gsub("%[([^%]]+)%]%(([^%)]+)%)", '<a href="%2">%1</a>')

    -- Paragraphs (double newline)
    output = output:gsub("\n\n+", "</p>\n<p>")
    output = "<p>" .. output .. "</p>"

    return output
end
-- }}}


-- {{{ Detect file type
local function detect_file_type(filename)
    local ext = filename:match("%.([^.]+)$")

    local type_map = {
        lua  = "lua",
        md   = "markdown",
        sh   = "shell",
        bash = "shell",
        c    = "c",
        cpp  = "cpp",
        h    = "c",
        hpp  = "cpp",
        sql  = "sql",
        conf = "config",
        json = "json",
    }

    return type_map[ext] or "text"
end
-- }}}


-- {{{ M.render_file
-- Public API: Renders a file to HTML
-- Returns: HTML string with syntax highlighting
function M.render_file(filepath, content)
    local filename = filepath:match("([^/]+)$")
    local file_type = detect_file_type(filename)

    if file_type == "lua" then
        return '<pre><code class="lua">' .. highlight_lua(content) .. '</code></pre>'

    elseif file_type == "markdown" then
        return render_markdown(content)

    else
        -- Generic: escape HTML and wrap in pre
        return '<pre><code>' .. escape_html(content) .. '</code></pre>'
    end
end
-- }}}


-- {{{ M.render_line_numbers
-- Adds line numbers to rendered code
function M.render_line_numbers(html_content, start_line)
    start_line = start_line or 1

    local lines = {}
    local line_num = start_line

    for line in html_content:gmatch("([^\n]*)\n?") do
        if #line > 0 or html_content:sub(-1) == "\n" then
            table.insert(lines, string.format(
                '<span class="line-number">%4d</span> %s',
                line_num,
                line
            ))
            line_num = line_num + 1
        end
    end

    return table.concat(lines, "\n")
end
-- }}}


-- {{{ M.get_css
-- Returns CSS for syntax highlighting
function M.get_css()
    return [[
/* Syntax Highlighting */
.keyword  { color: #569cd6; font-weight: bold; }
.string   { color: #ce9178; }
.comment  { color: #6a9955; font-style: italic; }
.number   { color: #b5cea8; }
.function { color: #dcdcaa; font-weight: bold; }

.line-number {
    color: #858585;
    margin-right: 1em;
    user-select: none;
    display: inline-block;
    text-align: right;
    min-width: 3em;
}

pre {
    background: #1e1e1e;
    color: #d4d4d4;
    padding: 1em;
    border-radius: 4px;
    overflow-x: auto;
    font-family: 'Consolas', 'Monaco', 'Courier New', monospace;
    font-size: 14px;
    line-height: 1.5;
}

code {
    font-family: 'Consolas', 'Monaco', 'Courier New', monospace;
}

pre code {
    background: none;
    padding: 0;
}

/* Markdown styles */
h1, h2, h3, h4, h5, h6 {
    margin-top: 1.5em;
    margin-bottom: 0.5em;
    color: #333;
}

p {
    margin: 0.5em 0;
    line-height: 1.6;
}

a {
    color: #0366d6;
    text-decoration: none;
}

a:hover {
    text-decoration: underline;
}

strong {
    font-weight: bold;
}

em {
    font-style: italic;
}
]]
end
-- }}}


return M
