const db_data_wait = RedisBlockedQueue{String}("data_wait")
const db_task_def = RedisDict{String, String}("task_def")
const db_task_log = RedisDict{String, String}("task_log")

@resource tasks <: root let
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

        tasks = collect(keys(db_task_def))

        idx = find(x->JSON.parse(db_task_def[x])["project"]==project, tasks)
        isempty(idx) ? 404 : JSON.json(tasks[idx])
    end

    :POST => begin
        # TODO: check model
        task_id = "task$(db_uid[])"
        db_task_def[task_id] = req[:body]
        enqueue!(db_data_wait, task_id)
        db_task_log[task_id] = "[$(now())] 等待调度...\n"
        json"{task_id: $task_id}"
    end
end

@resource task <: tasks let
    :route => "*"

    :GET => begin
        db_task_log[id]
    end
end
