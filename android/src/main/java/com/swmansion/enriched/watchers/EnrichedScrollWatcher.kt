package com.swmansion.enriched.watchers
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.EventDispatcher
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.events.OnScrollEvent

class EnrichedScrollWatcher(
  private val editText: EnrichedTextInputView,
) : ScrollWatcher {
  private val eventDispatcher: EventDispatcher?
  private val surfaceId: Int
  private var previousHorizontal = 0
  private var previousVert = 0

  init {
    val reactContext = UIManagerHelper.getReactContext(editText)
    eventDispatcher = UIManagerHelper.getEventDispatcherForReactTag(reactContext, editText.id)
    surfaceId = UIManagerHelper.getSurfaceId(reactContext)
  }

  override fun onScrollChanged(
    horiz: Int,
    vert: Int,
    oldHoriz: Int,
    oldVert: Int,
  ) {
    if (previousHorizontal != horiz || previousVert != vert) {
      val event =
        OnScrollEvent(
          surfaceId,
          editText.id,
          horiz.toFloat(),
          vert.toFloat(),
          0f, // can't get x velocity
          0f, // can't get y velocity
          0.0f, // can't get content width
          0.0f, // can't get content height
          editText.width.toFloat(),
          editText.height.toFloat(),
          editText.experimentalSynchronousEvents,
        )

      eventDispatcher?.dispatchEvent(event)

      previousHorizontal = horiz
      previousVert = vert
    }
  }
}
