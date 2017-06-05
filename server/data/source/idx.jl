const IDX_MAGIC = [0x00, 0x00]
const IDX_TYPE = Dict(
    0x08 => UInt8,
    0x09 => Int8,
    0x0b => Int16,
    0x0c => Int32,
    0x0d => Float32,
    0x0e => Float64
)

function read_idx(filename)
    f = open(filename) |> ZlibInflateInputStream
    @assert f >> 2 == IDX_MAGIC

    t = IDX_TYPE[f >> Byte]
    dim = f >> Byte |> Int
    dims = i32[ntoh(f >> Int32) for i in 1:dim]

    result = read(f, t, reverse(dims)...)
    permutedims(result, dim:-1:1)
end

function dispatch(::Val{:IDX}; file="")
    (read_idx(file),)
end
