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
        $deckClone = $deck.clone(true)

        $deckClone.find(_css_variables.selectors.controls).remove()
        $deckClone.find(_css_variables.selectors.title).remove()
        $deckClone.find(_css_variables.selectors.card_content+"[data-url]").html("")
        
        ### Save Removed Cards ###
        $dropdown = $deck.closest(_css_variables.selectors.deck_container).find(_css_variables.selectors.removed_dropdown)
        $dropdown.find("a").each((index)->
          $link = $(this)
          temp = $link.attr("id").indexOf(_css_variables.classes.removed_card_button)+
            _css_variables.classes.removed_card_button.length+1
          cardId = parseInt $link.attr("id").substring(temp)
          $card = __cards_by_id[cardId].clone().attr("data-is-removed","true")
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
            console.log("URL UNSTRINGIFYED",url)
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
      
      _add_callback = ($card)->

      _loadRemoteDeck = ()->
        #unless _localMgr("load":false) 
          persistance = _document.__deck_mgr.persistance
          url = 
            "url":persistance.url
            "type":"GET"
            "success":(data,status,response)->
              str  = "No Deck Saved"
              if(data._id == "undefined")
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

                console.log(str)            
                _reset_deck()
                ### Set new deck handle ###
                $deck = $("#"+deckId)   
                __is_saved = true
                ### INIT ###
                init()
                idsToRemove = []
                
                $.each($deck.find("[data-is-removed='true'] "+_css_variables.selectors.remove_handle),
                  (index)->
                    $(this).trigger('click')
                    idsToRemove
                    .push(parseInt $(this).closest(_css_variables.selectors.card).data("card-id"))
                )
                
                $.each(idsToRemove,(index)->
                  __cards_by_id[idsToRemove[index]].removeAttr("data-is-removed")
                )
                
              #_localMgr("save":true)

            "error":(response,status,exception)->
              str = "Error Loading Deck"
              console.log(str)
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
