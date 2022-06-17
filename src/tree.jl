AbstractTrees.children(invs::InvariantList) = invs.invariants
Base.show(io::IO, inv::AbstractInvariant) = AbstractTrees.print_tree(io, inv)
AbstractTrees.printnode(io::IO, inv::AbstractInvariant) = print(io, nameof(typeof(inv)), "(\"", title(inv), "\")")
AbstractTrees.children(::AbstractInvariant) = ()
