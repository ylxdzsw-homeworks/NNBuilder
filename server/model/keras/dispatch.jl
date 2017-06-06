function dispatch(::Val{:Keras}, ::Val{:Affine}, x; n=0, plugins=[], kwargs...)
    # TODO: plugins
    Keras.Dense(n)(x) |> Keras.Activation("sigmoid")
end

function dispatch(::Val{:Keras}, ::Val{:Conv}, x; n=0, kernel=[], stride=[], padding="", plugins=[], kwargs...)
    f = if length(kernel) == 1
        Keras.Conv1D(n, kernel[], stride[], padding)
    elseif length(kernel) == 2
        Keras.Conv2D(n, Tuple(kernel), Tuple(stride), padding)
    elseif length(kernel) == 3
        Keras.Conv3D(n, Tuple(kernel), Tuple(stride), padding)
    else
        error("BUG")
    end

    # TODO: plugins

    f(x) |> Keras.Activation("relu")
end

function dispatch(::Val{:Keras}, ::Val{:Pool}, x; kernel=[], stride=[], padding="", func="", kwargs...)
    if length(kernel) == 1 && func == "max"
        Keras.MaxPooling1D(kernel[], stride[], padding)
    elseif length(kernel) == 1 && func == "mean"
        Keras.AveragePooling1D(kernel[], stride[], padding)
    elseif length(kernel) == 2 && func == "max"
        Keras.MaxPooling2D(Tuple(kernel), Tuple(stride), padding)
    elseif length(kernel) == 2 && func == "mean"
        Keras.MaxPooling2D(Tuple(kernel), Tuple(stride), padding)
    elseif length(kernel) == 3 && func == "max"
        Keras.MaxPooling3D(Tuple(kernel), Tuple(stride), padding)
    elseif length(kernel) == 3 && func == "mean"
        Keras.MaxPooling3D(Tuple(kernel), Tuple(stride), padding)
    else
        error("BUG")
    end
end

function dispatch(::Val{:Keras}, ::Val{:Flat}, x; kwargs...)
    Keras.Flatten()(x)
end

function dispatch(::Val{:Keras}, ::Val{:Input}; index=0, task_id="", kwargs...)
    h5open("$cache_dir/$task_id.h5") do x
        Keras.Input(cdr(x["X$index"]))
    end
end

function dispatch(::Val{:Keras}, ::Val{:Output}; task_id="", kwargs...)
    # TODO: train
end
