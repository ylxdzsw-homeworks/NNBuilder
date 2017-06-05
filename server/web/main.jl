module NNBuilder_Web

using HttpServer
using RedisAlchemy
using Restful
using JSON
using JsonBuilder
using Restful: json, cors, staticserver, render

include("../util/language_extension.jl")
include("util.jl")

set_default_redis_connection(RedisConnectionPool())

const db_uid = RedisCounter("uid")

@resource root let
    :mixin => defaultmixin
    :onreturn => cors

    :GET => begin
        open(readstring, abs"client/build/main.html")
    end
end

include("static_assets.jl")
include("redis_proxy.jl")
include("projects.jl")
include("models.jl")
include("tasks.jl")

function main()
    run(Server(root), host=ip"0.0.0.0", port=8000)
end

end # module

web_service = Task(NNBuilder_Web.main)
