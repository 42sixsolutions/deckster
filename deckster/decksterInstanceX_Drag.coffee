  if options['draggable'] && options['draggable'] == true
    __$active_drag_card = undefined
    __active_drag_card_drag_data = undefined

    _on __events.inited, ($deck) ->
      controls = "<a title='Drag' class='#{_css_variables.classes.drag_handle} control drag'></a>"
      $deck.find(_css_variables.selectors.controls).append controls

    _on __events.inited, ($deck) ->
      _bind_drag_controls(this)

    _create_box = ($card, clazz)->
      $div = $("<div/>")
      .addClass(clazz)
      .addClass("deckster-card")
      .attr("data-col", $card.attr("data-col"))
      .attr("data-row", $card.attr("data-row"))
      .attr("data-col-span", $card.attr("data-col-span"))
      .attr("data-row-span", $card.attr("data-row-span"))

      return $div

    _bind_drag_controls = (deck) ->
      $deck.find(_css_variables.selectors.drag_handle).on "mousedown", (e) ->
        $drag_handle = $(this)

        __$active_drag_card = $drag_handle.parents(_css_variables.selectors.card)

        __$active_drag_card.addClass('draggable')
        __$active_drag_card.css 'z-index', 1000

        #Shadowbox
        $deck.append(_create_box(__$active_drag_card, "shadowbox"))
        __$active_drag_card.css 'z-index', '1000'

        __active_drag_card_drag_data =
          height: __$active_drag_card.outerHeight()
          width: __$active_drag_card.outerWidth()
          pos_y: __$active_drag_card.offset().top + __$active_drag_card.outerHeight() - e.pageY
          pos_x: __$active_drag_card.offset().left + __$active_drag_card.outerWidth() - e.pageX

        __active_drag_card_drag_data['original_top'] = e.pageY + __active_drag_card_drag_data['pos_y'] - __active_drag_card_drag_data['height']
        __active_drag_card_drag_data['original_left'] = e.pageX + __active_drag_card_drag_data['pos_x'] - __active_drag_card_drag_data['width']

        e.preventDefault();

      $deck.on 'mousemove', (e) ->
        if __$active_drag_card?
          new_top = e.pageY + __active_drag_card_drag_data['pos_y'] - __active_drag_card_drag_data['height']
          new_left = e.pageX + __active_drag_card_drag_data['pos_x'] - __active_drag_card_drag_data['width']
          original_left = __active_drag_card_drag_data['original_left']
          original_top = __active_drag_card_drag_data['original_top']

          $shadowbox = $(".shadowbox")
          top = parseInt $shadowbox.attr("data-row")
          left = parseInt $shadowbox.attr("data-col")

          messages = []
          if new_top - original_top < -200
            __active_drag_card_drag_data['original_top'] = __active_drag_card_drag_data['original_top'] - 200
            _move_card(__$active_drag_card, "up")
            top -= 1
            messages.push 'UP'
          if new_top - original_top > 200
            __active_drag_card_drag_data['original_top'] = __active_drag_card_drag_data['original_top'] + 200
            _move_card(__$active_drag_card, "down")
            top += 1
            messages.push 'DOWN'
          if new_left - original_left < -300
            __active_drag_card_drag_data['original_left'] = __active_drag_card_drag_data['original_left'] - 300
            _move_card(__$active_drag_card, "left")
            left -= 1
            messages.push 'LEFT'
          if new_left - original_left > 300
            __active_drag_card_drag_data['original_left'] = __active_drag_card_drag_data['original_left'] + 300
            _move_card(__$active_drag_card, "right")
            left += 1
            messages.push 'RIGHT'
          console.log messages.join(' ') if messages.length > 0

          $shadowbox.attr("data-col", left)
          $shadowbox.attr("data-row", top)

          __$active_drag_card.offset { top: new_top, left: new_left }

      $deck.on 'mouseup', (e) ->
        if __$active_drag_card?
          __$active_drag_card.removeClass('draggable')
          __$active_drag_card.css 'top', ''
          __$active_drag_card.css 'left', ''
          __$active_drag_card.css 'z-index', ''
          __$active_drag_card.css 'opacity', '1'

          $(".shadowbox").fadeOut("slow", ()->
            $(this).remove()
          )

          __$active_drag_card = undefined
          __active_drag_card_drag_data = undefined


    _move_card = ($card, direction) ->
      id = $card.data('card-id')
      d = __card_data_by_id[id]
      switch direction
        when 'left' then _force_card_to_position $card, d, { row: d.row, col: d.col - 1}
        when 'right' then _force_card_to_position $card, d, { row: d.row, col: d.col + 1}
        when 'up' then _force_card_to_position $card, d, { row: d.row - 1, col: d.col}
        when 'down' then _force_card_to_position $card, d, { row: d.row + 1, col: d.col}
      _apply_deck()