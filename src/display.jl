# Implements Markdown-enabled errors and an indentation IO wrapper


abstract type MarkdownException <: Exception end


errormessage(e::MarkdownException) = e.msg

function Base.showerror(io::IO, e::MarkdownException)
    msg = errormessage(e)
    md = Markdown.parse(msg)
    display(TextDisplay(IOContext(io, :color => true)), md)
    print(io, "\n")
end


struct InvariantException <: MarkdownException
    invariant::Invariant
    msg
end

errormessage(e::InvariantException) = "Invariant violated: **$(name(e.invariant))**\n\n" * e.msg



mutable struct IndentIO{I<:IO} <: IO
    io::I
    prefix::String
    indented::Bool
end

Base.get(io::IndentIO, k, v) = get(io.io, k, v)

IndentIO(io, n::Int; indentfirst = true) = IndentIO(io, repeat(' ', n), !indentfirst)

function Base.write(io::IndentIO, c::Char)
    if !io.indented
        write(io.io, io.prefix)
        io.indented = true
    end
    write(io.io, c)
    if c == '\n'
        io.indented = false
    end
end

function Base.write(io::IndentIO, x::String)
    foreach(c -> write(io, c), x)
end
