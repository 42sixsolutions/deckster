#!/usr/bin/env node

var
http = require("http"),
path = require("path"),

paperboy = require("paperboy"),
webroot = path.dirname(__filename),

port = 3030;

function server() {
  http.createServer(function (req, res) {
    paperboy.deliver(webroot, req, res).otherwise(function (err) {
      res.writeHead(404, { "Content-Type": "text/plain" });
      res.end("Resource not found.");
    });
  }).listen(port);

  console.log("Server started at http://localhost:" + port + "/");
}

server();
