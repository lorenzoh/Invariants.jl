# This file defines [`WrapInvariant`](#), which wraps around an invariant,
# changing part of its functionality

struct WrapInvariant <: AbstractInvariant
    inv::Any
    title::Any
    description::Any
    inputfn::Any
    format::Any
end

function title(wrap::WrapInvariant)
    t = isnothing(wrap.title) ? title(wrap.inv) : wrap.title
    format = isnothing(wrap.format) ? identity : wrap.format
    return format(t)
end

function description(wrap::WrapInvariant)
    desc = isnothing(wrap.description) ? description(wrap.inv) : wrap.description
    format = isnothing(wrap.format) ? identity : wrap.format
    return format(desc)
end

satisfies(wrap::WrapInvariant, input) = satisfies(wrap.inv, wrap.inputfn(input))

function errormessage(io::IO, wrap::WrapInvariant, msg)
    format = isnothing(wrap.format) ? identity : wrap.format
    errormessage(io, wrap.inv, format(msg))
end
