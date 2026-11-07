package com.swmansion.enriched.text

import android.content.Context
import com.swmansion.enriched.EnrichedHtmlHost
import com.swmansion.enriched.spans.interfaces.EnrichedSpan

/** The host of HTML parsed outside of a view, e.g. for a measurement */
internal class DetachedHtmlHost(
  override val hostContext: Context,
  override val editorWidth: Int,
  override val fontSize: Float?,
) : EnrichedHtmlHost {
  override fun redrawSpan(span: EnrichedSpan) = Unit
}
