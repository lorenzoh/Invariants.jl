# This file defines [`invariant`](#), which allows creating and combining
# invariants and should cover most use cases.
#
# It also defines [`check`](#) for running an innput against an invariant.
#
# ## `invariant`
#
# The basic method simply returns an [`Invariant`](#):

"""
    invariant(fn, title; kwargs...)

Create an invariant with name `title` that checks an input against
`fn` which returns either `nothing` when the invariant is satisfied,
or an error message when the invariant is violated.

    invariant(inv; title=title(inv), kwargs...)

Wrap an invariant `inv`, replacing some of its attributes.

    invariant(title, invariants, all; kwargs...)
    invariant(title, invariants, any; kwargs...)

Combine multiple invariants `invs` logically. The third argument defines how they are
combined. If it is `all`, the resulting invariant requires all `invariants` to pass,
while a value of `any` results in an invariant where only one of the `invariants` has
to be satisfied.

## Keyword arguments

Every method additionally accepts the following keyword arguments:

- `description::String = ""`: A description of the invariant that gives explanation and
    points to related resources.
- `inputfn = identity`: A function that is applied to an input before checking. Useful
    when composing multiple invariants.

## Examples

Basic usage:

{cell}
```julia
using Invariants

inv = invariant("Is negative") do n
    n < 0 ? nothing : "`n` is not negative!"
end
```

Successful check:

{cell}
```julia
check(inv, -1)
```

Failing check:

{cell}
```julia
check(inv, 1)
```

Or just get a Bool:

{cell}
```julia
check(Bool, inv, -1), check(Bool, inv, 1)
```

Throw an error when an invariant is not satisfied:

{cell}
```julia
check_throw(inv, 1)
```
"""
invariant(fn, title::String; kwargs...) = Invariant(; fn, title, kwargs...)

# `invariant` can be called on a vector of invariants, creating an invariant that
# logically composes them (either AND or OR):

function invariant(title, invariants::AbstractVector{<:AbstractInvariant}; kwargs...)
    invariant(title, invariants, all; kwargs...)
end
function invariant(title, invariants::AbstractVector{<:AbstractInvariant},
                   ::typeof(all); kwargs...)
    AllInvariant(invariants, title; kwargs...)
end
function invariant(title, invariants::AbstractVector{<:AbstractInvariant},
                   ::typeof(any); kwargs...)
    AnyInvariant(invariants, title; kwargs...)
end

# `invariant` can also wrap an invariant, changing some of its attributes.
# For a general `AbstractInvariant`, this will return a [`WrapInvariant`](#):

function invariant(inv::AbstractInvariant; title = nothing, inputfn = identity,
                   description = nothing, format = nothing)
    if isnothing(title) && inputfn === identity && isnothing(description) &&
       isnothing(format)
        return inv
    end
    return WrapInvariant(inv, title, description, inputfn, format)
end

# While for an [`Invariant`](#) this will simply return a new [`Invariant`](#)
# with changed fields:

function invariant(inv::Invariant; title = nothing, inputfn = identity,
                   description = nothing, format = nothing)
    return Invariant(inv.fn,
                     isnothing(title) ? inv.title : title,
                     isnothing(description) ? inv.description : description,
                     inputfn === identity ? inv.inputfn : inputfn ∘ inv.inputfn,
                     isnothing(format) ? inv.format : format)
end

# ## `check`

"""
    check(invariant, input)

Check an invariant against an input, and return a [`CheckResult`] that
gives detailed output in case of an invariant violation.

    check(Bool, invariant, input)

Check an invariant against an input, returning `true` if satisfied, `false`
if violated.
"""
function check(invariant, input)
    res = satisfies(invariant, input)
    return CheckResult(invariant, res)
end

check(::Type{Bool}, invariant, input) = isnothing(satisfies(invariant, input))
check(::Type{Exception}, invariant, input) = check_throw(invariant, input)

struct CheckResult{I, R}
    invariant::I
    result::R
end
Base.convert(::Type{Bool}, checkres::CheckResult) = isnothing(checkres.result)

function Base.show(io::IO, checkres::CheckResult{<:I, Nothing}) where {I}
    print(io, "\e[32m✔ Invariant satisfied:\e[0m ")
    print(io, md(title(checkres.invariant)))
end

function Base.show(io::IO, checkres::CheckResult)
    print(io, "\e[1m\e[31m⨯ Invariant not satisfied:\e[0m\e[1m ")
    print(io, md(title(checkres.invariant)))
    println(io, "\e[22m\n")
    errormessage(io, checkres.invariant, checkres.result)
end

md(s) = string(AsMarkdown(s))

# For cases where violating an invariant should lead to an error be thrown, use
# [`check_throw`](#):

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

struct InvariantException{I <: AbstractInvariant, M}
    invariant::I
    msg::M
end

function Base.showerror(io::IO, e::InvariantException)
    println(io, "Invariant violated!")
    errormessage(io, e.invariant, e.msg)
end


# Allow calling the invariant so that `check` doesn't need to be imported.
(inv::AbstractInvariant)(args...) = check(inv, args...)
(inv::AbstractInvariant)(T::Type, args...) = check(T, inv, args...)
