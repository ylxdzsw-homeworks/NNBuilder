loadCanvasFramework = ->
    $('#main').html """
        <div class="toolbox"></div>
        <div class="canvas"></div>
    """

    do fillToolbox

fillToolbox = ->
    for layer in do getLayerList
        $("<div class='toolbox-item'></div>")
            .append renderLayer {type: layer}
            .appendTo $('.toolbox')

# div.node
#   ol.node-input-list
#     li.node-input-item
#   div.node-body
#     h5.node-body-name
#     ul.node-plugin-list
#       li.node-plugin-item
#   ol.node-output-list
#     li.node-output-item
renderLayer = (layer) ->
    layerName = layer.type
    def = getLayerInfo layerName
    $ """
        <div class="node">
            <ol class="input-list">
                #{
                    ("<li class='input-item total-#{def.input}' data-index='#{i}'></li>" for i in [0...def.input]).join('')
                }
            </ol>
            <div class="body">
                <h5 class="body-name"> #{layerName} </h5>
                <ul class="plugin-list"></ul>
            </div>
            <ol class="output-list">
                #{
                    ("<li class='output-item total-#{def.output}' data-index='#{i}'></li>" for i in [0...def.output]).join('')
                }
            </ol>
        </div>
    """
