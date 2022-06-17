module Invariants

using InlineTest
using TextWrap: wrap
import AbstractTrees
import InvariantsCore
import InvariantsCore: AbstractInvariant, InvariantList, AnyInvariant, AllInvariant,
                       AsMarkdown, errormessage, satisfies, invariant, check, check_throw,
                       title, description, showdescription, showtitle

include("wrapio.jl")
include("tree.jl")
include("show.jl")

include("invariants/hasmethod.jl")

function exampleinvariant(symbol = :n)
    return Invariant("`$symbol` is positive",
        description = "The number `$symbol` should be larger than `0`.") do x
        if !(x isa Number)
            return "`$symbol` has type $(typeof(x)), but it should be a `Number` type."
        else
            x > 0 && return nothing
            return "`$symbol` is not a positive number, got value `$x`. Please pass a number larger than 0."
        end
    end
end



export invariant, check, check_throw

end
