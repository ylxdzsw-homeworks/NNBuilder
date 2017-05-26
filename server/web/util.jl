macro destruct(x...)
    result = Expr(:block)
    body = esc(:(req[:body]))
    for i in x
        push!(result.args, :($(string(i)) in keys($body) || return 400))
    end
    for i in x
        push!(result.args, :($(esc(i)) = $body[$(string(i))]))
    end
    result
end
