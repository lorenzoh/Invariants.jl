# This file defines `format_markdown`, a helper to turn Markdown strings
# into richly formatted text output.

struct AsMarkdown{T}
    s::T
end
AsMarkdown(am::AsMarkdown) = am

function Base.show(io::IO, md::AsMarkdown)
    print(io, __getmdstr(io, md))
end

function __getmdstr(io::IO, md::AsMarkdown)
    md = Markdown.parse(md.s)
    buf = IOBuffer()
    display(TextDisplay(IOContext(buf,
                                  :color => get(io, :color, false),
                                  :displaysize => get(io, :displaysize, (88, 500)))),
            md)
    res = strip(String(take!(buf)))
    # two calls so it doesn't crash on 1.6
    res = replace(res, "  " => "")
    res = replace(res, "\n\n\n" => "\n\n")
    return res
end

function Base.string(md::AsMarkdown)
    return __getmdstr(IOContext(IOBuffer(), :color => true, :displaysize => (88, 500)), md)
end

const format_markdown = AsMarkdown

default_format() = format_markdown
