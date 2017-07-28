{CompositeDisposable, Disposable} = require 'atom'

module.exports = RecursiveFolding =
  subscriptions: null
  listeners: null

  config:
    clickFold:
      title: 'Enable click'
      description: 'Allow to fold block recursively when clicked on fold icon'
      type: 'boolean'
      default: true
      order: 1
    clickCtrl:
      title: 'Ctrl-modifier'
      description: 'Enable click when ctrl pressed'
      type: 'boolean'
      default: true

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @listeners = new CompositeDisposable

    @subscriptions.add(
      atom.commands.add 'atom-workspace', 'recursive-folding:fold': => @fold(),
      atom.commands.add 'atom-workspace', 'recursive-folding:unfold': => @unfold(),
      @listeners
    )

    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      el = editor.element.querySelector('.line-numbers')
      el.addEventListener('mousedown', @_onFoldIconClick)
      @listeners.add new Disposable =>
        el.removeEventListener('click', @_onFoldIconClick)

  deactivate: ->
    @subscriptions.dispose()

  _getIndentAtBufferRow: (row) ->
    @editor.indentLevelForLine(
      @editor.lineTextForBufferRow row
    )

  foldRecursiveFrom: (row) ->
    startPosition = row
    stopPosition = row
    startIndentLevel = @_getIndentAtBufferRow row
    lineCount = @editor.getLineCount()
    row++
    while row < lineCount
      indentLevel = @_getIndentAtBufferRow row
      currentLineText = @editor.lineTextForBufferRow row
      break if indentLevel <= startIndentLevel and currentLineText.length > 0
      stopPosition = row
      row++
    for i in [stopPosition..startPosition]
      if @editor.isFoldableAtBufferRow(i) and not @editor.isFoldedAtBufferRow i
        @editor.foldBufferRow i

  unfoldRecursiveFrom: (row) ->
    startIndentLevel = @_getIndentAtBufferRow row
    lineCount = @editor.getLineCount()
    unless @editor.isFoldableAtBufferRow row
      return
    while row < lineCount - 1
      @editor.unfoldBufferRow row
      row++
      indent = @_getIndentAtBufferRow row
      currentLineText = @editor.lineTextForBufferRow row
      break if indent <= startIndentLevel and currentLineText.length > 0

  fold: ->
    @editor = atom.workspace.getActiveTextEditor()
    @foldRecursiveFrom(@editor.getCursorBufferPosition().row)

  unfold: ->
    @editor = atom.workspace.getActiveTextEditor()
    @unfoldRecursiveFrom(@editor.getCursorBufferPosition().row)
    
  _onFoldIconClick: (event) =>
    if event.target.classList.contains('icon-right')
      event.stopImmediatePropagation()
      clickCtrl = atom.config.get('recursive-folding.clickCtrl')
      return unless clickCtrl is event.ctrlKey
      row = +event.target.parentNode.dataset.bufferRow || 0
      RecursiveFolding.toggle(row)

  toggle: (row) ->
    @editor = atom.workspace.getActiveTextEditor()
    if @editor.isFoldedAtBufferRow row
      @unfoldRecursiveFrom row
    else
      @foldRecursiveFrom row
