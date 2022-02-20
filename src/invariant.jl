# Defines the abstract `Invariant` type and its interface


abstract type Invariant end



"""
    invariantname(invariant)

Short summary of what the invariant checks. Used as title in error
messages.
"""
function name end


"""
    checkinvariant(invariant, ctx) -> (passed, ctx)

Checks if an invariant passes given context variables `ctx`
(a named tuple).
"""
function checkinvariant end


"""
    printerror(io, invariant, ctx, errorctx)

Print error message explaining why an invariant did not pass. `errorctx` is
the updated context returned by `checkinvariant`.
"""
function printerror end


function printerror(::Type{String}, invariant, ctx, errorctx)
    io = IOBuffer()
    ioctx = IOContext(io, :color => true)
    printerror(ioctx, invariant, ctx, errorctx)
    return String(take!(io))
end


function Base.show(io::IO, inv::Invariant)
    print(typeof(inv), "(", name(inv), ")")
end
