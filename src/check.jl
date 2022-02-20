# Defines functions to check invariants for interactive, argument
# validation and testing use cases.


"""
    check(invariant, ctx) -> true|false

Check whether an invariant holds in context `ctx`, returning a `Bool`.
"""
check(invariant, ctx) = checkinvariant(invariant, ctx)[1]



"""
    check_error(invariant, ctx)

Check an invariant and provide a detailed error message if it
does not pass. If it passes, return `nothing`.
Use in tests in combination with `@test_nowarn`.
"""
function check_error(invariant, ctx)
    passed, errorctx = checkinvariant(invariant, ctx)
    passed && return
    msg = errormessage(invariant, ctx, errorctx)
    throw(InvariantException(invariant, msg))
end

function errormessage(inv::Invariant, ctx, errorctx)
    io = IOBuffer()
    ioctx = IOContext(io, :color => true)
    printerror(ioctx, inv, ctx, errorctx)
    return String(take!(io))
end
