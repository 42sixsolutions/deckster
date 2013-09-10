  # Options
  __default_options =
    draggable: true
    expandable: true
    url_enabled: true
    removable: true
    droppable: true
    persist:true
    
  options = $.extend {}, __default_options, options

  ###
  # Modify an option setting (with the config_option key) based on the
  # presence and value of a corresponding data- attribute (data_attr)
  # on the Deck DOM element
  ###
  __set_option = (data_attr, config_option) ->
    option = $deck.data data_attr
    if option?
      options[config_option or data_attr] = option in [true, 'true']
  # if the data- attribute is not found, don't change the value

  __set_option 'draggable'
  __set_option 'expandable'
  __set_option 'removable'
  __set_option 'url-enabled', 'url_enabled'
  __set_option 'droppable'

  ###
     Init Dragging options
  ###
  options.animate = options.animate ? {}
  options.animate.properties = options.animate.properties ? {}
  options.animate.options = options.animate.options ? {}

  ###
  # Nav menu options (global)
  ###

  $.extend(_nav_menu_options, options["scroll-helper"])

  __next_id = 1
  __deck = {}
  __cards_by_id = {}
  __card_data_by_id = {}
  __col_max = 0
  __row_max = 0

  __cards_needing_resolved_in_order = []
  __cards_needing_resolved_by_id = {}

  __dominate_card_data = undefined