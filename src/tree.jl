AbstractTrees.children(invs::InvariantList) = invs.invariants
Base.show(io::IO, inv::AbstractInvariant) = AbstractTrees.print_tree(io, inv)
function AbstractTrees.printnode(io::IO, inv::AbstractInvariant)
    print(io, nameof(typeof(inv)), "(\"", md(title(inv)), "\")")
end
AbstractTrees.children(::AbstractInvariant) = ()
