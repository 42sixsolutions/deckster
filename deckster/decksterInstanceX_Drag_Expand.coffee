  if options['drag_expand'] && options['drag_expand'] == true
    __$active_dragging_card = undefined
    __$active_dragging_placeholder = undefined
    __active_dragging_data = undefined
    __col_threshold_min = 300
    __col_threshold_max = 300
    __row_threshold_min = 200
    __row_threshold_max = 200
    width_min_limit = false
    width_max_limit = false
    height_min_limit = false
    height_max_limit = false

    _init_drag_expand = ()->
      return """ 
        <div style="float:right">
          <span class="#{_css_variables.classes.drag_mod_handle}">D</span>
        </div>
      """ 

    _limit_reached = (width,height)->

      $placeholder = _placeholder_div(__$active_dragging_card,__active_dragging_data.d)
      $placeholder.width(width)
      $placeholder.height(height)
      $placeholder.css("position","aboslute")
      $placeholder.css("z-index","2000")
      $placeholder.css("background-color","red")
      $deck.append($placeholder)
      $placeholder.fadeOut("slow", ()->
        $(_css_variables.selectors.placeholders).remove()
      )

    _expand_card = ()->
      col_mod = Math.round((__active_dragging_data.width-__active_dragging_data.delta_width)/__col_threshold_min)
      row_mod = Math.round((__active_dragging_data.height-__active_dragging_data.delta_height)/__row_threshold_min)

      console.log "col_mod",col_mod
      console.log "row_mod",row_mod

      row = parseInt __$active_dragging_card.attr("data-row-span")
      col = parseInt __$active_dragging_card.attr("data-col-span")
      
      console.log "row",row
      console.log "col",col

      row += row_mod
      col += col_mod

      __$active_dragging_card.height("")
      __$active_dragging_card.width("")

      __$active_dragging_card.attr("data-row-span",row)
      __$active_dragging_card.attr("data-col-span",col)

      __active_dragging_data.d["col_span"] =  col
      __active_dragging_data.d["row_span"] = row
      
      if col_mod != 0 or row_mod != 0 
          __$active_dragging_placeholder.attr("data-row-span",row)
          __$active_dragging_placeholder.attr("data-col-span",col)
          _force_card_to_position __$active_dragging_card,__active_dragging_data.d, { row: __active_dragging_data.d.row, col: __active_dragging_data.d.col}
          _apply_deck()
        
    _width_check = (currentX, diff)->
      ### Min Width Check ###
      widthCheck = __$active_dragging_card.outerWidth() + diff
      console.log "currentX", currentX
      console.log "widthCheck",widthCheck
      if __col_threshold_min <= widthCheck and widthCheck <= __col_threshold_max
        __active_dragging_data.width += diff
        ### Give User One-Time Warning  
        unless width_min_limit
          _limit_reached(__active_dragging_data.width,__active_dragging_data.height)
          width_min_limit = true###


      ### Max Width Check ###
      #if __active_dragging_data.width > __col_threshold_max 
      #  __active_dragging_data.width = __col_threshold_max
      #  ### Give User One-Time Warning  
      ##  unless width_max_limit
      #    _limit_reached(__active_dragging_data.width,__active_dragging_data.height)
      #    width_max_limit = true###

      __active_dragging_data.x = currentX

    _height_check = (currentY,diff)->
      ### Min Height Check ###
      heightCheck = __$active_dragging_card.outerHeight()+diff

      if __row_threshold_min <= heightCheck and heightCheck <= __row_threshold_max
        __active_dragging_data.height += diff
      #else if not height_min_limit
      #  ### Give User One-Time Warning  ###
      #  _limit_reached(__active_dragging_data.width,heightCheck-diff)
      #  height_min_limit = true

      __active_dragging_data.y = currentY
      ### Max Width Check 
      if __active_dragging_data.height > __$active_dragging_card.outerHeight() 
        __active_dragging_data.height = __row_threshold_max
      Give User One-Time Warning  
        unless height_max_limit
          _limit_reached(__active_dragging_data.width,__active_dragging_data.height)
          height_max_limit = true###

    _init_drag_expand_callbacks = ()->
      ### Init Dragging Process ###
      $deck.find(_css_variables.selectors.drag_mod_handle).on "mousedown", (event)->
        console.log "drag mousedown"
        $card = $(this).closest(_css_variables.selectors.card)
        cardId = parseInt $card.data("card-id")
        _d = __card_data_by_id[cardId]
        __$active_dragging_card = $card
        ### Increase z-index for visual purposes ###
        __$active_dragging_card.attr("data-prev-z",__$active_dragging_card.css("z-index"))
        __$active_dragging_card.css("z-index","1000")
        ### Reset Limit Check ###
        width_min_limit = false
        width_max_limit = false
        height_min_limit = false
        height_max_limit = false

        $container = $card.closest(_css_variables.selectors.deck_container)
        __col_threshold_max = $container.width()#__col_threshold_min * __col_max 
        __row_threshold_max = $container.height()#__row_threshold_min * __row_max 
        console.log "row max", __row_threshold_max
        console.log "col max", __col_threshold_max
        ### Set metadata for our expanding purposes ###
        __active_dragging_data =
            d: _d
            x: event.pageX
            y: event.pageY
            delta_width: $card.width()
            delta_height: $card.height()
            width: $card.width()
            height: $card.height()
            orig_width: $card.width()
            orig_height: $card.height()

        ### Add Shadowbox ###
        __$active_dragging_placeholder = _placeholder_div($card,_d)
        __$active_dragging_placeholder.css("background-color","blue")

      $deck.on "mousemove", (event)-> 
        if __$active_dragging_card?
          currentX = event.pageX
          currentY = event.pageY


          #__active_dragging_data.width += (currentX-__active_dragging_data.x)
          #__active_dragging_data.x = currentX
          _width_check(currentX,currentX-__active_dragging_data.x)

          #__active_dragging_data.height += (currentY-__active_dragging_data.y)
          #__active_dragging_data.y = currentY
          _height_check(currentY, currentY-__active_dragging_data.y)

          ### Set Height && Width ###
          __$active_dragging_card.width(__active_dragging_data.width)
          __$active_dragging_card.height(__active_dragging_data.height)

          ### Move surrounding cards if expanding / collapsing has reached a certain points ###
          col_change = (__active_dragging_data.width-__active_dragging_data.delta_width)
          if col_change > __col_threshold_min or col_change < -(__col_threshold_min)
            console.log "col_change", col_change 
            _expand_card()
            __active_dragging_data.delta_width += col_change

          row_change = (__active_dragging_data.height-__active_dragging_data.delta_height)
          if row_change > __row_threshold_min or row_change < -(__row_threshold_min)
            console.log "row_change", row_change 
            _expand_card()
            __active_dragging_data.delta_height += row_change

      $deck.on "mouseup", (event)->
        console.log "drag mouseup"
        if __$active_dragging_card?

          ### set card's final height and width ###
          currentX = event.pageX
          currentY = event.pageY

          _width_check(currentX,currentX-__active_dragging_data.x)
          _height_check(currentY, currentY-__active_dragging_data.y)
          _expand_card()

          ### Set z-index back to what it was before ###
          __$active_dragging_card.css("z-index",__$active_dragging_card.attr("data-prev-z"))
          __$active_dragging_card.removeAttr("data-prev-z")

          ### Remove Shadowbox ###
          __$active_dragging_placeholder.remove()
          __$active_dragging_placeholder = undefined

          ### Adjust Deck Height if necessary ###
          _clean_up_deck()
          _adjust_adjacent_decks($deck)

          ### Reset ivars ###
          __$active_dragging_card = undefined
          __active_dragging_data = undefined


    _on __events.inited, ($deck) ->
      console.log("Adding D-Expand")
      ### Add Draging Icon ###
      $deck.find(_css_variables.selectors.card).each((index)->
        
        $(this).append(_init_drag_expand())
      )
      ### Add Callback ####
      _init_drag_expand_callbacks()
