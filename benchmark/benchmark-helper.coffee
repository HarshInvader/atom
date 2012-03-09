nakedLoad 'jasmine-jquery'
$ = require 'jquery'
_ = require 'underscore'
Keymap = require 'keymap'
Point = require 'point'

require 'window'

keymap = new Keymap
keymap.bindDefaultKeys()
$(window).on 'keydown', (e) -> keymap.handleKeyEvent(e)
keymap.bindKeys '*',
  'meta-w': 'close'
  'alt-meta-i': 'show-console'
$(document).on 'close', -> window.close()
$(document).on 'show-console', -> window.showConsole()


window.pbenchmark = window.profile
window.fpbenchmark = (description, fn) -> window.profile(description, fn, true)
window.pfbenchmark = window.fpbenchmark
window.fbenchmark = (description, fn, profile) -> window.benchmark(description, fn, profile, true)

window.profile = (description, fn, focused) ->
  window.showConsole()
  window.benchmark(description, fn, true, focused)

window.benchmark = (description, fn, profile=false, focused=false) ->
  method = if focused then fit else it
  method description, ->
    count = 100
    total = measure ->
      console.profile(description) if profile
      _.times count, fn
      console.profileEnd(description) if profile
    avg = total / count
    report = "#{description}: #{total} / #{count} = #{avg}ms"

    console.log report
    throw new Error(report)

window.measure = (fn) ->
  start = new Date().getTime()
  fn()
  new Date().getTime() - start

window.waitsForPromise = (fn) ->
  window.waitsFor (moveOn) ->
    fn().done(moveOn)

window.eventPropertiesForPattern = (pattern) ->
  [modifiers..., key] = pattern.split '-'

  modifiers.push 'shift' if key == key.toUpperCase() and key.toUpperCase() != key.toLowerCase()
  charCode = key.toUpperCase().charCodeAt 0

  isNamedKey = key.length > 1
  if isNamedKey
    keyIdentifier = key
  else
    keyIdentifier = "U+00" + charCode.toString(16)

  ctrlKey: 'ctrl' in modifiers
  altKey: 'alt' in modifiers
  shiftKey: 'shift' in modifiers
  metaKey: 'meta' in modifiers
  which: charCode
  originalEvent:
    keyIdentifier: keyIdentifier

window.keydownEvent = (pattern, properties={}) ->
  event = $.Event "keydown", _.extend(eventPropertiesForPattern(pattern), properties)
  event.keystroke = (new Keymap).keystrokeStringForEvent(event)
  event

window.clickEvent = (properties={}) ->
  $.Event "click", properties

window.mouseEvent = (type, properties) ->
  if properties.point
    {point, editor} = properties
    {top, left} = @pagePixelPositionForPoint(editor, point)
    properties.pageX = left + 1
    properties.pageY = top + 1
  properties.originalEvent ?= {detail: 1}
  $.Event type, properties

window.mousedownEvent = (properties={}) ->
  window.mouseEvent('mousedown', properties)

window.mousemoveEvent = (properties={}) ->
  window.mouseEvent('mousemove', properties)

window.pagePixelPositionForPoint = (editor, point) ->
  point = Point.fromObject point
  top = editor.lines.offset().top + point.row * editor.lineHeight
  left = editor.lines.offset().left + point.column * editor.charWidth - editor.lines.scrollLeft()
  { top, left }

window.setEditorWidthInChars = (editor, widthInChars, charWidth=editor.charWidth) ->
  editor.width(charWidth * widthInChars + editor.lines.position().left)

$.fn.resultOfTrigger = (type) ->
  event = $.Event(type)
  this.trigger(event)
  event.result

$.fn.enableKeymap = ->
  @on 'keydown', (e) => window.keymap.handleKeyEvent(e)

$.fn.attachToDom = ->
  $('#jasmine-content').append(this)

$.fn.textInput = (data) ->
  event = document.createEvent 'TextEvent'
  event.initTextEvent('textInput', true, true, window, data)
  this.each -> this.dispatchEvent(event)

