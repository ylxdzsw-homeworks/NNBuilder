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
    data:
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
    loadCanvasFramework 'model'

navData = ->
    if not app.model?
        return #TODO

    $('.nav>li').removeClass 'active'
    $('#nav-data').addClass 'active'
    loadCanvasFramework 'data'

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

onLoadModelShow = ->
    $('#dialog-load-model-list').html ''
    $.get url: '/models', data: project: app.project.id, all: true
        .fail showError
        .done (data) ->
            JSON.parse data
                .forEach (model) ->
                    $ "<button class='list-group-item'>#{model.timestamp}</button>"
                        .data 'model', model
                        .click onModelSelected
                        .appendTo '#dialog-load-model-list'

onModelSelected = ->
    app.model = $(@).data 'model'
    showToast "读取完毕"
    switch $('.nav>li.active')[0].id
        when 'nav-model'
            do navModel
        when 'nav-data'
            do navData
        when 'nav-train'
            do navTrain
    $('#dialog-load-model').modal 'hide'

downloadAs = (filename, text) ->
    a = $('<a></a>')
        .attr 'href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(text)
        .attr 'download', filename
    do a[0].click

exportModel = ->
    if not app.model?
        return #TODO

    downloadAs "model.json", JSON.stringify app.model

$ ->
    $('#dialog-new-project-submit').click onNewProjectSubmit
    $('#dialog-load-project').on 'show.bs.modal', onLoadProjectShow
    $('#dialog-load-model').on 'show.bs.modal', onLoadModelShow

    $('#nav-model').click navModel
    $('#nav-data').click navData
    $('#nav-train').click navTrain

    $('#nav-menu-save').click -> saveCheckPoint -> showToast "保存成功"

    $('#nav-menu-export').click -> exportModel
