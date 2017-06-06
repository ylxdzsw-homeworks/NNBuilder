mutable struct Node
    def::Dict
    deps::Dict{Int, Tuple{Node, Int}}
    cache::Nullable
end

Node(x) = Node(x, Dict{Int, Node}(), nothing)

function load_graph(x::Dict)
    nodes = Dict(layer => Node(x["model"]["layers"][layer]) for layer in [x["model"]["positions"]...;])

    for conn in x["model"]["connections"]
        nodes[conn["inputId"]].deps[conn["inputIndex"]+1] = nodes[conn["outputId"]], conn["outputIndex"]+1
    end

    # TODO: check the completeness of deps

    backend = x["backend"] == "keras" ? Val{:Keras}() :
              x["backend"] == "mxnet" ? Val{:MXNet}() :
              error("BUG")

    backend, values(nodes), x["train"]
end

function eval_graph(graph, task_id)
    backend, nodes, setting = graph

    for node in nodes
        eval_node(node, task_id, backend)
    end

    inputs = [node for node in nodes if node.def["type"] == "Input"]
    output = [car(get(node.cache)) for node in nodes if node.def["type"] == "Output"][1]

    train(backend, task_id, inputs, output, setting)
end

function eval_node(node::Node, task_id, backend)
    if !isnull(node.cache)
        return get(node.cache)
    end

    deps = map(1:length(node.deps)) do dep
        dep = node.deps[dep]
        cache = car(dep).cache
        value = isnull(cache) ? eval_node(car(dep), task_id, backend) : get(cache)
        value[cadr(dep)]
    end

    info = Pair[:task_id => task_id]

    for (k, v) in node.def @unless k in ("type", "id")
        push!(info, Symbol(k) => v)
    end

    node.cache = (dispatch(backend, Val{Symbol(node.def["type"])}(), deps...; info...),)
end
