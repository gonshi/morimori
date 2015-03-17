$ = require "jquery"
EventDispatcher = require "../util/EventDispatcher"

class TalkManager extends EventDispatcher
  constructor: ->
    super()
    @first = true
    @is_stopInput = false
    @right_tmpl = '<div class="right">' +
                    '<div class="comment_container">' +
                      '<div class="info">' +
                        '<p class="read">既読 ${read_count}</p>' +
                        '<p class="time">${time}</p>' +
                      '</div>' +
                      '<p class="comment">${comment}</p>' +
                    '</div>' +
                  '</div>'

    @left_tmpl = '<div class="left">' +
                    '<p class="icon">' +
                      '<button>' +
                        '<img src="img/icon/${icon_name}.jpg" alt="アイコン">' +
                      '</button>' +
                    '</p>' +
                    '<p class="name">${name}</p>' +
                    '<div class="comment_container">' +
                      '<p class="comment">${comment}</p>' +
                      '<p class="time">${time}</p>' +
                    '</div>' +
                  '</div>'

    @function_tmpl = '<div class="function_container">' +
                       '<div class="function">' +
                         '<p class="time">${time}</p>' +
                         '<p class="comment">${comment}</p>' +
                       '</div>' +
                     '</div>'

  fillInput: ( txt )->
    return if @is_stopInput
    $input = $( ".input_container .input" )
    length = txt.length
    MAX_LENGTH = 22
    cur_length = $input.text().length + 1 # restart from current state

    if txt.match /^vine:/
      txt = txt.replace /^vine:/, ""
    else if txt.match /^picture:/
      txt = "(画像)"

    _write = =>
      @timer = setTimeout =>
        $input.html txt.slice 0, cur_length
        cur_length += 1
        if cur_length <= length &&
           cur_length <= MAX_LENGTH
          _write()
        else
          @dispatch "FIN_WRITE", this
          setTimeout =>
            $( ".tutorial_container" ).addClass( "show" ) if @first
          , 2000
      , 100
    _write()

  stopInput: ->
    clearInterval @timer
    @is_stopInput = true

  restartInput: ->
    @is_stopInput = false

  append: ( param )->
    @first = false
    is_picture = false
    should_border_rad = false
    read_count_target = 0
    if param.type == "right"
      _tmpl = @right_tmpl
    else if param.type == "left"
      _tmpl = @left_tmpl
    else
      _tmpl = @function_tmpl
      if param.comment.match "参加"
        @dispatch "MEMBER_CHANGE", this, 1
      else if param.comment.match "退出"
        @dispatch "MEMBER_CHANGE", this, -1

    vars = _tmpl.match /\${(.*?)}/g
    re = /\${(.*?)}/

    # embed vine
    if param.comment.match /^vine:/
      is_picture = true
      should_border_rad = true
      _re = /vine:(.*)$/
      vine_id = _re.exec( param.comment )[ 1 ]
      param.comment = '<iframe class="vine-embed" src="' +
                      "#{ vine_id }" + '/embed/simple" width="320" ' +
                      'height="320" frameborder="0"></iframe>'

    # embed stamp
    if param.comment.match /^stamp:/
      is_picture = true
      _re = /stamp:(.*)$/
      stamp_id = _re.exec( param.comment )[ 1 ]
      param.comment = '<a href="https://store.line.me/stickershop/' +
                      'product/1045491/ja" target="_blank">' +
                      "<img src=\"img/stamp/#{ stamp_id }.png\" " +
                      'alt="スタンプ" height="320"></a>'

    # embed picture
    if param.comment.match /^picture:/
      is_picture = true
      should_border_rad = true
      _re = /picture:(.*)$/
      picture_id = _re.exec( param.comment )[ 1 ]
      param.comment = '<button class="picture">' +
                      "<img src=\"img/picture/#{ picture_id }.jpg\" " +
                      'alt="画像" width="320" height="320"></button>'

    read_count_target = param.read_count # 既読1以上なら適当にカウントアップを演出
    if param.read_count < 2
      param.read_count = ""  # 既読2未満なら数字を表示しない
    else
      param.read_count = 1

    for v in vars
      key = re.exec v
      # html tag escape
      if !is_picture
        param[ key[ 1 ] ] = $( "<div>" ).text( param[ key[ 1 ] ] ).html()
      _tmpl = _tmpl.replace ///\${#{ key[ 1 ] }}///g, param[ key[ 1 ] ]

    _$tmpl = $( _tmpl ).appendTo ".talk"
    _$tmpl.css top: param.top

    _$tmpl.addClass "stamp" if is_picture # be transparent background
    _$tmpl.addClass "vine" if should_border_rad # be border radius circle

    if read_count_target > 1
      cur_count = parseInt( param.read_count ) + 1
      _countUp = ->
        setTimeout ->
          _$tmpl.find( ".read" ).text "既読 #{ cur_count }"
          cur_count += 1
          _countUp() if cur_count <= read_count_target
        , Math.random() * 400 + 80

      setTimeout ->
        _countUp()
      , 1000  # "既読"自体が表示されるまでの時間 (css animation)
    else if read_count_target == 0 # 既読0なら出さない
      _$tmpl.find( ".read" ).hide()

    if param.is_error? && param.is_error
      _$tmpl.find( ".read" ).hide()
      setTimeout ( -> _$tmpl.addClass "error" ), 1000

getInstance = ->
  if !instance
    instance = new TalkManager()
  return instance

module.exports = getInstance
