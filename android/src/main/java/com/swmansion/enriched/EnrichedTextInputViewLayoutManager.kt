package com.swmansion.enriched

import com.facebook.react.bridge.Arguments
import com.facebook.react.uimanager.PixelUtil

class EnrichedTextInputViewLayoutManager(
  private val view: EnrichedTextInputView,
) {
  private var lastHeight = -1

  fun invalidateLayoutIfNeeded() {
    val layout = view.layout ?: return
    val height = layout.height

    if (height == lastHeight) return
    lastHeight = height

    val state = Arguments.createMap()
    state.putInt("height", PixelUtil.toDIPFromPixel(layout.height.toFloat()).toInt())
    view.stateWrapper?.updateState(state)
  }

  fun release() {
    lastHeight = -1
  }
}
