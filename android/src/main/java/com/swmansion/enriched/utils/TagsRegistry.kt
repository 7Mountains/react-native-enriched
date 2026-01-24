package com.swmansion.enriched.utils

import com.swmansion.enriched.constants.HtmlTags
import com.swmansion.enriched.spans.EnrichedAlignmentSpan
import com.swmansion.enriched.spans.EnrichedBlockQuoteSpan
import com.swmansion.enriched.spans.EnrichedChecklistSpan
import com.swmansion.enriched.spans.EnrichedCodeBlockSpan
import com.swmansion.enriched.spans.EnrichedContentSpan
import com.swmansion.enriched.spans.EnrichedH1Span
import com.swmansion.enriched.spans.EnrichedH2Span
import com.swmansion.enriched.spans.EnrichedH3Span
import com.swmansion.enriched.spans.EnrichedH4Span
import com.swmansion.enriched.spans.EnrichedH5Span
import com.swmansion.enriched.spans.EnrichedH6Span
import com.swmansion.enriched.spans.EnrichedHorizontalRuleSpan
import com.swmansion.enriched.spans.EnrichedOrderedListSpan
import com.swmansion.enriched.spans.EnrichedUnorderedListSpan
import com.swmansion.enriched.spans.interfaces.EnrichedParagraphSpan
import kotlin.reflect.KClass

object TagsRegistry {
  data class TagInfo(
    val tag: String,
    val isSelfClosing: Boolean = false,
    val attributes: ((EnrichedParagraphSpan) -> Map<String, String>?)? = null,
  )

  private val registry: Map<KClass<out EnrichedParagraphSpan>, TagInfo> =
    mapOf(
      EnrichedUnorderedListSpan::class to TagInfo(HtmlTags.UNORDERED_LIST),
      EnrichedOrderedListSpan::class to TagInfo(HtmlTags.ORDERED_LIST),
      EnrichedH1Span::class to TagInfo(HtmlTags.H1),
      EnrichedH2Span::class to TagInfo(HtmlTags.H2),
      EnrichedH3Span::class to TagInfo(HtmlTags.H3),
      EnrichedH4Span::class to TagInfo(HtmlTags.H4),
      EnrichedH5Span::class to TagInfo(HtmlTags.H5),
      EnrichedH6Span::class to TagInfo(HtmlTags.H6),
      EnrichedBlockQuoteSpan::class to TagInfo(HtmlTags.BLOCK_QUOTE),
      EnrichedCodeBlockSpan::class to TagInfo(HtmlTags.CODE_BLOCK),
      EnrichedHorizontalRuleSpan::class to TagInfo(HtmlTags.HORIZONTAL_RULE, isSelfClosing = true),
      EnrichedChecklistSpan::class to
        TagInfo(
          tag = HtmlTags.CHECKLIST,
          isSelfClosing = false,
          attributes = { span -> (span as EnrichedChecklistSpan).getAttributes() },
        ),
      EnrichedAlignmentSpan::class to
        TagInfo(
          tag = "p",
          isSelfClosing = false,
          attributes = { span ->
            mapOf("alignment" to (span as EnrichedAlignmentSpan).alignmentString)
          },
        ),
      EnrichedContentSpan::class to
        TagInfo(
          tag = HtmlTags.CONTENT,
          isSelfClosing = true,
          attributes = { span ->
            val params = (span as EnrichedContentSpan).getAttributes()
            buildMap {
              put("text", params.text)
              put("type", params.type)
              put("src", params.src ?: "")
              putAll(params.attributes)
            }
          },
        ),
    )

  /**
   * Returns a *new copy* of TagInfo with resolved attributes (if any).
   */
  fun lookup(span: EnrichedParagraphSpan): TagInfo? {
    val base = registry[span::class] ?: return null
    return if (base.attributes != null) {
      base.copy(attributes = { base.attributes.invoke(span) })
    } else {
      base
    }
  }
}
