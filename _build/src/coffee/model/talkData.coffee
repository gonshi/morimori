$ = require "jquery"
EventDispatcher = require "../util/EventDispatcher"
instance = null

class TalkData
  constructor: ->
    @src = "https://spreadsheets.google.com/feeds/list/" +
           "1MCgqb_s3apyrD5ShriOMRNZ8UJsBMLGmcqdMKFrvcKI/" +
           "od6/public/basic?alt=json-in-script"

           

  exec: ->
    $( "head" ).append( $( document.createElement( "script" ) ).attr src: @src )

getInstance = ->
  if !instance
    instance = new TalkData()
  return instance

module.exports = getInstance

# spread sheet API callback
window.gdata = {}
window.gdata.io = {}
window.gdata.io.handleScriptLoaded = ( response )->
  length = response.feed.entry.length
  window.gdata.talk = []
  for i in [ 0...length ]
    window.gdata.talk[ i ] = {}
    window.gdata.talk[ i ].name = response.feed.entry[ i ].title.$t
    window.gdata.talk[ i ].comment =
      response.feed.entry[ i ].content.$t.replace( "発言: ", "" )
