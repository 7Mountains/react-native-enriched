package com.swmansion.enriched.utils

import android.text.Editable
import android.text.Spannable
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.util.Log
import com.swmansion.enriched.constants.Strings
import com.swmansion.enriched.spans.EnrichedOrderedListSpan
import com.swmansion.enriched.spans.EnrichedUnorderedListSpan
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.styles.HtmlStyle

fun Spannable.isListParagraph(
  start: Int,
  end: Int,
): Boolean {
  if (start < 0 || end > length || start >= end) return false

  return getSpans(start, end, EnrichedUnorderedListSpan::class.java).isNotEmpty() ||
    getSpans(start, end, EnrichedOrderedListSpan::class.java).isNotEmpty()
}

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

fun Editable.paragraphRangeAt(index: Int): IntRange {
  val start = lastIndexOf(Strings.NEWLINE, index - 1).let { if (it == -1) 0 else it + 1 }
  val end = indexOf(Strings.NEWLINE, index).let { if (it == -1) length else it + 1 }
  return start until end
}

fun Editable.isParagraphZeroOrOneAndEmpty(range: IntRange): Boolean {
  val text = substring(range)

  if (text.length > 1) return false
  if (text.isEmpty()) return true

  val c = text[0]
  return c == Strings.SPACE_CHAR || c == Strings.ZERO_WIDTH_SPACE_CHAR || c == Strings.NEWLINE
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

fun <T> Spannable.setContinuousSpan(
  start: Int,
  end: Int,
  type: Class<T>,
  html: HtmlStyle,
) where T : EnrichedSpan {
  val prev = getPreviousParagraphSpan(start, type)
  val next = getNextParagraphSpan(end, type)

  val template = prev ?: next
  val newSpan = (template?.copy()) ?: type.getDeclaredConstructor(HtmlStyle::class.java).newInstance(html)

  var newStart = start
  var newEnd = end

  prev?.let {
    newStart = getSpanStart(it)
    removeSpan(it)
  }

  next?.let {
    newEnd = getSpanEnd(it)
    removeSpan(it)
  }

  val (safeStart, safeEnd) = getSafeSpanBoundaries(newStart, newEnd)
  setSpan(newSpan, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
}

fun <T> Spannable.mergeOrSetSpan(
  start: Int,
  end: Int,
  type: Class<T>,
  html: HtmlStyle,
) where T : EnrichedSpan {
  val spans = getSpans(start, end, type)
  if (spans.isEmpty()) {
    val span = type.getDeclaredConstructor(HtmlStyle::class.java).newInstance(html)
    val (s, e) = getSafeSpanBoundaries(start, end)
    setSpan(span, s, e, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
    return
  }

  val template = spans.first() as EnrichedSpan
  spans.forEach { removeSpan(it) }

  val merged = template.copy()
  setSpan(merged, start, end, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
}

fun <T> Spannable.removeSpansForRange(
  start: Int,
  end: Int,
  clazz: Class<T>,
): Boolean {
  val ssb = this as SpannableStringBuilder
  val spans = ssb.getSpans(start, end, clazz)
  if (spans.isEmpty()) return false

  var newStart = start
  var newEnd = end

  spans.forEach {
    newStart = ssb.getSpanStart(it).coerceAtMost(newStart)
    newEnd = ssb.getSpanEnd(it).coerceAtLeast(newEnd)
    ssb.removeSpan(it)
  }

  ssb.replace(newStart, newEnd, ssb.substring(newStart, newEnd).replace("\u200B", ""))
  return true
}
