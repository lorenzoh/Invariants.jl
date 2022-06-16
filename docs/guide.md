# Tutorial

Invariants.jl gives you the tools to define and compose invariants to give more helpful error messages to package users. This page gives an overview of the different features of invariants.

## Defining and checking invariants

An invariant is a function that takes an input and either returns an error message if the input does not satisfy the invariant or `nothing` if it does. We use the [`invariant`](#) function to create them. Let's create an invariant that checks whether a number is positive:

{cell}
```julia
using Invariants: Invariants, invariant, check
inv = invariant("Is positive") do n
    n > 0 ? nothing : "n should be a positive number!"
end
```

We can then check whether the invariant holds for an input using [`check`](#):

{cell}
```julia
using Invariants: check
check(inv, 1)
```

{cell}
```julia
check(inv, -1)
```

!!! note "Checking invariants"

    While `check` gives you a nicely formatted report, you can also use [`check_bool`](#) to get a Boolean value or [`check_throw`](#) to throw an error when an invariant is not satisfied.


## Combining invariants

In real use cases, many invariants can be logically decomposed into smaller invariants. For example, interfaces often require a data structure to implement multiple methods.

We can logically compose invariants with the `invariant(title, [inv1, inv2, ...])` method. Let's take the [`hasmethod_invariant`](#) helper introduced on the [Examples](examples.md) page and build an invariant that checks that a data structure supports indexing and is non-empty.

{cell}
```julia
inv_indexing = invariant(
    "`xs` is indexable",
    [
        Invariants.hasmethod_invariant(length, :xs),
        invariant("`xs is not empty`") do (; xs)
            isempty(xs) ? "`xs` is empty!" : nothing
        end,
        Invariants.hasmethod_invariant(Base.getindex, :xs, :idx => 1),
    ],
    inputfn = xs -> (; xs)
)
check(inv_indexing, [1, 2, 3])
```

This has two advantages:

- We can reuse previously defined invariants
- We get specific error messages based on which constituent invariants were not satisfied

Let's see the second point in action, by passing in inputs that violate different invariants.

{cell}
```julia
check(inv_indexing, nothing)
```

{cell}
```julia
check(inv_indexing, [])
```

{cell}
```julia
check(inv_indexing, [1, 2, 3])
```



