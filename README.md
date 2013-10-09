# deckster - the web framework that holds all the cards

# ABOUT

Deckster is a lightweight web UI framework for organizing lots of interactive elements on a single screen.

# USAGE

Please reference the [samples](http://42sixsolutions.github.io/deckster/) for their usages.  In short, it's
    $("#deck1").deckster();

## Deck Data Attributes

* col-max (REQUIRED) (Example: 4)
    How many cards across is the deck?

* title (Example: 'Sample Deck')
    If given, a the title will display above the deck

* expandable (Default: True)
    Can the user expand the cards?  Individual card options can override this.

* cards-expanded (Default: True)
    Do the cards start out expanded?  Individual card options can override this.

* draggable (Default: True)
    Can the cards be dragged?  Individual card options can override this.

* removable (Default: True)
    Can the cards be removed?  Individual card options can override this.

## Card Data Attributes

* col (REQUIRED) (Example: 2)
    The initial column for the top left of the card

* row (REQUIRED) (Example: 2)
    The initial row for the top left of the card

* col-span (Example: 3)
    The width of the card

* row-span (Example: 3)
    The height of the card

* col-expand (Example: 4)
    The width of the card when expanded

* row-expand (Example: 4)
    The height of the card when expanded

* url (Example: 'http://www.google.com')
    If given, the response of the ajax call will be placed in the content

* title (Example: 'Sample Card')
    If given, the title will display above the deck

* expandable (Default: True)
    Can the user expand the card?  Individual card options can override this.

* cards-expanded (Default: True)
    Do the card start out expanded?  Individual card options can override this.

* draggable (Default: True)
    Can the card be dragged?  Individual card options can override this.

* removable (Default: True)
    Can the card be removed?  This will override the deck option.

# DEVELOPMENT REQUIREMENTS

* [Node.js](http://nodejs.org/) 0.10+. If multiple versions are needed in your environment, consult [NVM](https://github.com/creationix/nvm).
* `make`, such as from [Xcode](https://developer.apple.com/xcode/) command line tools, [build-essential](http://packages.ubuntu.com/search?keywords=build-essential), or [Strawberry Perl](http://chocolatey.org/packages/StrawberryPerl).
* A modern web browser, such as Mozilla Firefox 10+, Google Chrome 20+, or Microsoft IE 9+.

## Optional

* [tidy](http://tidy.sourceforge.net/) for linting HTML

# BUILD

1. Install the smelting tools: node-sass and coffee-script. `npm install -g node-sass coffee-script`
2. Smelt the source into finely crafted JavaScript and CSS. `make`
3. Launch Demo Database. `make database`
4. Launch REST service. `make rest`
5. Launch the demo server. `make serve`
6. View the demo. `open http://localhost:3030/`

# DEPLOY

1. Run `make zip`.
2. Copy the resulting `.zip` file to your web application.
3. Expand the contents into `public/` or the like.
4. Move files and modify `index.html` as necessary.

`sampleSites/` represents sample data sources for the main `index.html` application.

# LINT

Running `make lint` yields tips for improving the code.