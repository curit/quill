#= require underscore
#= require rangy/rangy-core
#= require tandem/range

class TandemSelection
  @POLL_INTERVAL: 500


  constructor: (@editor) ->
    @destructors = []
    @range = null
    this.initListeners()

  destroy: ->
    _.each(@destructors, (fn) =>
      fn.call(this)
    )
    @destructors = null

  initListeners: ->
    debouncedUpdate = _.debounce( =>
      return if !@destructors?
      this.update()
    , 100)
    @editor.doc.root.addEventListener('keyup', debouncedUpdate)
    @editor.doc.root.addEventListener('mouseup', debouncedUpdate)
    updateInterval = setInterval(debouncedUpdate, TandemSelection.POLL_INTERVAL)
    @destructors.push( =>
      clearInterval(updateInterval)
      @editor.doc.root.removeEventListener('keyup', debouncedUpdate)
      @editor.doc.root.removeEventListener('mouseup', debouncedUpdate)
    )


  getNative: ->
    rangySel = rangy.getSelection(@editor.contentWindow)
    return null unless rangySel.anchorNode? && rangySel.focusNode?
    if !rangySel.isBackwards()
      [anchorNode, anchorOffset, focusNode, focusOffset] = [rangySel.anchorNode, rangySel.anchorOffset, rangySel.focusNode, rangySel.focusOffset]
    else
      [focusNode, focusOffset, anchorNode, anchorOffset] = [rangySel.anchorNode, rangySel.anchorOffset, rangySel.focusNode, rangySel.focusOffset]
    return {
      anchorNode    : anchorNode
      anchorOffset  : anchorOffset
      focusNode     : focusNode
      focusOffset   : focusOffset
    }

  getRange: ->
    nativeSel = this.getNative()
    return null unless nativeSel?
    start = new Tandem.Position(@editor, nativeSel.anchorNode, nativeSel.anchorOffset)
    end = new Tandem.Position(@editor, nativeSel.focusNode, nativeSel.focusOffset)
    return new Tandem.Range(@editor, start, end)

  preserve: (fn, context = fn) ->
    if @range?
      this.save()
      fn.call(context)
      this.restore()
      this.update()
    else
      fn.call(context)

  removeMarkers: ->
    markers = @editor.doc.root.getElementsByClassName('sel-marker')
    _.each(_.clone(markers), (marker) ->
      marker.parentNode.removeChild(marker)
    )

  restore: ->
    markers = @editor.doc.root.getElementsByClassName('sel-marker')
    startMarker = markers[0]
    endMarker = markers[1]
    if startMarker && endMarker
      startLineNode = @editor.doc.findLineNode(startMarker)
      endLineNode = @editor.doc.findLineNode(endMarker)
      startOffset = Tandem.Position.getIndex(startMarker, 0, startLineNode)
      endOffset = Tandem.Position.getIndex(endMarker, 0, endLineNode)
      this.removeMarkers()
      startLine = @editor.doc.findLine(startLineNode)
      startLine.rebuild()
      if startLineNode != endLineNode
        endLine = @editor.doc.findLine(endLineNode)
        endLine.rebuild()
      range = new Tandem.Range(@editor, new Tandem.Position(@editor, startLineNode, startOffset), new Tandem.Position(@editor, endLineNode, endOffset))
      this.setRange(range)
    else
      # TODO this should never happen...
      console.warn "Not enough markers", startMarker, endMarker, @editor.id
      this.removeMarkers()

  save: ->
    this.removeMarkers()
    selection = this.getRange()
    if selection
      oldIgnoreDomChange = @editor.ignoreDomChanges
      @editor.ignoreDomChanges = true
      startMarker = @editor.doc.root.ownerDocument.createElement('span')
      startMarker.classList.add('sel-marker')
      startMarker.classList.add(Tandem.Constants.SPECIAL_CLASSES.EXTERNAL)
      endMarker = @editor.doc.root.ownerDocument.createElement('span')
      endMarker.classList.add('sel-marker')
      endMarker.classList.add(Tandem.Constants.SPECIAL_CLASSES.EXTERNAL)
      startNode = selection.start.leafNode
      endNode = selection.end.leafNode
      startOffset = selection.start.offset
      endOffset = selection.end.offset
      if selection.start.leafNode == selection.end.leafNode
        endOffset -= startOffset
      if startNode.lastChild?
        if startNode.nodeType == startNode.TEXT_NODE
          startNode.lastChild.splitText(startOffset)
          startNode.insertBefore(startMarker, startNode.lastChild)
        else
          startNode.parentNode.insertBefore(startMarker, startNode)
      else
        console.warn('startOffset is not 0', startOffset) if startOffset != 0
        startNode.parentNode.insertBefore(startMarker, startNode)
      if endNode.lastChild?
        if endNode.nodeType == endNode.TEXT_NODE
          endNode.lastChild.splitText(endOffset)
          endNode.insertBefore(endMarker, endNode.lastChild)
        else
          endNode.parentNode.insertBefore(endMarker, endNode)
      else
        console.warn('endOffset is not 0', endOffset) if endOffset != 0
        endNode.parentNode.insertBefore(endMarker, endNode)
      @editor.ignoreDomChanges = oldIgnoreDomChange

  setRange: (@range) ->
    rangySel = rangy.getSelection(@editor.contentWindow)
    if @range?
      rangySelRange = @range.getRangy()
      rangySel.setSingleRange(rangySelRange)
    else
      rangySel.removeAllRanges()

  update: ->
    range = this.getRange()
    unless (range == @range) || (@range?.equals(range))
      @editor.emit(Tandem.Editor.events.USER_SELECTION_CHANGE, range)
      @range = range



window.Tandem ||= {}
window.Tandem.Selection = TandemSelection
