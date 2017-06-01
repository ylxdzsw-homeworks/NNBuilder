loadTrainView = ->
    $('#main').html """
        <div class="col-md-5">
            <h3> 训练配置 </h3>
            <form class="form row train-setting">
                <div class="col-sm-6 form-group">
                    <label for="backend">Backend</label>
                    <select class="form-control" id="backend" value="#{app.model.backend}">
                        <option> Keras </option>
                        <option> MXNet </option>
                    </select>
                </div>
                <div class="col-sm-6 form-group">
                    <label for="optimizer">Optimizer</label>
                    <select class="form-control" id="optimizer" value="#{app.model.train.optimizer}">
                        <option> SGD </option>
                        <option> AdaGrad </option>
                        <option> Adam </option>
                        <option> AdaDelta </option>
                        <option> RMSProp </option>
                    </select>
                </div>
                <div class="col-sm-6 form-group">
                    <label for="loss">Loss</label>
                    <select class="form-control" id="loss" value="#{app.model.train.loss}">
                        <option> mean_squared_error </option>
                        <option> mean_absolute_error </option>
                        <option> categorical_crossentropy </option>
                        <option> binary_crossentropy </option>
                    </select>
                </div>
                <div class="col-sm-6 form-group">
                    <label for="epoch">Epoch</label>
                    <input type="number" min="1" step="1" class="form-control" id="epoch" value="#{app.model.train.epoch}" />
                </div>
                <div class="col-sm-6 form-group">
                    <label for="batch">Batch Size</label>
                    <input type="number" min="1" step="1" class="form-control" id="batch" value="#{app.model.train.batch}" />
                </div>
                <div class="col-sm-6 form-group">
                    <label for="lr">Learning Rate</label>
                    <input type="number" class="form-control" id="lr" value="#{app.model.train.lr}" />
                </div>

                <button type="submit" class="btn btn-primary train-setting-submit">Submit</button>
            </form>
        </div>
        <div class="col-md-7">
            <h3> 运行日志 </h3>
            <pre class="log">
                this is the fucking log
                this is the fucking log
                this is the fucking log
                this is the fucking log
                this is the fucking log
                this is the fucking log
                this is the fucking log
                this is the fucking log
                this is the fucking log
                this is the fucking log
                this is the fucking log
                this is the fucking log
            </pre>
        </div>
    """

    $('#backend').on 'change', onBackendSet
    $('#optimizer').on 'change', onOptimizerSet
    $('#loss').on 'change', onLossSet
    $('#epoch').on 'blur', onEpochSet
    $('#batch').on 'blur', onBatchSet
    $('#lr').on 'blur', onLearningRateSet

    do renderOptimizerOptions

onBackendSet = ->
    app.model.backend = do $(@).val

onOptimizerSet = ->
    app.model.train.optimizer = do $(@).val

    for name, info of getOptimizerInfo app.model.train.optimizer
        app.model.train[name] ?= info.default

    do renderOptimizerOptions

onLossSet = ->
    app.model.train.loss = do $(@).val

onEpochSet = ->
    app.model.train.epoch = parseInt do $(@).val

onBatchSet = ->
    app.model.train.batch = parseInt do $(@).val

onLearningRateSet = ->
    app.model.train.lr = parseFloat do $(@).val

onOptimizerFieldSet = ->
    info = getOptimizerInfo app.model.train.optimizer

    if msg = info[@id].check parseFloat @value
        $(@).addClass 'invalid'
        console.log msg
        return

    app.model.train[@id] = parseFloat @value

renderOptimizerOptions = ->
    do $('.optimizer-field').remove

    anchor = $('.train-setting-submit')

    for name, info of getOptimizerInfo app.model.train.optimizer
        anchor.before $ """
            <div class="col-sm-6 form-group optimizer-field">
                <label for="#{name}">#{name}</label>
                <input type="number" class="form-control" id="#{name}" value="#{app.model.train[name]}" />
            </div>
        """

        $("##{name}").on 'blur', onOptimizerFieldSet
