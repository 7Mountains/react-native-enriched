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

class InlineStyles(
  private val view: EnrichedTextInputView,
) {
  private fun <T : EnrichedSpan> setSpan(
    spannable: Spannable,
    type: Class<T>,
    start: Int,
    end: Int,
    styleName: TextStyle,
  ) {
    val previousSpanStart = (start - 1).coerceAtLeast(0)
    val previousSpanEnd = previousSpanStart + 1
    val nextSpanStart = (end + 1).coerceAtMost(spannable.length)
    val nextSpanEnd = (nextSpanStart + 1).coerceAtMost(spannable.length)
    val previousSpans = spannable.getSpans(previousSpanStart, previousSpanEnd, type)
    val nextSpans = spannable.getSpans(nextSpanStart, nextSpanEnd, type)
    var minimum = start
    var maximum = end

    for (span in previousSpans) {
      val spanStart = spannable.getSpanStart(span)
      minimum = spanStart.coerceAtMost(minimum)
    }

    for (span in nextSpans) {
      val spanEnd = spannable.getSpanEnd(span)
      maximum = spanEnd.coerceAtLeast(maximum)
    }

    val spans = spannable.getSpans(minimum, maximum, type)
    for (span in spans) {
      spannable.removeSpan(span)
    }

    val span = createSpan(styleName)
    val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(minimum, maximum)
    spannable.setSpan(span, safeStart, safeEnd, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
  }

  private fun <T : EnrichedSpan> setAndMergeSpans(
    spannable: Spannable,
    type: Class<T>,
    start: Int,
    end: Int,
    styleName: TextStyle,
  ) {
    val spans = spannable.getSpans(start, end, type)

    // No spans setup for current selection, means we just need to assign new span
    if (spans.isEmpty()) {
      setSpan(spannable, type, start, end, styleName)
      return
    }

    var setSpanOnFinish = false

    // Some spans are present, we have to remove spans and (optionally) apply new spans
    for (span in spans) {
      val spanStart = spannable.getSpanStart(span)
      val spanEnd = spannable.getSpanEnd(span)
      var finalStart: Int? = null
      var finalEnd: Int? = null
      if (spanStart == -1 || spanEnd == -1) continue

      spannable.removeSpan(span)

      if (start == spanStart && end == spanEnd) {
        setSpanOnFinish = false
      } else if (start > spanStart && end < spanEnd) {
        setSpan(spannable, type, spanStart, start, styleName)
        setSpan(spannable, type, end, spanEnd, styleName)
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
        setSpan(spannable, type, finalStart, finalEnd, styleName)
      }
    }

    if (setSpanOnFinish) {
      setSpan(spannable, type, start, end, styleName)
    }
  }

  private fun applyColorSpan(
    spannable: Spannable,
    start: Int,
    end: Int,
    color: Int,
  ) {
    val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(start, end)
    spannable.setSpan(
      EnrichedColoredSpan(color),
      safeStart,
      safeEnd,
      Spannable.SPAN_EXCLUSIVE_EXCLUSIVE,
    )
  }

  private fun splitExistingColorSpans(
    spannable: Spannable,
    start: Int,
    end: Int,
    onRemain: (s: Int, e: Int, color: Int) -> Unit,
  ) {
    val spans = spannable.getSpans(start, end, EnrichedColoredSpan::class.java)
    for (span in spans) {
      val spanStart = spannable.getSpanStart(span)
      val spanEnd = spannable.getSpanEnd(span)
      val color = span.color

      spannable.removeSpan(span)

      if (spanStart < start) {
        onRemain(spanStart, start, color)
      }

      if (spanEnd > end) {
        onRemain(end, spanEnd, color)
      }
    }
  }

  private fun mergeAdjacentColors(spannable: Spannable) {
    val colorSpans =
      spannable
        .getSpans(0, spannable.length, EnrichedColoredSpan::class.java)
        .sortedBy { spannable.getSpanStart(it) }

    var index = 0
    while (index < colorSpans.size - 1) {
      val currentSpan = colorSpans[index]
      val nextSpan = colorSpans[index + 1]

      val currentStart = spannable.getSpanStart(currentSpan)
      val currentEnd = spannable.getSpanEnd(currentSpan)
      val nextStart = spannable.getSpanStart(nextSpan)
      val nextEnd = spannable.getSpanEnd(nextSpan)

      if (currentEnd == nextStart && currentSpan.color == nextSpan.color) {
        spannable.removeSpan(currentSpan)
        spannable.removeSpan(nextSpan)

        applyColorSpan(spannable, currentStart, nextEnd, currentSpan.color)

        return mergeAdjacentColors(spannable)
      }

      index++
    }
  }

  private fun isFullyColoredWith(
    spannable: Spannable,
    start: Int,
    end: Int,
    color: Int,
  ): Boolean {
    val spans = spannable.getSpans(start, end, EnrichedColoredSpan::class.java)
    if (spans.isEmpty()) return false

    val allSame = spans.all { it.color == color }

    if (!allSame) {
      return false
    }

    val minStart = spans.minOf { spannable.getSpanStart(it) }
    val maxEnd = spans.maxOf { spannable.getSpanEnd(it) }

    return minStart <= start && maxEnd >= end
  }

  fun setColorStyle(color: Int) {
    val (start, end) = view.selection?.getInlineSelection() ?: return
    val spannable = view.text as Spannable

    if (start == end) {
      val spanState = view.spanState
      splitSpan(spannable, start, end, EnrichedColoredSpan::class.java)
      if (spanState?.getStart(TextStyle.COLOR) != null && color == spanState.typingColor) {
        view.spanState.setColorStartWithEventEmitting(null, null)
      } else {
        view.spanState?.setColorStartWithEventEmitting(start, color)
      }
      return
    }

    if (isFullyColoredWith(spannable, start, end, color)) {
      removeColorRange(start, end)
      view.spanState?.setColorStart(null, null)
      view.selection.validateStyles()
      return
    }

    splitExistingColorSpans(spannable, start, end) { spanStart, spanEnd, existingColor ->
      applyColorSpan(spannable, spanStart, spanEnd, existingColor)
    }

    applyColorSpan(spannable, start, end, color)

    mergeAdjacentColors(spannable)

    view.spanState?.setColorStart(null, null)
    view.selection.validateStyles()
  }

  private fun removeColorRange(
    start: Int,
    end: Int,
  ) {
    val spannable = view.text as Spannable

    splitExistingColorSpans(spannable, start, end) { spanStart, spanEnd, color ->
      if (spanStart < start) applyColorSpan(spannable, spanStart, start, color)
      if (spanEnd > end) applyColorSpan(spannable, end, spanEnd, color)
    }
  }

  fun removeColorSpan() {
    val (start, end) = view.selection?.getInlineSelection() ?: return

    view.spanState?.setColorStart(null, null)

    if (start == end) {
      val spannable = view.text as Spannable
      splitSpan(spannable, start, end, EnrichedColoredSpan::class.java)
      return
    }

    removeColorRange(start, end)
    view.selection.validateStyles()
  }

  fun afterTextChanged(
    editable: Editable,
    endCursorPosition: Int,
  ) {
    val spanState = view.spanState ?: return
    for ((style, config) in EnrichedSpans.inlineSpans) {
      val start = spanState.getStart(style) ?: continue
      var end = endCursorPosition
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
    mergeAdjacentInlineSpansAt(editable, endCursorPosition)
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
    spannable: Spannable,
    cursor: Int,
  ) {
    val state = view.spanState ?: return
    val colorStart = state.getStart(TextStyle.COLOR) ?: return
    val color = state.typingColor ?: return

    val existing =
      spannable
        .getSpans(colorStart, colorStart, EnrichedColoredSpan::class.java)
        .firstOrNull { it.color == color }

    if (existing != null) {
      val spanStart = spannable.getSpanStart(existing)
      val spanEnd = spannable.getSpanEnd(existing)

      if (cursor > spanEnd) {
        spannable.removeSpan(existing)
        applyColorSpan(spannable, spanStart, cursor, color)
      }

      view.spanState.setColorStart(cursor, color)
      return
    }

    applyColorSpan(spannable, colorStart, cursor, color)
    view.spanState.setColorStart(cursor, color)
  }

  private fun splitSpan(
    spannable: Spannable,
    start: Int,
    end: Int,
    type: Class<out EnrichedSpan>,
  ) {
    val currentSpans = spannable.getSpans(start, end, type)

    for (span in currentSpans) {
      val spanStart = spannable.getSpanStart(span)
      val spanEnd = spannable.getSpanEnd(span)

      spannable.removeSpan(span)

      spannable.setSpan(span.copy(), spanStart, start, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
      spannable.setSpan(span.copy(), end, spanEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
    }
  }

  fun toggleStyle(name: TextStyle) {
    if (view.selection == null) return
    val spanState = view.spanState ?: return
    val (start, end) = view.selection.getInlineSelection()
    val config = EnrichedSpans.inlineSpans[name] ?: return
    val type = config.clazz
    val spannable = view.text as Spannable

    // We either start or end current span
    if (start == end) {
      val styleStart = spanState.getStart(name)
      splitSpan(spannable, start, end, type)
      if (styleStart != null) {
        spanState.setStartWithStateChangeEmitting(name, null)
      } else {
        spanState.setStartWithStateChangeEmitting(name, start)
      }

      return
    }

    setAndMergeSpans(spannable, type, start, end, name)
    view.selection.validateStyles()
  }

  fun removeStyle(
    name: TextStyle,
    start: Int,
    end: Int,
  ): Boolean {
    val config = EnrichedSpans.inlineSpans[name] ?: return false
    val spannable = view.text as Spannable
    val spans = spannable.getSpans(start, end, config.clazz)
    if (spans.isEmpty()) return false

    spans.forEach { it -> spannable.removeSpan(it) }

    view.spanState?.setStart(name, null)

    return true
  }

  fun getStyleRange(): Pair<Int, Int> = view.selection?.getInlineSelection() ?: Pair(0, 0)

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
        val color = view.spanState?.typingColor ?: 0
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
