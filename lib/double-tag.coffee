# FIXME: not activating when backspace to end of tag
# backspace selects to the left then deletes
# I'm returning when there is a selection

{CompositeDisposable, Range, Point} = require 'atom'

module.exports =

class DoubleTag
  constructor: (@editor) ->
    # console.log 'new double tag' if @debugEnabled()
    @subscriptions = new CompositeDisposable
    @foundTag = false

  destroy: ->
    @subscriptions?.dispose()

  watchForTag: ->
    @subscriptions.add @editor.onDidChangeCursorPosition (event) =>
      console.log 'cursor position changed' if @debugEnabled()
      @reset() if @foundTag and @cursorLeftMarker()
      return if @foundTag

      @findTag(event.cursor)

  reset: ->
    console.log 'reset' if @debugEnabled()
    @foundTag = false
    @startMarker.destroy()
    @endMarker.destroy()
    @startMaker = null
    @endMaker = null

  # private

  findTag: (@cursor) ->
    console.log 'watching for tag' if @debugEnabled()
    return if @editor.hasMultipleCursors() or @editorHasSelectedText()
    return unless @cursorInHtmlTag()

    console.log 'in tag' if @debugEnabled()
    return unless @findStartTag()
    # console.log @tagText if @debugEnabled()
    return if @tagShouldBeIgnored()

    @startMarker = @editor.markBufferRange(@startTagRange, {})

    return unless @findEndTag()
    # console.log @endTagRange if @debugEnabled()
    @endMarker = @editor.markBufferRange(@endTagRange, {})
    @foundTag = true

    return unless @foundTag

    @subscriptions.add @startMarker.onDidChange (event) =>
      console.log 'marker changed' if @debugEnabled()
      @copyNewTagToEnd()

  copyNewTagToEnd: ->
    return if @editor.hasMultipleCursors() or @editorHasSelectedText()
    # console.log @startMarker.getBufferRange() if @debugEnabled()
    newTag = @editor.getTextInBufferRange(@startMarker.getBufferRange())
    # remove space after new tag, but allow blank new tag
    origTagLength = newTag.length
    if origTagLength
      matches = newTag.match(/^\w+/)
      return @reset() unless matches
      newTag = matches[0]
    newTagLength = newTag.length
    console.log 'newTag:', "`#{newTag}`" if @debugEnabled()
    @editor.setTextInBufferRange(@endMarker.getBufferRange(), newTag)
    # console.log 'copied' if @debugEnabled()
    # reset if a space was added
    @reset() unless origTagLength != null and newTagLength != null and
                    origTagLength == newTagLength

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
    # console.log tagRegex if @debugEnabled()
    @editor.buffer.scanInRange tagRegex, scanRange, (obj) ->
      if obj.matchText.match(/^<\w/)
        nestedTagCount++
      else
        nestedTagCount--
      if nestedTagCount < 0
        endTagRange = obj.range
        obj.stop()
    return unless endTagRange
    console.log 'found end' if @debugEnabled()
    # don't include <\, >
    @endTagRange = new Range(
      [endTagRange.start.row, endTagRange.start.column + 2],
      [endTagRange.end.row, endTagRange.end.column - 1]
    )
    true

  editorHasSelectedText: ->
    # TODO: add test for "undefined length for null"
    console.log 'here'
    bool = @editor.getSelectedText() || @editor.getSelectedText()?.length > 0
    console.log @editor.getSelectedBufferRange()
    bool

  cursorInHtmlTag: ->
    scopeDescriptor = @cursor?.getScopeDescriptor()
    return unless scopeDescriptor

    scopes = scopeDescriptor.getScopesArray()
    return unless scopes

    scopes[1]?.match(/(meta\.tag|incomplete\.html)/)

  cursorIsInStartTag: ->
    cursorPosition = @cursor.getBufferPosition()
    return unless @startTagRange.containsPoint(cursorPosition)
    true

  cursorLeftMarker: ->
    cursorPosition = @cursor.getBufferPosition()
    !@startMarker.getBufferRange().containsPoint(cursorPosition)

  debugEnabled: -> atom.config.get('double-tag.debug')

  tagShouldBeIgnored: ->
    atom.config.get('double-tag.ignoredTags')?.indexOf(@tagText) >= 0
