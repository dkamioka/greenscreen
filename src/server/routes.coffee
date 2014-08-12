###
Copyright (c) 2014, Groupon
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.###

pathLib = require "path"
Alert = require "./alert"
Channel = require "./channel"
Receiver = require "./receiver"
Takeover = require "./takeover"

module.exports = (app, sockets) ->
  addResources = (basePath, resourceClass) ->
    app.get "#{basePath}", (req, res) ->
      resourceClass.all (err, resources) ->
        if err then res.send err else res.send resources

    app.get "#{basePath}/:id", (req, res) ->
      resourceClass.findById req.param("id"), (err, resource) ->
        return res.status(404).send(null) if err && err.error == "not_found"
        return res.status(500).send(err) if err
        res.send resource

    app.post "#{basePath}", (req, res) ->
      data = req.body
      resource = new resourceClass(data)
      resource.save (err) ->
        return res.status(500).send(err) if err
        sockets.emit "#{resourceClass.type}-created", resource
        res.send resource

    app.put "#{basePath}/:id", (req, res) ->
      resourceClass.findById req.param("id"), (err, resource) ->
        return res.status(404).send(null) if err && err.error == "not_found"
        return res.status(500).send(err) if err
        resource.update req.body, (err) ->
          return res.status(500).send(err) if err
          sockets.emit "#{resourceClass.type}-updated", resource
          res.send resource

    app.delete "#{basePath}/:id", (req, res) ->
      resourceClass.findById req.param("id"), (err, resource) ->
        return res.status(404).send(null) if err && err.error == "not_found"
        return res.status(500).send(err) if err
        resource.destroy (err) ->
          return res.status(500).send(err) if err
          sockets.emit "#{resourceClass.type}-deleted", resource
          res.send status: "success"

  addResource = (basePath, resourceClass, id) ->
    app.get "#{basePath}", (req, res) ->
      resourceClass.findById id, (err, resource) ->
        return res.status(404).send(null) if err && err.error == "not_found"
        return res.status(500).send(err) if err
        res.send resource

    app.post "#{basePath}", (req, res) ->
      data = req.body
      data.id = id
      resource = new resourceClass(data)
      resource.save (err) ->
        return res.status(500).send(err) if err
        sockets.emit "#{resourceClass.type}-created", resource
        res.send resource

    app.put "#{basePath}", (req, res) ->
      resourceClass.findById id, (err, resource) ->
        return res.status(404).send(null) if err && err.error == "not_found"
        return res.status(500).send(err) if err
        resource.update req.body, (err) ->
          return res.status(500).send(err) if err
          sockets.emit "#{resourceClass.type}-updated", resource
          res.send resource

    app.post "#{basePath}/remove", (req, res) ->
      resourceClass.findById id, (err, resource) ->
        return res.status(404).send(null) if err && err.error == "not_found"
        return res.status(500).send(err) if err
        resource.destroy (err) ->
          return res.status(500).send(err) if err
          sockets.emit "#{resourceClass.type}-deleted", resource
          res.send status: "success"

  addResources "/api/alerts", Alert
  addResources "/api/channels", Channel
  addResources "/api/receivers", Receiver
  addResource "/api/takeover", Takeover, "takeover-singleton"

  app.get "/chromecasts/new", (req, res) ->
    res.sendfile pathLib.resolve("#{__dirname}/../../public/index.html")

  app.get "/chromecasts/:id", (req, res) ->
    res.sendfile pathLib.resolve("#{__dirname}/../../public/setup-chromecast.html")

  app.get "/channels/new", (req, res) ->
    res.sendfile pathLib.resolve("#{__dirname}/../../public/index.html")

  app.get "/channels/:id", (req, res) ->
    res.sendfile pathLib.resolve("#{__dirname}/../../public/channel.html")

  # Wildcard all GET routes, send to the Angular app
  app.get "*", (req, res) ->
    res.sendfile pathLib.resolve("#{__dirname}/../../public/index.html")
