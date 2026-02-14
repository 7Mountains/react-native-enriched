package com.swmansion.enriched.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class OnCheckboxPressEvent(
  surfaceId: Int,
  viewId: Int,
  private val isChecked: Boolean,
  private val experimentalSynchronousEvents: Boolean,
) : Event<OnCheckboxPressEvent>(surfaceId, viewId) {
  override fun getEventName(): String = EVENT_NAME

  override fun getEventData(): WritableMap {
    val eventData: WritableMap = Arguments.createMap()
    eventData.putBoolean("isChecked", isChecked)
    return eventData
  }

  override fun experimental_isSynchronous(): Boolean = experimentalSynchronousEvents

  companion object {
    const val EVENT_NAME: String = "onCheckboxPress"
  }
}
