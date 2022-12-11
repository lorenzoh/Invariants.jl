# This file defines the core interface for defining invariants.

"""
    abstract type AbstractInvariant

An `Invariant` checks if an input satisfies some invariant.
For example, it may check whether a number is positive.

For most use cases, using [`invariant`](#) to create an invariant
will suffice and implementing your own subtype of `AbstractInvariant`
will rarely be necessary.

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
    title(invariant) -> String

Short summary of an invariant. Is used as a title in reports and error
messages.

Part of the [`AbstractInvariant`](#) interface.
"""
function title end

"""
    description(invariant) -> String

Return a more detailed description of an invariant.

Part of the [`AbstractInvariant`](#) interface.
"""
description(::AbstractInvariant) = nothing

"""
    satisfies(invariant, input) -> nothing | errormessage

Check if `input` satisfies an `invariant`. If it does, return `nothing`.
Otherwise return an error message explaining why the invariant is violated.
"""
function satisfies end

# ## Defaults

function errormessage(inv::AbstractInvariant, msg)
    buf = IOBuffer()
    errormessage(IOContext(buf, :color => true, :displaysize => (88, 500)), inv, msg)
    return String(take!(buf))
end

function errormessage(io::IO, inv::AbstractInvariant, msg)
    println(io)
    showdescription(io, inv)
    println(io)
    println(io, msg)
end

function showdescription(io, inv)
    desc = description(inv)
    isnothing(desc) || print(io, description(inv))
end

function showtitle(io, inv)
    print(io, title(inv))
end
