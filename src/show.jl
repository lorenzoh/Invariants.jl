
function Invariants.errormessage(io::IO, invs::AllInvariant, msgs)
    __combinator_errormessage(io, invs, msgs, map(__getmarker, msgs),
        faint("All invariants listed below should be satisfied:\n\n "))
end

function InvariantsCore.errormessage(io::IO, invs::AnyInvariant, msgs)
    __combinator_errormessage(io, invs, msgs, map(m -> isnothing(m) ? PASS : FAIL, msgs),
        faint("At least one of the invariants listed below should be satisfied:\n\n"))
end


const PASS = "\e[32m✔\e[0m\e[2m"
const FAIL = "\e[31m⨯\e[0m"
const UNKNOWN = "\e[33m?\e[0m"

function __combinator_errormessage(io::IO, invs, msgs, markers, msg)
    showdescription(io, invs)
    print(io, msg)
    for (inv, message, marker) in zip(invs.invariants, msgs, markers)
        __errormessage_child(io, inv; marker, message)
    end
end

function __errormessage_child(
        io,
        inv;
        marker = "o",
        message=nothing,
        indent = "    "
        )
    print(io, marker, " ")
    showtitle(io, inv)
    print(io, "\e[0m")
    println(io)

    if !(isnothing(message) || ismissing(message))
        ioi = WrapIO(io; indent)
        errormessage(ioi, inv, message)
    end
end

__getmarker(::Nothing) = PASS
__getmarker(::Missing) = UNKNOWN
__getmarker(_) = FAIL
