function dispatch(::Val{:Keras}, ::Val{:Affine}, x; n=0, plugins=[], kwargs...)
    z = Keras.Dense(n)(x)

    activation = map(x->x["type"], plugins)

    if "sigmoid" in activation
        z = Keras.Activation("sigmoid")(z)
    elseif "tanh" in activation
        z = Keras.Activation("tanh")(z)
    elseif "relu" in activation
        z = Keras.Activation("relu")(z)
    elseif "softmax" in activation
        z = Keras.Activation("softmax")(z)
    else
        warn("no activation")
    end

    z
end

function dispatch(::Val{:Keras}, ::Val{:Conv}, x; n=0, kernel=[], stride=[], padding="", plugins=[], kwargs...)
    f = if length(kernel) == 1
        Keras.Conv1D(n, kernel[], strides=stride[], padding=padding)
    elseif length(kernel) == 2
        Keras.Conv2D(n, Tuple(kernel), strides=Tuple(stride), padding=padding)
    elseif length(kernel) == 3
        Keras.Conv3D(n, Tuple(kernel), strides=Tuple(stride), padding=padding)
    else
        error("BUG")
    end

    z = f(x)

    activation = map(x->x["type"], plugins)

    if "sigmoid" in activation
        z = Keras.Activation("sigmoid")(z)
    elseif "tanh" in activation
        z = Keras.Activation("tanh")(z)
    elseif "relu" in activation
        z = Keras.Activation("relu")(z)
    elseif "softmax" in activation
        z = Keras.Activation("softmax")(z)
    else
        warn("no activation")
    end

    z
end

function dispatch(::Val{:Keras}, ::Val{:Pool}, x; kernel=[], stride=[], padding="", func="", kwargs...)
    f = if length(kernel) == 1 && func == "max"
        Keras.MaxPooling1D(kernel[], strides=stride[], padding=padding)
    elseif length(kernel) == 1 && func == "mean"
        Keras.AveragePooling1D(kernel[], strides=stride[], padding=padding)
    elseif length(kernel) == 2 && func == "max"
        Keras.MaxPooling2D(Tuple(kernel), strides=Tuple(stride), padding=padding)
    elseif length(kernel) == 2 && func == "mean"
        Keras.MaxPooling2D(Tuple(kernel), strides=Tuple(stride), padding=padding)
    elseif length(kernel) == 3 && func == "max"
        Keras.MaxPooling3D(Tuple(kernel), strides=Tuple(stride), padding=padding)
    elseif length(kernel) == 3 && func == "mean"
        Keras.MaxPooling3D(Tuple(kernel), strides=Tuple(stride), padding=padding)
    else
        error("BUG")
    end

    f(x)
end

function dispatch(::Val{:Keras}, ::Val{:Flat}, x; kwargs...)
    Keras.Flatten()(x)
end

function dispatch(::Val{:Keras}, ::Val{:Input}; index=0, task_id="", kwargs...)
    h5open("$cache_dir/$task_id.h5") do x
        Keras.Input(shape=cdr(size(x["X$index"])))
    end
end

function dispatch(::Val{:Keras}, ::Val{:Output}, x; kwargs...)
    x
end
