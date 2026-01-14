package com.swmansion.enriched.spans

import android.graphics.Typeface
import android.text.style.StyleSpan
import com.swmansion.enriched.spans.interfaces.EnrichedBlockSpan
import com.swmansion.enriched.spans.interfaces.EnrichedInlineSpan
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.styles.HtmlStyle

class EnrichedBoldSpan :
  StyleSpan(Typeface.BOLD),
  EnrichedInlineSpan {
  override val dependsOnHtmlStyle: Boolean = false

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedBoldSpan = EnrichedBoldSpan()

  override fun copy(): EnrichedBoldSpan = EnrichedBoldSpan()
}
