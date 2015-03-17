###!
  * Main Function
###

$ = require "jquery"
TalkData = require "./model/talkData"
TalkManager = require "./view/talkManager"
ProfileManager = require "./view/profileManager"

$ ->
  ###
    DECLARE
  ###
  talkData = TalkData()
  talkManager = TalkManager()
  profileManager = ProfileManager()

  cur_talk = 0
  cur_person_num = 1
  cur_scrollTop = 0
  cur_talk_top = $( window ).height() - 400
  is_next_error = false

  TALK_INTERVAL = 2000
  TALK_MARGIN = 20
  SCROLL_DUR = 100

  MY_NAME = "ゆめ"

  # set filename from div.meber_list
  FILENAME = {}
  $( ".memberList .member" ).each ->
    FILENAME[ $( this ).data "name" ] = $( this ).data "filename"

  ORIGINAL_TTL = $( ".wrapper .header .ttl" ).text()

  if window._DEBUG
    window.DEBUG = Object.freeze window._DEBUG
  else
    window.DEBUG = Object.freeze state: false

  ###
    EVENT LISTENER
  ###

  talkManager.listen "FIN_WRITE", ->
    $( ".input_container .submit" ).addClass "active"

  talkManager.listen "MEMBER_CHANGE", ( num )->
    cur_person_num += num
    if cur_person_num > 1
      $( ".wrapper .header .ttl" ).text(
        "#{ ORIGINAL_TTL }(#{ cur_person_num + 1 })" )
    else
      $( ".wrapper .header .ttl" ).text ORIGINAL_TTL

  ## show profile

  # &from icon
  $( document ).on "click", ".left .icon button", ->
    _fixBackground()

    talkManager.stopInput()

    name = $( this ).parents( ".left" ).find( ".name" ).text()
    profileManager.show( name, FILENAME[ name ] )

  # &from memberList
  $( document ).on "click", ".memberList .member button", ->
    name = $( this ).parents( ".member" ).data "name"
    profileManager.show( name, FILENAME[ name ] )

  ## close profile
 
  # &from close btn
  $( document ).on "click", ".profile .close button", ->
    if !$( ".memberList_container" ).hasClass "show"
      _releaseBackground()
      _fillInputRestart()
    _closeProfile()

  # &from air click
  $( document ).on "click", ".profile_container", ( e )->
    if $( e.target ).hasClass "profile_container"
      if !$( ".memberList_container" ).hasClass "show"
        _releaseBackground()
        _fillInputRestart()
      _closeProfile()

  # show member list
  $( ".menu button" ).on "click", ->
    talkManager.stopInput()
    $( ".filter, .memberList_container" ).addClass "show"

  # close member list
  $( ".memberList_container .back button" ).on "click", ->
    $( ".filter, .memberList_container" ).removeClass "show"
    _fillInputRestart()

  # zoom picture
  $( document ).on "click", ".left .picture", ->
    _fixBackground()
    talkManager.stopInput()
    $( ".zoomPicture_container" ).addClass "show"
    $( ".zoomPicture img" ).attr src: $( this ).find( "img" ).attr "src"

  # close zoom picture
  $( ".zoomPicture_container" ).on "click", ( e )->
    if $( e.target ).get( 0 ).tagName != "IMG"
      _releaseBackground()
      _fillInputRestart()
      $( ".zoomPicture_container" ).removeClass "show"
      $( ".zoomPicture img" ).attr src: "img/common/dummy.png"

  # close tutorial
  $( ".tutorial_container" ).on "click", ->
    $( this ).hide()

  # enter submit btn
  # append right section
  $( ".input_container .submit" ).on "click", ->
    return if !$( this ).hasClass "active"
    now = new Date()
    $( this ).removeClass( "active" )
    $( ".input_container .input" ).text ""

    talkManager.append
      type: "right"
      read_count: cur_person_num
      time: "#{ now.getHours() }:" +
            "#{ ( "00" + now.getMinutes() ).slice( -2 ) }"
      comment: window.gdata.talk[ cur_talk ].comment
      top: cur_talk_top
      is_error: is_next_error

    is_next_error = false
    $( "html, body" ).animate
      scrollTop: cur_talk_top + $( ".talk >div:last-child" ).outerHeight() -
                 $( window ).height()
      , SCROLL_DUR, "linear"

    cur_talk += 1
    cur_talk_top += $( ".right:last-child" ).height() + TALK_MARGIN
    _nextTalk()

  # check password
  $( ".password" ).on "focus", ->
    $( this ).val( "" )
  $( ".secret_container .enter" ).on "click", ->
    txt = $( ".password" ).val()
    ascii_sum = 0
    for i in [ 0...txt.length ]
      ascii_sum += txt.charCodeAt( i )
    ascii_sum = ascii_sum << 2
    if ascii_sum == 2432
      _load()

  ###
    PRIVATE
  ###
  _load = ->
    # hide auth page
    $( ".secret_container" ).animate
      opacity: 0
    , 200, ->
      $( ".secret_container" ).hide()
      $( ".loading_container" ).show()

    talkData.exec()

    _checkLoaded = ->
      setTimeout ->
        if window.gdata.talk?
          $( ".loading_container" ).animate
            opacity: 0
          , 300, "linear", ->
            $( ".loading_container" ).hide()

          _nextTalk()
        else
          _checkLoaded()
      , 300

    setTimeout ->
      _checkLoaded() # show loading anim at least 2sec
    , 2000

  _nextTalk = ->
    # my turn
    if window.gdata.talk[ cur_talk ].name.match MY_NAME
      if window.gdata.talk[ cur_talk ].name.match /^error/
        is_next_error = true
      setTimeout ->
        talkManager.fillInput( window.gdata.talk[ cur_talk ].comment )
      , TALK_INTERVAL
    # friend turn
    else
      if window.gdata.talk[ cur_talk ].name.match /^interval/
        _re = /^interval_(.*?):/
        interval_rowData = _re.exec( window.gdata.talk[ cur_talk ].name )
        interval = interval_rowData[ 1 ]

        window.gdata.talk[ cur_talk ].name =
          window.gdata.talk[ cur_talk ].name.replace interval_rowData[ 0 ], ""
      else
        interval = TALK_INTERVAL * 1.5

      setTimeout ->
        now = new Date()
        if window.gdata.talk[ cur_talk ].name == "機能"
          talkManager.append
            type: "function"
            time: "#{ now.getHours() }:" +
                  "#{ ( "00" + now.getMinutes() ).slice( -2 ) }"
            comment: window.gdata.talk[ cur_talk ].comment
            top: cur_talk_top
          cur_talk_top += $( ".function:last-child" ).height() + TALK_MARGIN
        else
          talkManager.append
            type: "left"
            icon_name: FILENAME[ window.gdata.talk[ cur_talk ].name ]
            name: window.gdata.talk[ cur_talk ].name
            comment: window.gdata.talk[ cur_talk ].comment
            time: "#{ now.getHours() }:" +
                  "#{ ( "00" + now.getMinutes() ).slice( -2 ) }"
            top: cur_talk_top
          cur_talk_top += $( ".left:last-child" ).height() + TALK_MARGIN

        $( "html, body" ).animate
          scrollTop: cur_talk_top + $( ".talk >div:last-child" ).outerHeight() -
                    $( window ).height()
          , SCROLL_DUR, "linear"
        cur_talk += 1
        _nextTalk()
      , interval

  _fixBackground = ->
    cur_scrollTop = $( document ).scrollTop()
    $( ".wrapper" ).css
      position: "fixed"
      top: -cur_scrollTop

  _releaseBackground = ->
    $( ".wrapper" ).removeAttr "style"
    $( "html, body" ).prop scrollTop: cur_scrollTop

  _fillInputRestart = ->
    setTimeout ->
      if window.gdata.talk[ cur_talk ].name.match( MY_NAME ) &&
         !$( ".profile_container" ).hasClass "show"
        # プロフィール画面表示中ならinput入力しない(連続タップ対策)
        talkManager.restartInput()
        talkManager.fillInput( window.gdata.talk[ cur_talk ].comment )
    , TALK_INTERVAL / 2

  _closeProfile = ->
    profileManager.close()

  ###
    INIT
  ###
  if window.DEBUG.state
    _load()
