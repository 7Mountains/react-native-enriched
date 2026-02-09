package com.swmansion.enriched.spans

import com.swmansion.enriched.styles.HtmlStyle

class EnrichedH6Span(
  private val htmlStyle: HtmlStyle,
) : EnrichedHeadingSpan(htmlStyle.h6FontSize.toFloat(), htmlStyle.h6Bold) {
  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedHeadingSpan = EnrichedH6Span(htmlStyle)

  override fun copy() = EnrichedH6Span(htmlStyle)
}
