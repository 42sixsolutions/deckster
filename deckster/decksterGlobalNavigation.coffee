# Jump scroll area
_scrollToView = ($el) ->
  offset = $el.offset()
  offset.top -= 20
  offset.left -= 20
  $('html, body').animate {
    scrollTop: offset.top
    scrollLeft: offset.left
  }

_nav_menu = null # Feel free to rename this if something else fits better
_nav_menu_options = {}

###
# Creates the Bootstrap-based Navigation menu/Jump Scroll bar/Scroll helper from HTML,
# applies config options, places it in the DOM tree and returns the new element
###

_create_nav_menu = () ->
  markup = """<div class="btn-group #{_css_variables.classes.deck_jump_scroll}">
           <span class="dropdown-toggle control jump-deck" data-toggle="dropdown"></span>
           <ul class="dropdown-menu pull-right"></ul>
           </div>
           </div>
           """ # "stupid emacs
  button_dom = $ markup

  ### Let the Design/Developer place this in CSS
  stay_in_view = _nav_menu_options["stay-in-view"]
  if stay_in_view? and not stay_in_view
      outer_el = document
      button_dom.css 'position', 'absolute'
  else
      outer_el = window # outer_el is what we're going to measure to place the button bar

  left = false
  x_pos =_nav_menu_options["x-position"]
  calculate_x = () ->
      if x_pos is "left"
          left = "5px"
      else if x_pos is "right"
          button_dom.css "right", "5px"
          button_dom.find("ul.dropdown-menu")
              .removeClass("pull-left")
              .addClass("pull-right")
      else if x_pos is "middle"
          bw = button_dom.find(_css_variables.selectors.deck_jump_scroll)
                  .width()
          left = ($(outer_el).width() - bw) / 2
      else
      if left
          button_dom.css "left", left

  y_pos = _nav_menu_options["y-position"]
  top = "5px"
  calculate_top = () ->
      if y_pos is "bottom"
          top = ($(outer_el).height() - button_dom.height()) - 5
          button_dom.addClass("dropup")
      else if y_pos is "middle"
          top = ($(outer_el).height() - button_dom.height()) / 2
      button_dom.css "top", top

  # Apply calculate functions once to get approximate positioning
  calculate_x()
  calculate_top()
  ###
  $("body").append button_dom
  ###
  # Re-calculate with button size known
  calculate_top()
  calculate_x()
  ###
  # This makes sure something relevant is returned
  button_dom

# Designed both for scrolling to a deck and scrolling to a card in any deck.
# Builds the list based on all elements present in the DOM that match
# the title-selector (e.g., '.deckster-deck [data-title]' for a card
# with a title
_create_jump_scroll = (target_ul_selector, title_selector, classId) ->
  _nav_menu ?= _create_nav_menu()
  $item_title_ddl = $ target_ul_selector
  # Start fresh
  $item_title_ddl.children().remove()
  $title_items = $ title_selector
  if $title_items.length is 0
    return

  $title_items.each (index, item) ->
    title = $(item).data 'title'
    elementId = $(item).attr("data-card-id") ? $(item).attr("id")
    $nav_item = $ "<li id='#{classId + "-" + elementId}'><a href='#'>#{title}</a></li>"
    # Set up the click callback for the menu item
    $nav_item.on 'click', () ->
      _scrollToView $ item
    $item_title_ddl.append $nav_item

_create_jump_scroll_card = ($deck) ->
  # Collect all data-title cards from given deck
  _create_jump_scroll("#" + $deck.attr("id") + "-nav" + " ul",
    "#" + $deck.attr("id") + '.deckster-deck [data-title]',
    _css_variables.classes.card_jump_scroll)

_create_jump_scroll_deck = () ->
  _create_jump_scroll "#{_css_variables.selectors.deck_jump_scroll} ul",
    '.deckster-deck[data-title]',
    _css_variables.classes.deck_jump_scroll
