package com.swmansion.enriched.spans

import android.text.Layout
import android.text.style.AlignmentSpan
import com.swmansion.enriched.spans.interfaces.EnrichedParagraphSpan
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.styles.HtmlStyle
import com.swmansion.enriched.utils.toAlignment
import com.swmansion.enriched.utils.toStringName

class EnrichedAlignmentSpan(
  val alignmentString: String?,
) : EnrichedParagraphSpan,
  AlignmentSpan {
  private val alignment: Layout.Alignment = alignmentString?.toAlignment() ?: Layout.Alignment.ALIGN_NORMAL

  constructor() : this("default")

  constructor(alignment: Layout.Alignment) : this(alignment.toStringName())

  override val dependsOnHtmlStyle: Boolean = false

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedAlignmentSpan = this

  override fun getAlignment(): Layout.Alignment = alignment

  override fun copy(): EnrichedSpan = EnrichedAlignmentSpan(alignmentString = alignmentString)
}
