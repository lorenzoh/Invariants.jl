
md(s) = string(AsMarkdown(s))

function hasmethod_invariant(fn, args...; title = _title_hasmethod(fn, args), kwargs...)

    return invariant(title; kwargs...) do inputs
        if !(_validate_hasmethod(args)(inputs))
            return "Got invalid inputs $inputs"
        end
        argnames = map(arg -> arg isa Symbol ? arg : arg[1], args)
        argvalues = map(arg -> arg isa Symbol ? inputs[arg] : arg[2], args)
        try
            fn(argvalues...)
            return nothing
        catch e
            sig = _signature(fn, argnames, argvalues)
            if e isa MethodError && e.f == fn
                return md("""When calling `$fn`, got a `MethodError`. This means that there
                is no method implemented for the given arguments. To fix this, please
                implement the following method:
                """) * "\n\n    " * sig
            else
                return (md("When calling `$fn`, got an unexpected error:") * "\n\n" *
                    (sprint(Base.showerror, e; context = (:color => false,)) |> indent |> faint) *
                    "\n\n" * md("""This means that there is a method matching the given arguments,
                    but calling it throws an error. To fix this, please debug the following
                    method:""") * "\n\n    " * sig)
            end
        end
    end
end

indent(s, n = 4) = wrap(s; initial_indent=repeat(" ", n), subsequent_indent=repeat(" ", n))
faint(s) = "\e[2m$s\e[22m"

function _title_hasmethod(fn, args)
    buf = IOBuffer()
    print(buf, "Method `$(nameof(parentmodule(fn))).$(nameof(fn))(")
    for (i, arg) in enumerate(args)
        name = arg isa Symbol ? arg : first(arg)
        print(buf, name)
        i != length(args) && print(buf, ", ")
    end
    print(buf, ")` implemented")
    return String(take!(buf))
end

function _validate_hasmethod(args)
    return function (inputs)
        for arg in args
            inputs isa NamedTuple || return false
            if arg isa Symbol
                haskey(inputs, arg) || return false
            end
        end
        return true
    end
end

function _signature(fn, argnames, argvalues)
    buf = IOBuffer()
    bold(s) = "\e[1m$s\e[22m"
    print(buf, parentmodule(fn), ".", nameof(fn), faint("("))
    for (i, (name, val)) in enumerate(zip(argnames, argvalues))
        print(buf, name, faint("::"), bold(nameof(typeof(val))))
        i != length(argnames) && print(buf, faint(", "))
    end
    print(buf, faint(")"))
    return String(take!(buf))
end
