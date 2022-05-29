# User guide

Invariants.jl gives you the tools to define and compose invariants to give more helpful error messages to package users. This page gives an overview of the different features of invariants.

## Defining and checking invariants

An invariant is a function that takes an input and either returns an error message if the input does not satisfy the invariant or `nothing` if it does. We use the [`invariant`](#) function to create them. Let's create an invariant that checks whether a number is positive:

{cell}
```julia
using Invariants: invariant
inv = invariant("Is positive") do n
    n > 0 ? nothing : "n should be a positive number!"
end
```

We can then check whether the invariant holds for an input using [`check`](#):o

{cell}
```julia
using Invariants: check
check(inv, 1)
```

{cell}
```julia
using Invariants: check
check(inv, -1)
```

!!! note "Checking invariants"

    While `check` gives you a nicely formatted report, you can also use [`check_bool`](#) to get a Boolean value or [`check_throw`](#) to throw an error when an invariant is not satisfied.

## Combining invariants

We can also create more complex invariants by logically composing multiple invariants.

