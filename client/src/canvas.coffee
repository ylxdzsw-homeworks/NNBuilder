loadCanvasFramework = ->
    $('#main').html """
        <div class="toolbox"></div>
        <div class="canvas">
            <svg class="canvas_background" xmlns="http://www.w3.org/2000/svg"></svg>
        </div>
    """

    $('.toolbox')
        .on 'dragover', preventDefault
        .on 'drop', destroyDraggingOverlay

    app.canvas = app.model.model
    do fillToolbox
    do fillCanvasNodes
    do renderConnections

fillToolbox = ->
    for layer in do getLayerList
        {input, output} = getLayerInfo layer

        node = renderNode layer, input, output, layer
            .on 'dragstart', onToolboxLayerDragStart
            .on 'dragend', destroyDraggingOverlay

        $("<div class='toolbox-item'></div>")
            .append node
            .appendTo $('.toolbox')

fillCanvasNodes = ->
    for level in app.canvas.positions
        line = $("<div class='level'></div>")

        for layer in level
            layer = app.canvas.layers[layer]
            {input, output} = getLayerInfo layer.type

            node = renderNode layer.type, input, output, layer.id
                .on 'dragstart', onCanvasLayerDragStart
                .on 'dblclick', onCanvasNodeDoubleClick

            $('.input-item', node)
                .on 'dragstart', stopPropagation
                .on 'dragstart', onInputPinDragStart
                .on 'dragend', stopPropagation
                .on 'dragend', onInputPinDragEnd
                .on 'dragover', preventDefault
                .on 'drop', onInputPinDrop

            $('.output-item', node)
                .on 'dragstart', stopPropagation
                .on 'dragstart', onOutputPinDragStart
                .on 'dragend', stopPropagation
                .on 'dragend', onOutputPinDragEnd
                .on 'dragover', preventDefault
                .on 'drop', onOutputPinDrop

            $("<div class='cell'></div>")
                .append node
                .appendTo line

        $('.canvas').append line

onToolboxLayerDragStart = (e) ->
    e.originalEvent.dataTransfer.setData 'application/json', JSON.stringify {type: $(@).data 'id'}
    do triggerDraggingOverlay

onOverlayDrop = (e) ->
    data = JSON.parse e.originalEvent.dataTransfer.getData 'application/json'
    layer = switch
        when data.id?
            app.canvas.layers[data.id]
        when data.type?
            makeIdFor data
        else
            throw "fuck"

    {input, output} = getLayerInfo layer.type
    app.canvas.layers[layer.id] = layer
    node = renderNode layer.type, input, output, layer.id
        .on 'dragstart', onCanvasLayerDragStart
        .on 'dblclick', onCanvasNodeDoubleClick

    $('.input-item', node)
        .on 'dragstart', stopPropagation
        .on 'dragstart', onInputPinDragStart
        .on 'dragend', stopPropagation
        .on 'dragend', onInputPinDragEnd
        .on 'dragover', preventDefault
        .on 'drop', onInputPinDrop

    $('.output-item', node)
        .on 'dragstart', stopPropagation
        .on 'dragstart', onOutputPinDragStart
        .on 'dragend', stopPropagation
        .on 'dragend', onOutputPinDragEnd
        .on 'dragover', preventDefault
        .on 'drop', onOutputPinDrop

    {row, col} = do $(@).data

    if row == app.canvas.positions.length
        cell = $("<div class='cell'></div>")
            .append node
        level = $("<div class='level'></div>")
            .append cell
        $('.canvas').append level
        app.canvas.positions.push [layer.id]
    else
        level = $('.canvas > .level').eq row
        cells = $('.cell', level)
        if col == cells.length
            $("<div class='cell'></div>")
                .append node
                .appendTo level
        else
            $("<div class='cell'></div>")
                .append node
                .insertBefore cells.eq col
        app.canvas.positions[row].splice col, 0, layer.id

    do renderConnections
    do destroyDraggingOverlay
    do clearDeadLayers

onCanvasLayerDragStart = (e) ->
    id = $(@).data 'id'
    e.originalEvent.dataTransfer.setData 'application/json', JSON.stringify {id}
    setImmediate ->
        removeLayerById id
        do renderConnections
        do triggerDraggingOverlay

removeLayerById = (id) ->
    app.canvas.connections = app.canvas.connections.filter (conn) -> id not in [conn.inputId, conn.outputId]

    for i in [0...app.canvas.positions.length]
        for j in [0...app.canvas.positions[i].length]
            if app.canvas.positions[i][j] == id
                return if app.canvas.positions[i].length == 1
                    app.canvas.positions.splice i, 1
                    do $(".canvas > .level").eq(i).remove
                else
                    app.canvas.positions[i].splice j, 1
                    do $(".canvas > .level:eq(#{i}) > .cell").eq(j).remove

    throw 'bug'

setImmediate = (cb) ->
    setTimeout cb, 4

clearDeadLayers = ->
    set = [].concat(app.canvas.positions...)
    for k of app.canvas.layers
        delete app.canvas.layers[k] if k not in set

makeIdFor = do ->
    str = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
    gen = (prefix) -> prefix + '_' + (str[Math.floor(Math.random() * str.length)] for i in [1..5]).join('')
    (layer) ->
        loop
            id = gen layer.type
            if id not of app.model.model.layers and id not of app.model.processing.layers
                layer.id = id
                return layer

onOverlayDragEnter = (e) ->
    $(e.currentTarget).addClass 'active'

onOverlayDragLeave = (e) ->
    $(e.currentTarget).removeClass 'active'

renderOverlay = ->
    $("<div></div>")
        .addClass 'dragging-overlay'
        .on 'drop', onOverlayDrop
        .on 'dragover', preventDefault
        .on 'dragenter', onOverlayDragEnter
        .on 'dragleave', onOverlayDragLeave

triggerDraggingOverlay = ->
    lines = $('.canvas>.level')

    for i in [0...lines.length]
        left = 0
        cells = $('.cell', lines[i])

        for j in [0...cells.length]
            cell = cells.eq j
            right = cell.position().left + cell.innerWidth() / 2
            renderOverlay()
                .data 'row', i
                .data 'col', j
                .css
                    top: 100 * i
                    left: left
                    width: right - left
                .appendTo lines[i]
            left = right

        renderOverlay()
            .data 'row', i
            .data 'col', j
            .css
                top: 100 * i
                left: left
                width: $('.canvas').width() - left
                borderRight: 'none'
            .appendTo lines[i]

    renderOverlay()
        .data 'row', lines.length
        .data 'col', 0
        .css
            top: 100 * lines.length
            left: 0
            width: '100%'
            border: 'none'
        .appendTo $('.canvas')

destroyDraggingOverlay = ->
    do $('.dragging-overlay').remove

renderNode = (name, input, output, id) ->
    $ """
        <div class="node" draggable="true" data-id="#{id}">
            <ol class="input-list total-#{input}">
                #{
                    ("<li class='input-item' draggable='true' data-id='#{id}' data-index='#{i}'></li>" for i in [0...input]).join('')
                }
            </ol>
            <div class="body">
                <h5 class="body-name"> #{name} </h5>
                <ul class="plugin-list"></ul>
            </div>
            <ol class="output-list total-#{output}">
                #{
                    ("<li class='output-item' draggable='true' data-id='#{id}' data-index='#{i}'></li>" for i in [0...output]).join('')
                }
            </ol>
        </div>
    """

onInputPinDragStart = (e) ->
    {id, index} = do $(@).data
    e.originalEvent.dataTransfer.setData 'application/json', JSON.stringify {id, index, type: 'input'}
    app.canvas.connections = app.canvas.connections.filter (conn) -> conn.inputId isnt id or conn.inputIndex isnt index
    do renderConnections

onInputPinDragEnd = (e) ->

onInputPinDrop = (e) ->
    {id: outputId, index: outputIndex, type} = JSON.parse e.originalEvent.dataTransfer.getData 'application/json'
    return if type isnt 'output'

    {id: inputId, index: inputIndex} = do $(@).data
    return if findLevel(inputId) <= findLevel(outputId)

    app.canvas.connections = app.canvas.connections.filter (conn) -> conn.inputId isnt inputId or conn.inputIndex isnt inputIndex
    app.canvas.connections.push {inputId, inputIndex, outputId, outputIndex}
    do renderConnections

onOutputPinDragStart = (e) ->
    {id, index} = do $(@).data
    e.originalEvent.dataTransfer.setData 'application/json', JSON.stringify {id, index, type: 'output'}

onOutputPinDragEnd = (e) ->

onOutputPinDrop = (e) ->
    {id: inputId, index: inputIndex, type} = JSON.parse e.originalEvent.dataTransfer.getData 'application/json'
    return if type isnt 'input'

    {id: outputId, index: outputIndex} = do $(@).data
    return if findLevel(inputId) <= findLevel(outputId)

    app.canvas.connections.push {inputId, inputIndex, outputId, outputIndex}
    do renderConnections

findLevel = (id) ->
    app.canvas.positions.findIndex (x) -> id in x

renderConnections = ->
    {top: refTop, left: refLeft} = do $('.canvas_background').offset

    lines = for {inputId, outputId, inputIndex, outputIndex} in app.canvas.connections
        {top: inputTop,  left: inputLeft}  = do $(".input-item[data-id=#{inputId}][data-index=#{inputIndex}]").offset
        {top: outputTop, left: outputLeft} = do $(".output-item[data-id=#{outputId}][data-index=#{outputIndex}]").offset
        x1 = inputLeft - refLeft + 4
        x2 = outputLeft - refLeft + 4
        y1 = inputTop - refTop + 2
        y2 = outputTop - refTop + 8
        """<line x1="#{x1}" x2="#{x2}" y1="#{y1}" y2="#{y2}" stroke-width="1.5" stroke="#000" />"""

    $('.canvas_background').width do $('.canvas').width
    $('.canvas_background').height $('.canvas').prop 'scrollHeight'
    $('.canvas_background').html """
        <g>
            <title> fuck </title>
            #{lines.join("\n  ")}
        </g>
    """

onCanvasNodeDoubleClick = ->
    layer = app.canvas.layers[$(@).data 'id']

    do $('#dialog-set-param form').empty

    for name, def of getLayerParams layer.type
        renderParam name, def, layer[name]
            .appendTo $('#dialog-set-param form')

    $('#dialog-set-param')
        .data 'id', layer.id
        .modal()

renderParam = (name, def, value='') ->
    param = $ switch def.type
        when 'integer'
            """
                <div class="form-group">
                    <label class="col-sm-2 control-label" for="#{name}">#{name}</label>
                    <div class="col-sm-9">
                        <input type="number" step="1" class="form-control" id="#{name}" value="#{value}" />
                    </div>
                </div>
            """
        when 'size'
            """
                <div class="form-group">
                    <label class="col-sm-2 control-label" for="#{name}">#{name}</label>
                    <div class="col-sm-9">
                        <input type="text" class="form-control" id="#{name}" value="#{value}" />
                    </div>
                </div>
            """
        when 'number'
            """
                <div class="form-group">
                    <label class="col-sm-2 control-label" for="#{name}">#{name}</label>
                    <div class="col-sm-9">
                        <input type="number" class="form-control" id="#{name}" value="#{value}" />
                    </div>
                </div>
            """
        else
            throw 'bug' if not def.type.startsWith 'enum: '

            """
                <div class="form-group">
                    <label class="col-sm-2 control-label" for="#{name}">#{name}</label>
                    <div class="col-sm-9">
                        <select class="form-control" id="#{name}" value="#{value}">
                            #{
                                ("<option>#{option}</option>" for option in def.type[6..].split ', ').join '\n'
                            }
                        </select>
                    </div>
                </div>
            """

onSetParamFieldFocus = ->
    $(@).removeClass 'invalid'

onSetParamSubmit = ->
    id = $('#dialog-set-param').data 'id'
    layer = app.canvas.layers[id]

    valid = true

    for name, def of getLayerParams layer.type
        v = do $("##{name}").val

        continue if v is ''

        try
            v = parseType def.type, v
        catch e
            $("##{name}").addClass 'invalid'
            console.log e
            valid = false
            continue

        if msg = def.check? v
            $("##{name}").addClass 'invalid'
            console.log msg
            valid = false
            continue

        layer[name] = v

    if valid
        $('#dialog-set-param').modal 'hide'

parseType = (type, value) ->
    switch type
        when 'integer'
            value = parseInt value
            throw 'not an integer' if isNaN value
        when 'number'
            value = parseFloat value
            throw 'not a number' if isNaN value
        when 'size'
            value = value.match /\d+/g
            throw 'not a valid size expression' if not value?
            value = value.map (x) -> parseInt x

    value

$ ->
    $('#dialog-set-param-submit').click onSetParamSubmit
    $("#dialog-set-param input").on 'focus', onSetParamFieldFocus
