  _placeholder_div = ($card, _d) ->

    $placeholder =
      $("<div>")
      .addClass(_css_variables.classes.placeholders)
      .addClass(_css_variables.classes.card)
      .attr("data-col", _d["col"])
      .attr("data-row", _d["row"])
      .attr("data-col-span", _d.col_span)
      .attr("data-row-span", _d.row_span)
    $card.closest(_css_variables.selectors.deck).append($placeholder)
    return $placeholder

  _remove_old_position = ($card, d) ->
    row_end = d.row + d.row_span - 1
    col_end = d.col + d.col_span - 1

    for row_remove in [d.row..row_end]
      for col_remove in [d.col..col_end]
        break unless __deck[row_remove]
        delete __deck[row_remove][col_remove] if  __deck[row_remove][col_remove] == d.id

    return true

  _set_new_position = ($card, d,settings) ->
    deck = if settings and settings.deck then settings.deck else __deck
    row_end = d.row_span + d.row - 1
    col_end = d.col_span + d.col - 1

    #add new entry to grid
    for row_add in [d.row..row_end]
      unless deck[row_add]
        deck[row_add] = {}

      for col_add in [d.col..col_end]
        deck[row_add][col_add] = d.id

    if row_end > __row_max
      __row_max = row_end

    _clean_up_deck(settings)

    return true

  _clean_up_deck = (settings)->
    deck = if settings and settings.deck then settings.deck else __deck
    #Clean up empty rows
    row_subtractor = __row_max
    while row_subtractor > 0
      if $.isEmptyObject(deck[row_subtractor])
        delete deck[row_subtractor]
        if __row_max == row_subtractor
          __row_max -= 1

      row_subtractor -= 1

    ###
    if settings and settings.readjust
      r = 1
      while r <= __row_max
        empty_rows = 0
        while r <= __row_max and deck[r] == undefined
          empty_rows += 1
          r += 1

        if empty_rows > 0
          processed = {}
          for row_move in [r..__row_max]
            for c, id of __deck[row_move]
                if processed[id] == undefined
                  processed[id] = true
                  d = __card_data_by_id[id]
                  d.row -= empty_rows
                  __cards_by_id[id].attr("data-row",d.row)

        r += 1
    ###

  _fit_location = (row, col, d,settings) ->
    deck = if settings and settings.deck then settings.deck else __deck
    row_end = d.row_span + row - 1
    col_end = d.col_span + col - 1

    if col_end > __col_max or row_end < 1  or row < 1
      return false

    for row_test in [row..row_end]
      for col_test in [col..col_end]
        if deck[row_test] and deck[row_test][col_test] #these areas must be empty
          if settings and settings.ignoreId and settings.ignoreId == deck[row_test][col_test]
            continue
          else
            return false # if not return false; we can't use spot.

    return true

  _placeholder_callbacks = ($placeholder,_d)->
    $placeholder.click((action) ->
      $card = __cards_by_id[_d.id]
      _remove_old_position $card, __card_data_by_id[_d.id]
      $selectedCard = $(action.currentTarget)
      __card_data_by_id[_d.id] = _d
      _set_new_position $card, _d
      _apply_transition $card, _d
      $card.find(_css_variables.selectors.droppable).trigger("click")
    )
    
    $placeholder.mouseenter((action) ->
      $(this).css("z-index", 3000)
    )
    
    $placeholder.mouseleave((action) ->
      $(this).css("z-index", "")
    )

  _add_placeholders = ($card, d)->
    for row in [1..(__row_max + 1)] #search over all rows, including last.
      for col in [1..__col_max] #search over all columns.
        if _fit_location(row, col, d)

          new_d =
            "id": d.id
            "row": row
            "col": col
            "row_span": d.row_span
            "col_span": d.col_span

          $placeholder = _placeholder_div($card, new_d)
          _placeholder_callbacks($placeholder,new_d) 
    
    return -1;

  ###
    If set to true, cards can be picked up and dropped to a new spot on the deck without disturbing the positions of any other card.
    :Droppable Helper Methods End.
  ###
  if options.droppable == true
    _on __events.inited, ($card, d) ->
      $controls = $card.find(_css_variables.selectors.controls)
      $droppable = $("<a title='Drop' class='#{_css_variables.classes.droppable} control droppable1'></a>")

      $droppable.click((element) ->
        $drop_handle = $(element.currentTarget)
        unless $drop_handle.hasClass("cancel")
          $card = $drop_handle.closest(_css_variables.selectors.card)
          $deck = $drop_handle.closest(_css_variables.selectors.deck)
          $deck.find(_css_variables.selectors.controls).children(":visible").addClass("hider").hide()
          #Hide any other decks below the current one
          $deck.closest(_css_variables.selectors.deck_container).nextAll(_css_variables.selectors.deck_container).hide()
          $drop_handle.show()
          $drop_handle.addClass("cancel")
          id = parseInt($card.attr('data-card-id'))
          d = __card_data_by_id[id]
          _add_placeholders $card, d
        else
          $drop_handle.removeClass("cancel")
          $card = $drop_handle.closest(_css_variables.selectors.card)
          $deck = $drop_handle.closest(_css_variables.selectors.deck)
          $deck.find(_css_variables.selectors.controls).children(".hider").show().removeClass("hider")

          $deck.find(_css_variables.selectors.placeholders).remove()
          #Show all the decks again
          $(document).find(_css_variables.selectors.deck_container).show()
          #Callbacks registered for event:
          retain_callbacks = []
          for callback in __event_callbacks[__events.card_moved] || []
            unless callback($deck, $card) == false
              retain_callbacks.push(callback)

          __event_callbacks[__events.card_moved] = retain_callbacks
      )
      $controls.append($droppable)
