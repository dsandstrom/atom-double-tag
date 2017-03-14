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

  activate: (state) ->
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.workspace.observeTextEditors (editor) ->
      editorScope = editor.getRootScopeDescriptor?().getScopesArray()
      return unless editorScope and editorScope.length

      # TODO: add option for language scope
      editorScopeRegex = /text\.(html|xml|marko)|source\.js\.jsx/
      return unless editorScopeRegex.test(editorScope[0])

      doubleTag = new DoubleTag(editor)
      doubleTag.watchForTag()

      editor.onDidDestroy -> doubleTag?.destroy()

  deactivate: -> @subscriptions?.dispose()
