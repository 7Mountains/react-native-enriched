package com.swmansion.enriched.spans

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.text.style.ReplacementSpan
import androidx.core.graphics.toColorInt
import androidx.core.graphics.withTranslation
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.drawables.MDFDrawable
import com.swmansion.enriched.spans.interfaces.EnrichedFullWidthSpan
import com.swmansion.enriched.spans.interfaces.EnrichedNonEditableParagraphSpan
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.styles.HtmlStyle
import java.lang.ref.WeakReference

class EnrichedMDFSpan(
  val mdfParams: MDFParams,
  val htmlStyle: HtmlStyle,
) : ReplacementSpan(),
  EnrichedNonEditableParagraphSpan,
  EnrichedFullWidthSpan {
  private var tvRef: WeakReference<EnrichedTextInputView>? = null

  override val dependsOnHtmlStyle: Boolean = true

  private var internalDrawable: MDFDrawable? = null

  fun attachTo(tv: EnrichedTextInputView) {
    tvRef = WeakReference(tv)
  }

  private fun invalidate() {
    val tv = tvRef?.get() ?: return
    tv.redrawSpan(this)
  }

  override fun copyWithStyle(htmlStyle: HtmlStyle): EnrichedMDFSpan = EnrichedMDFSpan(mdfParams, htmlStyle)

  override fun copy(): EnrichedMDFSpan = this

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedSpan = copyWithStyle(htmlStyle)

  override fun getSize(
    paint: Paint,
    text: CharSequence?,
    start: Int,
    end: Int,
    fm: Paint.FontMetricsInt?,
  ): Int {
    val drawable = getOrCreateDrawable()

    val height = drawable.measureHeight()

    fm?.let {
      it.ascent = -height
      it.descent = 0
      it.top = it.ascent
      it.bottom = 0
    }
    val width = htmlStyle.editorWidth

    drawable.setBounds(0, 0, width, height)

    return width
  }

  override fun draw(
    canvas: Canvas,
    text: CharSequence?,
    start: Int,
    end: Int,
    x: Float,
    top: Int,
    y: Int,
    bottom: Int,
    paint: Paint,
  ) {
    val drawable = getOrCreateDrawable()

    val height = drawable.measureHeight()

    val centerY = top + (bottom - top - height) / 2f

    canvas.withTranslation(x, centerY) {
      drawable.draw(this)
    }
  }

  private fun getOrCreateDrawable(): MDFDrawable {
    internalDrawable?.let { return it }

    val style = htmlStyle.mdf

    val drawable =
      MDFDrawable(mdfParams, style).apply {
        onImageLoaded = {
          invalidate()
        }
      }

    internalDrawable = drawable

    return drawable
  }

  companion object {
    data class MDFParams(
      val label: String,
      val id: String,
      val tintColor: Int,
    )

    fun createMDFSpan(
      label: String,
      id: String,
      tintColor: String,
      htmlStyle: HtmlStyle,
    ): EnrichedMDFSpan {
      val color =
        try {
          tintColor.toColorInt()
        } catch (_: Exception) {
          Color.GRAY
        }

      val params = MDFParams(label, id, color)

      return EnrichedMDFSpan(params, htmlStyle)
    }
  }
}
