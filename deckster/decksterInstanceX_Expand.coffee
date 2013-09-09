  if options['expandable'] && options['expandable'] == true
    _on __events.inited, ($deck, cards) ->
      controls = """
                 <a title="Expand" class='#{_css_variables.classes.expand_handle} control expand'></a>
                 <a title="Collapse" class='#{_css_variables.classes.collapse_handle} control collapse' style='display:none;'></a>
                 """
      cards.each ->
        $card = $(this)
        row_expand = $card.attr 'data-row-expand'
        col_expand = $card.attr 'data-col-expand'

        $card.find(_css_variables.selectors.controls).append controls if row_expand? || col_expand?

      $deck.find(_css_variables.selectors.expand_handle).click ->
        _expand_on_click(this)

      $deck.find(_css_variables.selectors.collapse_handle).click ->
        _collapse_on_click(this)

    _expand_on_click = (element) ->
      $expand_handle = $(element)
      $card = $expand_handle.parents(_css_variables.selectors.card)
      id = parseInt $card.attr 'data-card-id'

      d = __card_data_by_id[id]

      console.log ['Expand <<<', $card, d, { row: d.row, col: d.col }]

      $card.attr 'data-original-col', d.col
      $card.attr 'data-original-row-span', d.row_span
      $card.attr 'data-original-col-span', d.col_span

      if $card.data("col-expand")?
        expandColTo = parseInt($card.data("col-expand"))
        expandColTo = if expandColTo > __col_max  then __col_max else expandColTo
      expandColTo = if expandColTo? and expandColTo > 0 then expandColTo else d.col_span
      expandRowTo = parseInt($card.data("row-expand")) if $card.data("row-expand")?
      expandRowTo = if expandRowTo? and expandRowTo > 0 then expandRowTo else d.row_span

      d['row_span'] = expandRowTo
      d['col'] = if (expandColTo - 1) + d.col <= __col_max  then d.col else 1
      d['col_span'] = expandColTo

      if d.col_span == $card.data('original-col-span') and d.row_span == $card.data('original-row-span')
        return;
      console.log ['Expand >>>', $card, d, { row: d.row, col: d.col }]


      _force_card_to_position $card, d, { row: d.row, col: d.col }
      _apply_deck()

      $expand_handle.hide()
      $expand_handle.siblings(_css_variables.selectors.collapse_handle).show()
      for callback in __event_callbacks[__events.card_expanded] || []
        break if callback($deck, $card) == false

    _collapse_on_click = (element) ->
      $collapse_handle = $(element)
      $card = $collapse_handle.parents(_css_variables.selectors.card)
      id = parseInt $card.attr 'data-card-id'

      d = __card_data_by_id[id]
      d.col = parseInt $card.attr 'data-original-col'
      d.row_span = parseInt $card.attr 'data-original-row-span'
      d.col_span = parseInt $card.attr 'data-original-col-span'

      $card.attr 'data-original-col', ''
      $card.attr 'data-original-row-span', ''
      $card.attr 'data-original-col-span', ''

      _force_card_to_position $card, d, { row: d.row, col: d.col }
      _apply_deck()

      $collapse_handle.hide()
      $collapse_handle.siblings(_css_variables.selectors.expand_handle).show()
      _clean_up_deck()
      for callback in __event_callbacks[__events.card_collapsed] || []
        break if callback($deck, $card) == false

    _on __events.inited, ()->
      #Find all decks that don't have "data-cards-expanded=false"
      $(_css_variables.selectors.deck + ":not(" + _css_variables.selector_functions.deck_expanded(false) + ")").each((index)->
        $deck = $(this);
        #Find all cards that don't have "data-expanded=false" and expand them
        $deck.find(_css_variables.selectors.card + ":not(" + _css_variables.selector_functions.card_expanded(false) + ")").each((index)->
          $(this).find(_css_variables.selectors.expand_handle).trigger "click"
        )
      )

    _card_changed = ($deck, $card, type) ->
      if options["card-actions"]? and options["card-actions"][type]?

        cardActions = options["card-actions"][type]
        deckId = $deck.attr("id")
        cardId = $card.attr("id")
        $cardContent = $card.find(_css_variables.selectors.card_content)
        for cardIdentity, action of cardActions
          if "#" + $card.attr("id") == cardIdentity || $card.hasClass(cardIdentity[1..]) || cardIdentity == "*"

            temp = action($card, $cardContent)
            if temp? and temp.url?
              ###
                 Abort any requests that are currently on-going.
              ###
              if _ajax_requests[deckId] and _ajax_requests[deckId][cardId]
                _ajax_requests[deckId][cardId].abort()
                delete _ajax_requests[deckId][cardId]

              ###
                Send the ajax request after any card animation has finished (Typically when a card is expanded its size will be changed.) For example, trying to animate and load content into the card makes both operations laggy and detract from the user experience.
              ###
              ajaxOptions = temp
              $card.queue().push(()->
                _ajax_requests[deckId][cardId] = _ajax(ajaxOptions)
              )
      ### Call any globally registered callbacks ###
      if _document.__deck_mgr? and _document.__deck_mgr["card-actions"]? and _document.__deck_mgr["card-actions"][type]?
        _document.__deck_mgr["card-actions"][type]($card, $cardContent)


    _on __events.card_expanded, ($deck, $card) ->
      _card_changed($deck, $card, "card-expanded")

    _on __events.card_collapsed, ($deck, $card) ->
      _card_changed($deck, $card, "card-collapsed")