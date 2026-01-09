package com.swmansion.enriched.spans.interfaces

import com.swmansion.enriched.styles.HtmlStyle

interface EnrichedFullWidthSpan {
  fun copyWithStyle(htmlStyle: HtmlStyle): EnrichedSpan
}
