macro destruct(x...)
    result = Expr(:block)
    for i in x
        push!(result.args, :($(string(i)) in keys(req[:body]) || return 400))
    end
    for i in x
        push!(result.args, :($(esc(i)) = req[:body][$(string(i))]))
    end
    result
end
