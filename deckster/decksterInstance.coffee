jQuery.deckster = (options)->
  console.log("Registering global callbacks")
  _document.__deck_mgr = options

window.Deckster = (options) ->
  $deck = $(this)

  unless $deck.hasClass(_css_variables.classes.deck)
    return console.log 'Not a valid deck'

  __event_callbacks = {}