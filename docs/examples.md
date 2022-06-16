# Examples

{.subtitle}
This page showcases some examples for commonly useful invariants that are either included in Invariants.jl or simple to construct.

{cell, show=false}
```julia
using Invariants
```

## Checking for method implementations

[`hasmethod_invariant`](#) is an invariant that lets us check that a method exists and can be called with the given arguments. We construct it with argument names and optional default values, and check it by providing a `NamedTuple` input with values for the arguments.

Checking that the input has a `length` method:

{cell}
```julia
inv_length = Invariants.hasmethod_invariant(Base.length, :xs)
check(inv_length, (; xs = 1:10))
```

{cell}
```julia
check(inv_length, (; xs = nothing))
```

!!! note "Functions with side effects"

    To be sure that a working method exists, `hasmethod_invariant` runs the functions on the given arguments. This means that you should not use it to check functions with side effects or long-running computations.

We can also construct an invariant that expects multiple arguments and provides default values. Here, we check that the `getindex` method exists and we can load the element at index 1:

{cell}
```julia
inv_index = Invariants.hasmethod_invariant(Base.getindex, :xs, :idx => 1)
check(inv_index, (; xs = [1, 2, 3]))
```

If violated, the invariant will output _contextual_ error messages based on the error encountered. If no `getindex` method is defined, we are told that a method is missing:

{cell}
```julia
check(inv_index, (; xs = nothing))
```

If there is a method, but it throws an error, we get a different error message:

{cell}
```julia
check(inv_index, (; xs = []))
```

