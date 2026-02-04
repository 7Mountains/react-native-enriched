package com.swmansion.enriched.spans

import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.styles.HtmlStyle

interface ISpanConfig {
  val clazz: Class<out EnrichedSpan>
}

enum class TextStyle {
  // inline styles
  BOLD,
  ITALIC,
  UNDERLINE,
  STRIKETHROUGH,
  INLINE_CODE,
  COLOR,

  // paragraph styles
  H1,
  H2,
  H3,
  H4,
  H5,
  H6,
  BLOCK_QUOTE,
  CODE_BLOCK,
  DIVIDER,
  CONTENT,
  ALIGNMENT,

  // list styles
  UNORDERED_LIST,
  ORDERED_LIST,
  CHECK_LIST,

  // parametrized styles
  LINK,
  IMAGE,
  MENTION,
}

data class BaseSpanConfig(
  override val clazz: Class<out EnrichedSpan>,
) : ISpanConfig

data class ParagraphSpanConfig(
  override val clazz: Class<out EnrichedSpan>,
  val isContinuous: Boolean,
  val isSelfClosing: Boolean,
) : ISpanConfig

data class ListSpanConfig(
  override val clazz: Class<out EnrichedSpan>,
  val shortcut: String?,
) : ISpanConfig

data class StylesMergingConfig(
  val conflictingStyles: Array<TextStyle> = emptyArray(),
  val blockingStyles: Array<TextStyle> = emptyArray(),
)

object EnrichedSpans {
  val inlineSpans: Map<TextStyle, ISpanConfig> =
    mapOf(
      TextStyle.BOLD to BaseSpanConfig(EnrichedBoldSpan::class.java),
      TextStyle.ITALIC to BaseSpanConfig(EnrichedItalicSpan::class.java),
      TextStyle.UNDERLINE to BaseSpanConfig(EnrichedUnderlineSpan::class.java),
      TextStyle.STRIKETHROUGH to BaseSpanConfig(EnrichedStrikeThroughSpan::class.java),
      TextStyle.INLINE_CODE to BaseSpanConfig(EnrichedInlineCodeSpan::class.java),
      TextStyle.COLOR to BaseSpanConfig(EnrichedColoredSpan::class.java),
    )

  val paragraphSpans: Map<TextStyle, ParagraphSpanConfig> =
    mapOf(
      TextStyle.H1 to ParagraphSpanConfig(EnrichedH1Span::class.java, false, false),
      TextStyle.H2 to ParagraphSpanConfig(EnrichedH2Span::class.java, false, false),
      TextStyle.H3 to ParagraphSpanConfig(EnrichedH3Span::class.java, false, false),
      TextStyle.H4 to ParagraphSpanConfig(EnrichedH4Span::class.java, false, false),
      TextStyle.H5 to ParagraphSpanConfig(EnrichedH5Span::class.java, false, false),
      TextStyle.H6 to ParagraphSpanConfig(EnrichedH6Span::class.java, false, false),
      TextStyle.DIVIDER to ParagraphSpanConfig(EnrichedHorizontalRuleSpan::class.java, false, true),
      TextStyle.CONTENT to ParagraphSpanConfig(EnrichedContentSpan::class.java, false, true),
      TextStyle.BLOCK_QUOTE to ParagraphSpanConfig(EnrichedBlockQuoteSpan::class.java, false, false),
      TextStyle.CODE_BLOCK to ParagraphSpanConfig(EnrichedCodeBlockSpan::class.java, true, false),
      TextStyle.ALIGNMENT to ParagraphSpanConfig(EnrichedAlignmentSpan::class.java, true, false),
    )

  val listSpans: Map<TextStyle, ListSpanConfig> =
    mapOf(
      TextStyle.UNORDERED_LIST to ListSpanConfig(EnrichedUnorderedListSpan::class.java, "- "),
      TextStyle.ORDERED_LIST to ListSpanConfig(EnrichedOrderedListSpan::class.java, "1. "),
      TextStyle.CHECK_LIST to ListSpanConfig(EnrichedChecklistSpan::class.java, null),
    )

  val parametrizedStyles: Map<TextStyle, BaseSpanConfig> =
    mapOf(
      TextStyle.LINK to BaseSpanConfig(EnrichedLinkSpan::class.java),
      TextStyle.IMAGE to BaseSpanConfig(EnrichedImageSpan::class.java),
      TextStyle.MENTION to BaseSpanConfig(EnrichedMentionSpan::class.java),
    )

  fun getMergingConfigForStyle(
    style: TextStyle,
    htmlStyle: HtmlStyle,
  ): StylesMergingConfig? =
    when (style) {
      TextStyle.BOLD -> {
        val blocking = mutableListOf(TextStyle.CODE_BLOCK, TextStyle.DIVIDER, TextStyle.CONTENT)
        if (htmlStyle.h1Bold) blocking.add(TextStyle.H1)
        if (htmlStyle.h2Bold) blocking.add(TextStyle.H2)
        if (htmlStyle.h3Bold) blocking.add(TextStyle.H3)
        if (htmlStyle.h4Bold) blocking.add(TextStyle.H4)
        if (htmlStyle.h5Bold) blocking.add(TextStyle.H5)
        if (htmlStyle.h6Bold) blocking.add(TextStyle.H6)
        StylesMergingConfig(blockingStyles = blocking.toTypedArray())
      }

      TextStyle.ITALIC,
      TextStyle.UNDERLINE,
      TextStyle.STRIKETHROUGH,
      -> {
        StylesMergingConfig(blockingStyles = arrayOf(TextStyle.CODE_BLOCK, TextStyle.DIVIDER, TextStyle.CONTENT))
      }

      TextStyle.INLINE_CODE -> {
        StylesMergingConfig(
          conflictingStyles = arrayOf(TextStyle.MENTION, TextStyle.LINK),
          blockingStyles = arrayOf(TextStyle.CODE_BLOCK, TextStyle.DIVIDER, TextStyle.CONTENT),
        )
      }

      TextStyle.ALIGNMENT -> {
        StylesMergingConfig(
          blockingStyles = arrayOf(TextStyle.CONTENT, TextStyle.DIVIDER),
        )
      }

      TextStyle.H1 -> {
        val conflicting =
          mutableListOf(
            TextStyle.H2,
            TextStyle.H3,
            TextStyle.H4,
            TextStyle.H5,
            TextStyle.H6,
            TextStyle.ORDERED_LIST,
            TextStyle.UNORDERED_LIST,
            TextStyle.BLOCK_QUOTE,
            TextStyle.CODE_BLOCK,
            TextStyle.CHECK_LIST,
          )
        if (htmlStyle.h1Bold) conflicting.add(TextStyle.BOLD)
        StylesMergingConfig(conflictingStyles = conflicting.toTypedArray(), blockingStyles = arrayOf(TextStyle.DIVIDER, TextStyle.CONTENT))
      }

      TextStyle.H2 -> {
        val conflicting =
          mutableListOf(
            TextStyle.H1,
            TextStyle.H3,
            TextStyle.H4,
            TextStyle.H5,
            TextStyle.H6,
            TextStyle.ORDERED_LIST,
            TextStyle.UNORDERED_LIST,
            TextStyle.BLOCK_QUOTE,
            TextStyle.CODE_BLOCK,
            TextStyle.CHECK_LIST,
          )
        if (htmlStyle.h2Bold) conflicting.add(TextStyle.BOLD)
        StylesMergingConfig(conflictingStyles = conflicting.toTypedArray(), blockingStyles = arrayOf(TextStyle.DIVIDER, TextStyle.CONTENT))
      }

      TextStyle.H3 -> {
        val conflicting =
          mutableListOf(
            TextStyle.H1,
            TextStyle.H2,
            TextStyle.H4,
            TextStyle.H5,
            TextStyle.H6,
            TextStyle.ORDERED_LIST,
            TextStyle.UNORDERED_LIST,
            TextStyle.BLOCK_QUOTE,
            TextStyle.CODE_BLOCK,
            TextStyle.CHECK_LIST,
          )
        if (htmlStyle.h3Bold) conflicting.add(TextStyle.BOLD)
        StylesMergingConfig(conflictingStyles = conflicting.toTypedArray(), blockingStyles = arrayOf(TextStyle.DIVIDER, TextStyle.CONTENT))
      }

      TextStyle.H4 -> {
        val conflicting =
          mutableListOf(
            TextStyle.H1,
            TextStyle.H2,
            TextStyle.H3,
            TextStyle.H5,
            TextStyle.H6,
            TextStyle.ORDERED_LIST,
            TextStyle.UNORDERED_LIST,
            TextStyle.BLOCK_QUOTE,
            TextStyle.CODE_BLOCK,
            TextStyle.CHECK_LIST,
          )
        if (htmlStyle.h4Bold) conflicting.add(TextStyle.BOLD)
        StylesMergingConfig(conflictingStyles = conflicting.toTypedArray(), blockingStyles = arrayOf(TextStyle.DIVIDER, TextStyle.CONTENT))
      }

      TextStyle.H5 -> {
        val conflicting =
          mutableListOf(
            TextStyle.H1,
            TextStyle.H2,
            TextStyle.H3,
            TextStyle.H4,
            TextStyle.H6,
            TextStyle.ORDERED_LIST,
            TextStyle.UNORDERED_LIST,
            TextStyle.BLOCK_QUOTE,
            TextStyle.CODE_BLOCK,
            TextStyle.CHECK_LIST,
          )
        if (htmlStyle.h5Bold) conflicting.add(TextStyle.BOLD)
        StylesMergingConfig(conflictingStyles = conflicting.toTypedArray(), blockingStyles = arrayOf(TextStyle.DIVIDER, TextStyle.CONTENT))
      }

      TextStyle.H6 -> {
        val conflicting =
          mutableListOf(
            TextStyle.H1,
            TextStyle.H2,
            TextStyle.H3,
            TextStyle.H4,
            TextStyle.H5,
            TextStyle.ORDERED_LIST,
            TextStyle.UNORDERED_LIST,
            TextStyle.BLOCK_QUOTE,
            TextStyle.CODE_BLOCK,
            TextStyle.CHECK_LIST,
          )
        if (htmlStyle.h6Bold) conflicting.add(TextStyle.BOLD)
        StylesMergingConfig(conflictingStyles = conflicting.toTypedArray(), blockingStyles = arrayOf(TextStyle.DIVIDER, TextStyle.CONTENT))
      }

      TextStyle.BLOCK_QUOTE -> {
        StylesMergingConfig(
          conflictingStyles =
            arrayOf(
              TextStyle.H1,
              TextStyle.H2,
              TextStyle.H3,
              TextStyle.H4,
              TextStyle.H5,
              TextStyle.H6,
              TextStyle.CODE_BLOCK,
              TextStyle.ORDERED_LIST,
              TextStyle.UNORDERED_LIST,
              TextStyle.CHECK_LIST,
            ),
          blockingStyles = arrayOf(TextStyle.DIVIDER, TextStyle.CONTENT),
        )
      }

      TextStyle.CODE_BLOCK -> {
        StylesMergingConfig(
          conflictingStyles =
            arrayOf(
              TextStyle.H1,
              TextStyle.H2,
              TextStyle.H3,
              TextStyle.H4,
              TextStyle.H5,
              TextStyle.H6,
              TextStyle.BOLD,
              TextStyle.ITALIC,
              TextStyle.UNDERLINE,
              TextStyle.STRIKETHROUGH,
              TextStyle.UNORDERED_LIST,
              TextStyle.ORDERED_LIST,
              TextStyle.CHECK_LIST,
              TextStyle.BLOCK_QUOTE,
              TextStyle.INLINE_CODE,
            ),
          blockingStyles = arrayOf(TextStyle.DIVIDER, TextStyle.CONTENT),
        )
      }

      TextStyle.UNORDERED_LIST -> {
        StylesMergingConfig(
          conflictingStyles =
            arrayOf(
              TextStyle.H1,
              TextStyle.H2,
              TextStyle.H3,
              TextStyle.H4,
              TextStyle.H5,
              TextStyle.H6,
              TextStyle.ORDERED_LIST,
              TextStyle.CHECK_LIST,
              TextStyle.CODE_BLOCK,
              TextStyle.BLOCK_QUOTE,
            ),
          blockingStyles = arrayOf(TextStyle.DIVIDER, TextStyle.CONTENT),
        )
      }

      TextStyle.ORDERED_LIST -> {
        StylesMergingConfig(
          conflictingStyles =
            arrayOf(
              TextStyle.H1,
              TextStyle.H2,
              TextStyle.H3,
              TextStyle.H4,
              TextStyle.H5,
              TextStyle.H6,
              TextStyle.UNORDERED_LIST,
              TextStyle.CHECK_LIST,
              TextStyle.CODE_BLOCK,
              TextStyle.BLOCK_QUOTE,
            ),
          blockingStyles = arrayOf(TextStyle.DIVIDER, TextStyle.CONTENT),
        )
      }

      TextStyle.LINK -> {
        StylesMergingConfig(
          blockingStyles = arrayOf(TextStyle.INLINE_CODE, TextStyle.CODE_BLOCK, TextStyle.MENTION, TextStyle.DIVIDER, TextStyle.CONTENT),
        )
      }

      TextStyle.IMAGE -> {
        StylesMergingConfig(
          blockingStyles = arrayOf(TextStyle.DIVIDER, TextStyle.CONTENT),
        )
      }

      TextStyle.MENTION -> {
        StylesMergingConfig(
          blockingStyles = arrayOf(TextStyle.INLINE_CODE, TextStyle.CODE_BLOCK, TextStyle.LINK, TextStyle.DIVIDER, TextStyle.CONTENT),
        )
      }

      TextStyle.CHECK_LIST -> {
        StylesMergingConfig(
          conflictingStyles =
            arrayOf(
              TextStyle.H1,
              TextStyle.H2,
              TextStyle.H3,
              TextStyle.H4,
              TextStyle.H5,
              TextStyle.H6,
              TextStyle.CODE_BLOCK,
              TextStyle.ORDERED_LIST,
              TextStyle.UNORDERED_LIST,
              TextStyle.BLOCK_QUOTE,
            ),
          blockingStyles = arrayOf(TextStyle.DIVIDER, TextStyle.CONTENT),
        )
      }

      TextStyle.DIVIDER -> {
        StylesMergingConfig(
          blockingStyles = TextStyle.entries.toTypedArray(),
        )
      }

      TextStyle.CONTENT -> {
        StylesMergingConfig(
          blockingStyles = TextStyle.entries.toTypedArray(),
        )
      }

      TextStyle.COLOR -> {
        StylesMergingConfig(
          conflictingStyles = arrayOf(TextStyle.MENTION),
          blockingStyles = arrayOf(TextStyle.CONTENT, TextStyle.DIVIDER),
        )
      }
    }
}
