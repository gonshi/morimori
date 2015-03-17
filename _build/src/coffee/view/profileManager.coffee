$ = require "jquery"

class ProfileManager
  constructor: ->
    @$defaultProfileContainer = $( ".profile_container" ).clone()
    @$profileContainer = $( ".profile_container" )

  show: ( name, filename )->
    @$profileContainer.addClass "show"

    @$profileContainer.find( ".cover img" ).attr
      src: "img/cover/#{ filename }.jpg"

    @$profileContainer.find( ".icon img" ).attr
      src: "img/icon/#{ filename }.jpg"

    @$profileContainer.find( ".name" ).text name
    @$profileContainer.find( ".comment" ).text(
      $( ".memberList .#{ filename } .comment" ).eq( 0 ).text() )

    twitterURL = $( ".memberList .#{ filename }" ).eq( 0 ).data( "twitter" )
    if twitterURL != ""
      @$profileContainer.find( ".twitter a" ).attr
        href: twitterURL
      .addClass "active"

    vineURL = $( ".memberList .#{ filename }" ).eq( 0 ).data( "vine" )
    if vineURL != ""
      @$profileContainer.find( ".vine a" ).attr
        href: vineURL
      .addClass "active"

  close: ->
    _$defaultProfileContainer = @$defaultProfileContainer.clone()
    @$profileContainer.after _$defaultProfileContainer
    @$profileContainer.remove()
    @$profileContainer = _$defaultProfileContainer


getInstance = ->
  if !instance
    instance = new ProfileManager()
  return instance

module.exports = getInstance
