module Invariants

using InlineTest
using ANSIColoredPrinters: PlainTextPrinter
using Markdown
using TextWrap

include("invariant.jl")
include("combinators.jl")
include("check.jl")
include("display.jl")

include("invariants/wrap.jl")
include("invariants/hasmethod.jl")
#include("render.jl")
#include("invariants/withcontext.jl")


export invariant, check, check_throw, check_bool

end
