@resource command <: root let
    :mixin => defaultmixin

    :POST | json => begin
        result = exec(conn, req[:body]...) |> parse_result
        result == nothing ? 404 : result
    end
end

parse_result(x) = x
parse_result(x::Int) = string(x)
parse_result(x::Bytes) = String(x)
parse_result(x::Vector) = map(parse_result, x)
