loadCanvasFramework = ->
    $('#main').html """
        <div class="toolbox"></div>
        <div class="canvas"></div>
    """

    app.canvas = app.model.model
    do fillToolbox

fillToolbox = ->
    for layer in do getLayerList
        {input, output} = getLayerInfo layer

        node = renderNode layer, input, output, layer
            .on 'dragstart', onToolboxLayerDragStart
            .on 'dragend', onToolboxLayerDragEnd

        $("<div class='toolbox-item'></div>")
            .append node
            .appendTo $('.toolbox')

onToolboxLayerDragStart = (e) ->
    e.originalEvent.dataTransfer.setData 'text/plain', $(@).data 'id'
    do triggerDraggingOverlay

onToolboxLayerDragEnd = (e) ->
    do destroyDraggingOverlay

onOverlayDrop = (e) ->
    layer = {type: e.originalEvent.dataTransfer.getData 'text'}
    makeIdFor layer
    {input, output} = getLayerInfo layer.type
    app.canvas.layers[layer.id] = layer
    node = renderNode layer.type, input, output, layer.id

    {row, col} = do $(@).data

    if row == app.canvas.positions.length
        cell = $("<div class='cell'></div>")
            .append node
        level = $("<div class='level'></div>")
            .append cell
        $('.canvas').append level
        app.canvas.positions.push [layer.id]
    else
        $("<div class='cell'></div>")
            .append node
        app.canvas.positions[row][col]
        #TODO

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

triggerDraggingOverlay = ->
    lines = $('.canvas>.level')

    newRow = $("<div></div>")
        .addClass 'dragging-overlay'
        .data 'row', lines.length
        .data 'col', 0
        .on 'drop', onOverlayDrop
        .on 'dragover', preventDefault
        .on 'dragenter', onOverlayDragEnter
        .on 'dragleave', onOverlayDragLeave
        .css
            top: 120 * lines.length
            left: 0
            width: '100%'
            borderBottom: 'none'

    $('.canvas')
        .append newRow

destroyDraggingOverlay = ->
    do $('.dragging-overlay').remove

# div.node
#   ol.node-input-list
#     li.node-input-item
#   div.node-body
#     h5.node-body-name
#     ul.node-plugin-list
#       li.node-plugin-item
#   ol.node-output-list
#     li.node-output-item
renderNode = (name, input, output, id) ->
    $ """
        <div class="node" draggable="true" data-id="#{id}">
            <ol class="input-list total-#{input}">
                #{
                    ("<li class='input-item' data-index='#{i}'></li>" for i in [0...input]).join('')
                }
            </ol>
            <div class="body">
                <h5 class="body-name"> #{name} </h5>
                <ul class="plugin-list"></ul>
            </div>
            <ol class="output-list total-#{output}">
                #{
                    ("<li class='output-item' data-index='#{i}'></li>" for i in [0...output]).join('')
                }
            </ol>
        </div>
    """
