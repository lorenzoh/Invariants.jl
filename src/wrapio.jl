
mutable struct WrapIO{I <: IO} <: IO
    io::I
    width::Int
    indent::String
    indentfirst::Bool
end

function WrapIO(io; width = displaysize(io)[2], indent = "", indentfirst = true)
    WrapIO(io, width, indent, indentfirst)
end

function WrapIO(io::WrapIO; width = displaysize(io)[2], indent = "", indentfirst = true)
    WrapIO(io.io, min(width, io.width), io.indent * indent, indentfirst)
end

Base.get(io::WrapIO, k, v) = get(io.io, k, v)

function Base.write(io::WrapIO, x::String)
    isempty(x) && return
    lines = split(x, '\n')
    lines = isempty(lines) ? [""] : lines

    for (i, line) in enumerate(lines)
        if isempty(line)
            if io.indentfirst
                write(io.io, io.indent)
            end
            write(io.io, '\n')
            io.indentfirst = true
        else
            if isempty(strip(line))
                if io.indentfirst
                    write(io.io, io.indent)
                end
                write(io.io, line)
                io.indentfirst = false
            else
                wrappedline = wrap(line, width = io.width,
                                   initial_indent = (io.indentfirst || i > 1) ? io.indent :
                                                    "",
                                   subsequent_indent = io.indent,
                                   replace_whitespace = false)
                write(io.io, wrappedline)
                io.indentfirst = false
            end

            if i != length(lines)
                write(io.io, '\n')
                io.indentfirst = true
            else
                io.indentfirst = isempty(line)
            end
        end
    end
end

function Base.write(io::WrapIO, b::UInt8)
    write(io.io, b)
end

@testset "WrapIO" begin
    function printwrapped(x; indentfirst = true, kwargs...)
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
    @test_broken printwrapped("\naa\nbb", width = 2, indent = " ") == "\n a\n a\n b\n b"
end
