{CompositeDisposable, Range, Point} = require 'atom'

module.exports =

class DoubleTag
  constructor: (@editor) ->
    @subscriptions = new CompositeDisposable
    @foundTag = false
    @foundEndTag = false
    @watchForTag()

  destroy: ->
    @subscriptions?.dispose()

  watchForTag: ->
    @subscriptions.add @editor.onDidChangeCursorPosition (event) =>
      @reset() if @foundTag and @cursorLeftMarker(@startMarker)
      @reset() if @foundEndTag and @cursorLeftMarker(@endMarker)
      return if @foundTag || @foundEndTag
      @findTag(event.cursor)

  reset: ->
    @foundTag = false
    @foundEndTag = false
    @startMarker.destroy()
    @endMarker.destroy()
    @startMaker = null
    @endMaker = null

  # private

  findTag: (@cursor) ->
    return if @editor.hasMultipleCursors()
    return unless @cursorInHtmlTag()

    if @findStartTag()
      return if @tagShouldBeIgnored()

      @startMarker = @editor.markBufferRange(@startTagRange, {})

      return unless @findMatchingEndTag()
      @endMarker = @editor.markBufferRange(@endTagRange, {})
      @foundTag = true

      @subscriptions.add @startMarker.onDidChange (event) =>
        @copyNewTagToEnd()
    else if atom.config.get('double-tag.allowEndTagSync') and @findEndTag()
      return if @tagShouldBeIgnored()

      @endMarker = @editor.markBufferRange(@endTagRange, {})

      return unless @findMatchingStartTag()
      @startMarker = @editor.markBufferRange(@startTagRange, {})
      @foundEndTag = true

      @subscriptions.add @endMarker.onDidChange (event) =>
        @copyNewTagToStart()

  copyNewTagToEnd: ->
    return if @editor.hasMultipleCursors()
    newTag = @editor.getTextInBufferRange(@startMarker.getBufferRange())
    # remove space after new tag, but allow blank new tag
    origTagLength = newTag.length
    if origTagLength
      matches = newTag.match(/^[\w-]+/)
      return @reset() unless matches
      newTag = matches[0]
    newTagLength = newTag.length
    @editor.setTextInBufferRange(@endMarker.getBufferRange(), newTag)
    @editor.buffer.groupLastChanges()
    # reset if a space was added
    @reset() unless origTagLength != null and newTagLength != null and
                    origTagLength == newTagLength

  copyNewTagToStart: ->
    return if @editor.hasMultipleCursors()
    newTag = @editor.getTextInBufferRange(@endMarker.getBufferRange())
    # remove space after new tag, but allow blank new tag
    origTagLength = newTag.length
    if origTagLength
      matches = newTag.match(/^[\w-]+/)
      return @reset() unless matches
      newTag = matches[0]
    newTagLength = newTag.length
    @editor.setTextInBufferRange(@startMarker.getBufferRange(), newTag)
    @editor.buffer.groupLastChanges()
    # reset if a space was added
    @reset() unless origTagLength != null and newTagLength != null and
                    origTagLength == newTagLength

  setFrontOfStartTag: ->
    frontRegex = /<[a-z]+/i
    frontOfStartTag = @cursor.getBeginningOfCurrentWordBufferPosition(
      {wordRegex: frontRegex}
    )
    return unless frontOfStartTag

    # don't include <
    @frontOfStartTag = new Point(
      frontOfStartTag.row, frontOfStartTag.column + 1
    )

  setFrontOfEndTag: ->
    endRegex = new RegExp("</", "i")
    frontOfEndTag =
      @cursor.getBeginningOfCurrentWordBufferPosition({wordRegex: endRegex})

    # don't include <
    @frontOfEndTag = new Point(
      frontOfEndTag.row, frontOfEndTag.column + 2
    )

  setBackOfStartTag: ->
    row = @frontOfStartTag.row
    rowLength = @editor.buffer.lineLengthForRow(row)

    backRegex = /[^\w-]/
    endOfLine = new Point(row, rowLength)
    scanRange = new Range(@frontOfStartTag, endOfLine)
    backOfStartTag = null
    @editor.buffer.scanInRange backRegex, scanRange, (obj) ->
      backOfStartTag = obj.range.start
      obj.stop()
    @backOfStartTag = backOfStartTag || endOfLine

  setBackOfEndTag: ->
    row = @frontOfEndTag.row
    rowLength = @editor.buffer.lineLengthForRow(row)

    backRegex = /[^\w-]/
    endOfLine = new Point(row, rowLength)
    scanRange = new Range(@frontOfEndTag, endOfLine)
    backOfEndTag = null
    @editor.buffer.scanInRange backRegex, scanRange, (obj) ->
      backOfEndTag = obj.range.start
      obj.stop()
    @backOfEndTag = backOfEndTag || endOfLine

  findStartTag: ->
    @setFrontOfStartTag()
    return unless @frontOfStartTag

    @setBackOfStartTag()
    return unless @backOfStartTag and @tagIsComplete()

    @startTagRange = new Range(@frontOfStartTag, @backOfStartTag)
    return unless @cursorIsInStartTag()

    @tagText = @editor.getTextInBufferRange(@startTagRange)
    true

  findMatchingEndTag: ->
    regexSafeTagText =
      @tagText.replace(/[-[\]{}()*+!<=:?.\/\\^$|#\s,]/g, '\\$&')
    tagRegex = new RegExp("<\\/?#{regexSafeTagText}[>\\s]", 'gi')
    endTagRange = null
    nestedTagCount = 0
    scanRange = new Range(@backOfStartTag, @editor.buffer.getEndPosition())
    @editor.buffer.scanInRange tagRegex, scanRange, (obj) ->
      if obj.matchText.match(/^<\w/)
        nestedTagCount++
      else
        nestedTagCount--
      if nestedTagCount < 0
        endTagRange = obj.range
        obj.stop()
    return unless endTagRange
    # don't include <\, >
    @endTagRange = new Range(
      [endTagRange.start.row, endTagRange.start.column + 2],
      [endTagRange.end.row, endTagRange.end.column - 1]
    )
    true

  findMatchingStartTag: ->
    # TODO: move regex to string
    regexSafeTagText =
      @tagText.replace(/[-[\]{}()*+!<=:?.\/\\^$|#\s,]/g, '\\$&')
    tagRegex = new RegExp("<\\/?#{regexSafeTagText}([> ]|(?=\\n))", 'gi')
    startTagRange = null
    nestedTagCount = 0
    scanRange = new Range([0, 0], @frontOfEndTag)
    @editor.buffer.backwardsScanInRange tagRegex, scanRange, (obj) ->
      if obj.matchText.match(/^<\//)
        nestedTagCount++
      else
        nestedTagCount--
      if nestedTagCount < 0
        startTagRange = obj.range
        obj.stop()
    return unless startTagRange
    # don't include <
    rangeStart = [startTagRange.start.row, startTagRange.start.column + 1]
    if /\w$/.test(@editor.getTextInBufferRange(startTagRange))
      rangeEnd = startTagRange.end
    else
      # don't include >
      rangeEnd = [startTagRange.end.row, startTagRange.end.column - 1]
    @startTagRange = new Range(rangeStart, rangeEnd)
    true

  findEndTag: ->
    @setFrontOfEndTag()
    return unless @frontOfEndTag

    @setBackOfEndTag()
    return unless @backOfEndTag

    @endTagRange = new Range(@frontOfEndTag, @backOfEndTag)

    @tagText = @editor.getTextInBufferRange(@endTagRange)
    true

  cursorInHtmlTag: ->
    scopeDescriptor = @cursor?.getScopeDescriptor()
    return unless scopeDescriptor

    scopes = scopeDescriptor.getScopesArray()
    return unless scopes and scopes.length

    tagScopeRegex = /meta\.tag|tag\.\w+(\.\w+)?\.html/
    scopes.some (scope) -> tagScopeRegex.test(scope)

  cursorIsInStartTag: ->
    cursorPosition = @cursor.getBufferPosition()
    return unless @startTagRange.containsPoint(cursorPosition)
    true

  cursorIsInEndTag: ->
    cursorPosition = @cursor.getBufferPosition()
    return unless @endTagRange.containsPoint(cursorPosition)
    true

  cursorLeftMarker: (marker) ->
    cursorPosition = @cursor.getBufferPosition()
    !marker.getBufferRange().containsPoint(cursorPosition)

  tagShouldBeIgnored: ->
    atom.config.get('double-tag.ignoredTags')?.indexOf(@tagText) >= 0

  tagIsComplete: ->
    tagIsComplete = false
    scanRange = new Range(@backOfStartTag, @editor.buffer.getEndPosition())
    regex = new RegExp('<|>')
    @editor.buffer.scanInRange regex, scanRange, (obj) ->
      tagIsComplete = obj.matchText == '>'
    tagIsComplete
