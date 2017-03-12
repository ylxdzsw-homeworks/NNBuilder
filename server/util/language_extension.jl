function del_end!(s::Bytes)
    ccall(:jl_array_del_end, Void, (Any, UInt), s, 1)
    return s
end

function del_end!(s::String)
    ccall(:jl_array_del_end, Void, (Any, UInt), s.data, 1)
    return s
end
