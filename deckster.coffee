#THESE NEED TO MATCH THE CSS
_css_variables =
  selectors:
    deck: '.deckster-deck'
    card: '.deckster-card'
    card_title: '.deckster-card-title'
    controls: '.deckster-controls'
    drag_handle: '.deckster-drag-handle'
    expand_handle: '.deckster-expand-handle'
    collapse_handle: '.deckster-collapse-handle'
    card_jump_scroll: '.deckster-card-jump-scroll'
    deck_jump_scroll: '.deckster-deck-jump-scroll'
    remove_handle: '.deckster-remove-handle'
    removed_dropdown: '.deckster-removed-dropdown'
    removed_card_li: '.deckster-removed-card-li'
    removed_card_button: '.deckster-removed-card-button'
    card_content:'.content'

  selector_functions:
    card_expanded: (option)->'[data-expanded='+option+']'
    deck_expanded: (option) -> '[data-cards-expanded='+option+']'
  classes: {}
  dimensions: {}
  styleSheet: "deckster.css"

_ajax_default = 
  success: (data,status, response) ->
      console.log("Success: "+status)
  error: (response,status,exception) ->
      console.log("Status: "+status+" Error: "+exception)
  timeout: 3000
  type: 'GET'
  async: true


_css_variables.classes[sym] = selector[1..] for sym, selector of _css_variables.selectors

# Jump scroll area
_jump_scroll =
  $title_cards: null
  $nav_list: null

_scrollToView = ($el) ->
  offset = $el.offset()
  offset.top -= 20
  offset.left -= 20
  $('html, body').animate {
    scrollTop: offset.top
    scrollLeft: offset.left
  }

_nav_menu = null # Feel free to rename this if something else fits better

_create_nav_menu = () ->
    markup = """<div id="deckster-scroll-helper" class="btn-group">
          <div class="btn-group #{_css_variables.classes.card_jump_scroll}">
            <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown">
              JC <!-- "jump [to] card" -->
              <span class="caret"></span>
            </button>
            <ul class="dropdown-menu pull-right">
            </ul>
          </div>
          <div class="btn-group #{_css_variables.classes.deck_jump_scroll}">
            <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown">
                (JD)<!-- "jump [to] deck" -- not implemented -->
              <span class="caret"></span>
            </button>
            <ul class="dropdown-menu pull-right">
            </ul>
          </div>
        </div>
        """ # "stupid emacs
    button_dom = $ markup
    $("body").append button_dom  
    
_create_jump_scroll = (target_ul_selector, title_selector) ->
    J = _jump_scroll
    _nav_menu ?= _create_nav_menu "()"
    $card_title_ddl = $ target_ul_selector
    $card_title_ddl.children().remove()
    # We're abusing J at this point.  At some point, maybe clean this
    # up.  Right now this function will run too many times: for each
    # of [card, deck] it will be run as many times as there are decks,
    # thus if there are 3 decks it will be run 6 times.
    J.$title_items = $ title_selector
    if J.$title_items.length is 0
        return

    J.$nav_list = $card_title_ddl

    J.$title_items.each (index, item) ->
        title = $(item).data 'title'
        console.log "title is #{title}"
        $nav_item = $  "<li>#{title}</li>"
        $nav_item.on 'click', () ->
          _scrollToView $ item
        J.$nav_list.append $nav_item

_create_jump_scroll_card = () ->
    # Collect all data-title cards from ALL DECKS on the pge
    _create_jump_scroll "#{_css_variables.selectors.card_jump_scroll} ul",
            '.deckster-deck [data-title]'

_add_to_jump_scroll_card = (target_ul_selector, $card) ->
    J = _jump_scroll

    $card_title_ddl = $ target_ul_selector
    J.$nav_list = $card_title_ddl

    title = $card.find(_css_variables.selectors.card_title).text()
    $nav_item = $  "<li>#{title}</li>"
    $nav_item.on 'click', () ->
      _scrollToView $card
    J.$nav_list.append $nav_item

_create_jump_scroll_deck = () ->
    _create_jump_scroll "#{_css_variables.selectors.deck_jump_scroll} ul",
            '.deckster-deck[data-title]'

window.Deckster = (options) ->
  $deck = $(this)

  unless $deck.hasClass(_css_variables.classes.deck)
    return console.log 'Not a valid deck'

  # Options
  __default_options =
    draggable: true
    expandable: true
    url_enabled:true
    removable:true

  options = $.extend {}, __default_options, options
  _option_draggable = $deck.data 'draggable'
  options['draggable'] = true if _option_draggable? && (_option_draggable == true || _option_draggable == 'true')
  _option_expandable = $deck.data 'expandable' 
  options['expandable'] = true if _option_expandable? && (_option_expandable == true || _option_expandable == 'true')
  _option_removable = $deck.data 'removable' 
  options['removable'] = true if _option_removable? && (_option_removable == true || _option_removable == 'true')
  ### 
   if 'url-enabled' is not defined then refer back to previously set option.
   if 'url-enabled' is defined then return 'true' if 'true' otherwise 'false'
  ###
  _option_url_enabled = $deck.data 'url-enabled'
  options['url_enabled'] = (if _option_url_enabled? then (if _option_url_enabled == true or _option_url_enabled == 'true' then true else false) else options['url_enabled'])
  ###
     Init Dragging options
  ###   
  options.animate = options.animate ? {}
  options.animate.properties = options.animate.properties ? {}
  options.animate.options = options.animate.options ? {}

  ###
    Deckster Base 
   --- Deckster Base Variables
  ###
  __next_id = 1
  __deck = {}
  __cards_by_id = {}
  __card_data_by_id = {}
  __col_max = 0

  __cards_needing_resolved_in_order = []
  __cards_needing_resolved_by_id = {}

  __dominate_card_data = undefined

  __events =
    card_added: 'card_added'
    inited: 'inited'
    card_expanded: 'card_expanded'
    card_collapsed: 'card_collapsed'
    
  __event_callbacks = {}

  # --- Deckster Base Functions
  _on = (event, callback) ->
    __event_callbacks[event] = [] unless __event_callbacks[event]?
    __event_callbacks[event].push callback

  _ajax = (options) ->
      options = $.extend(true,{},_ajax_default,options)
      $.ajax(options)

  _add_card = ($card, d) ->
    throw 'Card is too wide' if d.col_span > __col_max
    _force_card_to_position $card, d, {row: d.row, col: d.col}

    for callback in __event_callbacks[__events.card_added] || []
      break if callback($card, d) == false

  _force_card_to_position = ($card, d, p) ->
    throw 'Card expands out of bounds' if p.col + (d.col_span - 1) > __col_max
    _mark_card_as_resolved d
    __dominate_card_data = d
    _identify_problem_cards()
    __deck = {}

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

  _apply_transition = ($card,d) ->
    rowStr = _css_variables.selectors.card+"[data-row=\""+d.row+"\"]"
    colStr = _css_variables.selectors.card+"[data-col=\""+d.col+"\"]"
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
        $card.css 'opacity','1'
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
      $card.css 'opacity','1'

    $card.stop(true,false).animate(options.animate.properties, options.animate.options) 

  _apply_deck = () ->
    row_max = 0
    applied_card_ids = {}
    isDragging = true
    for row, cols of __deck
      for col, id of cols
        unless applied_card_ids[id]?
          applied_card_ids[id] = true

          $card = __cards_by_id[id]
          __card_data_by_id[id].row = parseInt row
          __card_data_by_id[id].col = parseInt col
          d = __card_data_by_id[id]

          $card.attr 'data-card-id', id
          if isDragging and not $card.hasClass "draggable"
            _apply_transition($card,d) 
          else
            $card.attr 'data-row', d.row
            $card.attr 'data-col', d.col
          $card.attr 'data-row-span', d.row_span
          $card.attr 'data-col-span', d.col_span

          row_max_value = d.row + d.row_span - 1
          row_max = row_max_value if row_max_value > row_max

    $deck.attr 'data-row-max', row_max

  init = ->
    __col_max = $deck.data 'col-max'
    # Add title to deck
    $deck_wrapper = $ "<div>"
    $deck.replaceWith($deck_wrapper)
    title = $deck.data("title") or "Deckster Deck"
    $title_div = $ "<div class=\"deckster-title\">#{title}</div>"
    $deck_wrapper.append $title_div, $deck

    cards = $deck.children(_css_variables.selectors.card)
    cards.each ->
      $card = $(this)

      _option_hidden = $card.data 'hidden'
      if _option_hidden == true
        $card.remove();
      else
        d =
          id: __next_id++
          row: parseInt $card.attr 'data-row'
          col: parseInt $card.attr 'data-col'
          row_span: parseInt $card.attr 'data-row-span'
          col_span: parseInt $card.attr 'data-col-span'

        __cards_by_id[d.id] = $card
        __card_data_by_id[d.id] = d
        _add_card($card, d)

    _apply_deck()
    cards.append "<div class='#{_css_variables.classes.controls}'></div>"
    for callback in __event_callbacks[__events.inited] || []
      break if callback($deck) == false
    _create_jump_scroll_card 0xDCC0FFEEBAD
    _create_jump_scroll_deck 0xDEADBEEF


  # Deckster Drag
  if options['draggable'] && options['draggable'] == true
    __$active_drag_card = undefined
    __active_drag_card_drag_data = undefined

    _on __events.inited, ($deck) ->
      controls = "<a class='#{_css_variables.classes.drag_handle} control drag'></a>"
      $deck.find(_css_variables.selectors.controls).append controls

    _on __events.inited, ($deck) ->
      _bind_drag_controls(this)

    _bind_drag_controls = (deck) ->
      $deck.find(_css_variables.selectors.drag_handle).on "mousedown", (e) ->
        $drag_handle = $(this)
        __$active_drag_card = $drag_handle.parents(_css_variables.selectors.card)

        __$active_drag_card.addClass('draggable')
        __$active_drag_card.css 'z-index', 1000

        __active_drag_card_drag_data =
          height: __$active_drag_card.outerHeight()
          width: __$active_drag_card.outerWidth()
          pos_y: __$active_drag_card.offset().top + __$active_drag_card.outerHeight() - e.pageY
          pos_x: __$active_drag_card.offset().left + __$active_drag_card.outerWidth() - e.pageX

        __active_drag_card_drag_data['original_top'] = e.pageY + __active_drag_card_drag_data['pos_y'] - __active_drag_card_drag_data['height']
        __active_drag_card_drag_data['original_left'] = e.pageX + __active_drag_card_drag_data['pos_x'] - __active_drag_card_drag_data['width']

        e.preventDefault();

      $deck.on 'mousemove', (e) ->
        if __$active_drag_card?
          new_top = e.pageY + __active_drag_card_drag_data['pos_y'] - __active_drag_card_drag_data['height']
          new_left = e.pageX + __active_drag_card_drag_data['pos_x'] - __active_drag_card_drag_data['width']
          original_left = __active_drag_card_drag_data['original_left']
          original_top = __active_drag_card_drag_data['original_top']
          
          messages = []
          if new_top - original_top < -200
            __active_drag_card_drag_data['original_top'] = __active_drag_card_drag_data['original_top']-200
            _move_card(__$active_drag_card,"up")
            messages.push 'UP' 
          if new_top - original_top > 200  
            __active_drag_card_drag_data['original_top'] = __active_drag_card_drag_data['original_top']+200
            _move_card(__$active_drag_card,"down")
            messages.push 'DOWN' 
          if new_left - original_left < -300
            __active_drag_card_drag_data['original_left'] = __active_drag_card_drag_data['original_left']-300
            _move_card(__$active_drag_card,"left")
            messages.push 'LEFT' 
          if new_left - original_left > 300
            __active_drag_card_drag_data['original_left']  = __active_drag_card_drag_data['original_left']+300
            _move_card(__$active_drag_card,"right")
            messages.push 'RIGHT'
          console.log messages.join(' ') if messages.length > 0

          __$active_drag_card.offset { top: new_top, left: new_left }

      $deck.on 'mouseup', (e) ->
        if __$active_drag_card?
          __$active_drag_card.removeClass('draggable')
          __$active_drag_card.css 'top', ''
          __$active_drag_card.css 'left', ''
          __$active_drag_card.css 'z-index', ''

          __$active_drag_card = undefined
          __active_drag_card_drag_data = undefined


    _move_card = ($card, direction) ->
      id = $card.data('card-id')
      d = __card_data_by_id[id]
      switch direction
        when 'left' then _force_card_to_position $card, d, { row: d.row, col: d.col - 1}
        when 'right' then _force_card_to_position $card, d, { row: d.row, col: d.col + 1}
        when 'up' then _force_card_to_position $card, d, { row: d.row - 1, col: d.col}
        when 'down' then _force_card_to_position $card, d, { row: d.row + 1, col: d.col}
      _apply_deck()

  # Deckster Expand
  if options['expandable'] && options['expandable'] == true
    _on __events.inited, ($deck) ->
      controls = """
                 <a class='#{_css_variables.classes.expand_handle} control expand'></a>
                 <a class='#{_css_variables.classes.collapse_handle} control collapse' style='display:none;'></a>
                 """
      $deck.find(_css_variables.selectors.controls).append controls

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
        d['col'] = if (expandColTo-1)+d.col <= __col_max  then d.col else 1
        d['col_span'] = expandColTo

        if d.col_span == $card.data('original-col-span') and d.row_span == $card.data('original-row-span')
          return;
        console.log ['Expand >>>', $card, d, { row: d.row, col: d.col }]


        _force_card_to_position $card, d, { row: d.row, col: d.col }
        _apply_deck()

        $expand_handle.hide()
        $expand_handle.siblings(_css_variables.selectors.collapse_handle).show()
        for callback in __event_callbacks[__events.card_expanded] || []
          break if callback($deck,$card) == false
          
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
        for callback in __event_callbacks[__events.card_collapsed] || []
          break if callback($deck,$card) == false
          
    if options['url_enabled'] == true
      _on __events.card_added, ($card,d) ->
        if $card.data("url")?
          ajax_options = 
            url: $card.data "url" 
            type: if $card.data("url-method")? then $card.data "url-method"  else "GET"
            context: $card
            success: (data,status,response) -> 
              if (!!data.trim()) # url content is not empty
                $controls = this.find(_css_variables.selectors.controls).clone true
                $title = this.find(_css_variables.selectors.card_title)
                this.html ""
                this.append $title
                this.append $controls
                this.append '<div class="content">' + data + '</div>'
              else # remove the card if url content is empty & div text content is empty
                divText = this.find(_css_variables.selectors.card_content).text()
                if (!divText.trim())
                  this.remove()

           _ajax(ajax_options)

    if options.url_enabled? # Just in case we'll be needing some real check
        _on __events.card_added, ($card,d) ->
          title = $card.data "title"

          unless title? and !$card.find(_css_variables.selectors.card_title).text()
                return
          $title_div = $('<div>')
                .text(title)
                .addClass(_css_variables.classes.card_title)
          $card.prepend $title_div

    if options['expandable'] and options['expandable'] == true 
      _on __events.inited, ()->
        #Find all decks that don't have "data-cards-expanded=false"
        $(_css_variables.selectors.deck+":not("+_css_variables.selector_functions.deck_expanded(false)+")").each((index)->
          $deck = $(this);
          #Find all cards that don't have "data-expanded=false" and expand them
          $deck.find(_css_variables.selectors.card+":not("+_css_variables.selector_functions.card_expanded(false)+")").each((index)->
            $(this).find(_css_variables.selectors.expand_handle).trigger "click"
          )
        )
        
       _on __events.card_expanded, ($deck,$card) ->
        deckId = $deck.data("deck-id") ? 1
        cardId = $card.data("card-id")
        if options["card-actions"]? and options["card-actions"]["deck-"+deckId]? and options["card-actions"]["deck-"+deckId]["card-"+cardId]? 

         cardActions = options["card-actions"]["deck-"+deckId]["card-"+cardId]
         if cardActions["card-expanded"]?
           ajaxOptions = cardActions["card-expanded"]($card,$card.find(_css_variables.selectors.card_content))
           if ajaxOptions?
            $card.queue().push(()->_ajax(ajaxOptions))

      _on __events.card_collapsed, ($deck,$card) ->
        deckId = $deck.data("deck-id") ? 1
        cardId = $card.data("card-id")
        if options["card-actions"]? and options["card-actions"]["deck-"+deckId]? and options["card-actions"]["deck-"+deckId]["card-"+cardId]? 

         cardActions = options["card-actions"]["deck-"+deckId]["card-"+cardId]
         if cardActions["card-collapsed"]?
           ajaxOptions = cardActions["card-collapsed"]($card,$card.find(_css_variables.selectors.card_content))
           if ajaxOptions?
            $card.queue().push(()->_ajax(ajaxOptions))

  # Deckster Remove
  if options['removable'] && options['removable'] == true
    _on __events.inited, ($deck) ->
      controls = """
                 <a class='#{_css_variables.classes.remove_handle}'>R</a>
                 """
      $deck.find(_css_variables.selectors.controls).append controls

      $deck.find(_css_variables.selectors.remove_handle).click ->
        _remove_on_click(this)

    _remove_on_click = (element) ->
        $remove_handle = $(element)
        $card = $remove_handle.parents(_css_variables.selectors.card)
        id = parseInt $card.attr 'data-card-id'
        titleText = $card.find(_css_variables.selectors.card_title).text()
        dropdown = $(_css_variables.selectors.removed_dropdown)

        if dropdown.val()?
          # add to dropdown menu
          dropdown.find('ul').append(_get_removed_card_li_tag(id, titleText)).appendTo(dropdown)
        else
          # construct a new dropdown menu
          removed_dropdown_div = "
          <div class='btn-group #{_css_variables.classes.removed_dropdown}'>
            <button type='button' class='btn btn-default dropdown-toggle' data-toggle='dropdown'>
              Removed Cards
              <span class='caret'></span>
            </button>
            <ul class='dropdown-menu pull-left'>
              " + _get_removed_card_li_tag(id, titleText) + " 
            </ul>
          </div>
          " 
          $('body').prepend(removed_dropdown_div)
          dropdown = $(_css_variables.selectors.removed_dropdown)
          
        dropdown.find('#' + _css_variables.classes.removed_card_button + '-' + id).click ->
          _add_back_card(id)

        $card.remove()
        _remove_from_jump_scroll $card, id, titleText
        _apply_deck()

    _get_removed_card_li_tag = (id, titleText) ->
      "<li id='#{_css_variables.classes.removed_card_li}-" + id + 
        "' class='#{_css_variables.classes.removed_card_li}'>" + titleText + 
        "<button id='#{_css_variables.classes.removed_card_button}-" + id + 
        "' class='btn btn-default #{_css_variables.classes.removed_card_button}'>Re-add</button>" + 
      "</li>"

    _remove_from_jump_scroll = ($card, cardId, cardTitle) ->
      $nav_list = $(_css_variables.selectors.card_jump_scroll).find('ul')

      $nav_list.find('li').filter () ->
        $.text([this]) == cardTitle 
      .remove();

    _add_back_card = (cardId) ->
      return unless cardId?
        
      $card = __cards_by_id[cardId] 
      d = __card_data_by_id[cardId]

      $('#deck1').append($card)
      _add_card $card, d
      _apply_deck()

      # add back the control buttons click behavior
      $card.find(_css_variables.selectors.remove_handle).click ->
        _remove_on_click(this)
      $card.find(_css_variables.selectors.expand_handle).click ->
        _expand_on_click(this)
      $card.find(_css_variables.selectors.collapse_handle).click ->
        _collapse_on_click(this)
      _bind_drag_controls($card)

      # add back to the jump card 
      _add_to_jump_scroll_card "#{_css_variables.selectors.card_jump_scroll} ul", $card

      # remove from the "Removed Cards" dropdown
      $('#' + _css_variables.classes.removed_card_li + '-' + cardId).remove()

      dropdown = $(_css_variables.selectors.removed_dropdown)
      dropdown.remove() if dropdown.find('ul').children().size() == 0
        
  # Deckster End

  init()

  deckster =
    deck: __deck
    on: _on
    events: __events

$ = jQuery
$.fn.deckster = window.Deckster


$("#deck1").deckster({
    animate: {
      properties: {
        opacity: ".5"
      },
      options: {
        duration: "slow"
      }
    }
  
    "card-actions":{
      "deck-1":
        "card-6":
          "card-expanded": ($card,$contentSection)->
            ajax_options =
              url:"./sampleSites/site6expand"
              type:"GET"
              success: (data,status, response)->
                ###
                  You'll want to replace the conte
                ###
                $cardContent = $contentSection.html(data)

                console.log("I've successfully replaced the content")
              error: ()->
                console.log("I've failed to repalce the content")
            
            return ajax_options
          "card-collapsed": ($card, $contentSection)->
            ajax_options =
              url:"./sampleSites/site6"
              type:"GET"
              success: (data,status, response)->
                $cardContent = $contentSection.html(data)

                console.log("I've successfully replaced the content")
              error: ()->
                console.log("I've failed to repalce the content")
            
            return ajax_options
    }
})
