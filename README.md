# Invariants

A Julia package for writing invariants for

- providing helpful, detailed error messages to package users when they misuse the API
- creating interface test suites (as described [here](https://invenia.github.io/blog/2020/11/06/interfacetesting/))

Designing the package, I focused on:

- reusability: invariants are easy to define and reuse, reducing boilerplate
- composability: invariants can be composed to create more complex invariants
- rich error messages: to be helpful, rich error messages should be easy to create

## Example

```julia
using Invariants: check, invariant, md

inv = invariant("Is negative") do n
    n < 0 ? nothing : md("`n` is not negative!")
end

check(inv, 1)
check(inv, -1)
```


