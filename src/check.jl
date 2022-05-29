# Defines functions to check invariants for interactive, argument
# validation and testing use cases.


"""
    check_bool(invariant, ctx) -> true|false

Check whether an invariant holds in context `ctx`, returning a `Bool`.
"""
check_bool(invariant, input) = isnothing(satisfies(invariant, input))


function check(invariant, input)
    res = satisfies(invariant, input)
    return CheckResult(invariant, res)
end



"""
    check_throw(invariant, input)

Check an invariant and provide a detailed error message if it
does not pass. If it passes, return `nothing`.
Use in tests in combination with `@test_nowarn`.
"""
function check_throw(invariant, input)
    res = satisfies(invariant, input)
    isnothing(res) && return
    throw(InvariantException(invariant, res))
end


struct CheckResult{I, R}
    invariant::I
    result::R
end

function Base.show(io::IO, checkres::CheckResult{<:I, Nothing}) where I
    print(io, "\e[32m✔ Invariant satisfied:\e[0m ")
    showtitle(io, checkres.invariant)
end

function Base.show(io::IO, checkres::CheckResult)
    print(io, "\e[1m\e[31m⨯ Invariant not satisfied:\e[0m\e[1m ")
    showtitle(io, checkres.invariant); print(io, "\e[22m\n")
    errormessage(io, checkres.invariant, checkres.result)
end
