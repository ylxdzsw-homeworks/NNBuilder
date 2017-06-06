mutable struct Node
    def::Dict
    deps::Dict{Int, Tuple{Node, Int}}
    cache::Nullable
end

Node(x) = Node(x, Dict{Int, Node}(), nothing)

function load_graph(x::Dict)
    nodes = Dict(layer => Node(x["layers"][layer]) for layer in [x["positions"]...;])

    for conn in x["connections"]
        nodes[conn["inputId"]].deps[conn["inputIndex"]+1] = nodes[conn["outputId"]], conn["outputIndex"]+1
    end

    # TODO: check the completeness of deps

    Symbol(x["backend"]), values(nodes), x["train"]
end

function eval_graph(graph, task_id)
    backend, nodes, train = graph

    for node in nodes
        eval_node(node, task_id, backend, train)
    end
end

function eval_node(node::Node, task_id, backend, train)
    deps = map(1:length(node.deps)) do dep
        dep = node.deps[dep]
        cache = car(dep).cache
        value = isnull(cache) ? eval_node(car(dep), task_id, backend, train) : get(cache)
        value[cadr(dep)]
    end

    info = Pair[:task_id => task_id, :train => train]

    for (k, v) in node.def @unless k in ("type", "id")
        push!(info, Symbol(k) => v)
    end

    node.cache = dispatch(backend, Val{Symbol(node.def["type"])}(), deps...; info...),
end
