package com.swmansion.enriched.watchers

interface ScrollWatcher {
  fun onScrollChanged(
    horiz: Int,
    vert: Int,
    oldHoriz: Int,
    oldVert: Int,
  ): Unit
}
