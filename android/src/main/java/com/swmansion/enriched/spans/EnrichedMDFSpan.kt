package com.swmansion.enriched.spans

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.text.style.ReplacementSpan
import androidx.core.graphics.toColorInt
import androidx.core.graphics.withTranslation
import com.swmansion.enriched.EnrichedHtmlHost
import com.swmansion.enriched.drawables.ImageLabelRenderer
import com.swmansion.enriched.loaders.EnrichedImageLoader
import com.swmansion.enriched.spans.interfaces.EnrichedFullWidthSpan
import com.swmansion.enriched.spans.interfaces.EnrichedHostBoundSpan
import com.swmansion.enriched.spans.interfaces.EnrichedNonEditableParagraphSpan
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.styles.HtmlStyle
import java.lang.ref.WeakReference

class EnrichedMDFSpan(
  val mdfParams: MDFParams,
  val htmlStyle: HtmlStyle,
) : ReplacementSpan(),
  EnrichedNonEditableParagraphSpan,
  EnrichedFullWidthSpan,
  EnrichedHostBoundSpan {
  @Volatile
  private var tvRef: WeakReference<EnrichedHtmlHost>? = null

  override val dependsOnHtmlStyle: Boolean = true

  // Drawn by the view (on its thread), which loads the image
  private var renderer: ImageLabelRenderer? = null
  private var bitmap: Bitmap? = null
  private var hasRequestedImage = false

  @Volatile
  private var measured: MeasuredHeight? = null

  override fun attachTo(host: EnrichedHtmlHost) {
    tvRef = WeakReference(host)
  }

  private fun invalidate() {
    val tv = tvRef?.get() ?: return
    renderer = null
    tv.redrawSpan(this)
  }

  override fun copyWithStyle(htmlStyle: HtmlStyle): EnrichedMDFSpan = this

  override fun copy(): EnrichedMDFSpan = this

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedSpan = copyWithStyle(htmlStyle)

  private fun createRenderer(bitmap: Bitmap?) =
    ImageLabelRenderer(
      contentStyle = htmlStyle.mdf,
      title = mdfParams.label,
      description = null,
      bitmap = bitmap,
      imageBackgroundColor = mdfParams.tintColor,
      borderLeftColor = mdfParams.tintColor,
    )

  private fun getOrCreateRenderer(): ImageLabelRenderer {
    val existing = renderer
    if (existing != null) return existing

    val style = htmlStyle.mdf

    val renderer = createRenderer(bitmap)

    this.renderer = renderer

    if (!hasRequestedImage) {
      hasRequestedImage = true
      style.imageUri?.let { uri ->
        EnrichedImageLoader.instance.load(uri) { bmp ->
          if (bmp != null) {
            bitmap = bmp
            this.renderer = null
            invalidate()
          }
        }
      }
    }

    return renderer
  }

  // Laid out by the measurement on its thread too, while the view draws it: the
  // height is measured without the renderer of the view
  private fun measureHeight(width: Int): Int {
    measured?.takeIf { it.width == width }?.let { return it.height }

    val margin = htmlStyle.mdf.container.margin
    val contentWidth = width - (margin.left + margin.right)
    val contentHeight = createRenderer(bitmap = null).measure(contentWidth.toInt())
    val height = (contentHeight + margin.top + margin.bottom).toInt()

    measured = MeasuredHeight(width, height)
    return height
  }

  override fun getSize(
    paint: Paint,
    text: CharSequence?,
    start: Int,
    end: Int,
    fm: Paint.FontMetricsInt?,
  ): Int {
    val measuredHeight = measureHeight(htmlStyle.editorWidth)

    fm?.let {
      it.ascent = -measuredHeight
      it.descent = 0
      it.top = it.ascent
      it.bottom = 0
    }

    return htmlStyle.editorWidth
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
    val style = htmlStyle.mdf
    val margin = style.container.margin

    val marginLeft = margin.left
    val marginTop = margin.top
    val marginRight = margin.right
    val marginBottom = margin.bottom

    val contentWidth = htmlStyle.editorWidth - (marginLeft + marginRight)
    val measuredHeight = measureHeight(htmlStyle.editorWidth)
    val contentHeight = measuredHeight - (marginTop + marginBottom)

    val renderer = getOrCreateRenderer()

    val centerY = top + (bottom - top - measuredHeight) / 2f

    canvas.withTranslation(x + marginLeft, centerY + marginTop) {
      renderer.draw(
        this,
        contentWidth.toInt(),
        contentHeight.toInt(),
      )
    }
  }

  companion object {
    private class MeasuredHeight(
      val width: Int,
      val height: Int,
    )

    data class MDFParams(
      val label: String,
      val tintColor: Int,
      val attributes: Map<String, String>?,
    )

    fun createMDFSpan(
      label: String,
      tintColor: String,
      attributes: Map<String, String>?,
      htmlStyle: HtmlStyle,
    ): EnrichedMDFSpan {
      val color =
        try {
          tintColor.toColorInt()
        } catch (_: Exception) {
          Color.GRAY
        }

      val params = MDFParams(label, color, attributes)

      return EnrichedMDFSpan(params, htmlStyle)
    }
  }
}
