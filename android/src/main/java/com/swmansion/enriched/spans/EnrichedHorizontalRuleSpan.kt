package com.swmansion.enriched.spans

import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.drawable.Drawable
import android.text.style.ReplacementSpan
import android.util.Log
import androidx.core.graphics.withTranslation
import com.swmansion.enriched.spans.interfaces.EnrichedFullWidthSpan
import com.swmansion.enriched.spans.interfaces.EnrichedNonEditableParagraphSpan
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.styles.HtmlStyle

class EnrichedHorizontalRuleSpan(
  private val htmlStyle: HtmlStyle,
) : ReplacementSpan(),
  EnrichedNonEditableParagraphSpan,
  EnrichedFullWidthSpan {
  override val dependsOnHtmlStyle: Boolean = false

  private val drawable: Drawable = htmlStyle.getHorizontalRuleDrawable()

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedSpan = this

  override fun copyWithStyle(htmlStyle: HtmlStyle): EnrichedHorizontalRuleSpan = this

  override fun getSize(
    paint: Paint,
    text: CharSequence?,
    start: Int,
    end: Int,
    fontMetrics: Paint.FontMetricsInt?,
  ): Int {
    fontMetrics?.let {
      val height = htmlStyle.dividerHeight.toInt()
      it.ascent = -height
      it.descent = 0
      it.top = it.ascent
      it.bottom = 0
    }
    return htmlStyle.editorWidth
  }

  override fun draw(
    canvas: Canvas,
    text: CharSequence,
    start: Int,
    end: Int,
    x: Float,
    top: Int,
    y: Int,
    bottom: Int,
    paint: Paint,
  ) {
    val width = canvas.clipBounds.width()
    val drawableHeight = htmlStyle.dividerThickness.toInt()

    val lineHeight = bottom - top
    val drawableTop = top + (lineHeight - drawableHeight) / 2

    drawable.setBounds(
      0,
      0,
      width,
      drawableHeight,
    )

    canvas.withTranslation(x, drawableTop.toFloat()) {
      drawable.draw(this)
    }
  }
}
