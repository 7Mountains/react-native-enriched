package com.swmansion.enriched.spans

import android.graphics.Canvas
import android.graphics.Paint
import android.text.style.ReplacementSpan
import androidx.core.graphics.withTranslation
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.drawables.BaseContentDrawable
import com.swmansion.enriched.drawables.ImageContentDrawable
import com.swmansion.enriched.drawables.LabelContentDrawable
import com.swmansion.enriched.spans.interfaces.EnrichedFullWidthSpan
import com.swmansion.enriched.spans.interfaces.EnrichedNonEditableParagraphSpan
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.styles.HtmlStyle
import java.lang.ref.WeakReference

data class ContentParams(
  val text: String,
  val type: String,
  val src: String?,
  val attributes: Map<String, String>,
)

class EnrichedContentSpan(
  private val contentParams: ContentParams,
  private val htmlStyle: HtmlStyle,
) : ReplacementSpan(),
  EnrichedNonEditableParagraphSpan,
  EnrichedFullWidthSpan {
  private var tvRef: WeakReference<EnrichedTextInputView>? = null

  fun attachTo(tv: EnrichedTextInputView) {
    tvRef = WeakReference(tv)
  }

  private fun invalidate() {
    val tv = tvRef?.get() ?: return
    tv.redrawSpan(this)
  }

  private val style = htmlStyle.contentStyle[contentParams.type]!!
  override val dependsOnHtmlStyle: Boolean = true

  private var internalDrawable: BaseContentDrawable? = null

  override fun copyWithStyle(htmlStyle: HtmlStyle): EnrichedContentSpan = this

  override fun copy() = this

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

  fun getAttributes() = contentParams

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedSpan = this

  private fun getOrCreateDrawable(): BaseContentDrawable {
    val existing = internalDrawable
    if (existing is BaseContentDrawable) return existing

    val src = contentParams.src

    val drawable =
      if (src != null) {
        ImageContentDrawable(style, contentParams.text, contentParams.src).apply {
          onContentLoadEnd = {
            invalidate()
          }
        }
      } else {
        LabelContentDrawable(style, contentParams.text)
      }

    internalDrawable = drawable

    return drawable
  }

  companion object {
    fun createEnrichedContentSpan(
      text: String,
      type: String,
      src: String?,
      attributes: Map<String, String>,
      htmlStyle: HtmlStyle,
    ): EnrichedContentSpan {
      val params = ContentParams(text, type, src, attributes)

      return EnrichedContentSpan(params, htmlStyle)
    }
  }
}
