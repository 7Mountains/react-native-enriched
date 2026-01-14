package com.swmansion.enriched.spans

import android.text.style.UnderlineSpan
import com.swmansion.enriched.spans.interfaces.EnrichedInlineSpan
import com.swmansion.enriched.styles.HtmlStyle

class EnrichedUnderlineSpan :
  UnderlineSpan(),
  EnrichedInlineSpan {
  override val dependsOnHtmlStyle: Boolean = false

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedUnderlineSpan = EnrichedUnderlineSpan()

  override fun copy(): EnrichedUnderlineSpan = EnrichedUnderlineSpan()
}
