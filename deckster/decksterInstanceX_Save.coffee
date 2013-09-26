  if options['persist'] && options['persist'] == true
      _on __events.inited, ($deck,$card) ->
        $deck.closest(_css_variables.selectors.deck_container)
        .find(_css_variables.selectors.deck_controls).append(_init_persistence())
        $("#save").bind("click",_saveDeckRemotly)
        $("#load").bind("click",_loadRemoteDeck)

      _init_persistence = ()->
        return """ 
          <span>
            <button id = "save">Save</button>
            <button id = "load">Load</button>
          </span>
        """

      _saveDeckRemotly = ()->
        persistance = _document.__deck_mgr.persistance
        ### Save DECK ###
        deckId = $deck.attr("id")
        $deckClone = $deck.clone()

        $deckClone.find(_css_variables.selectors.controls).each(()->          
          $controls = $(this)
          $expandHandle = $controls.find(_css_variables.selectors.expand_handle)
          $card = $controls.closest(_css_variables.selectors.card) 
          if $expandHandle.css("display")=="none"
            $card.attr("data-is-expanded","true")

          $card.find(_css_variables.selectors.controls).remove()
          $card.find(_css_variables.selectors.title).remove()
          $card.attr("data-skip-force","true")

          if $card.attr("[data-url]")?
            $card.attr("[data-url]").html("")          
        )

        ### Save Removed Cards ###
        $dropdown = $deck.closest(_css_variables.selectors.deck_container).find(_css_variables.selectors.removed_dropdown)
        $dropdown.find("a").each((index)->
          $link = $(this)
          temp = $link.attr("id").indexOf(_css_variables.classes.removed_card_button)+
            _css_variables.classes.removed_card_button.length+1
          cardId = parseInt $link.attr("id").substring(temp)
          $card = __cards_by_id[cardId].clone()

          ### Take Note: Card State (expanded/collapsed) ###
          $card.attr("data-is-expanded","true") if $card.find(_css_variables.selectors.expand_handle).css("display") == "none"
          ### Take Note: Removed Card ###
          $card.attr("data-is-removed","true")
          ### Remove content this regenerated when deck is loaded ###
          $card.find(_css_variables.selectors.controls).remove()
          $card.find(_css_variables.selectors.title).remove()
          $card.find(_css_variables.selectors.card_content+"[data-url]").html("")
  
          $deckClone.append($card)
        )
        deckClone = $deckClone[0].outerHTML
        deckId = $deck.attr("id")
        ### Create REST call ###
        if persistance?
            url = 
              "url":persistance.url
              "type": "POST" #if __is_saved then "PUT" else "POST"
              "success":(data,status,response)->
                console.log("successfully saved deck preferences")
                #_localMgr("save":true)
                __is_saved = true
              "error":(response,status,exception)->
                console.log("unsuccessfully saved deck preferences")
                
            url.data = {}
            url.data[deckId] = {}
            url.data[deckId].layout = deckClone

            _ajax(url)

        #else
          ### Only Persist Locally ###
          #_localMgr("save":true)

      _reset_deck = ()->
        __next_id = 1
        __deck = {}
        __cards_by_id = {}
        __card_data_by_id = {}
        __col_max = 0
        __row_max = 0
      
      _loadRemoteDeck = ()->
        #unless _localMgr("load":false) 
          persistance = _document.__deck_mgr.persistance
          url = 
            "url":persistance.url
            "type":"GET"
            "success":(data,status,response)->
              str  = "No Deck Saved"
              if(data._id == "undefined" or data._id == undefined)
                __is_saved = false
                _reset_deck()
                init()
              else
                str = "Loading Saved Deck"
                deckId = $deck.attr("id")
                layout = data[deckId].layout
                ### Add back saved deck ###
                if $deck.closest(_css_variables.selectors.deck_container).length > 0
                  console.log("Replacing Deck Container")
                  $deck.closest(_css_variables.selectors.deck_container)
                  .replaceWith(layout)
                else
                  console.log("Replacing Deck")
                  $deck.replaceWith(layout)

                         
                _reset_deck()
                ### Set new deck handle ###
                $deck = $("#"+deckId)   
                __is_saved = true
                ### INIT ###
                init()
                
                $("[data-is-expanded='true'] "+_css_variables.selectors.expand_handle).each(()->
                  $card = $(this).closest(_css_variables.selectors.card)
                  $deck = $(this).closest(_css_variables.selectors.deck) 
                  $card.removeAttr("data-is-expanded")
                  $(this).hide()
                  $(this).siblings(_css_variables.selectors.collapse_handle).show()
                  for callback in __event_callbacks[__events.card_expanded] || []
                    break if callback($deck, $card) == false
                )

                $("[data-is-removed='true'] "+_css_variables.selectors.remove_handle).each(()->
                    console.log "card-id",$(this).closest(_css_variables.selectors.card).data("card-id")
                    $(this).closest(_css_variables.selectors.card).removeAttr("data-is-removed")
                    $(this).trigger('click')
                )

                $("[data-skip-force='true']").removeAttr('data-skip-force')


              #_localMgr("save":true)
              console.log(str) 

            "error":(response,status,exception)->
              console.log "Error Loading Deck"
              init()
              #_localMgr("save":true)

          return _ajax(url)

      _localMgr = (option)->
        return false

        if typeof(Storage)?
          if option.load and localStorage.deck
            console.log("Loading Locally Saved Deck")
            console.log("DECK "+JSON.parse(localStorage.deck))

            __deck = JSON.parse(localStorage.deck)
            _apply_deck()
            return true
          else if option.save?
            console.log("Saving Deck Locally")
            localStorage.deck = JSON.stringify(__deck)
            return true    
          
        return false
