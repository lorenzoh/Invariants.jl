# Defines the abstract `Invariant` type and its interface

"""
    abstract type AbstractInvariant

An `Invariant` checks if an input satisfies some invariant.
For example, it may check whether a number is positive.

The interface of `Invariant`s is designed so that

- the invariant can be checked, given some input
- invariants can be composed to generate more complicated
    invariants
- the creation of rich error messages is possible when an
    invariant is not satisfied.

## Interface

An `Invariant` `I` must implement the following methods:

- [`title`](#)`(::I)::String`: Descriptive name for the invariant
- [`description`](#)`(::I)::String`: A longer description of the invariant,
    giving explanation and pointing to related information.
- [`satisfies`](#)`(::I, input) -> (nothing | msg)`: Check whether an `input`
    satisfies the invariant, returning either `nothing` on success
    or an error message.
"""
abstract type AbstractInvariant end

"""
    title(invariant)

Short summary of an invariant. Is used as a title in reports and error
messages
"""
function title end

"""
    description(invariant, ctx) -> Renderable

Give a more detailed description of an invariant, taking into
account the context `ctx`.
"""
description(::AbstractInvariant) = nothing
function satisfies end

function errormessage(inv::AbstractInvariant, msg)
    buf = IOBuffer()
    errormessage(IOContext(buf, :color => true, :displaysize => (88, 500)), inv, msg)
    return String(take!(buf))
end

function errormessage(io::IO, inv::AbstractInvariant, msg)
    println(io)
    showdescription(io, inv)
    println(io, msg)
end

Base.show(io::IO, inv::AbstractInvariant) = AbstractTrees.print_tree(io, inv)
function AbstractTrees.printnode(io::IO, inv::AbstractInvariant)
    print(io, nameof(typeof(inv)), "(\"", md(title(inv)), "\")")
end
AbstractTrees.children(::AbstractInvariant) = ()

# ## Basic invariant

Base.@kwdef struct Invariant <: AbstractInvariant
    fn::Any
    title::String
    description::Union{Nothing, String} = nothing
    inputfn = identity
end

function Invariant(fn, title::String; description = nothing, inputfn = identity)
    Invariant(; fn, title, description, inputfn)
end

"""
    invariant(fn, title; description, inputfn)

Create an invariant with name `title` that checks an input against
`fn` which returns either `nothing` when the invariant is satisfied,
or an error message when the invariant is violated.

    invariant(inv; title, description, inputfn)

Wrap an invariant `inv`, replacing some of its attributes with the
given keyword arguments.

    invariant(invs, title, combine = :all; description)

Combine multiple invariants `invs` logically. The type of composition dependsBy default, all invariants must be
on the third argument:

- `all` (default): All invariants must be satisfied (see [`AllInvariant`](#))
- `any`: At least one invariant must be satisfied (see [`AnyInvariant`](#))
satisfied. `

## Examples

Basic usage:

{cell}
```julia
using Invariants

inv = invariant("Is negative") do n
    n < 0 ? nothing : Invariants.md("`n` is not negative!")
end
```

Successful check:

{cell}
```julia
check(inv, -1)
```

Failing check:

{cell}
```julia
check(inv, 1)
```

Or just get a Bool:

{cell}
```julia
check(Bool, inv, -1), check(Bool, inv, 1)
```

Throw an error when an invariant is not satisfied:

{cell}
```julia
check_throw(inv, 1)
```
"""
invariant(fn, title::String; kwargs...) = Invariant(fn, title; kwargs...)

function invariant(title, invariants::AbstractVector{<:AbstractInvariant}; kwargs...)
    invariant(title, invariants, all; kwargs...)
end
function invariant(title, invariants::AbstractVector{<:AbstractInvariant},
                   ::typeof(all); kwargs...)
    AllInvariant(invariants, title; kwargs...)
end
function invariant(title, invariants::AbstractVector{<:AbstractInvariant},
                   ::typeof(any); kwargs...)
    AnyInvariant(invariants, title; kwargs...)
end

title(inv::Invariant) = inv.title
description(inv::Invariant) = inv.description
satisfies(inv::Invariant, input) = inv.fn(inv.inputfn(input))

function showdescription(io, inv)
    if !isnothing(description(inv))
        println(io, description(inv))
    end
end

function showtitle(io, inv)
    print(io, md(title(inv), io))
end

function testinvariant(inv, input)
    @test_nowarn title(inv)
    @test_nowarn description(inv)
    @test_nowarn satisfies(inv, input)
end

function exampleinvariant(symbol = :n)
    return Invariant("`$symbol` is positive",
                     description = "The number `$symbol` should be larger than `0`." |> md) do x
        if !(x isa Number)
            return "`$symbol` has type $(typeof(x)), but it should be a `Number` type." |>
                   md
        else
            x > 0 && return nothing
            return "`$symbol` is not a positive number, got value `$x`. Please pass a number larger than 0." |>
                   md
        end
    end
end

@testset "Invariant" begin
    inv = exampleinvariant()
    testinvariant(inv, 1)

    @test isnothing(satisfies(inv, 1))
    @test occursin("should be", satisfies(inv, ""))
    @test occursin("larger", satisfies(inv, -1))
    @test occursin("0", description(inv))
end