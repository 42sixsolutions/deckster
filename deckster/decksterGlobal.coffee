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
    add_card_to_bottom_button: '.deckster-add-card-to-bottom-button'
    card_content: '.content'
    placeholders: '.placeholders'
    droppable: '.droppable'
    deck_title: '.deckster-title'
    deck_container: '.deckster-deck-container'

  selector_functions:
    card_expanded: (option)->
      '[data-expanded=' + option + ']'
    deck_expanded: (option) ->
      '[data-cards-expanded=' + option + ']'
  classes: {}
  dimensions: {}
  styleSheet: "deckster.css"
# if no title available, display this many chars from the content section
  chars_to_display: 20
  buffer: "b"

_css_variables.classes[sym] = selector[1..] for sym, selector of _css_variables.selectors

__events =
  card_added: 'card_added'
  inited: 'inited'
  card_expanded: 'card_expanded'
  card_collapsed: 'card_collapsed'
  card_moved: 'card_moved'
