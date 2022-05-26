# Implements Markdown-enabled errors and an indentation IO wrapper


abstract type MarkdownException <: Exception end


errormessage(e::MarkdownException) = e.msg


struct InvariantException <: MarkdownException
    invariant::AbstractInvariant
    msg
end


function Base.showerror(io::IO, e::InvariantException)
    println(io, "Invariant violated!")
    println(io, errormessage(e.invariant, e.msg))
end


# Helpers for printing Markdown

md(str::String, io::IO) = md(
    str;
    color = get(io, :color, false),
    displaysize = get(io, :displaysize, (88, 500)),
)


# TODO: insert line breaks to break up words
function md(str::String; color = true, displaysize = (88, 500))
    md = Markdown.parse(str)
    io = IOBuffer()
    display(TextDisplay(IOContext(io, :color => color, :displaysize => displaysize)), md)
    res = strip(String(take!(io)))
    res = replace(res, "  " => "", "\n\n\n" => "\n\n")
    return res
end


# `IO` wrapper to write indented text.

mutable struct WrapIO{I<:IO} <: IO
    io::I
    width::Int
    indent::String
    indentfirst::Bool
end

WrapIO(io; width = displaysize(io)[2], indent = "", indentfirst=true) =
    WrapIO(io, width, indent, indentfirst)

WrapIO(io::WrapIO; width = displaysize(io)[2], indent = "", indentfirst=true) =
    WrapIO(io.io, min(width, io.width), io.indent * indent, indentfirst)

Base.get(io::WrapIO, k, v) = get(io.io, k, v)

function Base.write(io::WrapIO, x::String)
    isempty(x) && return
    #=if x == "\n"
        if io.indentfirst
            write(io.io, io.indent)
        end
        write(io.io, '\n')
        io.indentfirst = true
        return
    end=#
    lines = split(x, '\n')
    lines = isempty(lines) ? [""] : lines
    #=
    if length(lines) == 1
        @show only(lines)
        if io.indentfirst
            write(io.io, io.indent)
            io.indentfirst = false
        end
        write(io.io, only(lines))
        return
    end
    =#


    for (i, line) in enumerate(lines)
        if isempty(line)
            if io.indentfirst
                write(io.io, io.indent)
            end
            write(io.io, '\n')
            io.indentfirst=true
        else
            if isempty(strip(line))
                if io.indentfirst
                    write(io.io, io.indent)
                end
                write(io.io, line)
                io.indentfirst=false
            else
                wrappedline = wrap(line, width = io.width,
                    initial_indent=(io.indentfirst || i > 1) ? io.indent : "",
                    subsequent_indent=io.indent, replace_whitespace=false)
                write(io.io, wrappedline)
                io.indentfirst=false
            end

            if i != length(lines)
                write(io.io, '\n')
                io.indentfirst = true
            else
                io.indentfirst= isempty(line)
            end
        end
    end
end


function Base.write(io::WrapIO, b::UInt8)
    write(io.io, b)
end

@testset "WrapIO" begin
    function printwrapped(x; indentfirst=true, kwargs...)
        buf = IOBuffer()
        io = WrapIO(buf; indentfirst, kwargs...)
        print(io, x)
        String(take!(buf))
    end
    @test printwrapped("hello", indent = "  ") == "  hello"
    @test printwrapped("hello", indent = "  ") == "  hello"
    @test printwrapped("aaaa\nbbbb", width = 2) == "aa\naa\nbb\nbb"
    @testset "Composition" begin
        buf = IOBuffer()
        io = WrapIO(WrapIO(buf, indent = "  "), indent = "  ")
        @test io isa WrapIO
        @test io.io isa IOBuffer
        @test io.indent == "    "

    end

    @test printwrapped("\naaaa\nbbbb", width = 2) == "\naa\naa\nbb\nbb"
    @test printwrapped("\naa\nbb", width = 2, indent = " ") == "\n a\n a\n b\n b"
    @test printwrapped("\n a\nbb", width = 2, indent = " ") == "\n  \n a\n b\n b"
end

mutable struct IndentIO{I<:IO} <: IO
    io::I
    prefix::String
    indented::Bool
end

Base.get(io::IndentIO, k, v) = get(io.io, k, v)

IndentIO(io, n::Int; indentfirst = true) = IndentIO(io, repeat(' ', n), !indentfirst)
IndentIO(iio::IndentIO, prefix::String, indented::Bool) = IndentIO(iio.io, iio.prefix * prefix, iio.indented)

Base.show(io::IO, iio::IndentIO) = print(io, "IndentIO(", iio.io, ", \"", iio.prefix, "\")")

function Base.write(io::IndentIO, b::UInt8)
    write(io.io, b)
    return

    if !io.indented
        write(io.io, io.prefix)
        io.indented = true
    end
    write(io.io, b)
    if b == 0x0a # '\n'
        io.indented = false
    end
end

function Base.write(io::IndentIO, x::String)
    write(io.io, wrap(x; subsequent_indent=io.prefix, replace_whitespace=false))
    return
    for b in codeunits(x)
        write(io, b)
    end
end

Base.take!(io::IndentIO) = take!(io.io)


@testset "IndentIO" begin
    io = IndentIO(IOBuffer(), 2)
    write(io, "hello")
    @test String(take!(io)) == "  hello"

    io = IndentIO(IOBuffer(), 2)
    write(io, "hello\nworld")
    @test String(take!(io)) == "  hello\n  world"

    io = IndentIO(IOBuffer(), 2, indentfirst=false)
    write(io, "hello\nworld")
    @test String(take!(io)) == "hello\n  world"

    io = IndentIO(IndentIO(IOBuffer(), 2), 2)
    write(io, "hello\nworld")
    @test String(take!(io)) == "    hello\n    world"
end


mutable struct LimitLineLengthIO{I<:IO} <: IO
    io::I
    maxlength::Int
    length::Int
end

LimitLineLengthIO(io, l) = LimitLineLengthIO(io, l, 0)

LimitLineLengthIO(ll::LimitLineLengthIO, l) = LimitLineLengthIO(ll.io, min(l, ll.maxlength), ll.length)
function LimitLineLengthIO(iio::IndentIO, maxlength)
    prefixsize = length(__cleaned(IOBuffer(), iio.prefix))
    if prefixsize >= maxlength
        throw(ArgumentError("Not enough space to print indent and content"))
    end
    LimitLineLengthIO(iio, maxlength - prefixsize, 0)
end
IndentIO(ll::LimitLineLengthIO, prefix::String, indented::Bool) = LimitLineLengthIO(
    IndentIO(ll.io, prefix, indented), ll.maxlength)
Base.show(io::IO, ll::LimitLineLengthIO) = print(io, "LimitLineLengthIO(", ll.io, ", ", ll.maxlength, ")")

function Base.write(io::LimitLineLengthIO, c::Char)
    if c == '\n'
        io.length = 0
    end
    write(io.io, c)
end

function Base.write(io::LimitLineLengthIO, b::UInt8)
    if b == 0x0a
        io.length = 0
    end
    write(io.io, b)
end

function Base.write(io::LimitLineLengthIO, str::String)
    write(io.io, wrap(str; width = io.maxlength, replace_whitespace=false))
    return
    space = io.maxlength - io.length
    #str = "$space$str"
    lasti, w, rest = __takestringwidth(str, space)
    @show str, space, lasti, w, rest
    if lasti == 0
        write(io.io, '\n')
        io.length = 0
        write(io, rest)
    else
        chars = w == space ? collect(str) : str
        for (i, c) in enumerate(chars)
            write(io, c)
            i == lasti && break
        end
        io.length += w
        if w == space
            if length(chars) > lasti
                write(io.io, '\n')
                io.length = 0
                write(io, rest)
            end
        end
    end
end

Base.take!(io::LimitLineLengthIO) = take!(io.io)

Base.get(io::LimitLineLengthIO, k, v) = get(io.io, k, v)

##

function __takestringwidth(str::String, width::Int)
    w = 0
    bs = UInt8[]
    is = collect(eachindex(str))
    c = length(is)
    isempty(is) && return 0
    i = min(width, length(is))
    buf = IOBuffer()

    while true
        try
            cl = __cleaned(buf, str[1:i])
            n = length(cl)
            if n == width || i <= 0 || i >= c
                break
            else
                i += 1
            end
        catch e
            if e isa EOFError
                i += 3
            else
                rethrow()
            end
        end
    end
    # find any actual newline

    j = findfirst(==('\n'), str)
    rest = if !isnothing(j) && j <= i
        i = j-1
        str[j+1:end]
    else
        str[i+1:end]
    end
    return i, length(__cleaned(buf, str[1:i])), rest
end


function __cleaned(buf, str)
    print(buf, str)
    printer = PlainTextPrinter(buf)
    ret = repr("text/plain", printer, context = :color => false)
    take!(buf)
    return ret
end
