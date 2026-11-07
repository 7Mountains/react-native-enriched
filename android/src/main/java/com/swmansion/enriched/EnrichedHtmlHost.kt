package com.swmansion.enriched

import android.content.Context
import com.swmansion.enriched.spans.interfaces.EnrichedSpan

/**
 * A view showing parsed HTML (the input or the read-only text): what the html
 * style and the spans read from the view they're shown in.
 */
interface EnrichedHtmlHost {
  val hostContext: Context

  /** The width the full-width spans (e.g. the horizontal rule) take */
  val editorWidth: Int

  /** The font size in pixels, `null` when not set */
  val fontSize: Float?

  /** Redraws a span whose visual content changed without changing its geometry. */
  fun redrawSpan(span: EnrichedSpan)
}
