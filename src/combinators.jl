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
end

AllInvariant(
    invariants, title::String;
    description = nothing,
    kwargs...
) = invariant(AllInvariant(invariants, title, description); kwargs...)


function satisfies(invs::AllInvariant, input)
    results = [satisfies(inv, input) for inv in invs.invariants]
    return all(isnothing, results) ? nothing : results
end


function errormessage(io::IO, invs::AllInvariant, msgs)
    __combinator_errormessage(io, invs, msgs, map(m -> isnothing(m) ? PASS : FAIL, msgs),
        faint("All invariants listed below should be satisfied:\n\n "))
end


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

struct SequenceInvariant{I<:AbstractInvariant} <: InvariantList
    invariants::Vector{I}
    title::String
    description::Union{Nothing, String}
end

SequenceInvariant(
    invariants, title::String;
    description = nothing,
    kwargs...
) = invariant(SequenceInvariant(invariants, title, description); kwargs...)


function satisfies(invs::SequenceInvariant, input)
    results = []
    failed = false
    for inv in invs.invariants
        if failed
            push!(results, missing)
            continue
        else
            res = satisfies(inv, input)
            push!(results, res)
            if !isnothing(res)
                failed = true
            end
        end
    end
    return all(isnothing, results) ? nothing : results
end


function errormessage(io::IO, invs::SequenceInvariant, msgs)
    __combinator_errormessage(io, invs, msgs, map(__sequencemarker, msgs),
        faint("All of the invariants listed below should be satisfied:\n\n"))
end

__sequencemarker(::Nothing) = PASS
__sequencemarker(::Missing) = UNKNOWN
__sequencemarker(_) = FAIL

# ## Helpers for printing children

const PASS = "\e[32m✔\e[0m\e[2m"
const FAIL = "\e[31m⨯\e[0m"
const UNKNOWN = "\e[33m?\e[0m"

function __combinator_errormessage(io::IO, invs, msgs, markers, msg)
    n = length(msgs)
    nfailed = count(!isnothing, msgs)

    #showtitle(io, invs); println(io)
    showdescription(io, invs)

    print(io, msg)
    #println(io, md("`$nfailed / $n` invariants were not satisfied.", io), "\n")

    for (inv, message, marker) in zip(invs.invariants, msgs, markers)
        __errormessage_child(io, inv; marker, message)
    end
end

function __errormessage_child(
        io,
        inv;
        marker = "o",
        message=nothing,
        #indent = "  |  ",
        indent = "    "
        )
    print(io, marker, " ")
    #@show io
    showtitle(io, inv)
    print(io, "\e[0m")
    println(io)

    if !(isnothing(message) || ismissing(message))
        ioi = WrapIO(io; indent)
        #println(ioi)
        errormessage(ioi, inv, message)
        #println(io)
    end
end

@testset "Combinators" begin
    i = exampleinvariant()
    @test invariant([i, i], "test") isa AllInvariant
    @test invariant([i, i], "test", :all) isa AllInvariant
    @test invariant([i, i], "test", :any) isa AnyInvariant
end
