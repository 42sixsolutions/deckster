# deckster - the web framework that holds all the cards

# ABOUT

Deckster is a lightweight web UI framework for organizing lots of interactive elements on a single screen.

# REQUIREMENTS

* [Node.js](http://nodejs.org/) 0.10+. If multiple versions are needed in your environment, consult [NVM](https://github.com/creationix/nvm).
* `make`, such as from [Xcode](https://developer.apple.com/xcode/) command line tools, [build-essential](http://packages.ubuntu.com/search?keywords=build-essential), or [Strawberry Perl](http://chocolatey.org/packages/StrawberryPerl).
* A modern web browser, such as Mozilla Firefox 10+, Google Chrome 20+, or Microsoft IE 9+.

## Optional

* [tidy](http://tidy.sourceforge.net/) for linting HTML

# BUILD

1. Install the smelting tools: node-sass and coffee-script. `npm install -g node-sass coffee-script`
2. Smelt the source into finely crafted JavaScript and CSS. `make`
3. Launch the demo server. `make serve`
4. View the demo. `open http://localhost:3030/`

# DEPLOY

1. Run `make zip`.
2. Copy the resulting `.zip` file to your web application.
3. Expand the contents into `public/` or the like.
4. Move files and modify `index.html` as necessary.

`sampleSites/` represents sample data sources for the main `index.html` application.

# LINT

Running `make lint` yields tips for improving the code.

# Using Deckster

## Navigation
For large pages with many cards or multiple decks, a navigation button bar is provided at the top right (position is
configurable, see below).  Each button opens a drop-down menu with a list of items, either cards or decks, listed by title.
Clicking on one of these will scroll the page to bring the selected item into view.

# Options

1. Expand/Collapse a Deck
    
    Note:
    The attribute, data-expandable="true", must be set on the deck for this section to work.

    Expand/Collapse All Cards in a Deck:
    By default all cards will be expanded (i.e. a data attribute will be implicity added to the deck <..class="deckster-deck".. data-cards-expanded="true"..>). To override, a developer can set `data-cards-expanded="false"` (No cards in this deck will be expanded).
   
    Expand/Collapse a Card in the Deck:
    All cards in a deck will be expanded unless the deck has the data attribute `data-cards-expanded="false"`. If you want to make sure a card or cards isn't expanded with the whole deck, then add a `data-expanded="false"` attribute to the card's metadata. (i.e. < .. class="deckster-card" ... data-expanded="false" ..>)

2. Add Content via URL
    
    -You can add custom content to a card via URL by adding a `data-url="<url>"` attribute to the card.
    
    -For debugging purposes, you can disable all URL calls within a deck by declaring `data-url-enabled="false"` on the parent deck.

25. Add a Title to a Card or Deck
    Both Decks and Cards honor the "data-title" attribute in the HTML markup.  If a value is provided for this attribute in an element of class "deckster-deck" or "deckster-card", Deckster will add a title header to the Deck or Card.

3. Customize Expand Size

    To customize a card's expand size, set the `data-col-expand` attribute to adjust the column size and the `data-row-expand` attribute to adjust the row size. The maximum column size is specified via `data-col-max` (which is set on the deck element).

    Notes:
    
    -If `data-row-expand` or `data-col-expand` is not specified on the element, than that dimension will not change when the card is expanded.
    
    -If `data-row-expand` or `data-col-expand` is less than or equal to zero, then that dimension will not change when the card is expanded. 
    
    -If `data-col-expand` is greater than `data-col-max`, then `data-col-expand` will be implicitly shortened to `data-col-max`.
    
    -Otherwise, the card's dimensions are altered when expanded.

4. Hide Card

    To hide a card, set the `data-hidden` attribute to `true`.

    Notes:

    -If the content loaded from `data-url` is empty, and the card's existing content is empty, then the card will not be shown in the deck.
    
    -If the deck's `data-remove-empty` attribute is `false`, then no empty cards will be removed automatically when the deck loads.

5. Remove Card
    
    To remove a card from the deck, click on the "remove" control handle on the card. To disable this functionality, add the `data-removable="false"` attribute to the deck element. 

    Notes:

    -Removed cards will be displayed in the `Removed Cards` dropdown menu at top left corner.  Removed cards can be added back to the deck by clicking on the `Re-add` button on the removed card in the dropdown menu.

6. Adding Expanding/Collapsing Callbacks
    
    If you'd like to change the content of a card when it is expanded or collapsed, there are callbacks you can set when the deck is being initialized.  

    Required Format

              "card-actions": { ...
                "deck-<deckId>": { ...
                  "card-<cardId>": {
                      card-expanded: function(..) {
                        ..
                      },
                      card-collapsed: function(..){
                        ..
                      }
                  }
                }
              }
              
     The example below targets the deck with `data-deck-id = 1` that also contains a card with `data-card-id = 6` 

            $("#deck1").deckster({
              "card-actions": {
                "deck-1": {
                  "card-6": {
                    "card-expanded": function($card, $contentSection) {
                      var ajax_options;
                      ajax_options = {
                        url: "./sampleSites/site6expand",
                        ...
                        success: function(data, status, response) {
                              ...
                              $contentSection.html(data)
                        },
                      };
                      return ajax_options;
                    },
                    "card-collapsed": function($card, $contentSection) {
                       
                       $contentSection.append("...new content here...")
                    }
                  }
                }
              }
            });  
       
    Things to Note:

    1. You are given a handle to the card being expanded/collapsed.
    2. For convenience, you are also given a handle to the main content area of the card. If you'd like to make changes/edits to the content, you should use this handle.
    3. If you'd like to run an ajax request, construct a mapping with the required information and return it from the method.

14. Configuring the positioning of the Jump Scroll bar
    
    The positioning of the Jump Scroll Bar can be configured in the options object passed in to the Deckster
    constructor function.  For example:

            $("#deck1").deckster({
              "scroll-helper": {
                  "x-position": "middle" # left | middle | right
                  "y-position": "top" # bottom | middle | top
		  "stay-in-view": false # true | false
              }
            });
