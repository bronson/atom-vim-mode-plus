# Refactoring status: 100%
_ = require 'underscore-plus'

class FlashManager
  constructor: (@vimState) ->
    {@editor} = @vimState

  markerOptions = {ivalidate: 'never', persistent: false}
  flash: (range, options) ->
    range = [range] unless _.isArray(range)
    return unless range.length
    markers = (@editor.markBufferRange(r, markerOptions) for r in range)
    decorationOptions = {type: 'highlight', class: options.class}
    for m in markers
      @editor.decorateMarker(m, decorationOptions)
    setTimeout  ->
      m.destroy() for m in markers
    , options.timeout

  destroy: ->
    {@vimState, @editor} = {}

module.exports = FlashManager
