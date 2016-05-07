# sendKey = (key) ->
#   event = atom.keymaps.constructor.buildKeydownEvent(
#     key,
#     {target: document.activeElement}
#   )
#   atom.keymaps.handleKeyboardEvent(event)

describe "DoubleTag", ->
  [workspaceElement, editor, editorView] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)

    jasmine.attachToDOM(workspaceElement)

    waitsForPromise ->
      atom.workspace.open('example.html').then (e) ->
        editor = e
        editorView = atom.views.getView(editor)
        editor.setTabLength(2)

    waitsForPromise ->
      atom.packages.activatePackage('language-html')

    waitsForPromise ->
      atom.packages.activatePackage('double-tag')

  describe "for an html file with an inline div tag", ->
    beforeEach ->
      editor.setText('<div>test</div>')

    describe "when cursor is at the back of a start tag", ->
      beforeEach ->
        editor.setCursorBufferPosition([0, 4])

      describe "and a letter is added", ->
        it "copies the letter to the end tag", ->
          editor.insertText('s')

          expect(editor.getText()).toBe '<divs>test</divs>'

      describe "and a letter is removed", ->
        it "removes the letter from the end tag", ->
          editor.backspace()

          expect(editor.getText()).toBe '<di>test</di>'

      describe "and all letters are removed", ->
        it "removes all letters from the end tag", ->
          editor.backspace() for [1..3]

          expect(editor.getText()).toBe '<>test</>'

    describe "when two cursors", ->
      it "doesn't operate", ->
        editor.setCursorBufferPosition([0, 4])
        editor.addCursorAtBufferPosition([0, 6])
        editor.insertText('s')

        expect(editor.getText()).toBe '<divs>tsest</div>'

      # TODO: clear markers when space added, moved out of tag
      # describe "and a space is added", ->
      #   it "doesn't add a space to the end tag", ->
      #     editor.insertText(' ')
      #
      #     expect(editor.getText()).toBe '<div >test</div>'

  describe "for an html file with an tag with class", ->
    beforeEach ->
      editor.setText('<div class="css">test</div>')

    describe "when cursor is at the start tag", ->
      beforeEach ->
        editor.setCursorBufferPosition([0, 4])

      describe "and a character added", ->
        it "copies the tag text to the end tag", ->
          editor.insertText('v')

          expect(editor.getText()).toBe '<divv class="css">test</divv>'

      describe "and a tag deleted", ->
        it "deletes end tag", ->
          editor.backspace() for [1..3]

          expect(editor.getText()).toBe '< class="css">test</>'

    # describe "when ignoredTags config is set to 'div'", ->
    #   it "doens't add a cursor to the back of the end tag", ->
    #     atom.config.set('double-tag:ignoredTags', 'div')
    #
    #     editor.setCursorBufferPosition([0, 4])
    #
    #     cursors = editor.getCursors()
    #     expect(cursors.length).toBe(1)

  describe "for an html file with an multiple line div tag", ->
    beforeEach ->
      editor.setText('<div>\n  test\n</div>')
      editor.setCursorBufferPosition([0, 4])

    describe "when tag is changed", ->
      it "copies the new tag to the end", ->
        editor.backspace() for [1..3]
        editor.insertText('h3')

        expect(editor.getText()).toBe '<h3>\n  test\n</h3>'

  describe "for an html file with div tag and a nested span", ->
    beforeEach ->
      editor.setText('<div>\n  <span>test</span>\n</div>')

    describe "when outer tag is changed", ->
      it "copies the new tag to the end", ->
        editor.setCursorBufferPosition([0, 4])
        editor.backspace() for [1..3]
        editor.insertText('h3')

        expect(editor.getText()).toBe '<h3>\n  <span>test</span>\n</h3>'

    describe "when inner tag is changed", ->
      it "copies the new tag to the end", ->
        editor.setCursorBufferPosition([1, 7])
        editor.backspace() for [1..4]
        editor.insertText('p')

        expect(editor.getText()).toBe '<div>\n  <p>test</p>\n</div>'

  describe "for an html file with nested div tags", ->
    beforeEach ->
      editor.setText('<div>\n  <div>test</div>\n</div>')

    describe "when outer tag is changed", ->
      it "copies the new tag to the end", ->
        editor.setCursorBufferPosition([0, 4])
        editor.backspace() for [1..3]
        editor.insertText('h3')

        expect(editor.getText()).toBe '<h3>\n  <div>test</div>\n</h3>'

    describe "when inner tag is changed", ->
      it "copies the new tag to the end", ->
        editor.setCursorBufferPosition([1, 6])
        editor.backspace() for [1..3]
        editor.insertText('p')

        expect(editor.getText()).toBe '<div>\n  <p>test</p>\n</div>'
