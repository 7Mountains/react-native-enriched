package com.swmansion.enriched.utils

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.events.OnAlignmentChangeEvent
import com.swmansion.enriched.events.OnChangeStateEvent
import com.swmansion.enriched.events.OnColorChangeEvent
import com.swmansion.enriched.spans.EnrichedSpans
import com.swmansion.enriched.spans.TextStyle

class EnrichedSpanState(
  private val view: EnrichedTextInputView,
) {
  private var previousPayload: WritableMap? = null
  private var previousDispatchedColor: Int? = null
  private var previousDispatchedAlignment: String? = null
  private val styleStarts = mutableMapOf<TextStyle, Int?>()

  var typingColor: Int? = null
    private set
  var paragraphAlignment: String? = null
    private set

  fun setTypingColor(color: Int?) {
    typingColor = color
    emitColorChangeEvent(color)
  }

  fun setColorStart(start: Int?) {
    if (start == null) {
      setColorStart(null, null)
    } else {
      setColorStart(start, typingColor)
    }
  }

  fun setColorStart(
    start: Int?,
    color: Int?,
  ) {
    setStyleStart(TextStyle.COLOR, start)
    setTypingColor(color)
  }

  fun setColorStartWithEventEmitting(
    start: Int?,
    color: Int?,
  ) {
    setColorStart(start, color)
    emitStateChangeEvent()
  }

  fun setAlignment(alignment: String?) {
    paragraphAlignment = alignment
    emitAlignmentChangeEvent(alignment)
  }

  fun setAlignmentStart(start: Int?) {
    if (start == null) {
      setAlignmentStart(null, null)
    } else {
      setAlignmentStart(start, paragraphAlignment)
    }
  }

  fun setAlignmentStart(
    start: Int?,
    alignment: String?,
  ) {
    setStyleStart(TextStyle.ALIGNMENT, start)
    setAlignment(alignment)
  }

  fun getStart(name: TextStyle): Int? = styleStarts[name]

  fun setStart(
    name: TextStyle,
    start: Int?,
  ) {
    when (name) {
      TextStyle.ALIGNMENT -> {
        setAlignmentStart(start)
      }

      TextStyle.COLOR -> {
        setColorStart(start)
      }

      else -> {
        setStyleStart(name, start)
      }
    }
  }

  private fun setStyleStart(
    name: TextStyle,
    start: Int?,
  ) {
    if (start == null) {
      styleStarts.remove(name)
    } else {
      styleStarts[name] = start
    }
  }

  fun setStartWithStateChangeEmitting(
    name: TextStyle,
    start: Int?,
  ) {
    setStart(name, start)
    emitStateChangeEvent()
  }

  private fun emitAlignmentChangeEvent(alignment: String?) {
    val resolvedAlignment = alignment ?: "default"

    if (previousDispatchedAlignment == alignment) return

    previousDispatchedAlignment = alignment

    val context = view.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)

    dispatcher?.dispatchEvent(
      OnAlignmentChangeEvent(
        surfaceId,
        view.id,
        view.experimentalSynchronousEvents,
        resolvedAlignment,
      ),
    )
  }

  private fun emitColorChangeEvent(color: Int?) {
    val resolvedColor = color ?: view.currentTextColor

    if (previousDispatchedColor == resolvedColor) {
      return
    }

    previousDispatchedColor = resolvedColor

    val colorToDispatch = String.format("#%06X", resolvedColor and 0x00FFFFFF)

    val context = view.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)

    dispatcher?.dispatchEvent(
      OnColorChangeEvent(
        surfaceId,
        view.id,
        view.experimentalSynchronousEvents,
        colorToDispatch,
      ),
    )
  }

  fun emitStateChangeEvent() {
    val activeStyles =
      styleStarts
        .filterValues { it != null }
        .keys
        .toList()
    val payload = Arguments.createMap()
    payload.putMap("alignment", getStyleState(activeStyles, TextStyle.ALIGNMENT))
    payload.putMap("bold", getStyleState(activeStyles, TextStyle.BOLD))
    payload.putMap("colored", getStyleState(activeStyles, TextStyle.COLOR))
    payload.putMap("italic", getStyleState(activeStyles, TextStyle.ITALIC))
    payload.putMap("underline", getStyleState(activeStyles, TextStyle.UNDERLINE))
    payload.putMap("strikeThrough", getStyleState(activeStyles, TextStyle.STRIKETHROUGH))
    payload.putMap("inlineCode", getStyleState(activeStyles, TextStyle.INLINE_CODE))
    payload.putMap("h1", getStyleState(activeStyles, TextStyle.H1))
    payload.putMap("h2", getStyleState(activeStyles, TextStyle.H2))
    payload.putMap("h3", getStyleState(activeStyles, TextStyle.H3))
    payload.putMap("h4", getStyleState(activeStyles, TextStyle.H4))
    payload.putMap("h5", getStyleState(activeStyles, TextStyle.H5))
    payload.putMap("h6", getStyleState(activeStyles, TextStyle.H6))
    payload.putMap("codeBlock", getStyleState(activeStyles, TextStyle.CODE_BLOCK))
    payload.putMap("blockQuote", getStyleState(activeStyles, TextStyle.BLOCK_QUOTE))
    payload.putMap("orderedList", getStyleState(activeStyles, TextStyle.ORDERED_LIST))
    payload.putMap("unorderedList", getStyleState(activeStyles, TextStyle.UNORDERED_LIST))
    payload.putMap("link", getStyleState(activeStyles, TextStyle.LINK))
    payload.putMap("image", getStyleState(activeStyles, TextStyle.IMAGE))
    payload.putMap("mention", getStyleState(activeStyles, TextStyle.MENTION))
    payload.putMap("checkList", getStyleState(activeStyles, TextStyle.CHECK_LIST))
    payload.putMap("content", getStyleState(activeStyles, TextStyle.CONTENT))
    payload.putMap("mdf", getStyleState(activeStyles, TextStyle.MDF))

    // Do not emit event if payload is the same
    if (previousPayload == payload) {
      return
    }

    previousPayload =
      Arguments.createMap().apply {
        merge(payload)
      }
    val context = view.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)
    dispatcher?.dispatchEvent(
      OnChangeStateEvent(
        surfaceId,
        view.id,
        payload,
        view.experimentalSynchronousEvents,
      ),
    )
  }

  private fun getStyleState(
    activeStyles: List<TextStyle>,
    type: TextStyle,
  ): WritableMap {
    val mergingConfig = EnrichedSpans.getMergingConfigForStyle(type, view.htmlStyle)
    val blockingList = mergingConfig?.blockingStyles
    val conflictingList = mergingConfig?.conflictingStyles

    val state = Arguments.createMap()

    val isActive = activeStyles.contains(type)
    state.putBoolean("isActive", isActive)

    val isAvailable = EnrichedSpans.isStyleAvailable(type, view.availableStyles)

    val hasBlockingStyles =
      blockingList?.any { activeStyles.contains(it) } ?: false

    state.putBoolean(
      "canNotBeApplied",
      !isAvailable || hasBlockingStyles,
    )

    val isConflicting =
      conflictingList?.any { activeStyles.contains(it) } ?: false

    state.putBoolean("isConflicting", isConflicting)

    return state
  }

  companion object {
    const val NAME = "ReactNativeEnrichedView"
  }
}
