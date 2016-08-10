# FIXME: not activating when backspace to end of tag
# backspace selects to the left then deletes
# I'm returning when there is a selection

{CompositeDisposable, Range, Point} = require 'atom'

module.exports =

class DoubleTag
  constructor: (@editor) ->
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
    @foundTag = false
    @startMarker.destroy()
    @endMarker.destroy()
    @startMaker = null
    @endMaker = null

  # private

  findTag: (@cursor) ->
    return if @editor.hasMultipleCursors() or @editorHasSelectedText()
    return unless @cursorInHtmlTag()

    return unless @findStartTag()
    return if @tagShouldBeIgnored()

    @startMarker = @editor.markBufferRange(@startTagRange, {})

    return unless @findEndTag()
    @endMarker = @editor.markBufferRange(@endTagRange, {})
    @foundTag = true

    return unless @foundTag

    @subscriptions.add @startMarker.onDidChange (event) =>
      @copyNewTagToEnd()

  copyNewTagToEnd: ->
    return if @editor.hasMultipleCursors() or @editorHasSelectedText()
    newTag = @editor.getTextInBufferRange(@startMarker.getBufferRange())
    # remove space after new tag, but allow blank new tag
    origTagLength = newTag.length
    if origTagLength
      matches = newTag.match(/^[\w-]+/)
      return @reset() unless matches
      newTag = matches[0]
    newTagLength = newTag.length
    @editor.setTextInBufferRange(@endMarker.getBufferRange(), newTag)
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

  setBackOfStartTag: ->
    row = @frontOfStartTag.row
    rowLength = @editor.buffer.lineLengthForRow(row)

    backRegex = /($|[>\s/])/
    scanRange = new Range(@frontOfStartTag, new Point(row, rowLength))
    backOfStartTag = null
    @editor.buffer.scanInRange backRegex, scanRange, (obj) ->
      backOfStartTag = obj.range.start
      obj.stop()
    @backOfStartTag = backOfStartTag

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
    tagRegex = new RegExp("<\\/?#{@tagText}[>\\s]", 'gi')
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

  editorHasSelectedText: ->
    # TODO: add test for "undefined length for null"
    @editor.getSelectedText()?.length > 0

  cursorInHtmlTag: ->
    scopeDescriptor = @cursor?.getScopeDescriptor()
    return unless scopeDescriptor

    scopes = scopeDescriptor.getScopesArray()
    return unless scopes and scopes.length

    scopes.some (scope) -> /meta\.tag/.test(scope)

  cursorIsInStartTag: ->
    cursorPosition = @cursor.getBufferPosition()
    return unless @startTagRange.containsPoint(cursorPosition)
    true

  cursorLeftMarker: ->
    cursorPosition = @cursor.getBufferPosition()
    !@startMarker.getBufferRange().containsPoint(cursorPosition)

  tagShouldBeIgnored: ->
    atom.config.get('double-tag.ignoredTags')?.indexOf(@tagText) >= 0
