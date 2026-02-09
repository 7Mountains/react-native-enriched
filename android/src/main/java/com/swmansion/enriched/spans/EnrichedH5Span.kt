package com.swmansion.enriched.spans

import com.swmansion.enriched.styles.HtmlStyle

class EnrichedH5Span(
  private val htmlStyle: HtmlStyle,
) : EnrichedHeadingSpan(htmlStyle.h5FontSize.toFloat(), htmlStyle.h5Bold) {
  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedHeadingSpan = EnrichedH5Span(htmlStyle)

  override fun copy() = EnrichedH5Span(htmlStyle)
}
