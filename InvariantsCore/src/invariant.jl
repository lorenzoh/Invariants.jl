# This file defines `Invariant`, a default invariant that should be used
# in most cases to construct invariants.

"""
    struct Invariant(fn, title; kwargs...) <: AbstractInvariant

Default invariant type. Use [`invariant`](#) to construct invariants.
"""
Base.@kwdef struct Invariant <: AbstractInvariant
    fn::Any
    title::String
    description::Union{Nothing, String} = nothing
    inputfn = identity
    format = default_format()
end

function Invariant(fn, title::String; description = nothing, inputfn = identity,
                   format = default_format())
    Invariant(; fn, title, description, inputfn, format)
end

title(inv::Invariant) = inv.format(inv.title)
function description(inv::Invariant)
    isnothing(inv.description) ? nothing : inv.format(inv.description)
end
satisfies(inv::Invariant, input) = inv.fn(inv.inputfn(input))
