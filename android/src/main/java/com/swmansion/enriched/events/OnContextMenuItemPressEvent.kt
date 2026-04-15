package com.swmansion.enriched.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class OnContextMenuItemPressEvent(
  surfaceId: Int,
  viewId: Int,
  private val text: String,
  private val key: String,
  private val selectionStart: Int,
  private val selectionEnd: Int,
  private val experimentalSynchronousEvents: Boolean,
) : Event<OnContextMenuItemPressEvent>(surfaceId, viewId) {
  override fun getEventName(): String = EVENT_NAME

  override fun getEventData(): WritableMap {
    val eventData: WritableMap = Arguments.createMap()
    eventData.putString("text", text)
    eventData.putString("key", key)
    val selection = Arguments.createMap()
    selection.putInt("start", selectionStart)
    selection.putInt("end", selectionEnd)
    eventData.putMap("selection", selection)
    return eventData
  }

  override fun experimental_isSynchronous(): Boolean = experimentalSynchronousEvents

  companion object {
    const val EVENT_NAME: String = "onContextMenuItemPress"
  }
}
