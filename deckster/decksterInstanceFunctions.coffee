  _on = (event, callback) ->
    __event_callbacks[event] = [] unless __event_callbacks[event]?
    __event_callbacks[event].push callback

  _add_card = ($card, d, remainStatic) ->
    throw 'Card is too wide' if d.col_span > __col_max
    
    ### Note:
      * data-skip-force: cards that are being loaded from a saved deck and don't need to be positioned via
      _force_card_to_position(..)
      * data-is-removed: cards that have been removed and don't need to be position/added to __deck
    ###
    if ($card.attr("data-skip-force")=="true" and $card.attr("data-is-removed")!="true") or remainStatic
      ### 
        if loading a saved deck, just set the new position in __deck and run callbacks so cards don't
          get repositioned with _force_card_to_position(..). 
      ###
      _set_new_position($card, d) 
    else if $card.attr("data-skip-force")!="true" and $card.attr("data-is-removed")!="true"
      ### If we're not loading a saved deck, run this function (per usual) ###
      _force_card_to_position $card, d, {row: d.row, col: d.col}      
    ### else skip adding card to __deck and run callbacks ###

    ### Removed Cards: Since these cards will not be added to __deck 
        and hence its 'data-card-id' will not be updated/initialized in _apply_deck(),
        I will need to update its data-card-id here 
    ###    
    $card.attr 'data-card-id', d.id if $card.attr("data-is-removed")=="true"

    retain_callbacks = []
    for callback in __event_callbacks[__events.card_added] || []
      unless callback($card, d) == false
        retain_callbacks.push(callback)

    __event_callbacks[__events.card_added] = retain_callbacks

  _force_card_to_position = ($card, d, p) ->
    throw 'Card expands out of bounds' if p.col + (d.col_span - 1) > __col_max
    _mark_card_as_resolved d
    __dominate_card_data = d
    _identify_problem_cards()
    __deck = {}
    _document.__deck_mgr = _document.__deck_mgr || {}

    _loop_through_spaces p.row, p.col, (p.row + (d.row_span - 1)), (p.col + (d.col_span - 1)), (p2) ->
      __deck[p2.row] = {} unless __deck[p2.row]?
      __deck[p2.row][p2.col] = d.id

    _resolve_cards()

  _mark_card_as_resolved = (d) ->
    if __cards_needing_resolved_in_order.length > 0
      i = $.inArray(d.id, __cards_needing_resolved_in_order)
      if i > -1
        __cards_needing_resolved_in_order.splice i, 1
        delete __cards_needing_resolved_by_id[d.id]

  _identify_problem_cards = () ->
    for row, cols of __deck
      for col, id of cols
        unless id == undefined || id == __dominate_card_data.id || __cards_needing_resolved_by_id[id]?
          __cards_needing_resolved_by_id[id] = true
          __cards_needing_resolved_in_order.push id

  _loop_through_spaces = (row_start, col_start, row_end, col_end, callback) ->
    row_i = row_start
    while row_i <= row_end
      col_i = col_start
      while col_i <= col_end
        p =
          row: row_i
          col: col_i
        r_value = callback p
        return if r_value == false # gives the option to break the loop
        col_i++
      row_i++

  _resolve_cards = () ->
    while __cards_needing_resolved_in_order.length > 0
      id = __cards_needing_resolved_in_order[0]
      $card = __cards_by_id[id]
      d = __card_data_by_id[id]
      _resolve_card_position $card, d
      _mark_card_as_resolved d

  _resolve_card_position = ($card, d) ->
    row_i = 1
    while true # WARNING --- MUST BREAK LOOP
      __deck[row_i] = {} unless __deck[row_i]?
      col_i = 1
      while col_i <= (__col_max - d.col_span) + 1
        can_go_here = true

        # can the card start here
        _loop_through_spaces row_i, col_i, (row_i + (d.row_span - 1)), (col_i + (d.col_span - 1)), (p2) ->
          __deck[p2.row] = {} unless __deck[p2.row]?
          if __deck[p2.row][p2.col]
            can_go_here = false
            return false

        # if so, then put it here
        if can_go_here == true
          _loop_through_spaces row_i, col_i, (row_i + (d.row_span - 1)), (col_i + (d.col_span - 1)), (p2) ->
            __deck[p2.row] = {} unless __deck[p2.row]?
            __deck[p2.row][p2.col] = d.id
          return

        col_i++
      row_i++

  ###
    Used to transition cards to new positions on the deck. Typical scenario arises when a card is being dragged to a new position and adjacent cards need to be repositioned.
    Transition positions are looked up and cached locally.
  ###
  _apply_transition = ($card, d) ->
    rowStr = _css_variables.selectors.card + "[data-row=\"" + d.row + "\"]"
    colStr = _css_variables.selectors.card + "[data-col=\"" + d.col + "\"]"
    _css_variables.dimensions = _css_variables.dimensions || {}
    leftAnimate = _css_variables.dimensions[colStr]
    topAnimate = _css_variables.dimensions[rowStr]
    #Did we have this value saved?
    unless leftAnimate? and topAnimate?
      mysheet = null
      for sheet, index in document.styleSheets
        if _css_variables.styleSheet == sheet.href.split("/").pop()
          mysheet = sheet
          break

      if  mysheet == null
        $card.attr 'data-row', d.row
        $card.attr 'data-col', d.col
        $card.css 'opacity', '1'
        return

      myrules = mysheet.cssRules ? mysheet.rules
      for rule,index in myrules
        if rule.selectorText == rowStr
          topAnimate = rule.style.top
          _css_variables.dimensions[rowStr] = topAnimate
        else if rule.selectorText == colStr
          leftAnimate = rule.style.left
          _css_variables.dimensions[colStr] = leftAnimate

    options.animate.properties.top = topAnimate
    options.animate.properties.left = leftAnimate
    options.animate.options.duration?= "slow"
    options.animate.options.easing?= "swing"
    options.animate.options.always = () ->
      $card.attr 'data-row', d.row
      $card.attr 'data-col', d.col
      $card.css 'opacity', '1'

    ###
    The animation becomes confusing and inaccurate when to many animations are attempted on the same card;Solution: Stop current and pending animations and start just this one.
    ###
    $card.stop(true, false).animate(options.animate.properties, options.animate.options)

  _apply_deck = () ->
    row_max = 0
    applied_card_ids = {}
    isDragging = true
    for row, cols of __deck
      for col, id of cols
        unless applied_card_ids[id]?
          applied_card_ids[id] = true

          $card = __cards_by_id[id]
          d = __card_data_by_id[id]

          $card.attr 'data-card-id', id
          if isDragging and not $card.hasClass "draggable"
            _apply_transition($card, d)
          else
            $card.attr 'data-row', d.row
            $card.attr 'data-col', d.col
          $card.attr 'data-row-span', d.row_span
          $card.attr 'data-col-span', d.col_span

          row_max_value = d.row + d.row_span - 1
          __row_max = row_max_value if row_max_value > __row_max

    $deck.attr 'data-row-max', row_max

  ###
  # Initially, cards will be hidden if the 'data-hidden' attribute is true, or
  #   if the deck's 'remove-empty' attribute is true, and
  #   there is no card content, and
  #   there is no 'data-url' attribute
  ###
  _should_remove_card_in_init = ($card, $deck) ->
    ($card.data('hidden') == true or
    ($deck.data('remove-empty') == true and !$card.find(_css_variables.selectors.card_content).text().trim() and !$card.data('url')))


  _init_deck_header = ($deck) ->
    # Add title to deck if present
    title = $deck.data("title")
    unless title
      $deck.attr "data-title", $deck.attr("id")
      title = $deck.attr("id")

    $deck_wrapper = $(_init_deck_wrapper($deck))
    $deck.replaceWith($deck_wrapper)
    $deck_wrapper.append $deck
    # Hide the "Removed Cards" dropdown if it doesn't have any cards
    $dropdown = $deck_wrapper.find(_css_variables.selectors.removed_dropdown)
    $dropdown.hide() if $dropdown.find('ul').children().size() == 0

    return true

  _init_deck_wrapper = ($deck) ->
    return """
           <div class="#{_css_variables.classes.deck_container}">
           <div class="deck-header">
           <div class="wrapper">
           <div class="#{_css_variables.classes.deck_title}">#{$deck.data("title") or ""}</div>
           <div class="deck-controls">
    #{_init_card_add_remove()}
    #{_init_card_scroll($deck)}
           </div>
           </div>
           </div>
           """

  _init_card_add_remove = ()->
    return """
           <div class="btn-group #{_css_variables.classes.removed_dropdown}">
           <span class="dropdown-toggle control add" data-toggle="dropdown"></span>
           <ul class="dropdown-menu pull-right"></ul>
           </div>
           """

  _init_card_scroll = ($deck)->
    return """
           <div id="#{$deck.attr("id")}-nav" class="btn-group #{_css_variables.classes.card_jump_scroll}">
           <span class="dropdown-toggle control jump-card" data-toggle="dropdown"></span>
           <ul class="dropdown-menu pull-right"></ul>
           </div>
           """

  _layout_check = ($cards)->

    result = true
    $cards.each((index)->
      $card = $(this)
      unless $card.attr("data-row")? && $card.attr("data-col")?
        console.log "card does not have row and col specified"
        result = false
        return false
    )
    console.log "all cards have row, col specified", result
    return result

  init = ->
    __col_max = $deck.data 'col-max'
    _init_deck_header($deck)

    cards = $deck.children(_css_variables.selectors.card)  
    remainStatic = _layout_check(cards)

    cards.each ->
      $card = $(this)

      if _should_remove_card_in_init($card, $deck)
        $card.remove()
      else
        d =
          id: __next_id++
          row: parseInt $card.attr 'data-row'
          col: parseInt $card.attr 'data-col'
          row_span: parseInt $card.attr 'data-row-span'
          col_span: parseInt $card.attr 'data-col-span'

        __cards_by_id[d.id] = $card
        __card_data_by_id[d.id] = d
        _add_card($card, d,remainStatic)

      $cheight = $(this).height()
      $theight = $('.deckster-card-title', this).height() + 40
      $('.deckster-card-title', this).css('margin-top', -$theight)
      $(this).css('padding-top', $theight)

    _apply_deck()
    cards.append "<div class='#{_css_variables.classes.controls}'></div>"
    for callback in __event_callbacks[__events.inited] || []
      break if callback($deck, cards) == false
    _create_jump_scroll_card $deck
    _create_jump_scroll_deck 0xDEADBEEF

  _adjust_adjacent_decks = ($deck) ->
    ###
    deckId = $deck.attr("id")
    specs = _window.__deck_mgr.lookup[deckId]
    new_layout = {}

    #copy decks up to deck being modified
    for row in [1...specs.row_min]
      new_layout[row] = _window.__deck_mgr.layout[row]


    #add current deck
    for row,cols of __deck
      new_layout[specs.row_min-1+row] = {}
      new_layout[specs.row_min-1+row][col] = deckId for col in [1..__col_max]

    #add back buffer
    newRow = __row_max+specs.row_min
    new_layout[newRow] = {}
    new_layout[newRow][i] = _css_variables.buffer for i in [1..__col_max]

    # copy rest
    # (note: our previous buffer, for this deck, will be copied over when iterating
    # over the 'specs.row_max' row)
    newRow += 1
    prevId = -1
    for row in [(specs.row_max+1).._window.__deck_mgr.row]
      new_layout[newRow] = _window.__deck_mgr.layout[row]

      # Update global deck placements
      id = new_layout[newRow][1] #
      if id != prevId and id != _css_variables.buffer
        _window.__deck_mgr.lookup[id].row_min = newRow
        _window.__deck_mgr.lookup[id].row_max = newRow
        prevId = id
      else
        _window.__deck_mgr.lookup[prevId].row_max = newRow


      newRow+=1
    ###
    ###
      Update global variables.
      -New overall max row (note: the for loop increments this value 1 extra time when exiting for-loop)
      -New Layout
      -Deck Max
    ###
    ###
    _window.__deck_mgr.row = newRow-1
    console.log("_window.__deck_mgr.row",_window.__deck_mgr.row)
    _window.__deck_mgr.layout = new_layout # new layout
    console.log("layout",_window.__deck_mgr.layout)
    console.log("__row_max!",__row_max)
    _window.__deck_mgr.lookup[deckId].row_max = specs.row_min+__row_max
    ###

    #Update Page
    $deck
    .closest(_css_variables.selectors.deck_container)
    .attr("data-row-max", __row_max + 1)

    return true

  ###
    Adjust (if necessary) other decks when a particular deck is expanded/collapsed or its contents are moved around.
  ###
  _on __events.card_collapsed, ($deck, $card)->
    _adjust_adjacent_decks($deck)

  _on __events.card_expanded, ($deck, $card)->
    _adjust_adjacent_decks($deck)
  _on __events.card_moved, ($deck, $card) ->
    _adjust_adjacent_decks($deck)

  _on __events.inited, ($deck)->
    ###
    col_min = 1 # Should only be 1 as we will only be scrolling vertically
    deckId = $deck.attr("id")
    #How many decks "rows" are there currently?
    if _window.__deck_mgr.row?
      #Start at the next available row
      row_min = _window.__deck_mgr.row+1
    else
      row_min = 1

    #Max width for this deck
    col_max = __col_max
    #There's an extra row between decks to act as a buffer
    row_max = row_min+__row_max

    _window.__deck_mgr.layout = _window.__deck_mgr.layout || {}
    for y in [row_min..row_max]
      for x in [col_min..col_max]

        unless _window.__deck_mgr.layout[y]
          _window.__deck_mgr.layout[y] = {}

        _window.__deck_mgr.layout[y][x] = if y == row_max then _css_variables.buffer else $deck.attr("id")

    #Maximum number of rows
    _window.__deck_mgr.row = row_max
    _window.__deck_mgr.lookup = _window.__deck_mgr.lookup || {}
    #Record results
    _window.__deck_mgr.lookup[deckId] =
      "row_min":row_min
      "row_max":row_max
      "col_max":col_max
      "col_min":col_min
    ###

    #Adding Height to Deck via CSS (add extra row for buffer)
    $deck
    .closest(_css_variables.selectors.deck_container)
    .attr("data-row-max", __row_max + 1)

    #console.log("done init window layout",_window.__deck_mgr.layout)
    return true

  _on __events.card_added, ($card, d) ->
    title = $card.data "title"

    unless title? and !$card.find(_css_variables.selectors.card_title).text()
      return
    $title_div = $('<div>')
    .text(title)
    .addClass(_css_variables.classes.card_title)
    $card.prepend $title_div

  _does_fit_location = (row, col, d) ->
    row_end = d.row_span + row
    col_end = d.col_span + col

    if col_end - 1 > __col_max
      return false

    for row_test in [row..row_end]
      for col_test in [col..col_end]
        if __deck[row_test] and __deck[row_test][col_test] #these areas must be empty
          return false # if not return false; we can't use spot.

    return true