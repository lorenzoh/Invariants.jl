struct WithContext{I<:Invariant} <: Invariant
    contextfn
    invariant::I
end
name(inv::WithContext) = name(inv.invariant)

checkinvariant(inv::WithContext, ctx) =
    checkinvariant(inv.invariant, inv.contextfn(ctx))


printerror(io::IO, inv::WithContext, ctx, errorctx) =
    printerror(io, inv.invariant, inv.contextfn(ctx), errorctx)

##

struct WithMessage{I<:Invariant} <: Invariant
    message
    invariant::I
end
name(inv::WithMessage) = name(inv.invariant)

checkinvariant(inv::WithMessage, ctx) =
    checkinvariant(inv.invariant, ctx)


function printerror(io::IO, inv::WithMessage, ctx, errorctx)
    println(io, inv.message)
    println(io)
    printerror(io, inv.invariant, ctx, errorctx)
end
