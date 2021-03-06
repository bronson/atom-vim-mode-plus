_ = require 'underscore-plus'

{Disposable, CompositeDisposable} = require 'atom'

Base = require './base'
StatusBarManager = require './status-bar-manager'
globalState = require './global-state'
settings = require './settings'
VimState = require './vim-state'
{Hover, HoverElement} = require './hover'
{Input, InputElement, SearchInput, SearchInputElement} = require './input'

packageScope = 'vim-mode-plus'

module.exports =
  config: settings.config

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @statusBarManager = new StatusBarManager
    @vimStates = new Map

    @registerViewProviders()
    Base.init(@provideVimModePlus())
    @registerCommands()

    if atom.inDevMode()
      developer = (new (require './developer'))
      @subscribe developer.init()

    @subscribe atom.workspace.observeTextEditors (editor) =>
      return if editor.isMini()
      vimState = new VimState(editor, @statusBarManager)
      @vimStates.set(editor, vimState)
      vimState.onDidDestroy =>
        @vimStates.delete(editor)

    @subscribe new Disposable =>
      @vimStates.forEach (vimState) -> vimState.destroy()

  subscribe: (args...) ->
    @subscriptions.add args...

  registerCommands: ->
    # all commands here is executed with context where 'this' binded to 'vimState'
    vimStateCommands =
      'activate-normal-mode': -> @activate('normal')
      'activate-linewise-visual-mode': -> @activate('visual', 'linewise')
      'activate-characterwise-visual-mode': -> @activate('visual', 'characterwise')
      'activate-blockwise-visual-mode': -> @activate('visual', 'blockwise')
      'activate-previous-visual-mode': -> @activate('visual', 'previous')
      'reset-normal-mode': -> @activate('reset')
      'set-count': (e) -> @count.set(e) # 0-9
      'set-register-name': -> @register.setName() # "
      'replace-mode-backspace': -> @modeManager.replaceModeBackspace()

    getState = =>
      @getEditorState(atom.workspace.getActiveTextEditor())

    scope = 'atom-text-editor:not([mini])'
    for name, fn of vimStateCommands
      do (fn) =>
        @addCommand scope, name, (event) ->
          fn.bind(getState())(event)

  addCommand: (scope, name, fn) ->
    @subscribe atom.commands.add scope, "#{packageScope}:#{name}", fn

  registerViewProviders: ->
    addView = atom.views.addViewProvider.bind(atom.views)
    addView Hover, (model) -> new HoverElement().initialize(model)
    addView Input, (model) -> new InputElement().initialize(model)
    addView SearchInput, (model) -> new SearchInputElement().initialize(model)

  deactivate: ->
    @subscriptions.dispose()

  consumeStatusBar: (statusBar) ->
    @statusBarManager.initialize(statusBar)
    @statusBarManager.attach()
    @subscribe new Disposable =>
      @statusBarManager.detach()

  # Service API
  # -------------------------
  getSubscriptions: ->
    @subscriptions

  getGlobalState: ->
    globalState

  getEditorState: (editor) ->
    @vimStates.get(editor)

  provideVimModePlus: ->
    Base: Base
    getSubscriptions: @getSubscriptions.bind(this)
    getGlobalState: @getGlobalState.bind(this)
    getEditorState: @getEditorState.bind(this)
