package com.swmansion.enriched.spans

import android.text.style.StrikethroughSpan
import com.swmansion.enriched.spans.interfaces.EnrichedInlineSpan
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.styles.HtmlStyle

class EnrichedStrikeThroughSpan :
  StrikethroughSpan(),
  EnrichedInlineSpan {
  override val dependsOnHtmlStyle: Boolean = false

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedStrikeThroughSpan = EnrichedStrikeThroughSpan()

  override fun copy(): EnrichedStrikeThroughSpan = EnrichedStrikeThroughSpan()
}
