assert = require 'assert'
{ Parser } = require '../src/protocol'

class MockHandler
  constructor: ->
    @_log = []
    @gotError = no

  obtainLog: -> result = @_log.join("\n"); @_log = []; result
  log: (message) -> @_log.push message

  connected: (@protocol)  ->
  error:     (@error)     -> @gotError = yes

  message:   (msg) ->
    switch msg.command
      when 'reload'     then @log "reload(#{msg.path})"
      when 'inject'     then @log "inject(#{msg.javascript})"
      else                   @log msg.commmand



describe "Protocol", ->
  it "should reject a bogus handshake", ->
    handler = new MockHandler()
    parser  = new Parser(handler)

    parser.process 'boo'
    assert.ok handler.gotError


  it "should speak protocol 6", ->
    handler = new MockHandler()
    parser  = new Parser(handler)

    parser.process '!!ver:1.6'
    assert.equal 6, parser.protocol

    parser.process '[ "refresh", { "path": "foo.css" } ]'
    assert.equal "reload(foo.css)", handler.obtainLog()


  it "should speak protocol 7", ->
    handler = new MockHandler()
    parser  = new Parser(handler)

    parser.process '{ "command": "hello", "protocols": [ "http://livereload.com/protocols/official-7" ] }'
    assert.equal null, handler.error?.message
    assert.equal 7, parser.protocol

    parser.process '{ "command": "reload", "path": "foo.css" }'
    assert.equal "reload(foo.css)", handler.obtainLog()

  it "should speak protocol 7.1", ->
    handler = new MockHandler()
    parser  = new Parser(handler)

    parser.process '{ "command": "hello", "protocols": [ "http://livereload.com/protocols/unofficial-7.1" ] }'
    assert.equal null, handler.error?.message
    assert.equal 7.1, parser.protocol

    parser.process '{ "command": "reload", "path": "foo.css" }'
    assert.equal "reload(foo.css)", handler.obtainLog()

    parser.process '{ "command": "inject", "javascript": "var test=7.1" }'
    assert.equal "inject(var test=7.1)", handler.obtainLog()
