  _placeholder_div = ($card, _d, settings) ->
    width = $card.outerWidth()
    height = $card.outerHeight()
    $placeholder =
      $("<div>")
      .addClass("placeholders")
      .addClass(_css_variables.selectors.card.substring(1))
      .attr("data-col", _d["col"])
      .attr("data-row", _d["row"])
      .attr("data-col-span", _d.col_span)
      .attr("data-row-span", _d.row_span)
      #.css("background-color","rgb("+settings.r+","+settings.g+","+settings.b+")")
      .css("z-index", settings.zIndex)
    $card.closest(_css_variables.selectors.deck).append($placeholder)
    $placeholder.click((action) ->
      _remove_old_position $card, __card_data_by_id[_d.id]
      $selectedCard = $(action.currentTarget)
      #$card.css("z-index",0)
      __card_data_by_id[_d.id] = _d
      _set_new_position $card, _d
      _apply_transition $card, _d
      $card.find(_css_variables.selectors.droppable).trigger("click")
    )
    $placeholder.mouseenter((action) ->
      $(this).data("prev-z-index", $(this).css("z-index"))
      $(this).css("z-index", 1000)
    )
    $placeholder.mouseleave((action) ->
      $(this).css("z-index", $(this).data("prev-z-index"))
    )
    return $card

  _remove_old_position = ($card, d) ->
    row_end = d.row + d.row_span - 1
    col_end = d.col + d.col_span - 1

    for row_remove in [d.row..row_end]
      for col_remove in [d.col..col_end]
        break unless __deck[row_remove]
        delete __deck[row_remove][col_remove] if  __deck[row_remove][col_remove] == d.id

    return true

  _set_new_position = ($card, d) ->
    row_end = d.row_span + d.row - 1
    col_end = d.col_span + d.col - 1

    #add new entry to grid
    for row_add in [d.row..row_end]
      unless __deck[row_add]
        __deck[row_add] = {}

      for col_add in [d.col..col_end]
        __deck[row_add][col_add] = d.id

    if row_end > __row_max
      __row_max = row_end

    _clean_up_deck()

    return true

  _clean_up_deck = ()->
    #Clean up empty rows
    row_subtractor = __row_max
    while row_subtractor > 0
      if $.isEmptyObject(__deck[row_subtractor])
        delete __deck[row_subtractor]
        if __row_max == row_subtractor
          __row_max -= 1
      row_subtractor -= 1


  _fit_location = (row, col, d) ->
    row_end = d.row_span + row - 1
    col_end = d.col_span + col - 1

    if col_end > __col_max
      return false

    for row_test in [row..row_end]
      for col_test in [col..col_end]
        if __deck[row_test] and __deck[row_test][col_test] #these areas must be empty
          return false # if not return false; we can't use spot.

    return true

  _add_placeholders = ($card, d)->
    zIndex = 1
    r = 0
    g = 25
    b = 50
    for row in [1..(__row_max + 1)] #search over all rows, including last.
      for col in [1..__col_max] #search over all columns.
        if _fit_location(row, col, d)

          new_d =
            "id": d.id
            "row": row
            "col": col
            "row_span": d.row_span
            "col_span": d.col_span

          _placeholder_div($card, new_d,
            "zIndez": zIndex
            "r": r
            "g": g
            "b": b)

          zIndex += 1
          r = ((r + 0) % 200)
          g = ((g + 50) % 150)
          b = ((b + 50) % 250)

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
