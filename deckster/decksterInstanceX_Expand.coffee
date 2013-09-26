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
        _click_to_expand(this)
        #_expand_on_click(this)

      $deck.find(_css_variables.selectors.collapse_handle).click ->
        #_collapse_on_click(this)
        _click_to_collapse(this)

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

    ### COLLAPSING ###
    _collapse_card = ($card)->
      moving_info = {}
      moving_info["col_moves"] = {}
      ### Get Card ###
      id = parseInt $card.attr "data-card-id"
      d = __card_data_by_id[id]
      ### Remove old position/size of card ####
      _remove_old_position($card,d)

      ### Calculate New Dimensions ###
      o_col_span = d['original-col-span'] 
      o_col = d['original-col']
      o_col_end = o_col+o_col_span-1

      col = d.col
      col_end = d.col+d.col_span-1

      row_span = d.row_span
      o_row_span  = d['original-row-span'] 
      row = d.row

      ### Can we move this card up any further ? ###
      row_test = row-1
      shifts = 0
      while _fit_location(row_test,o_col,
        "row_span":o_row_span
        "col_span":o_col_span,
        "ignoreId",id)
        row = row_test
        row_test -= 1
        shifts += 1

      ### Set back origional values ###    
      d.col = o_col
      d.col_span = o_col_span
      d.row_span = o_row_span
      d.row = row
      delete d['original-row-span'] 
      delete  d['original-col-span']
      delete d['original-col']

      ### Set the new position/size of card ###
      _set_new_position($card,d)

      for c in [col..__col_max]
        if c >= o_col and c <= o_col_end
          moving_info["col_moves"][c] = row_span-o_row_span+(shifts)

        else if c >= col and c <= col_end
          ### Are there empty spaces above ? ###
          vertical_empty_spaces = 0
          row_test = row-1
          while row_test > 0 and __deck[row_test][c] == undefined 
            vertical_empty_spaces += 1
            row_test-=1

          moving_info["col_moves"][c] = row_span+vertical_empty_spaces
        else
          ### Are there empty spaces above ? ###
          vertical_empty_spaces = 0 
          row_test = row
          while row_test <= __row_max and __deck[row_test][c] == undefined 
            vertical_empty_spaces += 1
            row_test +=1

          ### Are there empty spaces below ? ###
          row_test = row-1
          while row_test > 0 and __deck[row_test][c] == undefined
            vertical_empty_spaces += 1
            row_test -= 1

          moving_info["col_moves"][c] = vertical_empty_spaces

      ### Moving Metadata ###
      moving_info["col"] = col
      moving_info["col_end"] = __col_max
      moving_info["row"] = row+shifts+row_span
      moving_info["id"] = d.id

      console.log "row" , row
      console.log "moving_info!!!",moving_info
      return moving_info

    free_vertical_spaces = (info,d)->

      min = Number.MAX_VALUE
      col_end = d.col+d.col_span-1

      for c in [d.col..col_end]
        if info["col_moves"][c] < min
          min = info["col_moves"][c]

      return min

    _move_up = (info)->

      for row in [info.row..__row_max]
        for col in [info.col..info.col_end]

          if __deck[row] and __deck[row][col] and __deck[row][col] != info.id 
            id = __deck[row][col]
            if __cards_needing_resolved_by_id[id] == undefined         
                d = __card_data_by_id[id]
                f_v_spaces = free_vertical_spaces(info,d)
              while f_v_spaces > 0 and f_v_spaces != Number.MAX_VALUE
                if  _fit_location(d.row-f_v_spaces,d.col,d,"ignoreId":id)
                  $card = __cards_by_id[id] 
                  _remove_old_position($card,d)
                  d.row -= f_v_spaces
                  _set_new_position($card,d)
                else
                  f_v_spaces -= 1

            
            __cards_needing_resolved_by_id[id]=true

      console.log "resolved cards",__cards_needing_resolved_by_id
      return true


    _click_to_collapse = (element)->
      ### Grab Card ###
      $collapse_handle = $(element)
      $card = $collapse_handle.parents(_css_variables.selectors.card)
      ### Collapse Card and retrieve metadata about new deck layout ###
      info  = _collapse_card($card)
      ### Move cards up into freed spaces ###
      _move_up(info)

      ### Hide Collapse View ###
      $collapse_handle.hide()
      $collapse_handle.siblings(_css_variables.selectors.expand_handle).show()
      _clean_up_deck()
      
      ### Call Collapsing Callbacks ###
      for callback in __event_callbacks[__events.card_collapsed] || []
        break if callback($deck, $card) == false

      ### Saves changes made ot each card ###
      _apply_deck()
      ### Clear out global helper variables ###
      __cards_needing_resolved_by_id = {}
      console.log "current deck", __deck

    ### EXPANDING ###
    _find_expansion_size = ($card)->
      console.log "_find_expansion_size"
      ### Get Card ###
      id = $card.data("card-id")
      d = __card_data_by_id[id]
      ### Calculate new dimensions ###
      row_expand = parseInt $card.attr "data-row-expand"
      row_end = d.row + -1 + row_expand
      row_start = d.row
     
      col_start = d.col
      col_expand = parseInt $card.attr "data-col-expand"
      col_end = col_start + col_expand - 1 
      
      ### 
         If necessary, adjust the card to the leftmost space 
         on the deck to accomidate the new size
      ###
      while col_start + col_expand - 1 > __col_max and col_start > 0
        col_start -= 1
        col_end = col_expand + col_start - 1
      
      ### If card to wide, truncate ###   
      if col_start == 0
        col_start = 1
        col_end = __col_max
        col_span = col_end - col_start + 1

      ### Expanded Card info and metadata ###
      result = 
          "id":id
          "row": row_start
          "row_end": row_end
          "row_span": row_expand
          "col": col_start
          "col_end": col_end
          "col_span": col_expand

      console.log "specs"
      console.log result

      return result


    _find_conflicting_cards = (settings)->

      for i in [settings.row..settings.row_end]

        for j in [settings.col..settings.col_end]

          if __deck[i] and __deck[i][j] and settings.id != __deck[i][j]
            id = __deck[i][j]
            if __cards_needing_resolved_by_id[id] == undefined or __cards_needing_resolved_by_id[id] < settings.blocks_to_move
              d = __card_data_by_id[id]
              col_end=d.col+d.col_span-1
              row = d.row+settings.blocks_to_move
              row_end = row+d.row_span-1
              console.log "Adding conflict: ",id
              __cards_needing_resolved_by_id[id] = settings.blocks_to_move

              _find_conflicting_cards(
                "id":id
                "blocks_to_move":settings.blocks_to_move
                "col":d.col
                "col_end":col_end
                "row": d.row#row
                "row_end": row_end
              )

              
            ### current card is wider, keep looking downward ###


    _identify_intersecting_cards = (changes)->
      console.log "_identify_intersecting_cards"
      moving_info = {}
      moving_info["col_moves"] = {}
      processed_cards = {}

      ### Scan through all rows that intersect with 
          our card's expansion 
      ###
      for i in [changes.row..changes.row_end]
        for col, id of __deck[i]

          unless id == undefined || id == changes.id || processed_cards[id] != undefined
            processed_cards[id] = true

            d = __card_data_by_id[id]
            col_start = d.col
            col_end = d.col + d.col_span - 1 
            blocks_to_move = changes.row - d.row + changes.row_span
            row_start = d.row + blocks_to_move
            row_end = row_start + -1 + d.row_span 

            ### If this card's width doesn't fall within our
                area of concern, skip it
            ###
            if changes.col > col_end or changes.col_end < col_start
              console.log "skipping!!", id
              continue

            ### We're going to need to push some cards down to make space for our expanded card.

            ###
            section_clear = true
            for i in [col_start..col_end] 
              if moving_info["col_moves"] != undefined and moving_info["col_moves"][i] > blocks_to_move
                section_clear = false
                break

            if section_clear
                for i in [col_start..col_end] 
                  moving_info["col_moves"][i] = blocks_to_move

            console.log "Adding conflict.... ",id

            ### If that current, card has not been dealth with ###
            if __cards_needing_resolved_by_id[id] == undefined or __cards_needing_resolved_by_id[id] < moving_info["col_moves"][col_start]
              __cards_needing_resolved_by_id[id] = moving_info["col_moves"][col_start]
              info = 
                "id":id
                "row":d.row#row_start
                "row_end":row_end
                "col":col_start
                "col_end":col_end
                "blocks_to_move":moving_info["col_moves"][col_start]
              console.log "data", info

              _find_conflicting_cards(info)


      console.log "moving_info",moving_info
      console.log "resolved_cards",__cards_needing_resolved_by_id
      return moving_info


    _adjust_conflicts = (info)->
      console.log "_adjust_conflicts"
      new_deck = {}

      ### For all cards in the deck ###
      for id, d of __card_data_by_id
     
        ### That are currently visible ###     
        if d.isRemoved or info.id == id
          continue

        $card = __cards_by_id[id]
        ### If the card conflicts with our expansion ###
        if __cards_needing_resolved_by_id[id]
          ### Move it down a certain amount of spots (calculated previously) ###
          d.row = d.row + __cards_needing_resolved_by_id[id]

        ### Now set the position of the card on our new deck ###
        _set_new_position($card,d,"deck":new_deck)

      console.log "new_deck",new_deck
      ### Set the global var to our new deck ###
      __deck = new_deck 


    set_up_expansion = ($card,changes)->
      $expand_handle = $card.find(_css_variables.selectors.expand_handle)
      ### Get Card ###
      id = parseInt $card.attr 'data-card-id'
      d = __card_data_by_id[id]

      console.log ['Expand <<<', $card, d, { row: d.row, col: d.col }]

      ### Update Card width/height and save previous dimensions ###
      d['original-col']  = d.col
      d['original-col-span'] = d.col_span
      d['original-row-span'] = d.row_span

      d['row_span'] = changes.row_span 
      d['col'] = changes.col
      d['col_span'] = changes.col_span

      ### If the card's dimensions aren't 
      if d.col_span == $card.data('original-col-span') and d.row_span == $card.data('original-row-span')
        return;
      ###

      console.log ['Expand >>>', $card, d, { row: d.row, col: d.col }]
      ### Set the card's new dimensions ###
      _set_new_position($card,d,"readjust":true)

      ### Hide Expansion Handle ###
      $expand_handle.hide()
      $expand_handle.siblings(_css_variables.selectors.collapse_handle).show()
      ### Call callbacks ###
      for callback in __event_callbacks[__events.card_expanded] || []
        break if callback($deck, $card) == false

    _click_to_expand = (element)->
      $expand_handle = $(element)
      $card = $expand_handle.closest(_css_variables.selectors.card)
      ### Find the expanded dimensions of the card ###
      info = _find_expansion_size($card)
      ### Identify cards that intersect with this expansion ###
      moving_info = _identify_intersecting_cards(info)
      ### Move conflicts cards ###  
      _adjust_conflicts(moving_info)
      ### Expand our new card and call Expansion callbacks ###
      set_up_expansion($card,info)

      ### Apply changes made to each card to UI ###
      _apply_deck()
      ### Clear out global helper variables ###
      __cards_needing_resolved_by_id = {} 

      console.log "row_check",__row_max
    _on __events.card_expanded, ($deck, $card) ->
      _card_changed($deck, $card, "card-expanded")

    _on __events.card_collapsed, ($deck, $card) ->
      _card_changed($deck, $card, "card-collapsed")