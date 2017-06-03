module NNBuilder_Data

using Libz
using HDF5
using JSON
using JsonBuilder
using RedisAlchemy

include("../util/language_extension.jl")

set_default_redis_connection(RedisConnectionPool())

const db_uid = RedisCounter("uid")
const db_task = RedisBlockedQueue{String}("data_task")

include("dispatch.jl")

function main()
    while true
        yield()
    end
end

end # module

data_service = Task(NNBuilder_Data.main)
