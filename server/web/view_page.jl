@resource view <: root let
    :route => "*"
    :mixin => defaultmixin

    :GET => begin
        render(rel"../client/build/main.html", id=id)
    end
end
