CSS_DIR = public/stylesheets
MAIN_CSS = ${CSS_DIR}/deckster.css

all: build

build: ${MAIN_CSS} deckster.js

${MAIN_CSS}: ${CSS_DIR}/deckster.scss ${CSS_DIR}/partials/*.scss
	node-sass $< $@

deckster.js: deckster/*.coffee
	coffee -j deckster.js -c $<

serve: deckster.js ${MAIN_CSS} index.html jquery-2.0.3.min.js
	node server.js

rest: 
	node express_example/app.js

database: 
	./mongodb/bin/mongod

zip: deckster.js ${MAIN_CSS} index.html jquery-2.0.3.min.js
	zip deckster-0.0.1.zip deckster.js ${MAIN_CSS} index.html jquery-2.0.3.min.js

lint: coffeelint jshint csslint tidy

coffeelint: deckster.coffee
	-coffeelint --nocolor -r .

jshint: deckster.js package.json
	-jshint .
	-jshint *.json

csslint: ${MAIN_CSS}
	-csslint .

tidy: index.html
	-tidy index.html 2>&1

clean:
	-rm *.zip
	-rm ${MAIN_CSS}
	-rm deckster.js
