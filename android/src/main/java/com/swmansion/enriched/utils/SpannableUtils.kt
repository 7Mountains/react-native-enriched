package com.swmansion.enriched.utils

import android.text.Spannable
import com.swmansion.enriched.spans.interfaces.EnrichedParagraphSpan
import com.swmansion.enriched.spans.interfaces.EnrichedSpan

fun Spannable.getListRange(
  paragraphStart: Int,
  paragraphEnd: Int,
  span: EnrichedParagraphSpan,
): Pair<Int, Int> {
  var start = paragraphStart
  var end = paragraphEnd

  val spanType = span::class.java

  if (getSpans(paragraphStart, paragraphEnd, spanType).isEmpty()) {
    return paragraphStart to paragraphEnd
  }

  // up
  var prevCursor = (start - 1).coerceAtLeast(0)
  while (prevCursor >= 0) {
    val (pStart, pEnd) = getParagraphBounds(prevCursor)

    if (getSpans(pStart, pEnd, spanType).isEmpty()) break

    start = pStart

    val nextPrev = pStart - 1
    if (nextPrev < 0) break
    prevCursor = nextPrev
  }

  // down
  var nextCursor = (end + 1).coerceAtMost(length - 1)
  while (nextCursor < length) {
    val (pStart, pEnd) = getParagraphBounds(nextCursor)

    if (getSpans(pStart, pEnd, spanType).isEmpty()) break

    end = pEnd

    val nextNext = pEnd + 1
    if (nextNext >= length) break
    nextCursor = nextNext
  }

  return start to end
}

fun Spannable.isTheSameParagraphInSelection(selection: EnrichedSelection): Boolean {
  val (start, end) = selection.getInlineSelection()

  val startParagraphBounds = this.getParagraphBounds(start)
  val endParagraphBounds = this.getParagraphBounds(end)

  return startParagraphBounds.first == endParagraphBounds.first
}

fun Spannable.removeSpans(
  start: Int,
  end: Int,
  clazz: Class<out EnrichedSpan>,
) = removeSpans(getSpans(start, end, clazz))

fun Spannable.removeSpans(spans: Array<out EnrichedSpan>) = spans.forEach(::removeSpan)

fun Spannable.removeSpans(spans: List<EnrichedSpan>) = spans.forEach(::removeSpan)
