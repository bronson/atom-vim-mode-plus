# Refactoring status: 80%
{getVimState, dispatch} = require './spec-helper'
settings = require '../lib/settings'

describe "Operator ActivateInsertMode family", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, vim) ->
      vimState = state
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = vim

  afterEach ->
    vimState.activate('reset')

  describe "the s keybinding", ->
    beforeEach ->
      set text: '012345', cursor: [0, 1]

    it "deletes the character to the right and enters insert mode", ->
      ensure 's',
        mode: 'insert'
        text: '02345'
        cursor: [0, 1]
        register: '"': text: '1'

    it "is repeatable", ->
      set cursor: [0, 0]
      keystroke '3s'
      editor.insertText 'ab'
      ensure 'escape', text: 'ab345'
      set cursor: [0, 2]
      ensure '.', text: 'abab'

    it "is undoable", ->
      set cursor: [0, 0]
      keystroke '3s'
      editor.insertText 'ab'
      ensure 'escape', text: 'ab345'
      ensure 'u', text: '012345', selectedText: ''

    describe "in visual mode", ->
      beforeEach ->
        keystroke 'vls'

      it "deletes the selected characters and enters insert mode", ->
        ensure
          mode: 'insert'
          text: '0345'
          cursor: [0, 1]
          register: '"': text: '12'

  describe "the S keybinding", ->
    beforeEach ->
      set
        text: "12345\nabcde\nABCDE"
        cursor: [1, 3]

    it "deletes the entire line and enters insert mode", ->
      ensure 'S',
        mode: 'insert'
        text: "12345\n\nABCDE"
        register: {'"': text: 'abcde\n', type: 'linewise'}

    it "is repeatable", ->
      keystroke 'S'
      editor.insertText 'abc'
      ensure 'escape', text: '12345\nabc\nABCDE'
      set cursor: [2, 3]
      ensure '.', text: '12345\nabc\nabc\n'

    it "is undoable", ->
      keystroke 'S'
      editor.insertText 'abc'
      ensure 'escape', text: '12345\nabc\nABCDE'
      ensure 'u', text: "12345\nabcde\nABCDE", selectedText: ''

    # Here is original spec I believe its not correct, if it says 'works'
    # text result should be '\n' since S delete current line.
    # Its orignally added in following commit, as fix of S(from description).
    # But original SubstituteLine replaced with Change and MoveToRelativeLine combo.
    # I believe this spec should have been failed at that time, but havent'.
    # https://github.com/atom/vim-mode/commit/6acffd2559e56f7c18a4d766f0ad92c9ed6212ae
    #
    # it "works when the cursor's goal column is greater than its current column", ->
    #   set text: "\n12345", cursor: [1, Infinity]
    #   ensure 'kS', text: '\n12345'

    it "works when the cursor's goal column is greater than its current column", ->
      set text: "\n12345", cursor: [1, Infinity]
      # Should be here, but I commented out before I have confidence.
      # ensure 'kS', text: '\n'
      # Folowing line include Bug ibelieve.
      ensure 'kS', text: '\n12345'
    # Can't be tested without setting grammar of test buffer
    xit "respects indentation", ->

  describe "the c keybinding", ->
    beforeEach ->
      set text: "12345\nabcde\nABCDE"

    describe "when followed by a c", ->
      describe "with autoindent", ->
        beforeEach ->
          set text: "12345\n  abcde\nABCDE"
          set cursor: [1, 1]
          spyOn(editor, 'shouldAutoIndent').andReturn(true)
          spyOn(editor, 'autoIndentBufferRow').andCallFake (line) ->
            editor.indent()
          spyOn(editor.languageMode, 'suggestedIndentForLineAtBufferRow').andCallFake -> 1

        it "deletes the current line and enters insert mode", ->
          set cursor: [1, 1]
          ensure 'cc',
            text: "12345\n  \nABCDE"
            cursor: [1, 2]
            mode: 'insert'

        it "is repeatable", ->
          keystroke 'cc'
          editor.insertText("abc")
          ensure 'escape', text: "12345\n  abc\nABCDE"
          set cursor: [2, 3]
          ensure '.', text: "12345\n  abc\n  abc\n"

        it "is undoable", ->
          keystroke 'cc'
          editor.insertText("abc")
          ensure 'escape', text: "12345\n  abc\nABCDE"
          ensure 'u', text: "12345\n  abcde\nABCDE", selectedText: ''

      describe "when the cursor is on the last line", ->
        it "deletes the line's content and enters insert mode on the last line", ->
          set cursor: [2, 1]
          ensure 'cc',
            text: "12345\nabcde\n\n"
            cursor: [2, 0]
            mode: 'insert'

      describe "when the cursor is on the only line", ->
        it "deletes the line's content and enters insert mode", ->
          set text: "12345", cursor: [0, 2]
          ensure 'cc',
            text: "\n"
            cursor: [0, 0]
            mode: 'insert'

    describe "when followed by i w", ->
      it "undo's and redo's completely", ->
        set cursor: [1, 1]
        ensure 'ciw',
          text: "12345\n\nABCDE"
          cursor: [1, 0]
          mode: 'insert'

        # Just cannot get "typing" to work correctly in test.
        set text: "12345\nfg\nABCDE"
        ensure 'escape',
          text: "12345\nfg\nABCDE"
          mode: 'normal'
        ensure 'u', text: "12345\nabcde\nABCDE"
        ensure [ctrl: 'r'], text: "12345\nfg\nABCDE"

    describe "when followed by a w", ->
      it "changes the word", ->
        set
          text: "word1 word2 word3"
          cursorBuffer: [0, "word1 w".length]
        ensure ['cw', 'escape'], text: "word1 w word3"

    describe "when followed by a G", ->
      beforeEach ->
        originalText = "12345\nabcde\nABCDE"
        set text: originalText

      describe "on the beginning of the second line", ->
        it "deletes the bottom two lines", ->
          set cursor: [1, 0]
          ensure ['cG', 'escape'], text: '12345\n\n'

      describe "on the middle of the second line", ->
        it "deletes the bottom two lines", ->
          set cursor: [1, 2]
          ensure ['cG', 'escape'], text: '12345\n\n'

    describe "when followed by a goto line G", ->
      beforeEach ->
        set text: "12345\nabcde\nABCDE"

      describe "on the beginning of the second line", ->
        it "deletes all the text on the line", ->
          set cursor: [1, 0]
          ensure ['c2G', 'escape'], text: '12345\n\nABCDE'

      describe "on the middle of the second line", ->
        it "deletes all the text on the line", ->
          set cursor: [1, 2]
          ensure ['c2G', 'escape'], text: '12345\n\nABCDE'

  describe "the C keybinding", ->
    beforeEach ->
      set text: "012\n", cursor: [0, 1]
      keystroke 'C'

    it "deletes the contents until the end of the line and enters insert mode", ->
      ensure
        text: "0\n"
        cursor: [0, 1]
        mode: 'insert'

  describe "the O keybinding", ->
    beforeEach ->
      spyOn(editor, 'shouldAutoIndent').andReturn(true)
      spyOn(editor, 'autoIndentBufferRow').andCallFake (line) ->
        editor.indent()

      set text: "  abc\n  012\n", cursor: [1, 1]

    it "switches to insert and adds a newline above the current one", ->
      keystroke 'O'
      ensure
        text: "  abc\n  \n  012\n"
        cursor: [1, 2]
        mode: 'insert'

    it "is repeatable", ->
      set
        text: "  abc\n  012\n    4spaces\n", cursor: [1, 1]
      keystroke 'O'
      editor.insertText "def"
      ensure 'escape', text: "  abc\n  def\n  012\n    4spaces\n"
      set cursor: [1, 1]
      ensure '.', text: "  abc\n  def\n  def\n  012\n    4spaces\n"
      set cursor: [4, 1]
      ensure '.', text: "  abc\n  def\n  def\n  012\n    def\n    4spaces\n"

    it "is undoable", ->
      keystroke 'O'
      editor.insertText "def"
      ensure 'escape', text: "  abc\n  def\n  012\n"
      ensure 'u', text: "  abc\n  012\n"

  describe "the o keybinding", ->
    beforeEach ->
      spyOn(editor, 'shouldAutoIndent').andReturn(true)
      spyOn(editor, 'autoIndentBufferRow').andCallFake (line) ->
        editor.indent()

      set text: "abc\n  012\n", cursor: [1, 2]

    it "switches to insert and adds a newline above the current one", ->
      ensure 'o',
        text: "abc\n  012\n  \n"
        mode: 'insert'
        cursor: [2, 2]

    # This works in practice, but the editor doesn't respect the indentation
    # rules without a syntax grammar. Need to set the editor's grammar
    # to fix it.
    xit "is repeatable", ->
      set text: "  abc\n  012\n    4spaces\n", cursor: [1, 1]
      keystroke 'o'
      editor.insertText "def"
      ensure 'escape', text: "  abc\n  012\n  def\n    4spaces\n"
      ensure '.', text: "  abc\n  012\n  def\n  def\n    4spaces\n"
      set cursor: [4, 1]
      ensure '.', text: "  abc\n  def\n  def\n  012\n    4spaces\n    def\n"

    it "is undoable", ->
      keystroke 'o'
      editor.insertText "def"
      ensure 'escape', text: "abc\n  012\n  def\n"
      ensure 'u', text: "abc\n  012\n"

  describe "the a keybinding", ->
    beforeEach ->
      set text: "012\n"

    describe "at the beginning of the line", ->
      beforeEach ->
        set cursor: [0, 0]
        keystroke 'a'

      it "switches to insert mode and shifts to the right", ->
        ensure cursor: [0, 1], mode: 'insert'

    describe "at the end of the line", ->
      beforeEach ->
        set cursor: [0, 3]
        keystroke 'a'

      it "doesn't linewrap", ->
        ensure cursor: [0, 3]

  describe "the A keybinding", ->
    beforeEach ->
      set text: "11\n22\n"

    describe "at the beginning of a line", ->
      it "switches to insert mode at the end of the line", ->
        set cursor: [0, 0]
        ensure 'A',
          mode: 'insert'
          cursor: [0, 2]

      it "repeats always as insert at the end of the line", ->
        set cursor: [0, 0]
        keystroke 'A'
        editor.insertText("abc")
        keystroke 'escape'
        set cursor: [1, 0]

        ensure '.',
          text: "11abc\n22abc\n"
          mode: 'normal'
          cursor: [1, 4]

  describe "the I keybinding", ->
    beforeEach ->
      set text: "11\n  22\n"

    describe "at the end of a line", ->
      it "switches to insert mode at the beginning of the line", ->
        set cursor: [0, 2]
        ensure 'I',
          cursor: [0, 0]
          mode: 'insert'

      it "switches to insert mode after leading whitespace", ->
        set cursor: [1, 4]
        ensure 'I',
          cursor: [1, 2]
          mode: 'insert'


      it "repeats always as insert at the first character of the line", ->
        set cursor: [0, 2]
        keystroke 'I'
        editor.insertText("abc")
        ensure 'escape', cursor: [0, 2]
        set cursor: [1, 4]
        ensure '.',
          text: "abc11\n  abc22\n"
          cursor: [1, 4]
          mode: 'normal'

  describe "the i keybinding", ->
    beforeEach ->
      set
        text: '123\n4567'
        cursorBuffer: [[0, 0], [1, 0]]

    it "allows undoing an entire batch of typing", ->
      keystroke 'i'
      editor.insertText("abcXX")
      editor.backspace()
      editor.backspace()
      ensure 'escape', text: "abc123\nabc4567"

      keystroke 'i'
      editor.insertText "d"
      editor.insertText "e"
      editor.insertText "f"
      ensure 'escape', text: "abdefc123\nabdefc4567"
      ensure 'u', text: "abc123\nabc4567"
      ensure 'u', text: "123\n4567"

    it "allows repeating typing", ->
      keystroke 'i'
      editor.insertText("abcXX")
      editor.backspace()
      editor.backspace()
      ensure 'escape', text: "abc123\nabc4567"
      ensure '.',      text: "ababcc123\nababcc4567"
      ensure '.',      text: "abababccc123\nabababccc4567"

    describe 'with nonlinear input', ->
      beforeEach ->
        set text: '', cursorBuffer: [0, 0]

      it 'deals with auto-matched brackets', ->
        keystroke 'i'
        # this sequence simulates what the bracket-matcher package does
        # when the user types (a)b<enter>
        editor.insertText '()'
        editor.moveLeft()
        editor.insertText 'a'
        editor.moveRight()
        editor.insertText 'b\n'
        ensure 'escape', cursor: [1,  0]
        ensure '.',
          text: '(a)b\n(a)b\n'
          cursor: [2,  0]

      it 'deals with autocomplete', ->
        keystroke 'i'
        # this sequence simulates autocompletion of 'add' to 'addFoo'
        editor.insertText 'a'
        editor.insertText 'd'
        editor.insertText 'd'
        editor.setTextInBufferRange [[0, 0], [0, 3]], 'addFoo'
        ensure 'escape',
          cursor: [0,  5]
          text: 'addFoo'
        ensure '.',
          text: 'addFoaddFooo'
          cursor: [0,  10]

  describe 'the a keybinding', ->
    beforeEach ->
      set
        text: ''
        cursorBuffer: [0, 0]

    it "can be undone in one go", ->
      keystroke 'a'
      editor.insertText("abc")
      ensure 'escape', text: "abc"
      ensure 'u', text: ""

    it "repeats correctly", ->
      keystroke 'a'
      editor.insertText("abc")
      ensure 'escape',
        text: "abc"
        cursor: [0, 2]
      ensure '.',
        text: "abcabc"
        cursor: [0, 5]
