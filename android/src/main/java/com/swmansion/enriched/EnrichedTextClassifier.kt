package com.swmansion.enriched

import android.os.Build
import android.view.textclassifier.TextClassification
import android.view.textclassifier.TextClassifier
import android.view.textclassifier.TextSelection
import androidx.annotation.RequiresApi
import com.swmansion.enriched.constants.Strings

@RequiresApi(Build.VERSION_CODES.O)
internal class EnrichedTextClassifier(
  private val delegate: TextClassifier,
) : TextClassifier {
  @RequiresApi(Build.VERSION_CODES.P)
  override fun suggestSelection(request: TextSelection.Request): TextSelection =
    if (touchesReplacementBlock(request.text, request.startIndex, request.endIndex)) {
      TextSelection.Builder(request.startIndex, request.endIndex).build()
    } else {
      delegate.suggestSelection(request)
    }

  @RequiresApi(Build.VERSION_CODES.P)
  override fun classifyText(request: TextClassification.Request): TextClassification =
    if (touchesReplacementBlock(request.text, request.startIndex, request.endIndex)) {
      TextClassification.Builder().build()
    } else {
      delegate.classifyText(request)
    }

  private fun touchesReplacementBlock(
    text: CharSequence,
    start: Int,
    end: Int,
  ): Boolean {
    val from = (start - 1).coerceAtLeast(0)
    val to = (end + 1).coerceAtMost(text.length)
    return (from until to).any { text[it] == Strings.OBJECT_REPLACEMENT_CHAR }
  }
}
