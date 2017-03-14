__precompile__()

module BinBlocks

using Libz

import Base: close, eof, read, write, readline

export BinBlock, blocksize

const typelist = UInt8, Int8, UInt32, UInt64, Int32, Int64, Float32, Float64

function type_to_bits{T<:Union{typelist...}, N}(::Array{T, N})
    ((N << 4) | (findfirst(typelist, T) - 1)) % UInt8
end

function bits_to_type(x::UInt8)
    T = typelist[x&0x0f+1]
    N = x >> 4 |> Int
    T, N
end

type BinBlockWriter <: IO
    initialized::Bool
    io::IO
end

BinBlockWriter(io) = BinBlockWriter(false, ZlibDeflateOutputStream(io))
close(bbw::BinBlockWriter) = close(bbw.io)
eof(bbw::BinBlockWriter) = eof(bbw.io)

function init_writer(bbw::BinBlockWriter, X::ANY, y::ANY)
    typeof(y) in typelist && (y = [y])
    write(bbw.io, b"BinBlockv1")
    write(bbw.io, type_to_bits(X), size(X)...)
    write(bbw.io, type_to_bits(y), size(y)...)
    bbw.initialized = true
end

function write(bbw::BinBlockWriter, X, y)
    !bbw.initialized && init_writer(bbw, X, y)
    write(bbw.io, X, y)
end

type BinBlockReader{T, S} <: IO
    sx::Tuple
    sy::Tuple
    io::IO
end

BinBlockReader(io::IO) = begin
    io = ZlibInflateInputStream(io)
    @assert read(io, 10) == b"BinBlockv1"
    Tx, Nx = read(io, UInt8) |> bits_to_type
    sx = (read(io, Int, Nx)...)
    Ty, Ny = read(io, UInt8) |> bits_to_type
    sy = (read(io, Int, Ny)...)
    BinBlockReader{Tx, Ty}(sx, sy, io)
end

function read{T, S}(bbr::BinBlockReader{T, S}, n::Integer)
    X, y = Array{T}(n, bbr.sx...), Array{S}(n, bbr.sy...)
    for i in 1:n
        X[i, :] = read(bbr.io, T, bbr.sx...)
        y[i, :] = read(bbr.io, S, bbr.sy...)
    end
    X, y
end

function readline{T, S}(bbr::BinBlockReader{T, S})
    X = read(bbr.io, T, bbr.sx...)
    y = read(bbr.io, S, bbr.sy...)
    X, y
end

close(bbr::BinBlockReader) = close(bbr.io)
eof(bbr::BinBlockReader) = eof(bbr.io)

function blocksize{T, S}(bbr::BinBlockReader{T, S})
    *(sizeof(T), bbr.sx...) + *(sizeof(S), bbr.sy...)
end

function BinBlock(file::AbstractString, mode::AbstractString="r")
    io = open(file, mode)
    if mode == "r"
        BinBlockReader(io)
    elseif mode == "w"
        BinBlockWriter(io)
    else
        ArgumentError("unknown mode") |> throw
    end
end

end # module BinBlocks
