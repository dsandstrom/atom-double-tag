{CompositeDisposable} = require 'atom'
DoubleTag = require './double-tag'

module.exports =
  subscriptions: null
  config:
    debug:
      title: 'Enable console log debug messages'
      type: 'boolean'
      default: false

  activate: (state) ->
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.workspace.observeTextEditors (editor) ->
      editorScope = editor.getRootScopeDescriptor?().getScopesArray()
      return unless editorScope and editorScope.length

      # TODO: add option for other scopes
      # TODO: make sure language is loaded
      return unless editorScope[0].match(/text\.html/)

      doubleTag = new DoubleTag(editor)
      doubleTag.watchForTag()

      editor.onDidDestroy -> doubleTag?.destroy()

  deactivate: -> @subscriptions?.dispose()
