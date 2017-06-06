function train(keras::Val{:Keras}, task_id, inputs, output, setting)
    X = map(inputs) do input
        index = input.def["index"]
        h5read("$cache_dir/$task_id.h5", "X$index")
    end

    Y = h5read("$cache_dir/$task_id.h5", "Y")

    epoch = setting["epoch"]
    batch = setting["batch"]

    optimizer = build_optimizer(keras, setting)
    loss = map_loss(keras, setting["loss"])

    inputs = map(x->car(get(x.cache)), inputs)

    model = Keras.Model(inputs=inputs, outputs=[output])
    model[:compile](optimizer, loss)
    model[:fit](X, Y, batch_size=batch, epochs=epoch)
    model[:save]("$model_dir/$task_id.h5")
end

function build_optimizer(::Val{:Keras}, setting)
    lr = setting["lr"]

    if setting["optimizer"] == "SGD"
        o = Keras.SGD(lr=lr, decay=setting["decay"], momentum=setting["momentum"])
    elseif setting["optimizer"] == "RMSProp"
        o = Keras.RMSProp(lr=lr, rho=setting["rho"], epsilon=setting["epsilon"], decay=setting["decay"])
    elseif setting["optimizer"] == "AdaGrad"
        o = Keras.AdaGrad(lr=lr, epsilon=setting["epsilon"], decay=setting["decay"])
    elseif setting["optimizer"] == "AdaDelta"
        o = Keras.AdaDelta(lr=lr, rho=setting["rho"], epsilon=setting["epsilon"], decay=setting["decay"])
    elseif setting["optimizer"] == "Adam"
        o = Keras.Adam(lr=lr, beta1=setting["beta1"], beta2=setting["beta2"], epsilon=setting["epsilon"], decay=setting["decay"])
    end
end

function map_loss(keras, x)
    x
end
