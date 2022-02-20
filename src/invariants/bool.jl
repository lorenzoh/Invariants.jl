# Invariant that checks a boolean condition

"""
    BooleanInvariant(fn, name, messagefn)

Invariant that checks a boolean condition `fn : ctx -> Bool`.
Error message is constructed from the context using
`messagefn : ctx -> String`.

"""
struct BooleanInvariant <: Invariant
    fn
    name::String
    messagefn
end

BooleanInvariant(fn; name = "BooleanInvariant", messagefn = _ -> "") =
    BooleanInvariant(fn, name, messagefn)

name(inv::BooleanInvariant) = inv.name


function checkinvariant(inv::BooleanInvariant, ctx)
    return inv.fn(ctx) ? (true, nothing) : (false, nothing)
end


function printerror(io::IO, inv::BooleanInvariant, ctx, errorctx)
    return print(io, inv.messagefn(ctx))
end


@testset "BooleanInvariant" begin
    inv = BooleanInvariant(iseven, "is_even", ctx -> "$ctx is not an even number!")
    @test check(inv, 2)
    @test !check(inv, 1)
    @test_nowarn check_error(inv, 2)
    @test_throws InvariantException check_error(inv, 1)
    @test printerror(String, inv, 1, nothing) == "1 is not an even number!"
end

##

struct HasMethodInvariant <: Invariant
    fn
    args
    constants
end


function checkinvariant(inv::HasMethodInvariant, ctx)
    ctxextended = (; ctx..., inv.constants...)
    args = Tuple(ctxextended[arg] for arg in args)
    try
        inv.fn
    catch e
        return false, (error=e, unexpected=!(e isa MethodError), args = args)
    end
    return true, nothing
end


function printerror(io, inv::HasMethodInvariant, ctx, errorctx)
    if errorctx.unexpected

    else

    end
end


function HasMethodInvariant(fn, args::NTuple{N, Symbol}, constants = (;)) where N
    function getargs(ctx)
        ctxextended = (; ctx..., constants...)
        return Tuple(ctxextended[arg] for arg in args)
    end
    function checkformethod(ctx)
        try
            fn(values(getargs(ctx))...)
            return true
        catch e
            return false
        end
    end
    return BooleanInvariant(
        checkformethod,
        "∃ method `$fn(" * join(string.(args), ", ") * ")`",
        ctx -> "Expected function `$fn` to have a method for argument types `$(typeof.(getargs(ctx)))`. Resolve by defining the method.",
    )
end


@testset "HasMethodInvariant" begin
    inv = HasMethodInvariant(Base.sum, (:xs,))
    @test check(inv, (xs = 1:10,))
    @test !check(inv, (xs = "hi",))
    inv = HasMethodInvariant(Base.sum, (:f, :xs,))
    @test check(inv, (f = abs, xs = 1:10,))
    @test !check(inv, (f = 1, xs = 1:10,))

    ctx = (f = 1, xs = 1:10)
    _, errorctx = checkinvariant(inv, ctx)
    @test printerror(String, inv, ctx, errorctx) == "Expected function `sum` to have a method for argument types `(Int64, UnitRange{Int64})`. Resolve by defining the method."
end
