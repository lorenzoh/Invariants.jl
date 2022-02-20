module Invariants

using InlineTest
using Markdown

include("invariant.jl")
include("combinators.jl")
include("check.jl")
include("display.jl")

include("invariants/bool.jl")
include("invariants/withcontext.jl")


export BooleanInvariant,
    WithContext,
    AllInvariant,
    AnyInvariant,
    SequenceInvariant,
    WithMessage,

    check_error,
    check

end
