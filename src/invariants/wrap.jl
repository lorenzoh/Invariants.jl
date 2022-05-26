struct WrapInvariant <: AbstractInvariant
    inv
    title
    description
    inputfn
    validate
end

function invariant(
        inv::AbstractInvariant;
        title = nothing,
        inputfn = identity,
        description = nothing,
        validate = nothing)
    if isnothing(title) && inputfn === identity && isnothing(description) && isnothing(validate)
        return inv
    end
    return WrapInvariant(inv, title, description, inputfn, validate)
end


function invariant(
        inv::Invariant;
        title = nothing,
        inputfn = identity,
        description = nothing,
        validate = nothing)
    return Invariant(inv.fn,
        isnothing(title) ? inv.title : title,
        isnothing(description) ? inv.description : description,
        isnothing(validate) ? inv.validate : x -> (inv.validate(x) && validate),
        inputfn === identity ? inv.inputfn : inputfn ∘ inv.inputfn)
end


function Base.show(io::IO, inv::WrapInvariant)
    print(io, "WrapInvariant(")
    show(io, inv.inv)
    print(io, ")")
end


title(wrap::WrapInvariant) = isnothing(wrap.title) ? title(wrap.inv) : wrap.title

description(wrap::WrapInvariant) = if isnothing(wrap.description)
    description(wrap.inv)
else
    wrap.description
end

validate(wrap::WrapInvariant, input) = if isnothing(wrap.validate)
    validate(wrap.inv, wrap.inputfn(input))
else
    wrap.validate(wrap.inputfn(input))
end

satisfies(wrap::WrapInvariant, input) = satisfies(wrap.inv, wrap.inputfn(input))

errormessage(io::IO, wrap::WrapInvariant, msg) = errormessage(io, wrap.inv, msg)

@testset "wrap" begin
    inv = exampleinvariant()
    @test invariant(inv) isa Invariant
    @test description(invariant(inv, description="x")) == "x"
    @test title(invariant(inv, title="x")) == "x"

    wrap = WrapInvariant(inv, "x", "x", identity, _ -> true)
    @test description(wrap) == "x"
    @test title(wrap) == "x"
    @test satisfies(wrap, 1) isa Nothing
    @test satisfies(wrap, -1) isa String

    @test invariant(inv) === inv
end
