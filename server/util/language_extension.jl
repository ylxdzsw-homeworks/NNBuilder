const ∞ = Inf

const AbstractBytes = Union{AbstractVector{UInt8}, Ptr{UInt8}}
const Bytes = Vector{UInt8}
const Byte = UInt8

const u8 =  UInt8
const u16 = UInt16
const u32 = UInt32
const u64 = UInt64
const i32 = Int32
const i64 = Int64
const f32 = Float32
const f64 = Float64

@inline car(x::ANY)   = x[1]
@inline cdr(x::ANY)   = x[2:end]
@inline cdr(x::Tuple) = Base.tail(x)
@inline cadr(x::ANY)  = x[2]

@inline void(x::ANY...) = nothing

const project_root = normpath(Base.source_dir(), "..", "..")

macro abs_str(x) isinteractive() ? x : joinpath(project_root, split(x, '/')...) end

<<(x::IO, y) = (print(x, y); x)
<<(x::IO, y::Byte) = (write(x, y); x)
<<(x::IO, y::Bytes) = (write(x, y); x)
<<(x::IO, f::Function) = (f(x); x)
<<(x, y) = Base.<<(x, y)

>>(x::IO, y) = read(x, y)
>>(x::IO, f::Function) = f(x)
>>(x, y) = Base.>>(x, y)

>>>(x::IO, y) = (read(x, y); x)
>>>(x::IO, f::Function) = (f(x); x)
>>>(x, y) = Base.>>>(x, y)

prt(xs...) = prt(STDOUT, xs...)
prt(io::IO, xs...) = begin
    lock(io)
    try
        print(io, car(xs))
        for x in cdr(xs)
            print(io, '\t')
            print(io, x)
        end
        print(io, '\n')
    finally
        unlock(io)
    end
end

macro i_str(ind)
    ex = parse("x[$ind]")
    ex.args[2] = esc(ex.args[2])
    Expr(:->, :x, ex)
end

macro when(exp)
    :( !$(esc(exp)) && continue )
end

macro unless(exp)
    :( $(esc(exp)) && continue )
end
