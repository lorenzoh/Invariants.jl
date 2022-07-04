function hastype_invariant(T; var = "x", title = nothing, kwargs...)
    s_T = nameof(T)
    title = isnothing(title) ? "`$var` has type `$s_T`" : title
    return invariant(title; kwargs...) do input
        IT = input isa Type ? input : typeof(input)
        if !(IT <: T)
            return "`$var` should be of type `$T`, but got type `$(IT)`." |> md
        end
    end
end
