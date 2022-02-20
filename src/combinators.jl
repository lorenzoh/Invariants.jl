# Implements invariants that combine other invariants
# - `AllInvariant` passes only if all child invariants are true
# - `AnyInvariant` passes only if any one child invariant is true
# - `SequenceInvariant` runs multiple invariants in an order and fails
#    early if one fails


struct AllInvariant <: Invariant
    invariants::Any
    name::Any
    description::String
end

AllInvariant(
    invariants;
    name = "AllInvariant",
    description="Expected all below invariants to pass, but some did not:"
    ) = AllInvariant(invariants, name, description)

AllInvariant(invariants, name) = AllInvariant(
    invariants,
    name,
    "Expected all below invariants to pass, but some did not:"
)


function checkinvariant(allinv::AllInvariant, ctx)
    errorctx = [checkinvariant(inv, ctx) for inv in allinv.invariants]
    passed = all(pass for (pass, _) in errorctx)
    return passed, errorctx
end


name(allinv::AllInvariant) = allinv.name

function printerror(io::IO, allinv::AllInvariant, ctx, errorctx)

    npassed = sum(pass for (pass, _) in errorctx)
    n = length(allinv.invariants)
    println(io, allinv.description)
    for (inv, (passed, errorctx_)) in zip(allinv.invariants, errorctx)
        if passed
            printchildpassed(io, inv, ctx)
        else
            printchildfailed(io, inv, ctx, errorctx_)
        end
    end
end

@testset "AllInvariant" begin
    inv = AllInvariant(
        [
            BooleanInvariant(ctx -> ctx.x == 0, "Is 0.", ctx -> "Is not 0.")
            BooleanInvariant(ctx -> ctx.y == 0, "Is 0.", ctx -> "Is not 0.")
        ],
        "Are 0",
    )
    @test check(inv, (x = 0, y = 0))
    @test !check(inv, (x = 1, y = 0))
    @test !check(inv, (x = 0, y = 1))
    @test !check(inv, (x = 1, y = 1))
    _, errorctx = checkinvariant(inv, (x = 0, y = 1))
    @test printerror(String, inv, (x = 0, y = 1), errorctx) == "Only 1 / 2 invariants passed:\n- \e[32m✔️\e[39m Is 0.\n- \e[31m\e[1m×\e[22m\e[39m Is 0.\n  \n  Is not 0.\n  \n"
end



struct AnyInvariant <: Invariant
    invariants::Any
    name::Any
    description::String
end

AnyInvariant(invariants, name) = AnyInvariant(
    invariants,
    name,
    "Expected at least one of below invariants to pass, but none did:"
)



function checkinvariant(allinv::AnyInvariant, ctx)
    errorctx = [checkinvariant(inv, ctx) for inv in allinv.invariants]
    passed = any(pass for (pass, _) in errorctx)
    return passed, errorctx
end


name(allinv::AnyInvariant) = allinv.name

function printerror(io::IO, anyinv::AnyInvariant, ctx, errorctx)
    println(io, anyinv.description)
    for (inv, (passed, errorctx_)) in zip(anyinv.invariants, errorctx)
        printchildfailed(io, inv, ctx, errorctx_)
    end
end


@testset "AnyInvariant" begin
    inv = AnyInvariant(
        [
            BooleanInvariant(ctx -> ctx.x == 0, "Is 0.", ctx -> "Is not 0.")
            BooleanInvariant(ctx -> ctx.y == 0, "Is 0.", ctx -> "Is not 0.")
        ],
        "Are 0",
    )
    @test check(inv, (x = 0, y = 0))
    @test check(inv, (x = 1, y = 0))
    @test check(inv, (x = 0, y = 1))
    @test !check(inv, (x = 1, y = 1))
    _, errorctx = checkinvariant(inv, (x = 0, y = 1))
    @test printerror(String, inv, (x = 0, y = 1), errorctx) == "Expected at least one of the below invariants to pass, but none did:\n- \e[31m\e[1m×\e[22m\e[39m Is 0.\n  \n  Is not 0.\n  \n- \e[31m\e[1m×\e[22m\e[39m Is 0.\n  \n  Is not 0.\n  \n"
end

##

struct SequenceInvariant <: Invariant
    invariants::Any
    name::Any
    description::String
end

SequenceInvariant(invariants, name) = SequenceInvariant(
    invariants,
    name,
    "Expected all below invariants to pass, but some did not:"
)

function checkinvariant(seq::SequenceInvariant, ctx)
    i = 1
    for inv in seq.invariants
        if !(inv isa Invariant)
            ctx = inv(ctx)
        else
            passed, errorctx = checkinvariant(inv, ctx)
            passed || return false, (i = i, errorctx = errorctx)
        end
        i += 1
    end
    return true, nothing
end


name(allinv::SequenceInvariant) = allinv.name

function printerror(io::IO, seqinv::SequenceInvariant, ctx, errorctx)
    println(io, seqinv.description)

    i, errorctx = errorctx.i, errorctx.errorctx

    for (j, inv) in enumerate(seqinv.invariants)
        inv isa Invariant || continue
        if j < i
            printchildpassed(io, inv, ctx)
        elseif j == i
            printchildfailed(io, inv, ctx, errorctx)
        else
            printchildunknown(io, inv, ctx)
        end
    end
end


@testset "SequenceInvariant" begin
    inv = SequenceInvariant(
        [
            BooleanInvariant(ctx -> ctx.x == 0, "Is 0.", ctx -> "Is not 0.")
            BooleanInvariant(ctx -> ctx.y == 0, "Is 0.", ctx -> "Is not 0.")
        ],
        "Are 0",
    )
    @test check(inv, (x = 0, y = 0))
    @test !check(inv, (x = 1, y = 0))
    @test !check(inv, (x = 0, y = 1))
    @test !check(inv, (x = 1, y = 1))
    _, errorctx = checkinvariant(inv, (x = 0, y = 1))
    @test printerror(String, inv, (x = 0, y = 1), errorctx) == "Expected all of the below dependent invariants to pass, but at least one does not:\n- \e[32m✔️\e[39m Is 0.\n- \e[31m\e[1m×\e[22m\e[39m Is 0.\n  \n  Is not 0.\n  \n"

    inv = SequenceInvariant(
        [
            BooleanInvariant(ctx -> ctx.x == 0, "Is 0.", ctx -> "Is not 0."),
            ctx -> (y = ctx.x, x = ctx.x),
            BooleanInvariant(ctx -> ctx.y == 0, "Is 0.", ctx -> "Is not 0.")
        ],
        "Are 0",
    )
    @test check(inv, (x = 0, y = 1))
end




## Utils

printchild(io, invariant, ctx, errorctx, passed) =
    (passed ? printchildpassed : printchildfailed)(io, invariant, ctx, errorctx)

function printchildpassed(io, invariant, ctx, errorctx = nothing)
    print(io, "- ")
    printstyled(io, "✔️", color=:green)
    println(io, " ", name(invariant))
end

function printchildfailed(io, invariant, ctx, errorctx)
    ioi = IndentIO(io, 2, indentfirst = false)
    print(ioi, "- ")
    printstyled(ioi, "×", bold=true, color=:red)
    printstyled(ioi, " ", name(invariant), bold=true)
    print(ioi, "\n\n\n\n")
    printerror(ioi, invariant, ctx, errorctx)
    print(ioi, "\n\n\n\n")
end


function printchildunknown(io, invariant, ctx, errorctx = nothing)
    print(io, "- ")
    printstyled(io, "? ", color=:yellow)
    print(io, name(invariant))
    println(io)
end
