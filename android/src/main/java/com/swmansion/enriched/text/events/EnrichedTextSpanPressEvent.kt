package com.swmansion.enriched.text.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event
import com.swmansion.enriched.spans.EnrichedLinkSpan
import com.swmansion.enriched.spans.EnrichedMentionSpan

/** A phase of a press on a link or a mention */
enum class SpanPressPhase {
  PRESS_IN,
  PRESS_OUT,
  PRESS,
  LONG_PRESS,
}

/** A press on a link (`url`) or on a mention (`text`, `indicator`, `type`, `attributes`) */
class EnrichedTextSpanPressEvent private constructor(
  surfaceId: Int,
  viewId: Int,
  private val name: String,
  private val data: WritableMap,
) : Event<EnrichedTextSpanPressEvent>(surfaceId, viewId) {
  override fun getEventName(): String = name

  // The phases are separate events, none of them replaces another
  override fun canCoalesce(): Boolean = false

  override fun getEventData(): WritableMap = data

  companion object {
    private val LINK_EVENTS =
      mapOf(
        SpanPressPhase.PRESS_IN to "onLinkPressIn",
        SpanPressPhase.PRESS_OUT to "onLinkPressOut",
        SpanPressPhase.PRESS to "onLinkPress",
        SpanPressPhase.LONG_PRESS to "onLinkLongPress",
      )

    private val MENTION_EVENTS =
      mapOf(
        SpanPressPhase.PRESS_IN to "onMentionPressIn",
        SpanPressPhase.PRESS_OUT to "onMentionPressOut",
        SpanPressPhase.PRESS to "onMentionPress",
        SpanPressPhase.LONG_PRESS to "onMentionLongPress",
      )

    val EVENT_NAMES: List<String> = LINK_EVENTS.values + MENTION_EVENTS.values

    fun forLink(
      surfaceId: Int,
      viewId: Int,
      phase: SpanPressPhase,
      span: EnrichedLinkSpan,
    ): EnrichedTextSpanPressEvent {
      val data = Arguments.createMap()
      data.putString("url", span.getUrl())

      return EnrichedTextSpanPressEvent(surfaceId, viewId, LINK_EVENTS.getValue(phase), data)
    }

    fun forMention(
      surfaceId: Int,
      viewId: Int,
      phase: SpanPressPhase,
      span: EnrichedMentionSpan,
    ): EnrichedTextSpanPressEvent {
      val data = Arguments.createMap()
      data.putString("text", span.getText())
      data.putString("indicator", span.getIndicator())
      data.putString("type", span.getType())

      val attributes = Arguments.createMap()
      span.getAttributes().forEach { (key, value) -> attributes.putString(key, value) }
      data.putMap("attributes", attributes)

      return EnrichedTextSpanPressEvent(surfaceId, viewId, MENTION_EVENTS.getValue(phase), data)
    }
  }
}
