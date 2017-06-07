module NNBuilder_Data

using Libz
using HDF5
using JSON
using JsonBuilder
using RedisAlchemy

include("../util/language_extension.jl")

set_default_redis_connection(RedisConnectionPool())

const cache_dir = abs"data/cache"
mkpath(cache_dir)

const db_uid = RedisCounter("uid")
const db_data_wait = RedisBlockedQueue{String}("data_wait")
const db_model_wait = RedisBlockedQueue{String}("model_wait")
const db_data_ongoing = RedisList{String}("data_ongoing")
const db_task_def = RedisDict{String, String}("task_def")
const db_task_log = RedisDict{String, String}("task_log")

include("graph.jl")

include("output/X.jl")
include("output/Y.jl")

include("reshape/flatten.jl")
include("reshape/unsqueeze.jl")

include("source/hdf5.jl")
include("source/idx.jl")

include("transform/normal.jl")
include("transform/onehot.jl")

function main()
    while true
        # 1. retrive task
        task_id = dequeue!(db_data_wait)
        push!(db_data_ongoing, task_id)
        println(STDERR, "[data $(now())]: $task_id started")
        db_task_log[task_id] = db_task_log[task_id] * "[$(now())]: 开始进行数据处理\n"

        # 2. run task
        def = db_task_def[task_id] |> JSON.parse
        graph = load_graph(def["data"])
        eval_graph(graph, task_id)

        # 3. report task
        println(STDERR, "[data $(now())]: $task_id finished")
        db_task_log[task_id] = db_task_log[task_id] * "[$(now())]: 数据处理完毕，等待进行训练\n"
        enqueue!(db_model_wait, task_id)
        exec(db_data_ongoing, "lrem", 1, task_id)
    end
end

end # module

data_service = Task(NNBuilder_Data.main)
