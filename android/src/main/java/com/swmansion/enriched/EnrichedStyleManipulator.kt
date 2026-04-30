package com.swmansion.enriched

import android.util.Log
import com.swmansion.enriched.spans.EnrichedSpans
import com.swmansion.enriched.spans.TextStyle
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

  internal fun removeStyle(
    name: TextStyle,
    start: Int,
    end: Int,
  ): Boolean =
    when (name) {
      TextStyle.BOLD -> inlineStyles.removeStyle(TextStyle.BOLD, start, end)
      TextStyle.ITALIC -> inlineStyles.removeStyle(TextStyle.ITALIC, start, end)
      TextStyle.UNDERLINE -> inlineStyles.removeStyle(TextStyle.UNDERLINE, start, end)
      TextStyle.STRIKETHROUGH -> inlineStyles.removeStyle(TextStyle.STRIKETHROUGH, start, end)
      TextStyle.INLINE_CODE -> inlineStyles.removeStyle(TextStyle.INLINE_CODE, start, end)
      TextStyle.H1 -> paragraphStyles.removeStyle(TextStyle.H1, start, end)
      TextStyle.H2 -> paragraphStyles.removeStyle(TextStyle.H2, start, end)
      TextStyle.H3 -> paragraphStyles.removeStyle(TextStyle.H3, start, end)
      TextStyle.H4 -> paragraphStyles.removeStyle(TextStyle.H4, start, end)
      TextStyle.H5 -> paragraphStyles.removeStyle(TextStyle.H5, start, end)
      TextStyle.H6 -> paragraphStyles.removeStyle(TextStyle.H6, start, end)
      TextStyle.CODE_BLOCK -> paragraphStyles.removeStyle(TextStyle.CODE_BLOCK, start, end)
      TextStyle.BLOCK_QUOTE -> paragraphStyles.removeStyle(TextStyle.BLOCK_QUOTE, start, end)
      TextStyle.ORDERED_LIST -> listStyles.removeStyle(TextStyle.ORDERED_LIST, start, end)
      TextStyle.UNORDERED_LIST -> listStyles.removeStyle(TextStyle.UNORDERED_LIST, start, end)
      TextStyle.CHECK_LIST -> listStyles.removeStyle(TextStyle.CHECK_LIST, start, end)
      TextStyle.LINK -> parametrizedStyles.removeStyle(TextStyle.LINK, start, end)
      TextStyle.IMAGE -> parametrizedStyles.removeStyle(TextStyle.IMAGE, start, end)
      TextStyle.MENTION -> parametrizedStyles.removeStyle(TextStyle.MENTION, start, end)
      else -> false
    }

  internal fun toggleStyle(name: TextStyle) {
    when (name) {
      TextStyle.BOLD -> inlineStyles.toggleStyle(TextStyle.BOLD)
      TextStyle.ITALIC -> inlineStyles.toggleStyle(TextStyle.ITALIC)
      TextStyle.UNDERLINE -> inlineStyles.toggleStyle(TextStyle.UNDERLINE)
      TextStyle.STRIKETHROUGH -> inlineStyles.toggleStyle(TextStyle.STRIKETHROUGH)
      TextStyle.INLINE_CODE -> inlineStyles.toggleStyle(TextStyle.INLINE_CODE)
      TextStyle.H1 -> paragraphStyles.toggleStyle(TextStyle.H1)
      TextStyle.H2 -> paragraphStyles.toggleStyle(TextStyle.H2)
      TextStyle.H3 -> paragraphStyles.toggleStyle(TextStyle.H3)
      TextStyle.H4 -> paragraphStyles.toggleStyle(TextStyle.H4)
      TextStyle.H5 -> paragraphStyles.toggleStyle(TextStyle.H5)
      TextStyle.H6 -> paragraphStyles.toggleStyle(TextStyle.H6)
      TextStyle.CODE_BLOCK -> paragraphStyles.toggleStyle(TextStyle.CODE_BLOCK)
      TextStyle.BLOCK_QUOTE -> paragraphStyles.toggleStyle(TextStyle.BLOCK_QUOTE)
      TextStyle.ORDERED_LIST -> listStyles.toggleStyle(TextStyle.ORDERED_LIST)
      TextStyle.UNORDERED_LIST -> listStyles.toggleStyle(TextStyle.UNORDERED_LIST)
      TextStyle.CHECK_LIST -> listStyles.toggleStyle(TextStyle.CHECK_LIST)
      else -> Log.w("EnrichedTextInputView", "Unknown style: $name")
    }
  }

  internal fun getTargetRange(name: TextStyle): Pair<Int, Int> =
    when (name) {
      TextStyle.BOLD -> inlineStyles.getStyleRange()
      TextStyle.ITALIC -> inlineStyles.getStyleRange()
      TextStyle.UNDERLINE -> inlineStyles.getStyleRange()
      TextStyle.STRIKETHROUGH -> inlineStyles.getStyleRange()
      TextStyle.INLINE_CODE -> inlineStyles.getStyleRange()
      TextStyle.H1 -> paragraphStyles.getStyleRange()
      TextStyle.H2 -> paragraphStyles.getStyleRange()
      TextStyle.H3 -> paragraphStyles.getStyleRange()
      TextStyle.H4 -> paragraphStyles.getStyleRange()
      TextStyle.H5 -> paragraphStyles.getStyleRange()
      TextStyle.H6 -> paragraphStyles.getStyleRange()
      TextStyle.DIVIDER -> paragraphStyles.getStyleRange()
      TextStyle.CODE_BLOCK -> paragraphStyles.getStyleRange()
      TextStyle.BLOCK_QUOTE -> paragraphStyles.getStyleRange()
      TextStyle.ORDERED_LIST -> listStyles.getStyleRange()
      TextStyle.UNORDERED_LIST -> listStyles.getStyleRange()
      TextStyle.CHECK_LIST -> listStyles.getStyleRange()
      TextStyle.LINK -> parametrizedStyles.getStyleRange()
      TextStyle.IMAGE -> parametrizedStyles.getStyleRange()
      TextStyle.MENTION -> parametrizedStyles.getStyleRange()
      else -> Pair(0, 0)
    }

  private fun canApplyStyle(name: TextStyle): Boolean = EnrichedSpans.isStyleAvailable(name, view.availableStyles)

  fun verifyStyle(name: TextStyle): Boolean {
    val spanState = view.spanState ?: return false
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
      val start = selection?.start ?: 0
      val end = selection?.end ?: 0
      val lengthBefore = view.text?.length ?: 0

      view.runAsATransaction {
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
      selection?.onSelection(finalStart, finalEnd)
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

    parametrizedStyles.setLinkSpan(start, end, text, url)
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
    if (canApplyStyle(TextStyle.DIVIDER)) {
      paragraphStyles.insertDivider()
    }
  }

  internal fun addContent(
    text: String,
    type: String,
    src: String,
    attributes: Map<String, String>?,
  ) {
    if (canApplyStyle(TextStyle.CONTENT)) {
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

    parametrizedStyles.setMentionSpan(text, indicator, type, attributes)
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
    view.selection?.validateStyles()
  }
}
