package com.swmansion.enriched.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.buildReadableMap
import com.facebook.react.uimanager.PixelUtil.toDIPFromPixel
import com.facebook.react.uimanager.events.Event

class OnScrollEvent(
  surfaceId: Int,
  viewId: Int,
  private val scrollX: Float,
  private val scrollY: Float,
  private val xVelocity: Float,
  private val yVelocity: Float,
  private val contentWidth: Float,
  private val contentHeight: Float,
  private val scrollViewWidth: Float,
  private val scrollViewHeight: Float,
  private val experimentalSynchronousEvents: Boolean,
) : Event<OnScrollEvent>(surfaceId, viewId) {
  override fun getEventName(): String = EVENT_NAME

  override fun getEventData(): WritableMap {
    val contentInset =
      buildReadableMap {
        put("top", 0.0)
        put("bottom", 0.0)
        put("left", 0.0)
        put("right", 0.0)
      }

    val contentOffset =
      buildReadableMap {
        put("x", toDIPFromPixel(scrollX).toDouble())
        put("y", toDIPFromPixel(scrollY).toDouble())
      }

    val contentSize =
      buildReadableMap {
        put("width", toDIPFromPixel(contentWidth).toDouble())
        put("height", toDIPFromPixel(contentHeight).toDouble())
      }

    val layoutMeasurement =
      buildReadableMap {
        put("width", toDIPFromPixel(scrollViewWidth).toDouble())
        put("height", toDIPFromPixel(scrollViewHeight).toDouble())
      }

    val velocity =
      buildReadableMap {
        put("x", toDIPFromPixel(xVelocity).toDouble())
        put("y", toDIPFromPixel(yVelocity).toDouble())
      }

    val event = Arguments.createMap()
    event.putMap("contentInset", contentInset)
    event.putMap("contentOffset", contentOffset)
    event.putMap("contentSize", contentSize)
    event.putMap("layoutMeasurement", layoutMeasurement)
    event.putMap("velocity", velocity)
    event.putInt("target", viewTag)
    return event
  }

  override fun experimental_isSynchronous(): Boolean = experimentalSynchronousEvents

  companion object {
    const val EVENT_NAME: String = "onInputScroll"
    const val TOP_EVENT_NAME = "topOnInputScroll"
  }
}
