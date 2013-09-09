  if options['removable'] && options['removable'] == true
    _on __events.inited, ($card) ->
      controls = "<a title='Remove' class='#{_css_variables.classes.remove_handle} control remove'></a>"
      $card.find(_css_variables.selectors.controls).append controls

      $card.find(_css_variables.selectors.remove_handle).click ->
        _remove_on_click(this)

    _remove_on_click = (element) ->
      $remove_handle = $(element)

      $card = $remove_handle.closest(_css_variables.selectors.card)
      cardId = parseInt $card.attr 'data-card-id'
      d = __card_data_by_id[cardId]

      $deck = $card.closest(_css_variables.selectors.deck)
      deckId = $deck.attr("id")

      ### Set Title ###
      titleText = $card.find(_css_variables.selectors.card_title).text()

      unless titleText.length
        # Display the first n characters of the content
        $content = $card.find(_css_variables.selectors.card_content)
        charLen = _css_variables.chars_to_display
        charLen = $content.text().length if $content.text().length < _css_variables.chars_to_display
        titleText = $content.text().substring(0, charLen) + "..."

      ### Dropdown Handle ###
      $dropdown = $deck.closest(_css_variables.selectors.deck_container).find(_css_variables.selectors.removed_dropdown)

      if $dropdown.is(":hidden")
        $dropdown.show()

      # Add to dropdown menu
      $dropdown.find('ul').append(_get_removed_card_li_tag(cardId, titleText))

      ###
      Event is currently unpredictable, hold off for now.
      Add card back to orig position (moving other cards if necessary)
      $dropdown.find('#'+_css_variables.classes.removed_card_button + '-' + cardId).click ->
        _add_back_card(cardId)
      ###

      ### Add card to open position ###
      $dropdown.find('#' + _css_variables.classes.removed_card_button + '-' + cardId).click ->
        _move_to_open_position(cardId, $dropdown)

      ### Detach card from deck ###
      $card.detach()

      ### Remove this card from the __deck variable ###
      _remove_old_position $card, d

      #Remove card from "Jump To" dropdown
      $dropdown.siblings("#" + deckId + "-nav").find("#" + _css_variables.classes.card_jump_scroll + "-" + cardId).remove()

      #Remvoe Empty Rows in Deck
      _clean_up_deck()

    _move_to_open_position = (cardId, $dropdown)->
      $card = __cards_by_id[cardId]
      d = __card_data_by_id[cardId]

      #Add back card to HTML page
      $deck.append($card.hide())

      _on __events.card_moved, ($deck, $card)->
        ###
          Show card once any transition animations are complete (which are called when a user selects a new spot.)
        ###
        $card.queue().push(()->
          $card.show()
        )

        #Add card to "Jump To" Dropdown
        _add_card_to_jump($card, $dropdown)

        #Only run this callback once.
        return false

      #Delete card from "Removed Dropdown"
      _delete_card_from_removed(d.id, $dropdown)

      #Show possible spots to move.
      $card
      .find(_css_variables.selectors.droppable)
      .trigger("click")

    _delete_card_from_removed = (cardId, $dropdown)->
      #Remove from the "Removed Cards" dropdown
      $dropdown
      .find('#' + _css_variables.classes.removed_card_li + '-' + cardId)
      .remove()

      # Hide the "Removed Cards" dropdown if empty
      if $dropdown.find('ul').children().size() == 0
        $dropdown.hide()

    _add_card_to_jump = ($card, $dropdown)->
      #Add Card back to "Jump To" dropdown
      if( $card.data("title")? )

        title = $card.data 'title'
        elementId = $card.attr("data-card-id")
        classId = _css_variables.classes.card_jump_scroll
        $nav_item = $ "<li id='#{classId + "-" + elementId}'><a href='#'>#{title}</a></li>"

        # Set up the click callback for the menu item
        $nav_item.on 'click', () ->
          _scrollToView $card

        $dropdown
        .siblings(_css_variables.selectors.card_jump_scroll)
        .find('ul').append $nav_item

    ###
    # Removes the card from the __deck variable so that it doesn't take up space once removed
    ###
    _remove_card_from_deck = ($card) ->
      cardId = parseInt($card.attr('data-card-id'))

      for row, cols of __deck
        for col, id of cols
          if cardId == id
            delete __deck[row][col]
            if $.isEmptyObject(__deck[row])
              delete __deck[row]

      return undefined

    ###
    # Returns the <li> tag for this card, to be shown within the 'Removed Card' dropdown.
    # It displays the card title (or the first 15 characters of the card content, if no title),
    #   and an 'Add' button.
    ###
    _get_removed_card_li_tag = (id, titleText) ->
      return """
             <li id=#{_css_variables.classes.removed_card_li}-#{id}
             class=#{_css_variables.classes.removed_card_li}>
             <a id=#{_css_variables.classes.removed_card_button}-#{id}>
      #{titleText}
             </a>
             </li>
             """
    ###
    # This is the callback when the 'Add' button is clicked for the card from the 'Removed Cards' dropdown
    ###
    _add_back_card = (cardId) ->
      return unless cardId?

      $card = __cards_by_id[cardId]
      d = __card_data_by_id[cardId]

      _add_back_card_helper(cardId, $card, d)

    ###
    # This is the callback when the 'Add to bottom ' button is clicked for the card from the 'Removed Cards' dropdown
    ###
    _add_back_card_to_bottom = (cardId) ->
      return unless cardId?

      $card = __cards_by_id[cardId]
      d = __card_data_by_id[cardId]

      # See if the card can fit in the last row, if not - add it back in the very last row, in the first column.
      can_fit_in_last_row = false

      for col in [1..__col_max] by 1
        if _does_fit_location(__row_max, col, d)
          can_fit_in_last_row = true
          console.log "fits in max row: __row_max, col: " + __row_max, col
          break
        else
          console.log$ "doesn't fit in max row: __row_max, col: " + __row_max, col

      if can_fit_in_last_row
        d.row = __row_max
        d.col = col
      else
        d.row = __row_max + 1
        d.col = 1

      _add_back_card_helper(cardId, $card, d)

    _add_back_card_helper = (cardId, $card, d) ->
      # Add the card back to the deck
      $deck.append($card)
      _add_card $card, d
      _apply_deck()

      # Add back to the jump card
      _create_jump_scroll_card($deck)

      # Remove from the "Removed Cards" dropdown
      $deck.parent().find('#' + _css_variables.classes.removed_card_li + '-' + cardId).remove()

      # Hide the "Removed Cards" dropdown if it doesn't have any cards
      dropdown = $deck.parent().find(_css_variables.selectors.removed_dropdown)
      dropdown.hide() if dropdown.find('ul').children().size() == 0