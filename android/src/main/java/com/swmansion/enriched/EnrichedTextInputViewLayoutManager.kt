package com.swmansion.enriched

import com.facebook.react.bridge.Arguments

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
    state.putInt("height", height)
    view.stateWrapper?.updateState(state)
  }

  fun release() {
    lastHeight = -1
  }
}
