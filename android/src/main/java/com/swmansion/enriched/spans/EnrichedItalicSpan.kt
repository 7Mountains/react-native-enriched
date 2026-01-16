package com.swmansion.enriched.spans

import android.graphics.Typeface
import android.text.style.StyleSpan
import com.swmansion.enriched.spans.interfaces.EnrichedInlineSpan
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.styles.HtmlStyle

class EnrichedItalicSpan :
  StyleSpan(Typeface.ITALIC),
  EnrichedInlineSpan {
  override val dependsOnHtmlStyle: Boolean = false

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedItalicSpan = EnrichedItalicSpan()

  override fun copy(): EnrichedItalicSpan = EnrichedItalicSpan()
}
