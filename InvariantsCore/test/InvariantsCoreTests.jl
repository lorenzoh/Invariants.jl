module InvariantsCoreTests

using InlineTest
using InvariantsCore
using InvariantsCore: Invariant, WrapInvariant, InvariantException, invariant, title,
                      description, satisfies, check, check_throw

# ## Helpers and setup

function exampleinvariant(symbol = :n)
    return Invariant("`$symbol` is positive",
                     description = "The number `$symbol` should be larger than `0`.") do x
        if !(x isa Number)
            return "`$symbol` has type $(typeof(x)), but it should be a `Number` type."
        else
            x > 0 && return nothing
            return "`$symbol` is not a positive number, got value `$x`. Please pass a number larger than 0."
        end
    end
end

function testinvariant(inv, input)
    @test_nowarn title(inv)
    @test_nowarn description(inv)
    @test_nowarn satisfies(inv, input)
    @test_nowarn inv(input)
end

# ## Tests

@testset "Invariant" begin
    inv = exampleinvariant()
    testinvariant(inv, 1)

    @test isnothing(satisfies(inv, 1))
    @test occursin("should be", satisfies(inv, ""))
    @test occursin("larger", satisfies(inv, -1))
    @test occursin("0", string(description(inv)))
end

@testset "WrapInvariant" begin
    @testset "Pass-through" begin
        inv = invariant(exampleinvariant())
        @test inv isa Invariant
    end

    @testset "Title" begin
        inv = invariant(exampleinvariant(), title = "new")
        @test inv isa Invariant
        @test string(title(inv)) == "new"
    end
end

@testset "invariant" begin
    @testset "Basic" begin
        inv = invariant(input -> input ? nothing : "Not true", "title")
        testinvariant(inv, true)
        @test string(title(inv)) == "title"
        @test isnothing(description(inv))
        @test check(Bool, inv, true)
        @test_nowarn check_throw(inv, true)
        @test_throws InvariantException check_throw(inv, false)
    end

    @testset "Wrap" begin
        _inv = invariant(input -> input ? nothing : "Not true", "title")
        inv = invariant(_inv, title = "newtitle", inputfn = input -> !input)
        testinvariant(inv, true)
        @test string(title(inv)) == "newtitle"
        @test isnothing(description(inv))
        @test check(Bool, inv, false)
    end

    @testset "Compose" begin
        @testset "all" begin
            invs = invariant("all",
                             [invariant(input -> input ? nothing : "Not true", "child",
                                        inputfn = inputs -> inputs[i])
                              for i in 1:3])
            @test check(Bool, invs, [true, true, true])
            @test !check(Bool, invs, [true, true, false])
            @test_throws InvariantException check_throw(invs, [true, false, false])
        end
        @testset "any" begin
            invs = invariant("all",
                             [invariant(input -> input ? nothing : "Not true", "child",
                                        inputfn = inputs -> inputs[i])
                              for i in 1:3], any)
            @test check(Bool, invs, [true, true, true])
            @test check(Bool, invs, [true, true, false])
            @test !check(Bool, invs, [false, false, false])
            @test_throws InvariantException check_throw(invs, [false, false, false])
        end
    end
end

end
