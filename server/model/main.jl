module NNBuilder_Model

using HDF5
using JSON
using JsonBuilder
using RedisAlchemy

include("../util/language_extension.jl")

set_default_redis_connection(RedisConnectionPool())

const cache_dir = abs"data/cache"
const model_dir = abs"data/model"

const db_uid = RedisCounter("uid")
const db_model_wait = RedisBlockedQueue{String}("model_wait")
const db_model_ongoing = RedisList{String}("model_ongoing")
const db_task_done = RedisList{String}("task_done")
const db_task_def = RedisDict{String, String}("task_def")

include("graph.jl")

include("keras/wrapper.jl")
include("keras/dispatch.jl")

function main()
    while true
        # 1. retrive task
        task_id = dequeue!(db_model_wait)
        push!(db_model_ongoing, task_id)
        info("[model $(now())]: $task_id started")

        # 2. train model
        def = db_task_def[task_id] |> JSON.parse
        graph = load_graph(def["data"])
        eval_graph(graph, task_id)

        # 3. report task
        info("[model $(now())]: $task_id finished")
        push!(db_task_done, task_id)
        exec(db_task_ongoing, "lrem", 1, task_id)
    end
end

end # module

model_service = Task(NNBuilder_Model.main)
