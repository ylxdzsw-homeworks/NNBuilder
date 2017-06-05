const db_data_wait = RedisBlockedQueue{String}("data_wait")
const db_task_def = RedisDict{String, String}("task_def")

@resource tasks <: root let
    :mixin => defaultmixin

    :GET => begin
        # TODO
    end

    :POST => begin
        # TODO: check model
        task_id = "task$(db_uid[])"
        db_task_def[task_id] = req[:body]
        enqueue!(db_data_wait, task_id)
        json"{task_id: $task_id}"
    end
end

@resource task <: tasks let
    :route => "*"

    :GET => begin
        # TODO
    end
end
