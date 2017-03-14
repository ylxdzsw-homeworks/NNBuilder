window.app = Object.create null

newProject = (name) ->
    $.post url: "/projects", data: JSON.stringify {name}
        .fail showError
        .done (data) ->
            id = JSON.parse(data).id
            app.project = id
            app.model = do newModel
            do navModel

newModel = ->
    {
        "version": 1,
        "name": "MNIST Example",
        "project": 1,
        "backend": "keras",
        "layers": [{
            "type": "BatchInput",
            "name": "input1",
            "outshape": [28, 28, 1]
        }, {
            "type": "Convolution",
            "name": "conv1",
            "in": "input1",
            "filter": [3, 3],
            "stride": [1, 1],
            "n_filter": 64,
            "plugins": [{
                "type": "Activation",
                "function": "ReLU"
            }]
        }, {
            "type": "Pooling",
            "name": "pool1",
            "in": "conv1",
            "function": "max",
            "filter": [2, 2],
            "stride": [2, 2]
        }, {
            "type": "Convolution",
            "name": "conv2",
            "in": "pool1",
            "filter": [3, 3],
            "stride": [1, 1],
            "n_filter": 64,
            "plugins": [{
                "type": "Activation",
                "function": "ReLU"
            }]
        }, {
            "type": "Pooling",
            "name": "pool2",
            "in": "conv2",
            "function": "max",
            "filter": [2, 2],
            "stride": [2, 2]
        }, {
            "type": "Flatten",
            "name": "flat1",
            "in": "pool2"
        }, {
            "type": "InnerProduct",
            "name": "fc1",
            "in": "flat1",
            "plugins": [{
                "type": "Activation",
                "function": "Sigmoid"
            }]
        }, {
            "type": "Softmax",
            "name": "output"
        }],
        "train": {
            "n_epoch": "15",
            "batch_size": "64",
            "loss": "categorical_crossentropy",
            "metrics": ["accuracy"],
            "optimizer": {
                "type": "SGD",
                "lr": 0.01,
                "decay": 1e-6,
                "momentum": 0.9
            }
        }
    }

navModel = ->
    if not app.model?
        return #TODO

    $('.nav>li').removeClass 'active'
    $('#nav-model').addClass 'active'
    $('#main').html null
    $('#dialog-new-project').modal 'hide'

navData = ->
    if not app.model?
        return #TODO

    $('.nav>li').removeClass 'active'
    $('#nav-data').addClass 'active'

navTrain = ->
    if not app.model?
        return #TODO

    $('.nav>li').removeClass 'active'
    $('#nav-train').addClass 'active'

showToast = do ->
    done = ->
    (msg, level='success', duration=2000) ->
        $ '#toast'
            .text msg
            .removeClass "alert-success alert-info alert-warning alert-danger"
            .addClass "in alert-#{level}"
        cb = ->
            if done == cb
                $('#toast').removeClass 'in'
        done = cb
        setTimeout cb, duration

showError = (e) ->
    showToast e.msg, 'danger'

onNewProjectSubmit = ->
    name = $('#dialog-new-project-name').val()
    if name.trim() == ""
        # TODO
    else
        $('#dialog-new-project-name').val ''
        newProject name

onLoadProjectShow = ->
    $('#dialog-load-project-list').html ''
    $.get '/projects'
        .fail showError
        .done (data) ->
            JSON.parse data
                .forEach ({id, name}) ->
                    $ "<button class='list-group-item' data-id='#{id}'>#{name}</button>"
                        .click onProjectSelected
                        .appendTo '#dialog-load-project-list'

onProjectSelected = ->
    id = $(@).data 'id'
    app.project = id
    $.get url: '/models', data: project: id

$ ->
    $('#dialog-new-project-submit').click onNewProjectSubmit
    $('#dialog-load-project').on 'show.bs.modal', onLoadProjectShow

    $('#nav-model').click navModel
    $('#nav-data').click navData
    $('#nav-train').click navTrain

