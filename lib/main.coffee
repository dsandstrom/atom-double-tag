{CompositeDisposable} = require 'atom'
DoubleTag = require './double-tag'

module.exports =
  subscriptions: null
  config:
    ignoredTags:
      description: 'These HTML tags will be skipped'
      type: 'array'
      default: [
        'area', 'base', 'body', 'br', 'col', 'command', 'embed', 'head', 'hr',
        'html', 'img', 'input', 'keygen', 'link', 'meta', 'param', 'source',
        'title', 'track', 'wbr'
      ]
    debug:
      title: 'Enable debug messages in the console'
      type: 'boolean'
      default: false

  activate: (state) ->
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.workspace.observeTextEditors (editor) ->
      editorScope = editor.getRootScopeDescriptor?().getScopesArray()
      return unless editorScope and editorScope.length

      # TODO: make sure language is loaded
      return unless editorScope[0].match(/text\.html/)

      doubleTag = new DoubleTag(editor)
      doubleTag.watchForTag()

      editor.onDidDestroy -> doubleTag?.destroy()

  deactivate: -> @subscriptions?.dispose()
