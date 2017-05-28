loadCanvasFramework = ->
    $('#main').html """
        <div class="toolbox"></div>
        <div class="canvas"></div>
    """

    do fillToolbox

fillToolbox = ->
    for layer in do getLayerList
        {input, output} = getLayerInfo layer

        node = renderNode layer, input, output
            .on 'dragstart', onToolboxLayerDragStart
            .on 'dragend', onToolboxLayerDragEnd

        $("<div class='toolbox-item'></div>")
            .append node
            .appendTo $('.toolbox')


onToolboxLayerDragStart = (e) ->
    e.originalEvent.dataTransfer.setData 'text/plain', e.target.dataset.name
    do triggerDraggingOverlay

onToolboxLayerDragEnd = (e) ->
    do destroyDraggingOverlay

triggerDraggingOverlay = ->
    lines = $('.canvas>.level')

    newRow = $("<div></div>")
        .addClass 'dragging-overlay'
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
renderNode = (name, input, output) ->
    $ """
        <div class="node" draggable="true" data-name="#{name}">
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
