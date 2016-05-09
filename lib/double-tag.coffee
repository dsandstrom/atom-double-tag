{CompositeDisposable, Range, Point} = require 'atom'

module.exports =

class DoubleTag
  constructor: (@editor) ->
    console.log 'new double tag'
    @subscriptions = new CompositeDisposable
    @foundTag = false

  destroy: ->
    @subscriptions?.dispose()

  watchForTag: ->
    @subscriptions.add @editor.onDidChangeCursorPosition (event) =>
      @reset() if @foundTag and @cursorLeftMarker()
      return if @foundTag

      @findTag(event.cursor)

  reset: ->
    console.log 'reset'
    @foundTag = false
    @startMarker.destroy()
    @endMarker.destroy()
    @startMaker = null
    @endMaker = null

  # private

  findTag: (@cursor) ->
    console.log 'watching for tag'
    return if @editor.hasMultipleCursors() or @editorHasSelectedText()

    if @cursorInHtmlTag()
      console.log 'in tag'
      return unless @findStartTag()
      console.log @tagText

      @startMarker = @editor.markBufferRange(@startTagRange, {})

      return unless @findEndTag()
      console.log @endTagRange
      @endMarker = @editor.markBufferRange(@endTagRange, {})
      @foundTag = true

    return unless @foundTag

    @subscriptions.add @startMarker.onDidChange (event) =>
      console.log 'marker changed'
      @copyNewTagToEnd()

  copyNewTagToEnd: ->
    return if @editor.hasMultipleCursors() or @editorHasSelectedText()
    # console.log @startMarker.getBufferRange()
    newTag = @editor.getTextInBufferRange(@startMarker.getBufferRange())
    # remove space after new tag, but allow blank new tag
    origTagLength = newTag.length
    if origTagLength
      matches = newTag.match(/^\w+/)
      return @reset() unless matches
      newTag = matches[0]
    newTagLength = newTag.length
    console.log 'newTag:', "`#{newTag}`"
    @editor.setTextInBufferRange(@endMarker.getBufferRange(), newTag)
    console.log 'copied'
    # reset if a space was added
    @reset() unless origTagLength != null && newTagLength != null &&
                    origTagLength == newTagLength

  editorHasSelectedText: ->
    # TODO: add test for "undefined length for null"
    @editor.getSelectedText()?.length > 0

  cursorInHtmlTag: ->
    scopeDescriptor = @cursor?.getScopeDescriptor()
    return unless scopeDescriptor

    scopes = scopeDescriptor.getScopesArray()
    return unless scopes

    scopes[1]?.match(/(meta\.tag|incomplete\.html)/)

  setFrontOfStartTag: ->
    frontRegex = /<(a-z)?/i
    frontOfStartTag = @cursor.getBeginningOfCurrentWordBufferPosition(
      {wordRegex: frontRegex}
    )
    return unless frontOfStartTag

    # don't include <
    @frontOfStartTag = new Point(
      frontOfStartTag.row, frontOfStartTag.column + 1
    )

  setBackOfStartTag: ->
    row = @frontOfStartTag.row
    rowLength = @editor.buffer.lineLengthForRow(row)

    backRegex = /[>\s/]/
    scanRange = new Range(@frontOfStartTag, new Point(row, rowLength))
    backOfStartTag = null
    @editor.buffer.scanInRange backRegex, scanRange, (obj) ->
      backOfStartTag = obj.range.start
      obj.stop()
    @backOfStartTag = backOfStartTag

  cursorIsInStartTag: ->
    cursorPosition = @cursor.getBufferPosition()
    return unless @startTagRange.containsPoint(cursorPosition)
    true

  findStartTag: ->
    # TODO: don't allow #, in tag
    @setFrontOfStartTag()
    return unless @frontOfStartTag

    @setBackOfStartTag()
    return unless @backOfStartTag

    @startTagRange = new Range(@frontOfStartTag, @backOfStartTag)
    return unless @cursorIsInStartTag()

    @tagText = @editor.getTextInBufferRange(@startTagRange)
    true

  findEndTag: ->
    startTagRegex = new RegExp("<#{@tagText}[>\\s]", 'i')
    tagRegex = new RegExp("<\\/?#{@tagText}[>\\s]", 'gi')
    endTagRange = null
    nestedTagCount = 0
    scanRange = new Range(@backOfStartTag, @editor.buffer.getEndPosition())
    console.log tagRegex
    @editor.buffer.scanInRange tagRegex, scanRange, (obj) ->
      if obj.matchText.match(startTagRegex)
        nestedTagCount++
      else
        nestedTagCount--
      if nestedTagCount < 0
        endTagRange = obj.range
        obj.stop()
    console.log 'found end'
    return unless endTagRange
    @endTagRange = new Range(
      [endTagRange.start.row, endTagRange.start.column + 2],
      [endTagRange.end.row, endTagRange.end.column - 1]
    )
    true

  cursorLeftMarker: ->
    cursorPosition = @cursor.getBufferPosition()
    !@startMarker.getBufferRange().containsPoint(cursorPosition)
