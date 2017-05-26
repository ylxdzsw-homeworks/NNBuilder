using HttpServer
using RedisAlchemy
using Restful
using JSON
using JsonBuilder
using Restful: json, cors, staticserver, render

set_default_redis_connection(RedisConnectionPool())

const db_uid = RedisCounter("uid")

@resource root let
    :mixin => defaultmixin
    :onreturn => cors

    :GET => begin
        open(readstring, rel"../../client/build/main.html")
    end
end

include("util.jl")
include("static_assets.jl")
include("redis_proxy.jl")
include("projects.jl")
include("models.jl")
