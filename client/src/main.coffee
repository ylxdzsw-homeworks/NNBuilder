window.app = Object.create null

newProject = (name) ->
    $.post url: "/projects", data: JSON.stringify {name}
        .fail showError
        .done (data) ->
            id = JSON.parse(data).id
            app.project = {id, name}
            app.model = do newModel
            do saveCheckPoint
            do navModel
            $('#dialog-new-project').modal 'hide'

newModel = ->
    version: 1
    project: app.project.id
    backend: 'keras'
    model:
        layers: {}
        positions: []
        connections: []
    processing:
        layers: {}
        positions: []
        connections: []
    train:
        epoch: 5
        batch: 64
        loss: 'categorical_crossentropy'
        optimizer: 'SGD'
        momentum: 0.9
        decay: 0
        lr: 0.1

saveCheckPoint = (cb=->) ->
    if not app.model?
        return #TODO

    $.post url: "/models", data: JSON.stringify app.model
        .fail showError
        .done cb

navModel = ->
    if not app.model?
        return #TODO

    $('.nav>li').removeClass 'active'
    $('#nav-model').addClass 'active'
    do loadCanvasFramework

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
    do loadTrainView

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

preventDefault = (e) ->
    do e.preventDefault

stopPropagation = (e) ->
    do e.stopPropagation

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
                    $ "<button class='list-group-item' data-id='#{id}' data-name='#{name}'>#{name}</button>"
                        .click onProjectSelected
                        .appendTo '#dialog-load-project-list'

onProjectSelected = ->
    {id, name} = do $(@).data
    app.project = {id, name}
    $.get url: '/models', data: project: id
        .fail showError
        .done (data) ->
            app.model = JSON.parse data
            do navModel
            $('#dialog-load-project').modal 'hide'

$ ->
    $('#dialog-new-project-submit').click onNewProjectSubmit
    $('#dialog-load-project').on 'show.bs.modal', onLoadProjectShow

    $('#nav-model').click navModel
    $('#nav-data').click navData
    $('#nav-train').click navTrain

    $('#nav-menu-save').click -> saveCheckPoint -> showToast "保存成功"
