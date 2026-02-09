package com.swmansion.enriched.spans

import com.swmansion.enriched.styles.HtmlStyle

class EnrichedH4Span(
  private val htmlStyle: HtmlStyle,
) : EnrichedHeadingSpan(htmlStyle.h4FontSize.toFloat(), htmlStyle.h4Bold) {
  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedHeadingSpan = EnrichedH4Span(htmlStyle)

  override fun copy() = EnrichedH4Span(htmlStyle)
}
