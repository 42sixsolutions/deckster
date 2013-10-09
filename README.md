# deckster - the web framework that holds all the cards

# ABOUT

Deckster is a lightweight web UI framework for organizing lots of interactive elements on a single screen.

# USAGE

Please reference the [samples](http://42sixsolutions.github.io/deckster/) for their usages.  In short, it's
'''javascript
    $("#deck1").deckster();
'''

## Deck Data Attributes

<dl>
    <dt>col-max (REQUIRED) (Example: 4)</dt>
    <dd>How many cards across is the deck?</dd>

    <dt>title (Example: 'Sample Deck')</dt>
    <dd>If given, a the title will display above the deck</dd>

    <dt>expandable (Default: True)</dt>
    <dd>Can the user expand the cards?  Individual card options can override this.</dd>

    <dt>cards-expanded (Default: True)</dt>
    <dd>Do the cards start out expanded?  Individual card options can override this.</dd>

    <dt>draggable (Default: True)</dt>
    <dd>Can the cards be dragged?  Individual card options can override this.</dd>

    <dt>removable (Default: True)</dt>
    <dd>Can the cards be removed?  Individual card options can override this.</dd>
</dl>

## Card Data Attributes

<dl>
    <dt>col (REQUIRED) (Example: 2)</dt>
    <dd>The initial column for the top left of the card</dd>

    <dt>row (REQUIRED) (Example: 2)</dt>
    <dd>The initial row for the top left of the card</dd>

    <dt>col-span (Example: 3)</dt>
    <dd>The width of the card</dd>

    <dt>row-span (Example: 3)</dt>
    <dd>The height of the card</dd>

    <dt>col-expand (Example: 4)</dt>
    <dd>The width of the card when expanded</dd>

    <dt>row-expand (Example: 4)</dt>
    <dd>The height of the card when expanded</dd>

    <dt>url (Example: 'http://www.google.com')</dt>
    <dd>If given, the response of the ajax call will be placed in the content</dd>

    <dt>title (Example: 'Sample Card')</dt>
    <dd>If given, the title will display above the deck</dd>

    <dt>expandable (Default: True)</dt>
    <dd>Can the user expand the card?  Individual card options can override this.</dd>

    <dt>cards-expanded (Default: True)</dt>
    <dd>Do the card start out expanded?  Individual card options can override this.</dd>

    <dt>draggable (Default: True)</dt>
    <dd>Can the card be dragged?  Individual card options can override this.</dd>

    <dt>removable (Default: True)</dt>
    <dd>Can the card be removed?  This will override the deck option.</dd>
</dl>

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