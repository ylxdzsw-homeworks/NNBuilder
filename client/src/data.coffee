layerInfo =
    Affine:
        category: 'core'
        input: 1
        output: 1
        params:
            n:
                description: "numebr of hidden units"
                type: 'integer'
                check: (x) ->
                    return "Affine layer must have positive number of units" if x < 0
        plugins: ['activation']
    Conv:
        category: 'convolution'
        input: 1
        output: 1
        params:
            kernel:
                description: "kernel size"
                type: 'size'
            stride:
                description: "kernel stride"
                type: 'size'
        plugins: ['activation']
    Pool:
        category: 'convolution'
        input: 1
        output: 1
        params:
            kernel:
                description: "kernel size"
                type: 'size'
            stride:
                description: "kernel stride"
                type: 'size'
            func:
                description: "aggregate function"
                type: 'enum: max, mean'
    Flat:
        category: 'convolution'
        input: 1
        output: 1
        params: {}
    Softmax:
        category: 'core'
        input: 1
        output: 1
        params: {}
    Input:
        category: 'io'
        input: 0
        output: 1
        params:
            index:
                description: "the index of the input"
                type: 'integer'
                check: (x) ->
                    return "input index must be positive" if x < 0
    Output:
        category: 'io'
        input: 1
        output: 0
        params: {}

    IDX:
        category: 'source'
        input: 0
        output: 1
        params:
            file:
                description: "path to file"
                type: 'file'
    HDF5:
        category: 'source'
        input: 0
        output: 1
        params:
            variable:
                description: "variable name"
                type: 'symbol'
            file:
                description: "path to file"
                type: 'file'
    Flatten:
        category: 'reshape'
        input: 1
        output: 1
        params: {}
    Normal:
        category: 'transform'
        input: 1
        output: 1
        params:
            func:
                description: "function used to normalize"
                type: 'enum: standardize, scale'
            dim:
                description: "normalize along with specific dimension (start from 1)"
                type: 'size'
    X:
        category: 'output'
        input: 1
        output: 0
        params:
            index:
                description: "the index of the output"
                type: 'integer'
                check: (x) ->
                    return "output index must be positive" if x < 0
    Y:
        category: 'output'
        input: 1
        output: 0
        params: {}

getLayerList = (category) -> k for k, v of layerInfo when v.category is category

getLayerInfo = (name) ->
    layerInfo[name] ? throw "no such a layer: #{name}"

getLayerParams = (name) ->
    layerInfo[name]?.params ? throw "no such a layer: #{name}"

optimizerInfo =
    SGD:
        momentum:
            default: 0.9
            check: (x) ->
                return "0 <= momentum < 1" if not (0 <= x < 1)
        decay:
            default: 0
            check: (x) ->
                return "decay >= 0" if x < 0
    RMSProp:
        rho:
            default: 0.9
            check: (x) ->
                return "rho >= 0" if x < 0
        epsilon:
            default: 1e-08
            check: (x) ->
                return "epsilon >= 0" if x < 0
        decay:
            default: 0
            check: (x) ->
                return "decay >= 0" if x < 0
    AdaGrad:
        epsilon:
            default: 1e-08
            check: (x) ->
                return "epsilon >= 0" if x < 0
        decay:
            default: 0
            check: (x) ->
                return "decay >= 0" if x < 0
    AdaDelta:
        rho:
            default: 0.95
            check: (x) ->
                return "rho >= 0" if x < 0
        epsilon:
            default: 1e-08
            check: (x) ->
                return "epsilon >= 0" if x < 0
        decay:
            default: 0
            check: (x) ->
                return "decay >= 0" if x < 0
    Adam:
        beta1:
            default: 0.9
            check: (x) ->
                return "0 < beta1 < 1" if not (0 < x < 1)
        beta2:
            default: 0.999
            check: (x) ->
                return "0 < beta2 < 1" if not (0 < x < 1)
        epsilon:
            default: 1e-08
            check: (x) ->
                return "epsilon >= 0" if x < 0
        decay:
            default: 0
            check: (x) ->
                return "decay >= 0" if x < 0

getOptimizerList = -> k for k of optimizerInfo

getOptimizerInfo = (name) ->
    optimizerInfo[name] ? throw "no such a optimizer: #{name}"

pluginInfo =
    sigmoid:
        category: 'activation'
    tanh:
        category: 'activation'
    relu:
        category: 'activation'

getPluginList = (category) -> k for k, v of pluginInfo when v.category is category

getPluginInfo = (name) ->
    pluginInfo[name] ? throw "no such a plugin: #{name}"
