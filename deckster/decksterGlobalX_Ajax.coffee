###
  Default Ajax options, some options are typically overwritten.
###
_ajax_default =
  success: (data, status, response) ->
    console.log("Success: " + status)
  error: (response, status, exception) ->
    console.log("Status: " + status + " Error: " + exception)
  timeout: 3000
  type: 'GET'
  async: true

###
  Used to keep track of ajax requests. Typically stored as _ajax_requests[deckId][cardId] = $.ajax(...)
###
_ajax_requests = {}