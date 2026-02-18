package com.swmansion.enriched.utils

import android.text.Spannable
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.util.Log
import com.swmansion.enriched.constants.Strings
import com.swmansion.enriched.spans.interfaces.EnrichedBlockSpan
import com.swmansion.enriched.spans.interfaces.EnrichedNonEditableParagraphSpan
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

data class MergeResult(
  val text: Spannable,
  val insertedCharactersAmount: Int,
)

fun Spannable.mergeSpannables(
  start: Int,
  end: Int,
  inserted: Spannable,
): MergeResult {
  val builder = SpannableStringBuilder(this)

  val safeStart = minOf(start, end)
  val safeEnd = maxOf(start, end)

  val paragraphBounds = builder.getParagraphBounds(safeStart, safeEnd)

  val (pStart, pEnd) = paragraphBounds

  if (pStart == pEnd) {
    builder.insert(pEnd, inserted)
    return MergeResult(
      text = builder,
      insertedCharactersAmount = inserted.length,
    )
  }

  if (builder.tryInsertNonEditableParagraph(safeStart, safeEnd, inserted) ||
    builder.tryInsertAfterNonEditableTarget(safeStart, safeEnd, inserted)
  ) {
    return MergeResult(
      text = builder,
      insertedCharactersAmount = 1 + inserted.length, // newline + text
    )
  }

  if (inserted.startsWithNonEditableParagraph()) {
    builder.insertAfter(safeEnd, inserted)
    return MergeResult(
      text = builder,
      insertedCharactersAmount = 1 + inserted.length,
    )
  }

  val targetParagraphSpans =
    getSpans(safeStart, safeStart, EnrichedParagraphSpan::class.java)

  cleanInsertedFromParagraphSpansIfNeeded(
    targetParagraphSpans,
    inserted,
  )

  var addedCharacters = 0

  val (finalStart, finalEnd, newlineAdded) =
    builder.maybeInsertNewLine(
      safeStart,
      safeEnd,
      paragraphBounds,
      inserted,
    )

  if (newlineAdded) {
    addedCharacters++
  }

  builder.replace(finalStart, finalEnd, inserted)
  addedCharacters += inserted.length

  if (shouldSkipParagraphSpanMerge(
      targetParagraphSpans,
      paragraphBounds,
    )
  ) {
    return MergeResult(builder, addedCharacters)
  }

  builder.applyParagraphSpans(
    targetParagraphSpans,
    finalStart,
  )

  return MergeResult(
    text = builder,
    insertedCharactersAmount = addedCharacters,
  )
}

private fun SpannableStringBuilder.tryInsertAfterNonEditableTarget(
  start: Int,
  end: Int,
  inserted: Spannable,
): Boolean {
  if (start != end) return false

  val (pStart, pEnd) = getParagraphBounds(start, end)

  val hasNonEditable =
    getSpans(
      pStart,
      pEnd,
      EnrichedNonEditableParagraphSpan::class.java,
    ).isNotEmpty()

  if (!hasNonEditable) return false

  insertAfter(end, inserted)
  return true
}

private fun SpannableStringBuilder.tryInsertNonEditableParagraph(
  start: Int,
  end: Int,
  inserted: Spannable,
): Boolean {
  if (start != end) return false

  val hasNonEditable = inserted.getSpans(0, 0, EnrichedNonEditableParagraphSpan::class.java).isNotEmpty()

  if (!hasNonEditable) return false

  val (_, pEnd) = getParagraphBounds(start, end)

  insertAfter(pEnd, inserted)

  return true
}

private fun Spannable.startsWithNonEditableParagraph(): Boolean {
  val (pStart, pEnd) = getParagraphBounds(0, 0)

  return getSpans(
    pStart,
    pEnd,
    EnrichedNonEditableParagraphSpan::class.java,
  ).isNotEmpty()
}

private fun SpannableStringBuilder.insertAfter(
  index: Int,
  inserted: Spannable,
) {
  insert(index, Strings.NEWLINE_STRING)
  insert(index + 1, inserted)
}

private fun cleanInsertedFromParagraphSpansIfNeeded(
  targetSpans: Array<EnrichedParagraphSpan>,
  inserted: Spannable,
) {
  if (targetSpans.isEmpty()) return

  val (pStart, pEnd) = inserted.getParagraphBounds(0, 0)

  inserted
    .getSpans(pStart, pEnd, EnrichedParagraphSpan::class.java)
    .forEach { inserted.removeSpan(it) }

  inserted
    .getSpans(pStart, pEnd, EnrichedBlockSpan::class.java)
    .forEach { inserted.removeSpan(it) }
}

private fun SpannableStringBuilder.maybeInsertNewLine(
  safeStart: Int,
  safeEnd: Int,
  paragraphBounds: Pair<Int, Int>,
  inserted: Spannable,
): Triple<Int, Int, Boolean> {
  val (_, paragraphEnd) = paragraphBounds

  val insertsNewParagraph =
    inserted.contains(Strings.NEWLINE_STRING) &&
      safeStart == paragraphEnd

  if (!insertsNewParagraph) {
    return Triple(safeStart, safeEnd, false)
  }

  insert(safeStart, Strings.NEWLINE_STRING)
  return Triple(
    safeStart + 1,
    safeEnd + 1,
    true,
  )
}

private fun shouldSkipParagraphSpanMerge(
  targetSpans: Array<EnrichedParagraphSpan>,
  paragraphBounds: Pair<Int, Int>,
): Boolean {
  val (pStart, pEnd) = paragraphBounds
  return targetSpans.isEmpty() && pStart == pEnd
}

private fun SpannableStringBuilder.applyParagraphSpans(
  spans: Array<EnrichedParagraphSpan>,
  at: Int,
) {
  val (pStart, pEnd) = getParagraphBounds(at, at)

  getSpans(pStart, pEnd, EnrichedParagraphSpan::class.java)
    .forEach { removeSpan(it) }

  spans.forEach { span ->
    setSpan(
      span.copy(),
      pStart,
      pEnd,
      Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
    )
  }
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
