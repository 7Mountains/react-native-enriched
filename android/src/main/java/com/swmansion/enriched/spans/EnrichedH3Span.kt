package com.swmansion.enriched.spans

import com.swmansion.enriched.styles.HtmlStyle

class EnrichedH3Span(
  private val htmlStyle: HtmlStyle,
) : EnrichedHeadingSpan(htmlStyle.h3FontSize.toFloat(), htmlStyle.h3Bold) {
  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedHeadingSpan = EnrichedH3Span(htmlStyle)

  override fun copy() = EnrichedH3Span(htmlStyle)
}
