  _ajax = (options) ->
    options = $.extend(true, {}, _ajax_default, options)
    $.ajax(options)

  if options['url_enabled'] == true
    _on __events.card_added, ($card, d) ->
      if $card.data("url")?
        ajax_options =
          url: $card.data "url"
          type: if $card.data("url-method")? then $card.data "url-method" else "GET"
          context: $card
          success: (data, status, response) ->
            if (!!data.trim()) # URL content is not empty
              $controls = this.find(_css_variables.selectors.controls).clone true
              $title = this.find(_css_variables.selectors.card_title)
              this.html ""
              this.append $title
              this.append $controls
              this.append '<div class="content">' + data + '</div>'
            else # Remove the card if url content is empty & div text content is empty
              divText = this.find(_css_variables.selectors.card_content).text()
              if (!divText.trim() and $deck.data('remove-empty') == true)
                _create_jump_scroll_card($deck)
                this.remove()
                _remove_card_from_deck this

        deckId = $card.closest(_css_variables.selectors.deck).attr("id")
        cardId = $card.attr("id")
        ###
         Keep track of requests incase we need to abort them.
        ###
        _ajax_requests[deckId] = _ajax_requests[deckId] || {}
        _ajax_requests[deckId][cardId] = _ajax(ajax_options)