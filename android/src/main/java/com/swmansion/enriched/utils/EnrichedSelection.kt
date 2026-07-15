package com.swmansion.enriched.utils

import android.text.Editable
import android.text.Layout
import android.text.Spannable
import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.constants.Strings
import com.swmansion.enriched.events.OnChangeSelectionEvent
import com.swmansion.enriched.events.OnLinkDetectedEvent
import com.swmansion.enriched.events.OnMentionDetectedEvent
import com.swmansion.enriched.spans.EnrichedAlignmentSpan
import com.swmansion.enriched.spans.EnrichedColoredSpan
import com.swmansion.enriched.spans.EnrichedLinkSpan
import com.swmansion.enriched.spans.EnrichedMentionSpan
import com.swmansion.enriched.spans.EnrichedSpans
import com.swmansion.enriched.spans.interfaces.EnrichedInlineSpan
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import org.json.JSONObject

class EnrichedSelection(
  private val view: EnrichedTextInputView,
) {
  var start: Int = 0
  var end: Int = 0
  var prevTextVersion: Int? = null

  val inlineStylesList =
    EnrichedSpans.inlineSpans.map { (type, config) -> type to config } +
      EnrichedSpans.parametrizedStyles.map { (type, config) -> type to config }

  private var previousLinkDetectedEvent: MutableMap<String, String> = mutableMapOf("text" to "", "url" to "")
  private var previousMentionDetectedEvent: MutableMap<String, String> = mutableMapOf("text" to "", "payload" to "")

  fun onSelection(
    selStart: Int,
    selEnd: Int,
  ) {
    var shouldValidateStyles = false
    var newStart = start
    var newEnd = end

    if (selStart != -1 && selStart != newStart) {
      newStart = selStart
      shouldValidateStyles = true
    }

    if (selEnd != -1 && selEnd != newEnd) {
      newEnd = selEnd
      shouldValidateStyles = true
    }

    if (prevTextVersion != view.textVersion) {
      shouldValidateStyles = true
      prevTextVersion = view.textVersion
    }

    val textLength = view.text?.length ?: 0
    val finalStart = newStart.coerceAtMost(newEnd).coerceAtLeast(0).coerceAtMost(textLength)
    val finalEnd = newEnd.coerceAtLeast(newStart).coerceAtLeast(0).coerceAtMost(textLength)

    if (isZeroWidthSelection(finalStart, finalEnd) && !view.isDuringTransaction) {
      view.setSelection(finalStart + 1)
      shouldValidateStyles = false
    }

    if (!shouldValidateStyles) return

    start = finalStart
    end = finalEnd
    validateStyles()
    val (paragraphStart, paragraphEnd) = getParagraphSelection()
    emitSelectionChangeEvent(view.text, finalStart, finalEnd, paragraphStart, paragraphEnd)
  }

  private fun isZeroWidthSelection(
    start: Int,
    end: Int,
  ): Boolean {
    val text = view.text ?: return false
    if (start !in 0..text.length || end !in start..text.length) return false

    if (start != end) {
      return end - start == 1 && text[start] == Strings.ZERO_WIDTH_SPACE_CHAR
    }

    val isNewLine = start == 0 || text[start - 1] == Strings.NEWLINE
    val isNextCharacterZeroWidth =
      start < text.length && text[start] == Strings.ZERO_WIDTH_SPACE_CHAR

    return isNewLine && isNextCharacterZeroWidth
  }

  fun validateStyles() {
    val state = view.spanState

    // We don't validate inline styles when removing many characters at once
    // We don't want to remove styles on auto-correction
    // If user removes many characters at once, we want to keep the styles config
    if (!view.isRemovingMany) {
      handleInlineStyleState()
    } else {
      view.isRemovingMany = false
    }

    val paragraphSelection = getParagraphSelection()

    handleParagraphStyleState(paragraphSelection)

    for ((style, config) in EnrichedSpans.listSpans) {
      state.setStart(style, getCoveredParagraphStyleStart(config.clazz, paragraphSelection))
    }

    state.emitStateChangeEvent()
  }

  fun getInlineSelection(): Pair<Int, Int> {
    val finalStart = start.coerceAtMost(end).coerceAtLeast(0)
    val finalEnd = end.coerceAtLeast(start).coerceAtLeast(0)

    return Pair(finalStart, finalEnd)
  }

  private fun handleInlineStyleState() {
    val spanState = view.spanState
    val (start, end) = getInlineSelection()
    val editable = view.editableText

    val spans = editable.getSpans(start, end, EnrichedInlineSpan::class.java)

    if (spans.isEmpty()) {
      inlineStylesList.forEach { (type, _) ->
        spanState.setStart(type, null)
      }
      emitLinkDetectedEvent(editable, null, start, end)
      emitMentionDetectedEvent(editable, null, start, end)
      return
    }

    for ((type, config) in inlineStylesList) {
      val span =
        if (config.clazz == EnrichedColoredSpan::class.java) {
          spans
            .filterIsInstance<EnrichedColoredSpan>()
            .minByOrNull { editable.getSpanStart(it) }
        } else {
          spans.firstOrNull { it.javaClass == config.clazz }
        }

      val isSingleSelection = start == end

      span?.let {
        val spanStart = editable.getSpanStart(it)
        val spanEnd = editable.getSpanEnd(it)

        val isSpanInSelection = if (isSingleSelection) start <= spanStart || end > spanEnd else start < spanStart || end > spanEnd

        if (isSpanInSelection) {
          spanState.setStart(type, null)
          return@let
        }

        when (it) {
          is EnrichedLinkSpan -> {
            emitLinkDetectedEvent(editable, it, spanStart, spanEnd)
          }

          is EnrichedMentionSpan -> {
            emitMentionDetectedEvent(editable, it, spanStart, spanEnd)
          }

          is EnrichedColoredSpan -> {
            spanState.setColorStart(spanStart, it.color)
            return@let
          }
        }

        spanState.setStart(type, spanStart)
      } ?: spanState.setStart(type, null)
    }
  }

  fun getParagraphSelection(): Pair<Int, Int> {
    val (currentStart, currentEnd) = getInlineSelection()
    return view.editableText.getParagraphBounds(currentStart, currentEnd)
  }

  private fun getParagraphStyleStart(
    clazz: Class<out EnrichedSpan>,
    paragraphSelection: Pair<Int, Int>,
  ): Int? =
    if (clazz == EnrichedAlignmentSpan::class.java) {
      getAlignmentStyleStart(paragraphSelection)
    } else {
      getCoveredParagraphStyleStart(clazz, paragraphSelection)
    }

  private fun getAlignmentStyleStart(paragraphSelection: Pair<Int, Int>): Int? {
    var alignment: Layout.Alignment? = null
    val styleStart =
      getCoveredParagraphStyleStart(EnrichedAlignmentSpan::class.java, paragraphSelection) { span ->
        if (alignment != null && alignment != span.alignment) {
          return@getCoveredParagraphStyleStart false
        }

        alignment = span.alignment
        true
      }

    view.spanState.setAlignment(alignment?.toStringName())
    return styleStart
  }

  private fun handleParagraphStyleState(paragraphSelection: Pair<Int, Int>) {
    val spanState = view.spanState

    for ((style, config) in EnrichedSpans.paragraphSpans) {
      spanState.setStart(style, getParagraphStyleStart(config.clazz, paragraphSelection))
    }
  }

  private fun <T> getCoveredParagraphStyleStart(
    type: Class<T>,
    paragraphSelection: Pair<Int, Int>,
    onCoveredSpan: (T) -> Boolean = { true },
  ): Int? {
    val (start, end) = paragraphSelection
    val spannable = view.editableText
    var styleStart: Int? = null

    var paragraphStart = start
    val paragraphs = spannable.getParagraphsBounds(start, end)
    for (paragraph in paragraphs) {
      val paragraphEnd = paragraph.endInclusive
      val span =
        spannable
          .getSpans(paragraphStart, paragraphEnd, type)
          .firstOrNull {
            spannable.getSpanStart(it) == paragraphStart &&
              spannable.getSpanEnd(it) >= paragraphEnd
          } ?: return null

      if (!onCoveredSpan(span)) {
        return null
      }

      styleStart = spannable.getSpanStart(span)
      paragraphStart = paragraphEnd + 1
    }

    return styleStart
  }

  private fun emitSelectionChangeEvent(
    editable: Editable?,
    start: Int,
    end: Int,
    paragraphStart: Int,
    paragraphEnd: Int,
  ) {
    if (editable == null) return

    val context = view.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)

    val text = editable.substring(start, end)
    dispatcher?.dispatchEvent(
      OnChangeSelectionEvent(
        surfaceId,
        view.id,
        text,
        start,
        end,
        paragraphStart,
        paragraphEnd,
        view.experimentalSynchronousEvents,
      ),
    )
  }

  private fun emitLinkDetectedEvent(
    spannable: Spannable,
    span: EnrichedLinkSpan?,
    start: Int,
    end: Int,
  ) {
    val text = spannable.substring(start, end)
    val url = span?.getUrl() ?: ""

    // Prevents emitting unnecessary events
    if (text == previousLinkDetectedEvent["text"] && url == previousLinkDetectedEvent["url"]) return

    previousLinkDetectedEvent.put("text", text)
    previousLinkDetectedEvent.put("url", url)

    val context = view.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)
    dispatcher?.dispatchEvent(
      OnLinkDetectedEvent(
        surfaceId,
        view.id,
        text,
        url,
        start,
        end,
        view.experimentalSynchronousEvents,
      ),
    )
  }

  private fun emitMentionDetectedEvent(
    spannable: Spannable,
    span: EnrichedMentionSpan?,
    start: Int,
    end: Int,
  ) {
    val text = spannable.substring(start, end)
    val attributes = span?.getAttributes() ?: emptyMap()
    val indicator = span?.getIndicator() ?: ""
    val payload = JSONObject(attributes).toString()

    val previousText = previousMentionDetectedEvent["text"] ?: ""
    val previousPayload = previousMentionDetectedEvent["payload"] ?: ""
    val previousIndicator = previousMentionDetectedEvent["indicator"] ?: ""

    if (text == previousText && payload == previousPayload && indicator == previousIndicator) return

    previousMentionDetectedEvent.put("text", text)
    previousMentionDetectedEvent.put("payload", payload)
    previousMentionDetectedEvent.put("indicator", indicator)

    val context = view.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)
    dispatcher?.dispatchEvent(
      OnMentionDetectedEvent(
        surfaceId,
        view.id,
        text,
        indicator,
        payload,
        view.experimentalSynchronousEvents,
      ),
    )
  }
}
