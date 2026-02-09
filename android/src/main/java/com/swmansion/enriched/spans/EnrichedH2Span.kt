package com.swmansion.enriched.spans

import com.swmansion.enriched.styles.HtmlStyle

class EnrichedH2Span(
  private val htmlStyle: HtmlStyle,
) : EnrichedHeadingSpan(htmlStyle.h2FontSize.toFloat(), htmlStyle.h2Bold) {
  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedHeadingSpan = EnrichedH2Span(htmlStyle)

  override fun copy() = EnrichedH2Span(htmlStyle)
}
