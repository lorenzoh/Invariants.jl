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
- [`validate`](#)`(::I, input)::Bool`: Check whether an `input`
    is valid for the invariant.
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
function validate end

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
AbstractTrees.printnode(io::IO, inv::AbstractInvariant) = print(io, nameof(typeof(inv)), "(\"", md(title(inv)), "\")")
AbstractTrees.children(::AbstractInvariant) = ()


# ## Basic invariant

Base.@kwdef struct Invariant <: AbstractInvariant
    fn
    title::String
    description::Union{Nothing, String} = nothing
    validate = _ -> true
    inputfn = identity
end


Invariant(fn, title::String; description = nothing, validate = _ -> true, inputfn = identity) =
    Invariant(; fn, title, description, validate, inputfn)


"""
    invariant(fn, title; description, validate, inputfn)

Create an invariant with name `title` that checks an input against
`fn` which returns either `nothing` when the invariant is satisfied,
or an error message when the invariant is violated.

    invariant(inv; title, description, validate, inputfn)

Wrap an invariant `inv`, replacing some of its attributes with the
given keyword arguments.

    invariant(invs, title, combine = :all; description)

Combine multiple invariants `invs` logically. The type of composition dependsBy default, all invariants must be
on the third argument:

- `:all` (default): All invariants must be satisfied (see [`AllInvariant`](#))
- `:any`: At least one invariant must be satisfied (see [`AnyInvariant`](#))
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
check_bool(inv, -1), check_bool(inv, 1)
```

Throw an error when an invariant is not satisfied:

{cell}
```julia
check_throw(inv, 1)
```
"""
invariant(fn, title::String; kwargs...) = Invariant(fn, title; kwargs...)


invariant(invariants::AbstractVector, title::String, combine = :all; kwargs...) = _invariants(invariants, title, Val(combine); kwargs...)


_invariants(invariants, title, ::Val{:all}; kwargs...) = AllInvariant(invariants, title; kwargs...)
_invariants(invariants, title, ::Val{:any}; kwargs...) = AnyInvariant(invariants, title; kwargs...)
_invariants(invariants, title, ::Val{:seq}; kwargs...) = SequenceInvariant(invariants, title; kwargs...)


title(inv::Invariant) = inv.title
description(inv::Invariant) = inv.description
validate(inv::Invariant, input) = inv.validate(inv.inputfn(input))
satisfies(inv::Invariant, input) = inv.fn(inv.inputfn(input))

##

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
    @test_nowarn validate(inv, input)
    @test_nowarn satisfies(inv, input)
end

function exampleinvariant(symbol = :n)
    return Invariant("`$symbol` is positive",
        description = "The number `$symbol` should be larger than `0`.") do x
        if !(x isa Number)
            return "`$symbol` has type $(typeof(x)), but it should be a `Number` type."
        else
            x > 0 && return nothing
            return "`$symbol` is not a positive number, got value `$x`. Please pass a number larger than 0."
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
