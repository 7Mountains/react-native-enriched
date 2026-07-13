package com.swmansion.enriched.styles

import android.text.Editable
import android.text.Spannable
import android.text.Spanned
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.spans.EnrichedBoldSpan
import com.swmansion.enriched.spans.EnrichedColoredSpan
import com.swmansion.enriched.spans.EnrichedInlineCodeSpan
import com.swmansion.enriched.spans.EnrichedItalicSpan
import com.swmansion.enriched.spans.EnrichedSpans
import com.swmansion.enriched.spans.EnrichedStrikeThroughSpan
import com.swmansion.enriched.spans.EnrichedUnderlineSpan
import com.swmansion.enriched.spans.TextStyle
import com.swmansion.enriched.spans.interfaces.EnrichedInlineSpan
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.utils.areInlineSpansTouchingOrOverlapping
import com.swmansion.enriched.utils.getSafeSpanBoundaries
import com.swmansion.enriched.utils.isTheSameInlineSpan
import com.swmansion.enriched.watchers.TextChangedEvent

class InlineStyles(
  private val view: EnrichedTextInputView,
) {
  private fun <T : EnrichedSpan> setSpan(
    editable: Editable,
    type: Class<T>,
    start: Int,
    end: Int,
    styleName: TextStyle,
  ) {
    val previousSpanStart = (start - 1).coerceAtLeast(0)
    val previousSpanEnd = previousSpanStart + 1
    val nextSpanStart = (end + 1).coerceAtMost(editable.length)
    val nextSpanEnd = (nextSpanStart + 1).coerceAtMost(editable.length)
    val previousSpans = editable.getSpans(previousSpanStart, previousSpanEnd, type)
    val nextSpans = editable.getSpans(nextSpanStart, nextSpanEnd, type)
    var minimum = start
    var maximum = end

    for (span in previousSpans) {
      val spanStart = editable.getSpanStart(span)
      minimum = spanStart.coerceAtMost(minimum)
    }

    for (span in nextSpans) {
      val spanEnd = editable.getSpanEnd(span)
      maximum = spanEnd.coerceAtLeast(maximum)
    }

    val spans = editable.getSpans(minimum, maximum, type)
    for (span in spans) {
      editable.removeSpan(span)
    }

    val span = createSpan(styleName)
    val (safeStart, safeEnd) = editable.getSafeSpanBoundaries(minimum, maximum)
    editable.setSpan(span, safeStart, safeEnd, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
  }

  private fun <T : EnrichedSpan> setAndMergeSpans(
    editable: Editable,
    type: Class<T>,
    start: Int,
    end: Int,
    styleName: TextStyle,
  ) {
    val spans = editable.getSpans(start, end, type)

    // No spans setup for current selection, means we just need to assign new span
    if (spans.isEmpty()) {
      setSpan(editable, type, start, end, styleName)
      return
    }

    var setSpanOnFinish = false

    // Some spans are present, we have to remove spans and (optionally) apply new spans
    for (span in spans) {
      val spanStart = editable.getSpanStart(span)
      val spanEnd = editable.getSpanEnd(span)
      var finalStart: Int? = null
      var finalEnd: Int? = null
      if (spanStart == -1 || spanEnd == -1) continue

      editable.removeSpan(span)

      if (start == spanStart && end == spanEnd) {
        setSpanOnFinish = false
      } else if (start > spanStart && end < spanEnd) {
        setSpan(editable, type, spanStart, start, styleName)
        setSpan(editable, type, end, spanEnd, styleName)
      } else if (start == spanStart && end < spanEnd) {
        finalStart = end
        finalEnd = spanEnd
      } else if (start > spanStart && end == spanEnd) {
        finalStart = spanStart
        finalEnd = start
      } else if (start > spanStart) {
        finalStart = spanStart
        finalEnd = end
      } else if (start < spanStart && end < spanEnd) {
        finalStart = start
        finalEnd = spanEnd
      } else {
        setSpanOnFinish = true
      }

      if (!setSpanOnFinish && finalStart != null && finalEnd != null) {
        setSpan(editable, type, finalStart, finalEnd, styleName)
      }
    }

    if (setSpanOnFinish) {
      setSpan(editable, type, start, end, styleName)
    }
  }

  private fun applyColorSpan(
    editable: Editable,
    start: Int,
    end: Int,
    color: Int,
  ) {
    val (safeStart, safeEnd) = editable.getSafeSpanBoundaries(start, end)
    editable.setSpan(
      EnrichedColoredSpan(color),
      safeStart,
      safeEnd,
      Spannable.SPAN_EXCLUSIVE_EXCLUSIVE,
    )
  }

  private fun splitExistingColorSpans(
    editable: Editable,
    start: Int,
    end: Int,
    onRemain: (s: Int, e: Int, color: Int) -> Unit,
  ) {
    val spans = editable.getSpans(start, end, EnrichedColoredSpan::class.java)
    for (span in spans) {
      val spanStart = editable.getSpanStart(span)
      val spanEnd = editable.getSpanEnd(span)
      val color = span.color

      editable.removeSpan(span)

      if (spanStart < start) {
        onRemain(spanStart, start, color)
      }

      if (spanEnd > end) {
        onRemain(end, spanEnd, color)
      }
    }
  }

  private fun mergeAdjacentColors(editable: Editable) {
    val colorSpans =
      editable
        .getSpans(0, editable.length, EnrichedColoredSpan::class.java)
        .sortedBy { editable.getSpanStart(it) }

    var index = 0
    while (index < colorSpans.size - 1) {
      val currentSpan = colorSpans[index]
      val nextSpan = colorSpans[index + 1]

      val currentStart = editable.getSpanStart(currentSpan)
      val currentEnd = editable.getSpanEnd(currentSpan)
      val nextStart = editable.getSpanStart(nextSpan)
      val nextEnd = editable.getSpanEnd(nextSpan)

      if (currentEnd == nextStart && currentSpan.color == nextSpan.color) {
        editable.removeSpan(currentSpan)
        editable.removeSpan(nextSpan)

        applyColorSpan(editable, currentStart, nextEnd, currentSpan.color)

        return mergeAdjacentColors(editable)
      }

      index++
    }
  }

  private fun isFullyColoredWith(
    editable: Editable,
    start: Int,
    end: Int,
    color: Int,
  ): Boolean {
    val spans = editable.getSpans(start, end, EnrichedColoredSpan::class.java)
    if (spans.isEmpty()) return false

    val allSame = spans.all { it.color == color }

    if (!allSame) {
      return false
    }

    val minStart = spans.minOf { editable.getSpanStart(it) }
    val maxEnd = spans.maxOf { editable.getSpanEnd(it) }

    return minStart <= start && maxEnd >= end
  }

  fun setColorStyle(color: Int) {
    val (start, end) = view.selection.getInlineSelection()
    val editable = view.editableText

    if (start == end) {
      val spanState = view.spanState
      splitSpan(editable, start, end, EnrichedColoredSpan::class.java)
      if (spanState.getStart(TextStyle.COLOR) != null && color == spanState.typingColor) {
        view.spanState.setColorStartWithEventEmitting(null, null)
      } else {
        view.spanState.setColorStartWithEventEmitting(start, color)
      }
      return
    }

    if (isFullyColoredWith(editable, start, end, color)) {
      removeColorRange(start, end)
      view.spanState.setColorStart(null, null)
      view.selection.validateStyles()
      return
    }

    splitExistingColorSpans(editable, start, end) { spanStart, spanEnd, existingColor ->
      applyColorSpan(editable, spanStart, spanEnd, existingColor)
    }

    applyColorSpan(editable, start, end, color)

    mergeAdjacentColors(editable)

    view.spanState.setColorStart(null, null)
    view.selection.validateStyles()
  }

  private fun removeColorRange(
    start: Int,
    end: Int,
  ) {
    val editable = view.editableText

    splitExistingColorSpans(editable, start, end) { spanStart, spanEnd, color ->
      if (spanStart < start) applyColorSpan(editable, spanStart, start, color)
      if (spanEnd > end) applyColorSpan(editable, end, spanEnd, color)
    }
  }

  fun removeColorSpan() {
    val (start, end) = view.selection.getInlineSelection()

    view.spanState.setColorStart(null, null)

    if (start == end) {
      val editable = view.editableText
      splitSpan(editable, start, end, EnrichedColoredSpan::class.java)
      return
    }

    removeColorRange(start, end)
    view.selection.validateStyles()
  }

  fun afterTextChanged(event: TextChangedEvent) {
    handleExtendingSpans(event)
    mergeAdjacentInlineSpansAt(event.text, event.endCursorPosition)
  }

  private fun handleExtendingSpans(event: TextChangedEvent) {
    if (event.isBackspace) return
    val editable = event.text
    val spanState = view.spanState
    for ((style, config) in EnrichedSpans.inlineSpans) {
      val start = spanState.getStart(style) ?: continue
      var end = event.endCursorPosition
      if (style == TextStyle.COLOR) {
        applyTypingColorIfActive(editable, end)
        continue
      }
      val spans = editable.getSpans(start, end, config.clazz)

      for (span in spans) {
        end = editable.getSpanEnd(span).coerceAtLeast(end)
        editable.removeSpan(span)
      }

      setSpan(editable, config.clazz, start, end, style)
    }
  }

  private fun mergeAdjacentInlineSpansAt(
    editable: Editable,
    position: Int,
  ) {
    if (editable.isEmpty()) return

    val safePosition = position.coerceIn(0, editable.length)

    val inlineSpans =
      editable
        .getSpans(safePosition, safePosition, EnrichedInlineSpan::class.java)
        .filter { span ->
          val start = editable.getSpanStart(span)
          val end = editable.getSpanEnd(span)

          start >= 0 && end >= 0 && start < end
        }.sortedWith(
          compareBy<EnrichedInlineSpan> { it::class.java.name }
            .thenBy { editable.getSpanStart(it) }
            .thenBy { editable.getSpanEnd(it) },
        )

    if (inlineSpans.size < 2) return

    var index = 0
    while (index < inlineSpans.size - 1) {
      val current = inlineSpans[index]
      val next = inlineSpans[index + 1]

      if (isTheSameInlineSpan(current, next) && editable.areInlineSpansTouchingOrOverlapping(current, next)) {
        mergeInlineSpans(editable, current, next)
        return mergeAdjacentInlineSpansAt(editable, safePosition)
      }

      index++
    }
  }

  private fun mergeInlineSpans(
    editable: Editable,
    first: EnrichedInlineSpan,
    second: EnrichedInlineSpan,
  ) {
    val firstStart = editable.getSpanStart(first)
    val firstEnd = editable.getSpanEnd(first)
    val secondStart = editable.getSpanStart(second)
    val secondEnd = editable.getSpanEnd(second)

    if (firstStart < 0 || firstEnd < 0 || secondStart < 0 || secondEnd < 0) {
      return
    }

    val mergedStart = minOf(firstStart, secondStart)
    val mergedEnd = maxOf(firstEnd, secondEnd)
    val flags = editable.getSpanFlags(first)

    editable.removeSpan(first)
    editable.removeSpan(second)

    val mergedSpan = first.copy()

    editable.setSpan(
      mergedSpan,
      mergedStart,
      mergedEnd,
      flags,
    )
  }

  private fun applyTypingColorIfActive(
    editable: Editable,
    cursor: Int,
  ) {
    val state = view.spanState
    val colorStart = state.getStart(TextStyle.COLOR) ?: return
    val color = state.typingColor ?: return

    val existing =
      editable
        .getSpans(colorStart, colorStart, EnrichedColoredSpan::class.java)
        .firstOrNull { it.color == color }

    if (existing != null) {
      val spanStart = editable.getSpanStart(existing)
      val spanEnd = editable.getSpanEnd(existing)

      if (cursor > spanEnd) {
        editable.removeSpan(existing)
        applyColorSpan(editable, spanStart, cursor, color)
      }

      view.spanState.setColorStart(cursor, color)
      return
    }

    applyColorSpan(editable, colorStart, cursor, color)
    view.spanState.setColorStart(cursor, color)
  }

  private fun splitSpan(
    editable: Editable,
    start: Int,
    end: Int,
    type: Class<out EnrichedSpan>,
  ) {
    val currentSpans = editable.getSpans(start, end, type)

    for (span in currentSpans) {
      val spanStart = editable.getSpanStart(span)
      val spanEnd = editable.getSpanEnd(span)

      editable.removeSpan(span)

      editable.setSpan(span.copy(), spanStart, start, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
      editable.setSpan(span.copy(), end, spanEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
    }
  }

  fun toggleStyle(name: TextStyle) {
    val spanState = view.spanState
    val (start, end) = view.selection.getInlineSelection()
    val config = EnrichedSpans.inlineSpans[name] ?: return
    val type = config.clazz
    val editable = view.editableText

    // We either start or end current span
    if (start == end) {
      val styleStart = spanState.getStart(name)
      splitSpan(editable, start, end, type)
      if (styleStart != null) {
        spanState.setStartWithStateChangeEmitting(name, null)
      } else {
        spanState.setStartWithStateChangeEmitting(name, start)
      }

      return
    }

    setAndMergeSpans(editable, type, start, end, name)
    view.selection.validateStyles()
  }

  fun removeStyle(
    name: TextStyle,
    start: Int,
    end: Int,
  ): Boolean {
    val config = EnrichedSpans.inlineSpans[name] ?: return false
    val editable = view.editableText
    val spans = editable.getSpans(start, end, config.clazz)
    if (spans.isEmpty()) return false

    spans.forEach { it -> editable.removeSpan(it) }

    view.spanState.setStart(name, null)

    return true
  }

  fun getStyleRange(): Pair<Int, Int> = view.selection.getInlineSelection()

  private fun createSpan(name: TextStyle): EnrichedInlineSpan? =
    when (name) {
      TextStyle.BOLD -> {
        EnrichedBoldSpan()
      }

      TextStyle.ITALIC -> {
        EnrichedItalicSpan()
      }

      TextStyle.UNDERLINE -> {
        EnrichedUnderlineSpan()
      }

      TextStyle.STRIKETHROUGH -> {
        EnrichedStrikeThroughSpan()
      }

      TextStyle.COLOR -> {
        val color = view.spanState.typingColor ?: 0
        EnrichedColoredSpan(color)
      }

      TextStyle.INLINE_CODE -> {
        EnrichedInlineCodeSpan(view.htmlStyle)
      }

      // fallback
      else -> {
        null
      }
    }
}
