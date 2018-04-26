describe "DoubleTag", ->
  [workspaceElement, editor, editorView] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspaceElement)

    waitsForPromise ->
      atom.workspace.open('example.html').then (e) ->
        editor = e
        editorView = atom.views.getView(editor)

    waitsForPromise ->
      atom.packages.activatePackage('language-html')

    waitsForPromise ->
      atom.packages.activatePackage('double-tag')

  describe "for a start tag", ->
    describe "with an inline div tag", ->
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

        describe "and a space is added", ->
          it "doesn't add a space to the end tag", ->
            editor.insertText(' ')

            expect(editor.getText()).toBe '<div >test</div>'

        describe "and a class is added", ->
          it "doesn't add a space to the end tag", ->
            editor.insertText(' ')
            editor.insertText('c')

            expect(editor.getText()).toBe '<div c>test</div>'

        describe "and a space is added instead of a tag", ->
          it "doesn't add a space to the end tag", ->
            editor.backspace() for [1..3]
            editor.insertText(' ')

            expect(editor.getText()).toBe '< >test</>'

        describe "and undo after changing tag", ->
          it "doesn't add a space to the end tag", ->
            editor.insertText('v')
            expect(editor.getText()).toBe '<divv>test</divv>'
            editor.undo()
            expect(editor.getText()).toBe '<div>test</div>'

        describe "and redo after undo after changing tag", ->
          it "changes both tags at the same time", ->
            editor.insertText('v')
            expect(editor.getText()).toBe '<divv>test</divv>'
            editor.undo()
            expect(editor.getText()).toBe '<div>test</div>'
            editor.redo()
            expect(editor.getText()).toBe '<divv>test</divv>'

      describe "when cursor is at the front of a start tag", ->
        beforeEach ->
          editor.setCursorBufferPosition([0, 1])

        describe "and a letter is added", ->
          it "copies the letter to the end tag", ->
            editor.insertText('s')

            expect(editor.getText()).toBe '<sdiv>test</sdiv>'

      describe "when div is an ignored tag", ->
        beforeEach ->
          atom.config.set('double-tag.ignoredTags', ['div'])
          editor.setCursorBufferPosition([0, 4])

        describe "and a letter is added", ->
          it "doesn't copy the letter to the end tag", ->
            editor.insertText('s')

            expect(editor.getText()).toBe '<divs>test</div>'

      describe "when two cursors", ->
        it "doesn't operate", ->
          editor.setCursorBufferPosition([0, 4])
          editor.addCursorAtBufferPosition([0, 6])
          editor.insertText('s')

          expect(editor.getText()).toBe '<divs>tsest</div>'

      describe "when allowEndTagSync is false", ->
        beforeEach ->
          atom.config.set('double-tag.allowEndTagSync', false)
          editor.setCursorBufferPosition([0, 4])

        describe "and a letter is added", ->
          it "still copies the letter to the end tag", ->
            editor.insertText('s')

            expect(editor.getText()).toBe '<divs>test</divs>'

    describe "with an tag with class", ->
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

    describe "with an tag with an extra space", ->
      beforeEach ->
        editor.setText('<div  class="css">test</div>')

      describe "when cursor is a space away from the tag", ->
        beforeEach ->
          editor.setCursorBufferPosition([0, 5])

        describe "and backspaced to the tag", ->
          it "copies the tag text to the end tag", ->
            editor.backspace()
            editor.insertText('v')

            expect(editor.getText()).toBe '<divv class="css">test</divv>'

    describe "with an multiple line div tag", ->
      beforeEach ->
        editor.setText('<div>\n  test\n</div>')
        editor.setCursorBufferPosition([0, 4])

      describe "when tag is changed", ->
        it "copies the new tag to the end", ->
          editor.backspace() for [1..3]
          editor.insertText('h3')

          expect(editor.getText()).toBe '<h3>\n  test\n</h3>'

    describe "with div tag and a nested span", ->
      beforeEach ->
        editor.setText('<div>\n  <span>test</span>\n</div>')

      describe "when outer tag is changed", ->
        beforeEach ->
          editor.setCursorBufferPosition([0, 4])
          editor.backspace() for [1..3]
          editor.insertText('h3')

        it "copies the new tag to the end", ->
          expect(editor.getText()).toBe '<h3>\n  <span>test</span>\n</h3>'

        describe "then inner tag is changed after moving cursor with arrows", ->
          it "copies the new tag to the end", ->
            editor.moveDown()
            editor.moveRight(4)
            editor.backspace() for [1..4]
            editor.insertText('b')

            expect(editor.getText()).toBe '<h3>\n  <b>test</b>\n</h3>'

        describe "then inner tag is changed after moving cusor with mouse", ->
          it "copies the new tag to the end", ->
            editor.setCursorBufferPosition([1, 7])
            editor.backspace() for [1..4]
            editor.insertText('b')

            expect(editor.getText()).toBe '<h3>\n  <b>test</b>\n</h3>'

      describe "when inner start tag is changed", ->
        it "copies the new tag to the end", ->
          editor.setCursorBufferPosition([1, 7])
          editor.backspace() for [1..4]
          editor.insertText('p')

          expect(editor.getText()).toBe '<div>\n  <p>test</p>\n</div>'

    describe "with nested div tags", ->
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

    describe "with dashed tag", ->
      beforeEach ->
        editor.setText('<dashed-div>test</dashed-div>')

      describe "when tag is changed", ->
        it "copies the new tag to the end", ->
          editor.setCursorBufferPosition([0, 11])
          editor.backspace() for [1..4]
          editor.insertText('-span')

          expect(editor.getText()).toBe '<dashed-span>test</dashed-span>'

    describe "with php inside tag", ->
      describe "when cursor added to php", ->
        it "doesn't raise an error", ->
          html = '<foo <?=$ifFoo(\'first\', \'last\')?>></foo>'
          editor.setText(html)

          editor.setCursorBufferPosition([0, 17])

          expect(editor.getText()).toBe html

    describe "with erb inside tag", ->
      describe "when cursor added to erb", ->
        it "doesn't raise an error", ->
          html = '<foo <%=foo(first, last)%>></foo>'
          editor.setText(html)

          editor.setCursorBufferPosition([0, 17])

          expect(editor.getText()).toBe html

    describe "with class on second line", ->
      beforeEach ->
        editor.setText('<foo\n  class="bar">foobar</foo>')

      describe "when letter is removed", ->
        it "removes letter form end tag", ->
          editor.setCursorBufferPosition([0, 4])
          editor.backspace()

          expect(editor.getText()).toBe '<fo\n  class="bar">foobar</fo>'

    describe "with parenthesis after tag", ->
      beforeEach ->
        editor.setText('<foo( class="bar">foobar</foo>')

      describe "when letter is removed", ->
        it "removes letter from end tag", ->
          editor.setCursorBufferPosition([0, 4])
          editor.backspace()

          expect(editor.getText()).toBe '<fo( class="bar">foobar</fo>'

  describe "for a end tag", ->
    describe "when not allowing end tag sync", ->
      beforeEach ->
        atom.config.set('double-tag.allowEndTagSync', false)
        editor.setText('<div>test</div>')

      describe "when cursor is at the back of an end tag", ->
        beforeEach ->
          editor.setCursorBufferPosition([0, 14])

        describe "and a letter is added", ->
          it "doesn't copy the letter to the start tag", ->
            editor.insertText('s')

            expect(editor.getText()).toBe '<div>test</divs>'
    describe "when allowing end tag sync", ->
      beforeEach ->
        atom.config.set('double-tag.allowEndTagSync', true)

      describe "with an inline div tag", ->
        beforeEach ->
          editor.setText('<div>test</div>')

        describe "when cursor is at the back of a end tag", ->
          beforeEach ->
            editor.setCursorBufferPosition([0, 14])

          describe "and a letter is added", ->
            it "copies the letter to the start tag", ->
              editor.insertText('s')

              expect(editor.getText()).toBe '<divs>test</divs>'

          describe "and a letter is removed", ->
            it "removes the letter from the start tag", ->
              editor.backspace()

              expect(editor.getText()).toBe '<di>test</di>'

          describe "and all letters are removed", ->
            it "removes all letters from the start tag", ->
              editor.backspace() for [1..3]

              expect(editor.getText()).toBe '<>test</>'

          describe "and a space is added", ->
            it "doesn't add a space to the start tag", ->
              editor.insertText(' ')

              expect(editor.getText()).toBe '<div>test</div >'

          describe "and a space is added instead of a tag", ->
            it "doesn't add a space to the start tag", ->
              editor.backspace() for [1..3]
              editor.insertText(' ')

              expect(editor.getText()).toBe '<>test</ >'

          describe "and undo after changing tag", ->
            it "doesn't add a space to the end tag", ->
              editor.insertText('v')
              expect(editor.getText()).toBe '<divv>test</divv>'
              editor.undo()
              expect(editor.getText()).toBe '<div>test</div>'

          describe "and redo after undo after changing tag", ->
            it "changes both tags at the same time", ->
              editor.insertText('v')
              expect(editor.getText()).toBe '<divv>test</divv>'
              editor.undo()
              expect(editor.getText()).toBe '<div>test</div>'
              editor.redo()
              expect(editor.getText()).toBe '<divv>test</divv>'

        describe "when cursor is at the front of a end tag", ->
          beforeEach ->
            editor.setCursorBufferPosition([0, 11])

          describe "and a letter is added", ->
            it "copies the letter to the start tag", ->
              editor.insertText('s')

              expect(editor.getText()).toBe '<sdiv>test</sdiv>'

        describe "when div is an ignored tag", ->
          beforeEach ->
            atom.config.set('double-tag.ignoredTags', ['div'])
            editor.setCursorBufferPosition([0, 14])

          describe "and a letter is added", ->
            it "doesn't copy the letter to the start tag", ->
              editor.insertText('s')

              expect(editor.getText()).toBe '<div>test</divs>'

        describe "when two cursors", ->
          it "doesn't operate", ->
            editor.setCursorBufferPosition([0, 14])
            editor.addCursorAtBufferPosition([0, 6])
            editor.insertText('s')

            expect(editor.getText()).toBe '<div>tsest</divs>'

        describe "when allowEndTagSync is false", ->
          beforeEach ->
            atom.config.set('double-tag.allowEndTagSync', false)
            editor.setCursorBufferPosition([0, 14])

          describe "and a letter is added", ->
            it "doesn't copy the letter to the start tag", ->
              editor.insertText('s')

              expect(editor.getText()).toBe '<div>test</divs>'

      describe "with an tag with class", ->
        beforeEach ->
          editor.setText('<div class="css">test</div>')

        describe "when cursor is at the end tag", ->
          beforeEach ->
            editor.setCursorBufferPosition([0, 26])

          describe "and a character added", ->
            it "copies the tag text to the start tag", ->
              editor.insertText('v')

              expect(editor.getText()).toBe '<divv class="css">test</divv>'

          describe "and a tag deleted", ->
            it "deletes start tag", ->
              editor.backspace() for [1..3]

              expect(editor.getText()).toBe '< class="css">test</>'

      describe "with an tag with an extra space", ->
        beforeEach ->
          editor.setText('<div class="css">test</div >')

        describe "when cursor is a space away from the tag", ->
          beforeEach ->
            editor.setCursorBufferPosition([0, 27])

          describe "and backspaced to the tag", ->
            it "copies the tag text to the start tag", ->
              editor.backspace()
              editor.insertText('v')

              expect(editor.getText()).toBe '<divv class="css">test</divv>'

      describe "with an multiple line div tag", ->
        beforeEach ->
          editor.setText('<div>\n  test\n</div>')
          editor.setCursorBufferPosition([2, 5])

        describe "when tag is changed", ->
          it "copies the new tag to the start", ->
            editor.backspace() for [1..3]
            editor.insertText('h3')

            expect(editor.getText()).toBe '<h3>\n  test\n</h3>'

      describe "with div tag and a nested span", ->
        beforeEach ->
          editor.setText('<div>\n  <span>test</span>\n</div>')

        describe "when outer tag is changed", ->
          beforeEach ->
            editor.setCursorBufferPosition([2, 5])
            editor.backspace() for [1..3]
            editor.insertText('h3')

          it "copies the new tag to the start", ->
            expect(editor.getText()).toBe '<h3>\n  <span>test</span>\n</h3>'

          describe "then inner tag is changed after moving cursor with arrows", ->
            it "copies the new tag to the start", ->
              editor.moveUp()
              editor.moveRight(14)
              editor.backspace() for [1..4]
              editor.insertText('b')

              expect(editor.getText()).toBe '<h3>\n  <b>test</b>\n</h3>'

          describe "then inner tag is changed after moving cusor with mouse", ->
            it "copies the new tag to the start", ->
              editor.setCursorBufferPosition([1, 18])
              editor.backspace() for [1..4]
              editor.insertText('b')

              expect(editor.getText()).toBe '<h3>\n  <b>test</b>\n</h3>'

        describe "when inner end tag is changed", ->
          it "copies the new tag to the start", ->
            editor.setCursorBufferPosition([1, 18])
            editor.backspace() for [1..4]
            editor.insertText('p')

            expect(editor.getText()).toBe '<div>\n  <p>test</p>\n</div>'

      describe "with nested div tags", ->
        beforeEach ->
          editor.setText('<div>\n  <div>test</div>\n</div>')

        describe "when outer tag is changed", ->
          it "copies the new tag to the start", ->
            editor.setCursorBufferPosition([2, 5])
            editor.backspace() for [1..3]
            editor.insertText('h3')

            expect(editor.getText()).toBe '<h3>\n  <div>test</div>\n</h3>'

        describe "when inner tag is changed", ->
          it "copies the new tag to the start", ->
            editor.setCursorBufferPosition([1, 16])
            editor.backspace() for [1..3]
            editor.insertText('p')

            expect(editor.getText()).toBe '<div>\n  <p>test</p>\n</div>'

      describe "with dashed tag", ->
        beforeEach ->
          editor.setText('<dashed-div>test</dashed-div>')

        describe "when tag is changed", ->
          it "copies the new tag to the end", ->
            editor.setCursorBufferPosition([0, 28])
            editor.backspace() for [1..4]
            editor.insertText('-span')

            expect(editor.getText()).toBe '<dashed-span>test</dashed-span>'

      describe "with php inside tag", ->
        describe "when cursor added to php", ->
          it "doesn't raise an error", ->
            html = '<foo <?=$ifFoo(\'first\', \'last\')?>></foo>'
            editor.setText(html)

            editor.setCursorBufferPosition([0, 39])

            expect(editor.getText()).toBe html

      describe "with erb inside tag", ->
        describe "when cursor added to erb", ->
          it "doesn't raise an error", ->
            html = '<foo <%=foo(first, last)%>></foo>'
            editor.setText(html)

            editor.setCursorBufferPosition([0, 30])

            expect(editor.getText()).toBe html

      describe "with class on second line", ->
        beforeEach ->
          editor.setText('<foo\n  class="bar">foobar</foo>')

        describe "when letter is removed", ->
          it "removes letter form end tag", ->
            editor.setCursorBufferPosition([1, 25])
            editor.backspace()

            expect(editor.getText()).toBe '<fo\n  class="bar">foobar</fo>'

      describe "with parenthesis after tag", ->
        beforeEach ->
          editor.setText('<foo ( class="bar">foobar</foo>')

        describe "when letter is removed", ->
          it "removes letter from end tag", ->
            editor.setCursorBufferPosition([0, 30])
            editor.backspace()

            expect(editor.getText()).toBe '<fo ( class="bar">foobar</fo>'
