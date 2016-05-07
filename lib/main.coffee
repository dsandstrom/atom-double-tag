{CompositeDisposable} = require 'atom'
DoubleTag = require './double-tag'

module.exports =
  subscriptions: null

  activate: (state) ->
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.workspace.observeTextEditors (editor) ->
      editorSubscriptions = new CompositeDisposable

      editorScope = editor.getRootScopeDescriptor?().getScopesArray()
      return unless editorScope and editorScope.length

      # TODO: add option for other scopes
      # TODO: make sure language is loaded
      return unless editorScope[0].match(/text\.html/)

      doubleTag = new DoubleTag(editor)

      # @doubleTag.watchForTag()
      editorSubscriptions.add editor.onDidChangeCursorPosition (event) ->
        return if doubleTag.foundTag
        doubleTag.watchForTag(event)

      # TODO: use onDidStopChanging
      # editorSubscriptions.add editor.onDidStopChanging (tagEvent) ->
      # editorSubscriptions.add editor.onDidChange (tagEvent) ->
      #   return unless doubleTag.foundTag
      #
      #   doubleTag.copyNewTagToEnd()
      #   console.log 'copied'
      #   # doubleTag.reset()

      editor.onDidDestroy ->
        # TODO: maybe destroy @doubleTag
        doubleTag.destroy()
        editorSubscriptions?.dispose()
        # cursorSubscriptions?.dispose()

  deactivate: ->
    @subscriptions?.dispose()
