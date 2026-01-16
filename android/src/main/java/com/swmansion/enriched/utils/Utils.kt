package com.swmansion.enriched.utils

import android.text.Spannable
import android.text.SpannableString
import android.text.SpannableStringBuilder
import android.util.Log
import com.swmansion.enriched.constants.Strings
import com.swmansion.enriched.spans.interfaces.EnrichedBlockSpan
import com.swmansion.enriched.spans.interfaces.EnrichedParagraphSpan
import org.json.JSONObject

fun jsonStringToStringMap(json: String): Map<String, String> {
  val result = mutableMapOf<String, String>()
  try {
    val jsonObject = JSONObject(json)
    for (key in jsonObject.keys()) {
      val value = jsonObject.opt(key)
      if (value is String) {
        result[key] = value
      }
    }
  } catch (e: Exception) {
    Log.w("ReactNativeEnrichedView", "Failed to parse JSON string to Map: $json", e)
  }

  return result
}

fun Spannable.getSafeSpanBoundaries(
  start: Int,
  end: Int,
): Pair<Int, Int> {
  val safeStart = start.coerceAtMost(end).coerceAtLeast(0)
  val safeEnd = end.coerceAtLeast(start).coerceAtMost(this.length)

  return Pair(safeStart, safeEnd)
}

fun Spannable.getParagraphBounds(
  start: Int,
  end: Int,
): Pair<Int, Int> {
  var startPosition = start.coerceAtLeast(0).coerceAtMost(this.length)
  var endPosition = end.coerceAtLeast(0).coerceAtMost(this.length)

  // Find the start of the paragraph
  while (startPosition > 0 && this[startPosition - 1] != Strings.NEWLINE) {
    startPosition--
  }

  // Find the end of the paragraph
  while (endPosition < this.length && this[endPosition] != Strings.NEWLINE) {
    endPosition++
  }

  if (startPosition >= endPosition) {
    // If the start position is equal or greater than the end position, return the same position
    startPosition = endPosition
  }

  return Pair(startPosition, endPosition)
}

fun Spannable.getParagraphBounds(index: Int): Pair<Int, Int> = this.getParagraphBounds(index, index)

fun Spannable.mergeSpannables(
  start: Int,
  end: Int,
  string: String,
): Spannable = this.mergeSpannables(start, end, SpannableString(string))

fun Spannable.mergeSpannables(
  start: Int,
  end: Int,
  spannable: Spannable,
): Spannable {
  var finalStart = start
  var finalEnd = end

  val builder = SpannableStringBuilder(this)
  val startBlockSpans = spannable.getSpans(0, 0, EnrichedBlockSpan::class.java)
  val startParagraphSpans = spannable.getSpans(0, 0, EnrichedParagraphSpan::class.java)
  val endBlockSpans = spannable.getSpans(this.length, this.length, EnrichedBlockSpan::class.java)
  val endParagraphSpans = spannable.getSpans(this.length, this.length, EnrichedParagraphSpan::class.java)
  val (paragraphStart, paragraphEnd) = this.getParagraphBounds(start, end)
  val isNewLineStart = startBlockSpans.isNotEmpty() || startParagraphSpans.isNotEmpty()
  val isNewLineEnd = endBlockSpans.isNotEmpty() || endParagraphSpans.isNotEmpty()

  if (isNewLineStart && start != paragraphStart) {
    builder.insert(start, Strings.NEWLINE_STRING)
    finalStart = start + 1
    finalEnd = end + 1
  }

  if (isNewLineEnd && end != paragraphEnd) {
    builder.insert(finalEnd, Strings.NEWLINE_STRING)
  }

  builder.replace(finalStart, finalEnd, spannable)

  return builder
}

// Removes zero-width spaces from the given range in the SpannableStringBuilder without affecting spans
fun SpannableStringBuilder.removeZWS(
  start: Int,
  end: Int,
): Pair<Int, Int> {
  var removedLeft = 0
  var removedRight = 0
  val mid = (start + end) / 2

  for (i in (end - 1) downTo start) {
    if (this[i] == Strings.ZERO_WIDTH_SPACE_CHAR) {
      if (i < mid) removedLeft++ else removedRight++

      delete(i, i + 1)
    }
  }

  return removedLeft to removedRight
}

fun Spannable.getParagraphsBounds(
  start: Int,
  end: Int,
): List<IntRange> {
  val result = mutableListOf<IntRange>()

  var pos = start.coerceIn(0, length)

  while (pos <= end && pos < length) {
    var pStart = pos
    while (pStart > 0 && this[pStart - 1] != Strings.NEWLINE) {
      pStart--
    }

    var pEnd = pos
    while (pEnd < length && this[pEnd] != Strings.NEWLINE) {
      pEnd++
    }

    result.add(pStart until pEnd)

    pos = pEnd + 1
  }

  return result
}
