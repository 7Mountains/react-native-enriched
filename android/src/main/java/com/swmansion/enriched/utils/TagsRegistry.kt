package com.swmansion.enriched.utils

import com.swmansion.enriched.spans.EnrichedChecklistSpan
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
      EnrichedUnorderedListSpan::class to TagInfo("ul"),
      EnrichedOrderedListSpan::class to TagInfo("ol"),
      EnrichedH1Span::class to TagInfo("h1"),
      EnrichedH2Span::class to TagInfo("h2"),
      EnrichedH3Span::class to TagInfo("h3"),
      EnrichedH4Span::class to TagInfo("h4"),
      EnrichedH5Span::class to TagInfo("h5"),
      EnrichedH6Span::class to TagInfo("h6"),
      EnrichedHorizontalRuleSpan::class to TagInfo("hr", isSelfClosing = true),
      EnrichedChecklistSpan::class to
        TagInfo(
          tag = "checklist",
          isSelfClosing = false,
          attributes = { span -> (span as EnrichedChecklistSpan).getAttributes() },
        ),
      EnrichedContentSpan::class to
        TagInfo(
          tag = "content",
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
