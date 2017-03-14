__precompile__()

module BioDataStructures

export IntRangeDict, save

import Base: push!, in, show, foreach, collect, getindex, read, write

type IntRangeSpan{K<:Integer, V}
    lv::K
    rv::K
    data::Vector{V}
end

immutable IntRangeDict{K<:Integer, V}
    data::Vector{IntRangeSpan{K, V}}
    IntRangeDict(data::Vector=[]) = new(data)
    IntRangeDict(io::IO) = begin
        n = read(io, Int)
        data = Vector{IntRangeSpan{K, V}}(n)
        for i in 1:n
            lv = read(io, K)
            rv = read(io, K)
            len = read(io, Int)
            data[i] = IntRangeSpan{K, V}(lv, rv, read(io, V, len))
        end
        IntRangeDict{K, V}(data)
    end
end

immutable IntRangeHandler{K<:Integer, V}
    lv::K
    rv::K
    dict::IntRangeDict{K, V}
end

function find_last{K, V}(dict::IntRangeDict{K, V}, int::K)::Int
    findlast(x->x.lv <= int, dict.data)
end

function find_binary{K, V}(dict::IntRangeDict{K, V}, int::K)::Int
    isempty(dict.data) && return 0

    v(i) = dict.data[i].lv

    find_within(i, j) = if i == j
        v(i) <= int ? i : i - 1
    else
        m = (i + j + 1) ÷ 2
        v(m) <= int ? find_within(m, j) :
                      find_within(i, m-1)
    end

    find_within(1, length(dict.data))
end

function getindex{K, V}(dict::IntRangeDict{K, V}, range::UnitRange{K})
    IntRangeHandler{K, V}(range.start, range.stop, dict)
end

function push!{K, V}(handle::IntRangeHandler{K, V}, v::V)
    data, lv, rv = handle.dict.data, handle.lv, handle.rv

    if lv > rv
        return handle
    end

    i = find_last(handle.dict, lv) # use last rahter than binary to make inserting incremently faster

    if i == 0 || lv > data[i].rv
        if i+1 <= length(data) && rv >= data[i+1].lv
            insert!(data, i+1, IntRangeSpan{K, V}(lv, data[i+1].lv-1, [v]))
            push_aligned_left!(handle.dict, rv, v, i+2)
        else
            insert!(data, i+1, IntRangeSpan{K, V}(lv, rv, [v]))
        end
    else
        if lv == data[i].lv
            push_aligned_left!(handle.dict, rv, v, i)
        else
            old_rv = data[i].rv
            data[i].rv = lv-1

            if rv <= old_rv
                insert!(data, i+1, IntRangeSpan{K, V}(lv, rv, [data[i].data[:]; v]))

                if rv != old_rv
                    insert!(data, i+2, IntRangeSpan{K, V}(rv+1, old_rv, data[i].data[:]))
                end
            else
                insert!(data, i+1, IntRangeSpan{K, V}(lv, old_rv, [data[i].data[:]; v]))
                push_aligned_right!(handle.dict, rv, v, i+1)
            end
        end
    end

    handle.dict
end

"push when handle.lv == handle.dict.data[i].lv"
function push_aligned_left!{K, V}(dict::IntRangeDict{K, V}, rv::K, v::V, i::Int)
    p = dict.data[i]

    if rv < p.rv
        lv = p.lv
        p.lv = rv + 1
        insert!(dict.data, i, IntRangeSpan{K, V}(lv, rv, [p.data[:]; v]))
    else
        push!(p.data, v)
        if rv > p.rv
            push_aligned_right!(dict, rv, v, i)
        end
    end
end

"push when handle.lv == handle.dict.data[i].rv+1"
function push_aligned_right!{K, V}(dict::IntRangeDict{K, V}, rv::K, v::V, i::Int)
    p = dict.data[i]
    if i+1 <= length(dict.data)
        pnext = dict.data[i+1]
        if p.rv+1 == pnext.lv
            push_aligned_left!(dict, rv, v, i+1)
        elseif rv < pnext.lv
            insert!(dict.data, i+1, IntRangeSpan{K, V}(p.rv+1, rv, [v]))
        else
            insert!(dict.data, i+1, IntRangeSpan{K, V}(p.rv+1, pnext.lv-1, [v]))
            push_aligned_left!(dict, rv, v, i+2)
        end
    else
        push!(dict.data, IntRangeSpan{K, V}(p.rv+1, rv, [v]))
    end
end

function show{K, V}(io::IO, dict::IntRangeDict{K, V})::Void
    println(io, "IntRangeDict{$K, $V}:")
    if isempty(dict.data)
        println(io, "  (empty)")
    else
        for i in dict.data
            println(io, "  ", i.lv, '-', i.rv, ": ", join(i.data, ','))
        end
    end
end

function getindex{K, V}(dict::IntRangeDict{K, V}, index::K)::Vector{V}
    i = find_binary(dict, index)
    i == 0 || dict.data[i].rv < index ? [] : dict.data[i].data
end

function save{K, V}(io::IO, dict::IntRangeDict{K, V})
    write(io, length(dict.data))
    for i in dict.data
        write(io, i.lv, i.rv, length(i.data), i.data)
    end
end

export IntRangeSet

import Base: push!, in, show, foreach, collect, union, union!, intersect

type IntRange{T<:Integer}
    lv::T
    rv::T
    lp::Nullable{IntRange{T}}
    rp::Nullable{IntRange{T}}
    lc::Nullable{IntRange{T}}
    rc::Nullable{IntRange{T}}
    IntRange(lv, rv=lv, lp=nothing, rp=nothing, lc=nothing, rc=nothing) = new(lv, rv, lp, rp, lc, rc)
end

type IntRangeSet{T<:Integer} # <: Base.AbstractSet{T}
    balanced::Bool
    root::Nullable{IntRange{T}}
    cache::Nullable{IntRange{T}}
    IntRangeSet() = new(true, nothing, nothing)
end

# NOTE: tree.cache only used and updated in `push!` methods

function push!{T}(tree::IntRangeSet{T}, x::T)::IntRangeSet{T}
    if tree.root.isnull
        node = IntRange{T}(x)
        tree.root = node
        tree.cache = node
    elseif between_parents(x, tree.cache.value)
        push!(tree, tree.cache.value, x)
    else
        push!(tree, tree.root.value, x)
    end

    tree
end

function push!{T}(tree::IntRangeSet{T}, x::UnitRange{T})::IntRangeSet{T}
    x.start <= x.stop || return tree
    if tree.root.isnull
        node = IntRange{T}(x.start, x.stop)
        tree.root = node
        tree.cache = node
    elseif between_parents(x, tree.cache.value)
        push!(tree, tree.cache.value, x)
    else
        push!(tree, tree.root.value, x)
    end

    tree
end

function push!{T}(tree::IntRangeSet{T}, node::IntRange{T}, x::T)::IntRangeSet{T}
    if x == node.lv - 1
        extend_left!(tree, node, x)
        tree.cache = node
    elseif x == node.rv + 1
        extend_right!(tree, node, x)
        tree.cache = node
    elseif x < node.lv
        if node.lc.isnull
            x = IntRange{T}(x, x, node.lp, node)
            node.lc = x
            tree.cache = x
            tree.balanced = false
        else
            push!(tree, node.lc.value, x)
        end
    elseif x > node.rv
        if node.rc.isnull
            x = IntRange{T}(x, x, node, node.rp)
            node.rc = x
            tree.cache = x
            tree.balanced = false
        else
            push!(tree, node.rc.value, x)
        end
    end

    tree
end

"""
six position relations:
+-------------------+
     3333333333
    2222    5555
1111     44     6666
       ******
+-------------------+
1: insert to left child
2: extend left
3: extend both side
4: just ingnore
5: extend right
6: insert to right child
"""
function push!{T}(tree::IntRangeSet{T}, node::IntRange{T}, x::UnitRange{T})::IntRangeSet{T}
    if x.start < node.lv
        if x.stop < node.lv - 1
            if node.lc.isnull
                x = IntRange{T}(x.start, x.stop, node.lp, node)
                node.lc = x
                tree.cache = x
                tree.balanced = false
            else
                push!(tree, node.lc.value, x)
            end
        else
            extend_left!(tree, node, x.start)
            if x.stop > node.rv
                extend_right!(tree, node, x.stop)
            end
            tree.cache = node
        end
    elseif x.stop > node.rv
        if x.start <= node.rv + 1
            extend_right!(tree, node, x.stop)
            tree.cache = node
        else
            if node.rc.isnull
                x = IntRange{T}(x.start, x.stop, node, node.rp)
                node.rc = x
                tree.cache = x
                tree.balanced = false
            else
                push!(tree, node.rc.value, x)
            end
        end
    end

    tree
end

function extend_left!{T}(tree::IntRangeSet{T}, node::IntRange{T}, x::T)::IntRange{T}
    if !node.lc.isnull
        rmlc = right_most(tree, node.lc.value) # here can be optimized: stop at the first node that rv + 1 >= x
        if x <= rmlc.rv + 1
            fuse_rp!(tree, rmlc)
        else
            node.lv = x
        end
    else
        node.lv = x
    end

    x < node.lv ? extend_left!(tree, node, x) : node
end

function extend_right!{T}(tree::IntRangeSet{T}, node::IntRange{T}, x::T)::IntRange{T}
    if !node.rc.isnull
        lmrc = left_most(tree, node.rc.value)
        if x >= lmrc.lv - 1
            fuse_lp!(tree, lmrc)
        else
            node.rv = x
        end
    else
        node.rv = x
    end

    x > node.rv ? extend_right!(tree, node, x) : node
end

# left subtree will be lost, as they are covered by the fused node
function fuse_lp!{T}(tree::IntRangeSet{T}, node::IntRange{T})::IntRange{T}
    # 1. hoist right child to the position of node
    if node.lp.value.rc.value == node # linked to lp directly
        node.lp.value.rc = node.rc
    else
        node.rp.value.lc = node.rc
    end
    # 2. inherit lp
    p = node.rc
    while !p.isnull
        p.value.lp = node.lp
        p = p.value.lc
    end
    # 3. adjust lp range
    node.lp.value.rv = node.rv
    # 4. track balanced property
    tree.balanced = false
    node.lp.value
end

function fuse_rp!{T}(tree::IntRangeSet{T}, node::IntRange{T})::IntRange{T}
    if node.rp.value.lc.value == node
        node.rp.value.lc = node.lc
    else
        node.lp.value.rc = node.lc
    end
    p = node.lc
    while !p.isnull
        p.value.rp = node.rp
        p = p.value.rc
    end
    node.rp.value.lv = node.lv
    tree.balanced = false
    node.rp.value
end

function swap_lc!{T}(tree::IntRangeSet{T}, node::IntRange{T})::IntRange{T}
    # 1. preserve a pointer to the right subtree
    temp = node.lc.value.rc
    # 2. hoist left child to the position of node
    if !node.lp.isnull && node.lp.value.rc.value == node
        node.lp.value.rc = node.lc
    elseif !node.rp.isnull
        node.rp.value.lc = node.lc
    else # root
        tree.root = node.lc
    end
    # 3. inherit
    node.lc.value.rc = node
    node.lc.value.rp = node.rp
    # 4. setup node itself
    node.lp = node.lc
    node.lc = temp
    # 5. return the node in the origin position
    node.lp.value
end

function swap_rc!{T}(tree::IntRangeSet{T}, node::IntRange{T})::IntRange{T}
    temp = node.rc.value.lc
    if !node.rp.isnull && node.rp.value.lc.value == node
        node.rp.value.lc = node.rc
    elseif !node.lp.isnull
        node.lp.value.rc = node.rc
    else
        tree.root = node.rc
    end
    node.rc.value.lc = node
    node.rc.value.lp = node.lp
    node.rp = node.rc
    node.rc = temp
    node.rp.value
end

function rebalance!{T}(tree::IntRangeSet{T})::Int
    depth = tree.root.isnull ? 0 : rebalance!(tree, tree.root.value)
    tree.balanced = true
    depth
end

# TODO: this is O(n) operation. Maybe we should store balance factor in each node?
function rebalance!{T}(tree::IntRangeSet{T}, node::IntRange{T})::Int
    ld = node.lc.isnull ? 0 : rebalance!(tree, node.lc.value)
    rd = node.rc.isnull ? 0 : rebalance!(tree, node.rc.value)
    if ld - rd > 1
        swap_lc!(tree, node)
        ld
    elseif rd - ld > 1
        swap_rc!(tree, node)
        rd
    else # already balance
        max(ld, rd) + 1
    end
end

"apply f to each UnitRange in IntRangeSet, order is guaranteed"
function foreach{T}(f::Function, tree::IntRangeSet{T})::Void
    traverse(tree) do node
        f(node.lv:node.rv)
    end
end

"get a list of UnitRange that is in IntRangeSet, order is guaranteed"
function collect{T}(tree::IntRangeSet{T})::Vector{UnitRange{T}}
    list = UnitRange{T}[]
    foreach(x->push!(list, x), tree)
    list
end

function union{T}(t1::IntRangeSet{T}, t2::IntRangeSet{T})::IntRangeSet{T}
    tree = IntRangeSet{T}()
    union!(tree, t1)
    union!(tree, t2)
    tree
end

function union{T}(ts::IntRangeSet{T}...)::IntRangeSet{T}
    tree = IntRangeSet{T}()
    for t in ts
        union!(tree, t)
    end
    tree
end

function union!{T}(t1::IntRangeSet{T}, t2)::IntRangeSet{T}
    t1.balanced || rebalance!(t1)
    foreach(x->push!(t1, x), t2)
    t1
end

function intersect{T}(t1::IntRangeSet{T}, t2::IntRangeSet{T})::IntRangeSet{T}
    tree = IntRangeSet{T}()
    a, b = collect(t1), collect(t2)
    i, j = 1, 1

    while true
        if i > length(a) || j > length(b)
            break
        end

        start = max(a[i].start, b[j].start)

        if a[i].stop < b[j].stop
            push!(tree, start:a[i].stop)
            i += 1
        else
            push!(tree, start:b[j].stop)
            j += 1
        end
    end

    tree
end

# TODO: intersect all in one pass
function intersect{T}(ts::IntRangeSet{T}...)::IntRangeSet{T}
    reduce(intersect, ts)
end

function in{T}(x::T, tree::IntRangeSet{T})::Bool
    tree.balanced || rebalance!(tree)
    tree.root.isnull ? false : in(tree, tree.root.value, x)
end

function in{T}(tree::IntRangeSet{T}, node::IntRange{T}, x::T)::Bool
    if x < node.lv
        node.lc.isnull ? false : in(tree, node.lc.value, x)
    elseif x > node.rv
        node.rc.isnull ? false : in(tree, node.rc.value, x)
    else
        true
    end
end

function between_parents{T}(x::T, node::IntRange{T})::Bool
    !node.lp.isnull && x <= node.lp.value.rv + 1 && return false
    !node.rp.isnull && x >= node.rp.value.lv - 1 && return false
    true
end

function between_parents{T}(x::UnitRange{T}, node::IntRange{T})::Bool
    !node.lp.isnull && x.start <= node.lp.value.rv + 1 && return false
    !node.rp.isnull && x.stop  >= node.rp.value.lv - 1 && return false
    true
end

function traverse{T}(f::Function, tree::IntRangeSet{T})::Void
    traverse(f, tree, tree.root)
end

function traverse{T}(f::Function, tree::IntRangeSet{T}, node::Nullable{IntRange{T}})::Void
    if !node.isnull
        node = node.value
        traverse(f, tree, node.lc)
        f(node)
        traverse(f, tree, node.rc)
    end
end

function left_most{T}(tree::IntRangeSet{T}, node::IntRange{T})::IntRange{T}
    while !node.lc.isnull
        node = node.lc.value
    end
    node
end

function right_most{T}(tree::IntRangeSet{T}, node::IntRange{T})::IntRange{T}
    while !node.rc.isnull
        node = node.rc.value
    end
    node
end

function show{T}(io::IO, tree::IntRangeSet{T})::Void
    println(io, "IntRangeSets{$T}:")
    if tree.root.isnull
        println(io, "  (empty)")
    else
        traverse(tree) do node
            println(io, "  ", node.lv, ':', node.rv)
        end
    end
end

end # BioDataStructures
