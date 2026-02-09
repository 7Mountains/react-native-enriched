package com.swmansion.enriched.spans

import com.swmansion.enriched.styles.HtmlStyle

class EnrichedH1Span(
  private val style: HtmlStyle,
) : EnrichedHeadingSpan(style.h1FontSize.toFloat(), style.h1Bold) {
  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedH1Span = EnrichedH1Span(htmlStyle)

  override fun copy() = EnrichedH1Span(style)
}
