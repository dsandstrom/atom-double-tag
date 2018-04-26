{CompositeDisposable} = require 'atom'
DoubleTag = require './double-tag'

module.exports =
  subscriptions: null
  config:
    enabledScopes:
      description: 'Language scopes that are active'
      type: 'array'
      default: [
        'text.html', 'text.html.basic', 'text.xml', 'text.marko',
        'source.js.jsx', 'source.tsx', 'text.html.erb', 'text.html.php'
      ]
    ignoredTags:
      description: 'These HTML tags will be skipped'
      type: 'array'
      default: [
        'area', 'base', 'body', 'br', 'col', 'command', 'embed', 'head', 'hr',
        'html', 'img', 'input', 'keygen', 'link', 'meta', 'param', 'source',
        'title', 'track', 'wbr'
      ]
    allowEndTagSync:
      description: 'Editing the end tag will change the start tag'
      type: 'boolean'
      default: false

  activate: (state) ->
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.workspace.observeTextEditors (editor) ->
      editorScope = editor.getRootScopeDescriptor?().getScopesArray()
      return unless editorScope?.length

      return unless atom.config.get('double-tag.enabledScopes').includes(editorScope[0])

      doubleTag = new DoubleTag(editor)
      editor.onDidDestroy -> doubleTag?.destroy()

  deactivate: -> @subscriptions?.dispose()
