package com.swmansion.enriched.utils

import android.text.Spannable
import android.util.Log
import com.swmansion.enriched.spans.EnrichedOrderedListSpan
import com.swmansion.enriched.spans.EnrichedUnorderedListSpan
import com.swmansion.enriched.spans.interfaces.EnrichedSpan

fun Spannable.expandUp(
  start: Int,
  isSameType: (pStart: Int, pEnd: Int) -> Boolean,
): Int {
  var cursor = start
  while (cursor > 0) {
    val prev = (cursor - 1).coerceAtLeast(0)
    val (pStart, pEnd) = getParagraphBounds(prev)

    if (pStart < 0 || pEnd > length || pStart >= pEnd) break
    if (!isSameType(pStart, pEnd)) break
    if (pStart >= cursor) break

    cursor = pStart
  }
  return cursor
}

fun Spannable.expandDown(
  end: Int,
  isSameType: (pStart: Int, pEnd: Int) -> Boolean,
): Int {
  var cursor = end
  val limit = length

  while (cursor < limit) {
    val safeCursor = cursor.coerceAtMost(limit - 1)
    val (pStart, pEnd) = getParagraphBounds(safeCursor)

    if (pStart < 0 || pEnd > limit || pStart >= pEnd) break
    if (!isSameType(pStart, pEnd)) break
    if (pEnd <= cursor) break

    cursor = pEnd
  }

  return cursor
}

fun Spannable.getListParagraphSpanClass(
  pStart: Int,
  pEnd: Int,
): Class<out EnrichedSpan>? =
  when {
    getSpans(pStart, pEnd, EnrichedOrderedListSpan::class.java).isNotEmpty() -> {
      EnrichedOrderedListSpan::class.java
    }

    getSpans(pStart, pEnd, EnrichedUnorderedListSpan::class.java).isNotEmpty() -> {
      EnrichedUnorderedListSpan::class.java
    }

    getSpans(
      pStart,
      pEnd,
      com.swmansion.enriched.spans.EnrichedChecklistSpan::class.java,
    ).isNotEmpty() -> {
      com.swmansion.enriched.spans.EnrichedChecklistSpan::class.java
    }

    else -> {
      null
    }
  }

fun <T> Spannable.getPreviousParagraphSpan(
  paragraphStart: Int,
  type: Class<T>,
): T? {
  if (paragraphStart <= 0) return null
  val (pStart, pEnd) = getParagraphBounds(paragraphStart - 1)
  val spans = getSpans(pStart, pEnd, type)
  if (spans.size > 1) Log.w("SpanUtils", "Multiple spans in previous paragraph")
  return spans.firstOrNull()
}

fun <T> Spannable.getNextParagraphSpan(
  paragraphEnd: Int,
  type: Class<T>,
): T? {
  if (paragraphEnd >= length - 1) return null
  val (pStart, pEnd) = getParagraphBounds(paragraphEnd + 1)
  val spans = getSpans(pStart, pEnd, type)
  if (spans.size > 1) Log.w("SpanUtils", "Multiple spans in next paragraph")
  return spans.firstOrNull()
}

fun Spannable.expandListBlockAtCursor(cursor: Int): IntRange? {
  if (isEmpty()) return null

  val safeCursor =
    cursor.coerceIn(0, length.coerceAtLeast(1) - 1)

  val (pStart, pEnd) = getParagraphBounds(safeCursor)

  val spanClass = getListParagraphSpanClass(pStart, pEnd) ?: return null

  val sameClass: (Int, Int) -> Boolean = { s, e ->
    getSpans(s, e, spanClass).isNotEmpty()
  }

  val blockStart = expandUp(pStart, sameClass)
  val blockEnd = expandDown(pEnd, sameClass)

  return blockStart until blockEnd
}
