get_hash = ->
    o = Object.create null
    location.hash[2..]
        .split '&'
        .map (x) -> x.split('=')
        .forEach ([k, v]) -> o[k] = parseInt v
    $.extend {line: 0, page: 20}, o

set_hash = ({line, page}) ->
    history.pushState null, null, "#!line=#{line}&page=#{page}"
    $(window).trigger 'hashchange'

do_query = do ->
    cache = Object.create null
    (query, cb) ->
        if cache in query
            cb cache[query]
        else
            $.post "/command", query, (data) -> # there might be races, but it doesn't matter
                cache[query] = data
                cb data

append_history = do ->
    hist = []
    (line) ->
        hist.unshift(line)
        hist.pop() if hist.length > 20
        $('#history').html hist.join ''

peek_ref = ->
    d = @dataset
    query = do (d.q ? d.query).trim
    show = switch d.f ? d.format ? 't'
        when 't', 'text'
            show_text
        when 'm', 'multiline'
            show_multiline

    query = JSON.stringify query.split(' ') if query[0] isnt '['
    do_query query, show

show_text = append_history

show_multiline = (x) -> x.forEach append_history

$(window).on 'hashchange', ->
    {line, page} = do get_hash
    $.post "/command", JSON.stringify(['lrange', app.id, line, line + page]), (data) ->
        data.push "[EOF]" if data.length < page
        $('#content').html data.join ''

$(window).on 'keydown', (e) ->
    {line, page} = do get_hash

    switch e.key
        when 'Control'
            if app.current
                peek_ref.call app.current
                app.current = null
        when 'ArrowDown'
            set_hash({line: line + 1, page})
        when 'ArrowUp'
            set_hash({line: Math.max(line - 1, 0), page})
        when 'f', 'PageDown'
            set_hash({line: line + page, page})
        when 'r', 'PageUp'
            set_hash({line: Math.max(line - page, 0), page})
        when 'End'
            $.post "/command", JSON.stringify(['llen', app.id]), (data) ->
                set_hash({line: Math.max(data - page, 0), page})
        when 'Home'
            set_hash({line: 0, page})
        else
            return
    do e.preventDefault

$ ->
    set_hash do get_hash
    $('#content').on 'mouseover', '.ref', (e) ->
        if e.ctrlKey then peek_ref.call @ else app.current = @
    $('#content').on 'mouseout', '.ref', -> app.current = null
