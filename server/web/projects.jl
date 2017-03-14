"""
project structure:
{
    name: String,
    id: Int
}
"""

const db_projects = RedisList{String}("projects")

@resource projects <: root let
    :mixin => defaultmixin

    :GET => begin
        "[$(join(db_projects[:], ','))]"
    end

    :POST | json => begin
        @destruct name
        uid = db_uid[]
        push!(db_projects, json"{name: $name, id: $uid}")
        json"{id: $uid}"
    end
end

@resource project <: projects let
    :route => "*"

    :PUT | json => begin
        @destruct name
        id = try parse(Int, id) catch return 404 end
        idx = findfirst(x->JSON.parse(x)["id"]==id, db_projects)
        idx == 0 || return 404
        db_projects[idx] = json"{name: $name, id: $id}"
        200
    end

    :DELETE => begin
        id = try parse(Int, id) catch return 404 end
        idx = findfirst(x->JSON.parse(x)["id"]==id, db_projects)
        idx == 0 || return 404
        db_projects[idx] = "__deleted__"
        exec(db_projects, "lrem", 1, "__deleted__")
        200
    end
end
