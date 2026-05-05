package com.swmansion.enriched.utils

import android.text.Editable
import com.swmansion.enriched.spans.EnrichedColoredSpan
import com.swmansion.enriched.spans.interfaces.EnrichedInlineSpan

fun isTheSameInlineSpan(
  first: EnrichedInlineSpan,
  second: EnrichedInlineSpan,
): Boolean {
  if (first::class.java.name != second::class.java.name) {
    return false
  }

  if (first is EnrichedColoredSpan && second is EnrichedColoredSpan) {
    return first.color == second.color
  }

  return true
}

fun Editable.areInlineSpansTouchingOrOverlapping(
  first: EnrichedInlineSpan,
  second: EnrichedInlineSpan,
): Boolean {
  val firstStart = getSpanStart(first)
  val firstEnd = getSpanEnd(first)
  val secondStart = getSpanStart(second)
  val secondEnd = getSpanEnd(second)

  if (firstStart < 0 || firstEnd < 0 || secondStart < 0 || secondEnd < 0) {
    return false
  }

  return firstEnd >= secondStart && secondEnd >= firstStart
}
