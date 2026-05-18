package com.swmansion.enriched

import android.util.Log
import com.swmansion.enriched.spans.EnrichedSpans
import com.swmansion.enriched.spans.TextStyle
import com.swmansion.enriched.spans.TextStyleGroup
import com.swmansion.enriched.styles.InlineStyles
import com.swmansion.enriched.styles.ListStyles
import com.swmansion.enriched.styles.ParagraphStyles
import com.swmansion.enriched.styles.ParametrizedStyles

class EnrichedStyleManipulator(
  val view: EnrichedTextInputView,
) {
  val inlineStyles: InlineStyles = InlineStyles(view)
  val paragraphStyles: ParagraphStyles = ParagraphStyles(view)
  val listStyles: ListStyles = ListStyles(view)
  val parametrizedStyles: ParametrizedStyles = ParametrizedStyles(view)

  private fun runWithIgnoredSpanWatcherTransaction(block: () -> Unit) {
    view.transactionManager.runTransaction {
      view.transactionManager.runWithIgnoredSpanWatcher {
        block()
      }
    }
  }

  internal fun removeStyle(
    name: TextStyle,
    start: Int,
    end: Int,
  ): Boolean =
    when (EnrichedSpans.getStyleGroup(name)) {
      TextStyleGroup.INLINE -> inlineStyles.removeStyle(name, start, end)
      TextStyleGroup.PARAGRAPH -> paragraphStyles.removeStyle(name, start, end)
      TextStyleGroup.LIST -> listStyles.removeStyle(name, start, end)
      TextStyleGroup.PARAMETRIZED -> parametrizedStyles.removeStyle(name, start, end)
      null -> false
    }

  internal fun toggleStyle(name: TextStyle) {
    when (EnrichedSpans.getStyleGroup(name)) {
      TextStyleGroup.INLINE -> inlineStyles.toggleStyle(name)

      TextStyleGroup.PARAGRAPH -> paragraphStyles.toggleStyle(name)

      TextStyleGroup.LIST -> listStyles.toggleStyle(name)

      TextStyleGroup.PARAMETRIZED,
      null,
      -> Log.w("EnrichedTextInputView", "Unknown style: $name")
    }
  }

  internal fun getTargetRange(name: TextStyle): Pair<Int, Int> =
    when (EnrichedSpans.getStyleGroup(name)) {
      TextStyleGroup.INLINE -> inlineStyles.getStyleRange()
      TextStyleGroup.PARAGRAPH -> paragraphStyles.getStyleRange()
      TextStyleGroup.LIST -> listStyles.getStyleRange()
      TextStyleGroup.PARAMETRIZED -> parametrizedStyles.getStyleRange()
      null -> Pair(0, 0)
    }

  private fun canApplyStyle(name: TextStyle): Boolean = EnrichedSpans.isStyleAvailable(name, view.availableStyles)

  fun verifyStyle(name: TextStyle): Boolean {
    val spanState = view.spanState
    val selection = view.selection

    if (!canApplyStyle(name)) {
      return false
    }

    val mergingConfig = EnrichedSpans.getMergingConfigForStyle(name, view.htmlStyle) ?: return true
    val conflictingStyles = mergingConfig.conflictingStyles
    val blockingStyles = mergingConfig.blockingStyles
    val isEnabling = spanState.getStart(name) == null

    if (!isEnabling) return true

    for (style in blockingStyles) {
      if (spanState.getStart(style) != null) {
        spanState.setStart(name, null)
        return false
      }
    }

    for (style in conflictingStyles) {
      val start = selection.start
      val end = selection.end
      val lengthBefore = view.text?.length ?: 0

      runWithIgnoredSpanWatcherTransaction {
        val targetRange = getTargetRange(name)
        val removed = removeStyle(style, targetRange.first, targetRange.second)
        if (removed) {
          spanState.setStart(style, null)
        }
      }

      val lengthAfter = view.text?.length ?: 0
      val charactersRemoved = lengthBefore - lengthAfter
      val finalEnd =
        if (charactersRemoved > 0) {
          (end - charactersRemoved).coerceAtLeast(0)
        } else {
          end
        }

      val finalStart = start.coerceAtLeast(0).coerceAtMost(finalEnd)
      selection.onSelection(finalStart, finalEnd)
    }

    return true
  }

  internal fun addLink(
    start: Int,
    end: Int,
    text: String,
    url: String,
  ) {
    val isValid = verifyStyle(TextStyle.LINK)
    if (!isValid) return

    runWithIgnoredSpanWatcherTransaction {
      parametrizedStyles.setLinkSpan(start, end, text, url)
    }
  }

  internal fun addImage(
    src: String,
    width: Float,
    height: Float,
  ) {
    val isValid = verifyStyle(TextStyle.IMAGE)
    if (!isValid) return

    parametrizedStyles.setImageSpan(src, width, height)
  }

  internal fun insertDivider() {
    runWithIgnoredSpanWatcherTransaction {
      if (canApplyStyle(TextStyle.DIVIDER)) {
        paragraphStyles.insertDivider()
      }
    }
  }

  internal fun addContent(
    text: String,
    type: String,
    src: String,
    attributes: Map<String, String>?,
  ) {
    if (!canApplyStyle(TextStyle.CONTENT)) return

    runWithIgnoredSpanWatcherTransaction {
      paragraphStyles.addContent(text, type, src, attributes)
    }
  }

  internal fun startMention(indicator: String) {
    val isValid = verifyStyle(TextStyle.MENTION)
    if (!isValid) return

    parametrizedStyles.startMention(indicator)
  }

  internal fun addMention(
    indicator: String,
    text: String,
    type: String,
    attributes: Map<String, String>,
  ) {
    val isValid = verifyStyle(TextStyle.MENTION)
    if (!isValid) return

    runWithIgnoredSpanWatcherTransaction {
      parametrizedStyles.setMentionSpan(text, indicator, type, attributes)
    }
  }

  internal fun setColor(color: Int) {
    val isValid = verifyStyle(TextStyle.COLOR)
    if (!isValid) return

    inlineStyles.setColorStyle(color)
  }

  internal fun removeColor() = inlineStyles.removeColorSpan()

  internal fun setParagraphAlignment(alignment: String) {
    val canApply = verifyStyle(TextStyle.ALIGNMENT)

    if (!canApply) {
      return
    }

    paragraphStyles.setParagraphAlignmentSpan(alignment)
  }

  internal fun removeLink(
    start: Int,
    end: Int,
  ) {
    parametrizedStyles.removeLinkSpan(start, end)
    view.selection.validateStyles()
  }
}
