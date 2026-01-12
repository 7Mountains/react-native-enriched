package com.swmansion.enriched.spans

import com.swmansion.enriched.styles.HtmlStyle

interface ISpanConfig {
  val clazz: Class<*>
}

data class BaseSpanConfig(
  override val clazz: Class<*>,
) : ISpanConfig

data class ParagraphSpanConfig(
  override val clazz: Class<*>,
  val isContinuous: Boolean,
  val isSelfClosing: Boolean,
) : ISpanConfig

data class ListSpanConfig(
  override val clazz: Class<*>,
  val shortcut: String?,
) : ISpanConfig

data class StylesMergingConfig(
  // styles that should be removed when we apply specific style
  val conflictingStyles: Array<String> = emptyArray(),
  // styles that should block setting specific style
  val blockingStyles: Array<String> = emptyArray(),
)

object EnrichedSpans {
  // inline styles
  const val BOLD = "bold"
  const val ITALIC = "italic"
  const val UNDERLINE = "underline"
  const val STRIKETHROUGH = "strikethrough"
  const val INLINE_CODE = "inline_code"

  // paragraph styles
  const val H1 = "h1"
  const val H2 = "h2"
  const val H3 = "h3"
  const val H4 = "h4"
  const val H5 = "h5"
  const val H6 = "h6"
  const val BLOCK_QUOTE = "block_quote"
  const val CODE_BLOCK = "code_block"
  const val DIVIDER = "divider"
  const val CONTENT = "content"

  // list styles
  const val UNORDERED_LIST = "unordered_list"
  const val ORDERED_LIST = "ordered_list"
  const val CHECK_LIST = "check_list"

  // parametrized styles
  const val LINK = "link"
  const val IMAGE = "image"
  const val MENTION = "mention"

  val inlineSpans: Map<String, BaseSpanConfig> =
    mapOf(
      BOLD to BaseSpanConfig(EnrichedBoldSpan::class.java),
      ITALIC to BaseSpanConfig(EnrichedItalicSpan::class.java),
      UNDERLINE to BaseSpanConfig(EnrichedUnderlineSpan::class.java),
      STRIKETHROUGH to BaseSpanConfig(EnrichedStrikeThroughSpan::class.java),
      INLINE_CODE to BaseSpanConfig(EnrichedInlineCodeSpan::class.java),
    )

  val paragraphSpans: Map<String, ParagraphSpanConfig> =
    mapOf(
      H1 to ParagraphSpanConfig(EnrichedH1Span::class.java, false, false),
      H2 to ParagraphSpanConfig(EnrichedH2Span::class.java, false, false),
      H3 to ParagraphSpanConfig(EnrichedH3Span::class.java, false, false),
      H4 to ParagraphSpanConfig(EnrichedH4Span::class.java, false, false),
      H5 to ParagraphSpanConfig(EnrichedH5Span::class.java, false, false),
      H6 to ParagraphSpanConfig(EnrichedH6Span::class.java, false, false),
      DIVIDER to ParagraphSpanConfig(EnrichedHorizontalRuleSpan::class.java, false, true),
      CONTENT to ParagraphSpanConfig(EnrichedContentSpan::class.java, false, true),
      BLOCK_QUOTE to ParagraphSpanConfig(EnrichedBlockQuoteSpan::class.java, true, false),
      CODE_BLOCK to ParagraphSpanConfig(EnrichedCodeBlockSpan::class.java, true, false),
    )

  val listSpans: Map<String, ListSpanConfig> =
    mapOf(
      UNORDERED_LIST to ListSpanConfig(EnrichedUnorderedListSpan::class.java, "- "),
      ORDERED_LIST to ListSpanConfig(EnrichedOrderedListSpan::class.java, "1. "),
      CHECK_LIST to ListSpanConfig(EnrichedChecklistSpan::class.java, null),
    )

  val parametrizedStyles: Map<String, BaseSpanConfig> =
    mapOf(
      LINK to BaseSpanConfig(EnrichedLinkSpan::class.java),
      IMAGE to BaseSpanConfig(EnrichedImageSpan::class.java),
      MENTION to BaseSpanConfig(EnrichedMentionSpan::class.java),
    )

  val allSpans: Map<String, ISpanConfig> =
    inlineSpans + paragraphSpans + listSpans + parametrizedStyles

  fun getMergingConfigForStyle(
    style: String,
    htmlStyle: HtmlStyle,
  ): StylesMergingConfig? =
    when (style) {
      BOLD -> {
        val blockingStyles = mutableListOf(CODE_BLOCK, DIVIDER, CONTENT)
        if (htmlStyle.h1Bold) blockingStyles.add(H1)
        if (htmlStyle.h2Bold) blockingStyles.add(H2)
        if (htmlStyle.h3Bold) blockingStyles.add(H3)
        if (htmlStyle.h4Bold) blockingStyles.add(H4)
        if (htmlStyle.h5Bold) blockingStyles.add(H5)
        if (htmlStyle.h6Bold) blockingStyles.add(H6)
        StylesMergingConfig(blockingStyles = blockingStyles.toTypedArray())
      }

      ITALIC, UNDERLINE, STRIKETHROUGH -> {
        StylesMergingConfig(
          blockingStyles = arrayOf(CODE_BLOCK, DIVIDER, CONTENT),
        )
      }

      INLINE_CODE -> {
        StylesMergingConfig(
          conflictingStyles = arrayOf(MENTION, LINK),
          blockingStyles = arrayOf(CODE_BLOCK, DIVIDER, CONTENT),
        )
      }

      H1 -> {
        val conflicting = mutableListOf(H2, H3, H4, H5, H6, ORDERED_LIST, UNORDERED_LIST, BLOCK_QUOTE, CODE_BLOCK, CHECK_LIST)
        if (htmlStyle.h1Bold) conflicting.add(BOLD)
        StylesMergingConfig(conflictingStyles = conflicting.toTypedArray(), blockingStyles = arrayOf(DIVIDER, CONTENT))
      }

      H2 -> {
        val conflicting = mutableListOf(H1, H3, H4, H5, H6, ORDERED_LIST, UNORDERED_LIST, BLOCK_QUOTE, CODE_BLOCK, CHECK_LIST)
        if (htmlStyle.h2Bold) conflicting.add(BOLD)
        StylesMergingConfig(conflictingStyles = conflicting.toTypedArray(), blockingStyles = arrayOf(DIVIDER, CONTENT))
      }

      H3 -> {
        val conflicting = mutableListOf(H1, H2, H4, H5, H6, ORDERED_LIST, UNORDERED_LIST, BLOCK_QUOTE, CODE_BLOCK, CHECK_LIST)
        if (htmlStyle.h3Bold) conflicting.add(BOLD)
        StylesMergingConfig(conflictingStyles = conflicting.toTypedArray(), blockingStyles = arrayOf(DIVIDER, CONTENT))
      }

      H4 -> {
        val conflicting = mutableListOf(H1, H2, H3, H5, H6, ORDERED_LIST, UNORDERED_LIST, BLOCK_QUOTE, CODE_BLOCK, CHECK_LIST)
        if (htmlStyle.h4Bold) conflicting.add(BOLD)
        StylesMergingConfig(conflictingStyles = conflicting.toTypedArray(), blockingStyles = arrayOf(DIVIDER, CONTENT))
      }

      H5 -> {
        val conflicting = mutableListOf(H1, H2, H3, H4, H6, ORDERED_LIST, UNORDERED_LIST, BLOCK_QUOTE, CODE_BLOCK, CHECK_LIST)
        if (htmlStyle.h5Bold) conflicting.add(BOLD)
        StylesMergingConfig(conflictingStyles = conflicting.toTypedArray(), blockingStyles = arrayOf(DIVIDER, CONTENT))
      }

      H6 -> {
        val conflicting = mutableListOf(H1, H2, H3, H4, H5, ORDERED_LIST, UNORDERED_LIST, BLOCK_QUOTE, CODE_BLOCK, CHECK_LIST)
        if (htmlStyle.h6Bold) conflicting.add(BOLD)
        StylesMergingConfig(conflictingStyles = conflicting.toTypedArray(), blockingStyles = arrayOf(DIVIDER, CONTENT))
      }

      BLOCK_QUOTE -> {
        StylesMergingConfig(
          conflictingStyles = arrayOf(H1, H2, H3, H4, H5, H6, CODE_BLOCK, ORDERED_LIST, UNORDERED_LIST, CHECK_LIST),
          blockingStyles = arrayOf(DIVIDER, CONTENT),
        )
      }

      CODE_BLOCK -> {
        StylesMergingConfig(
          conflictingStyles =
            arrayOf(
              H1,
              H2,
              H3,
              H4,
              H5,
              H6,
              BOLD,
              ITALIC,
              UNDERLINE,
              STRIKETHROUGH,
              UNORDERED_LIST,
              ORDERED_LIST,
              CHECK_LIST,
              BLOCK_QUOTE,
              INLINE_CODE,
            ),
          blockingStyles = arrayOf(DIVIDER, CONTENT),
        )
      }

      UNORDERED_LIST -> {
        StylesMergingConfig(
          conflictingStyles = arrayOf(H1, H2, H3, H4, H5, H6, ORDERED_LIST, CHECK_LIST, CODE_BLOCK, BLOCK_QUOTE),
          blockingStyles = arrayOf(DIVIDER, CONTENT),
        )
      }

      ORDERED_LIST -> {
        StylesMergingConfig(
          conflictingStyles = arrayOf(H1, H2, H3, H4, H5, H6, UNORDERED_LIST, CHECK_LIST, CODE_BLOCK, BLOCK_QUOTE),
          blockingStyles = arrayOf(DIVIDER, CONTENT),
        )
      }

      LINK -> {
        StylesMergingConfig(
          blockingStyles = arrayOf(INLINE_CODE, CODE_BLOCK, MENTION, DIVIDER, CONTENT),
        )
      }

      IMAGE -> {
        StylesMergingConfig(blockingStyles = arrayOf(DIVIDER, CONTENT))
      }

      MENTION -> {
        StylesMergingConfig(
          blockingStyles = arrayOf(INLINE_CODE, CODE_BLOCK, LINK, DIVIDER, CONTENT),
        )
      }

      CHECK_LIST -> {
        StylesMergingConfig(
          conflictingStyles = arrayOf(H1, H2, H3, H4, H5, H6, CODE_BLOCK, ORDERED_LIST, UNORDERED_LIST, BLOCK_QUOTE),
          blockingStyles = arrayOf(DIVIDER, CONTENT),
        )
      }

      DIVIDER -> {
        StylesMergingConfig(
          blockingStyles =
            arrayOf(
              BOLD,
              ITALIC,
              UNDERLINE,
              STRIKETHROUGH,
              INLINE_CODE,
              CODE_BLOCK,
              LINK,
              MENTION,
              H1,
              H2,
              H3,
              H4,
              H5,
              H6,
              BLOCK_QUOTE,
              UNORDERED_LIST,
              ORDERED_LIST,
              CHECK_LIST,
              IMAGE,
              CONTENT,
            ),
        )
      }

      CONTENT -> {
        StylesMergingConfig(
          blockingStyles =
            arrayOf(
              BOLD,
              ITALIC,
              UNDERLINE,
              STRIKETHROUGH,
              INLINE_CODE,
              CODE_BLOCK,
              LINK,
              MENTION,
              H1,
              H2,
              H3,
              H4,
              H5,
              H6,
              BLOCK_QUOTE,
              UNORDERED_LIST,
              ORDERED_LIST,
              CHECK_LIST,
              IMAGE,
              DIVIDER,
            ),
        )
      }

      else -> {
        null
      }
    }

  fun isTypeContinuous(type: Class<*>): Boolean = paragraphSpans.values.find { it.clazz == type }?.isContinuous == true
}
