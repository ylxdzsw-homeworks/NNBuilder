const db_models = RedisList{String}("models")

@resource models <: root let
    :mixin => defaultmixin

    :GET | json => begin
        @destruct project

        models = db_models[:]

        if "all" in req[:body] && req[:body]["all"]
            idx = find(x->JSON.parse(x)["project"]==project, model)
            isempty(idx) ? 404 : "[$(join(models[idx], ','))]"
        else
            idx = findlast(x->JSON.parse(x)["project"]==project, model)
            idx == 0 ? 404 : models[idx]
        end
    end

    :POST => begin
        # TODO: check model
        push!(db_models, req[:body])
        200
    end
end
