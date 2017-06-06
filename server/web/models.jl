const db_models = RedisList{String}("models")

@resource models <: root let
    :mixin => defaultmixin

    :GET => begin
        if !("project" in keys(req[:query]))
            return 400
        end

        project = try
             parse(Int, req[:query]["project"])
        catch
            return 400
        end

        models = db_models[:]

        if "all" in keys(req[:query])
            idx = find(x->JSON.parse(x)["project"]==project, models)
            isempty(idx) ? 404 : "[$(join(models[idx], ','))]"
        else
            idx = findlast(x->JSON.parse(x)["project"]==project, models)
            idx == 0 ? 404 : models[idx]
        end
    end

    :POST | json => begin
        # TODO: check model
        model = @json "{timestamp: $(now()), $(req[:body])...}"
        push!(db_models, model)
        200
    end
end
