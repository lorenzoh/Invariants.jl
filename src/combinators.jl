# Implements invariants that combine other invariants
# - `AllInvariant` passes only if all child invariants are true
# - `AnyInvariant` passes only if any one child invariant is true
# - `SequenceInvariant` runs multiple invariants in an order and fails
#    early if one fails


abstract type InvariantList <: AbstractInvariant end

title(invs::InvariantList) = invs.title
description(invs::InvariantList) = invs.description
validate(invs::InvariantList, input) = all(map(inv -> validate(inv, input), invs.invariants))

AbstractTrees.children(invs::InvariantList) = invs.invariants

# ## AllInvariant

struct AllInvariant{I<:AbstractInvariant} <: InvariantList
    invariants::Vector{I}
    title::String
    description::Union{Nothing, String}
    shortcircuit::Bool
end

AllInvariant(
    invariants, title::String;
    description = nothing,
    shortcircuit = true,
    kwargs...
) = invariant(AllInvariant(invariants, title, description, shortcircuit); kwargs...)

# TODO: check for errors thrown and check invariants individually
# TODO: remove SequenceInvariant and add `shortcircuit` kwarg to `AllInvariant`

function satisfies(invs::AllInvariant, input)
    results = []
    keepchecking = true
    for inv in invs.invariants
        if !keepchecking
            push!(results, missing)
            continue
        else
            res = try
                satisfies(inv, input)
            catch e
                "Unexpected error while checking invariant: $e"
            end
            push!(results, res)
            if !isnothing(res) && invs.shortcircuit
                keepchecking = false
            end
        end

    end
    return all(isnothing, results) ? nothing : results
end


function errormessage(io::IO, invs::AllInvariant, msgs)
    __combinator_errormessage(io, invs, msgs, map(__getmarker, msgs),
        faint("All invariants listed below should be satisfied:\n\n "))
end

__getmarker(::Nothing) = PASS
__getmarker(::Missing) = UNKNOWN
__getmarker(_) = FAIL


# ## AnyInvariant

struct AnyInvariant{I<:AbstractInvariant} <: InvariantList
    invariants::Vector{I}
    title::String
    description::Union{Nothing, String}
end

AnyInvariant(
    invariants, title::String;
    description = nothing,
    kwargs...
) = invariant(AnyInvariant(invariants, title, description); kwargs...)


function satisfies(invs::AnyInvariant, input)
    results = []

    for inv in invs.invariants
        res = satisfies(inv, input)
        push!(results, res)
        if isnothing(res)
            return nothing
        end
    end
    return results
end


function errormessage(io::IO, invs::AnyInvariant, msgs)
    __combinator_errormessage(io, invs, msgs, map(m -> isnothing(m) ? PASS : FAIL, msgs),
        faint("At least one of the invariants listed below should be satisfied:\n\n"))
end

# ## Helpers for printing children

const PASS = "\e[32m✔\e[0m\e[2m"
const FAIL = "\e[31m⨯\e[0m"
const UNKNOWN = "\e[33m?\e[0m"

function __combinator_errormessage(io::IO, invs, msgs, markers, msg)
    showdescription(io, invs)
    print(io, msg)
    for (inv, message, marker) in zip(invs.invariants, msgs, markers)
        __errormessage_child(io, inv; marker, message)
    end
end

function __errormessage_child(
        io,
        inv;
        marker = "o",
        message=nothing,
        indent = "    "
        )
    print(io, marker, " ")
    showtitle(io, inv)
    print(io, "\e[0m")
    println(io)

    if !(isnothing(message) || ismissing(message))
        ioi = WrapIO(io; indent)
        errormessage(ioi, inv, message)
    end
end

@testset "Combinators" begin
    i = exampleinvariant()
    @test invariant([i, i], "test") isa AllInvariant
    @test invariant([i, i], "test", :all) isa AllInvariant
    @test invariant([i, i], "test", :any) isa AnyInvariant
end
