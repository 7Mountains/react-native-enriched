package com.swmansion.enriched.text

import android.graphics.Paint
import android.os.Build
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import android.widget.TextView

/**
 * The line breaking of `EnrichedTextView`, set on the view and on the layout
 * it's measured with, so the text is broken into the same lines.
 *
 * Simple (greedy) breaking: a text measured at its widest line breaks the
 * same way in a view of exactly that width. The high quality breaking
 * balances the lines, so it can break differently in the narrower view, and
 * the text no longer fits the measured box.
 */
internal object EnrichedTextLayout {
  const val BREAK_STRATEGY = Layout.BREAK_STRATEGY_SIMPLE
  const val HYPHENATION_FREQUENCY = Layout.HYPHENATION_FREQUENCY_NONE
  const val INCLUDE_FONT_PADDING = true

  fun applyTo(view: TextView) {
    view.breakStrategy = BREAK_STRATEGY
    view.hyphenationFrequency = HYPHENATION_FREQUENCY
    view.includeFontPadding = INCLUDE_FONT_PADDING
    view.setLineSpacing(0f, 1f)
  }

  fun createPaint(
    params: EnrichedTextParams,
    typeface: android.graphics.Typeface,
  ): TextPaint =
    TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
      this.typeface = typeface
      textSize = params.fontSizePx
    }

  fun build(
    text: CharSequence,
    paint: TextPaint,
    width: Int,
    params: EnrichedTextParams,
  ): StaticLayout {
    val builder =
      StaticLayout.Builder
        .obtain(text, 0, text.length, paint, width.coerceAtLeast(0))
        .setAlignment(Layout.Alignment.ALIGN_NORMAL)
        .setIncludePad(INCLUDE_FONT_PADDING)
        .setLineSpacing(0f, 1f)
        .setBreakStrategy(BREAK_STRATEGY)
        .setHyphenationFrequency(HYPHENATION_FREQUENCY)

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
      builder.setUseLineSpacingFromFallbacks(true)
    }

    if (params.numberOfLines > 0) {
      builder.setMaxLines(params.numberOfLines).setEllipsize(params.ellipsize)
    }

    return builder.build()
  }
}
