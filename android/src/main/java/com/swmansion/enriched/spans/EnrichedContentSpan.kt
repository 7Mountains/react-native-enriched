package com.swmansion.enriched.spans

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.text.style.ReplacementSpan
import androidx.core.graphics.drawable.toBitmap
import androidx.core.graphics.withTranslation
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.R
import com.swmansion.enriched.drawables.ImageLabelRenderer
import com.swmansion.enriched.loaders.EnrichedImageLoader
import com.swmansion.enriched.spans.interfaces.EnrichedFullWidthSpan
import com.swmansion.enriched.spans.interfaces.EnrichedNonEditableParagraphSpan
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.styles.ContentStyle
import com.swmansion.enriched.styles.HtmlStyle
import com.swmansion.enriched.utils.ResourceManager
import java.lang.ref.WeakReference

class EnrichedContentSpan(
  private val contentParams: ContentParams,
  private val htmlStyle: HtmlStyle,
) : ReplacementSpan(),
  EnrichedNonEditableParagraphSpan,
  EnrichedFullWidthSpan {
  private var hasRequestedImage = false

  private var tvRef: WeakReference<EnrichedTextInputView>? = null

  private val style = htmlStyle.contentStyle[contentParams.type] ?: ContentStyle.default()

  private var renderer: ImageLabelRenderer? = null
  private var bitmap: Bitmap? = ResourceManager.getDrawableResource(R.drawable.loader_placeholder).toBitmap(40, 40)
  private var measuredHeight = 0

  override val dependsOnHtmlStyle: Boolean = true

  override fun copyWithStyle(htmlStyle: HtmlStyle): EnrichedContentSpan = this

  override fun copy() = this

  fun attachTo(tv: EnrichedTextInputView) {
    tvRef = WeakReference(tv)
  }

  private fun invalidate() {
    val tv = tvRef?.get() ?: return
    renderer = null
    tv.redrawSpan(this)
  }

  private fun getOrCreateRenderer(): ImageLabelRenderer {
    renderer?.let { return it }

    val renderer =
      ImageLabelRenderer(
        contentStyle = style,
        title = contentParams.title,
        description = contentParams.description,
        subTitle = contentParams.subtitle,
        subDescription = contentParams.subDescription,
        bitmap = bitmap,
      )

    this.renderer = renderer

    loadImage()

    return renderer
  }

  private fun loadImage() {
    if (hasRequestedImage) return
    hasRequestedImage = true

    val uri = contentParams.src
    println("loadImage src=$uri")

    if (uri.isNullOrEmpty()) {
      println("src empty -> fallback")
      loadFallbackImage()
      return
    }

    EnrichedImageLoader.instance.load(uri) { bmp ->
      println("main load result = ${bmp != null}")
      if (bmp != null) {
        updateBitmap(bmp)
      } else {
        println("main load failed -> fallback")
        loadFallbackImage()
      }
    }
  }

  private fun loadFallbackImage() {
    val uri = style.fallbackImageURI
    println("loadFallbackImage uri=$uri")

    EnrichedImageLoader.instance.load(uri) { bmp ->
      println("fallback result = ${bmp != null}")
      if (bmp != null) {
        updateBitmap(bmp)
      }
    }
  }

  private fun updateBitmap(bitmap: Bitmap) {
    this.bitmap = bitmap
    renderer = null
    invalidate()
  }

  override fun getSize(
    paint: Paint,
    text: CharSequence?,
    start: Int,
    end: Int,
    fm: Paint.FontMetricsInt?,
  ): Int {
    val margin = style.container.margin

    val marginHorizontal = (margin.left + margin.right)
    val marginVertical = (margin.top + margin.bottom)

    val contentWidth = htmlStyle.editorWidth - marginHorizontal

    val renderer = getOrCreateRenderer()
    val contentHeight = renderer.measure(contentWidth.toInt())

    val finalHeight = contentHeight + marginVertical

    measuredHeight = finalHeight.toInt()

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
    val style = htmlStyle.contentStyle[contentParams.type] ?: ContentStyle.default()
    val margin = style.container.margin

    val marginLeft = margin.left
    val marginTop = margin.top
    val marginRight = margin.right
    val marginBottom = margin.bottom

    val contentWidth = htmlStyle.editorWidth - (marginLeft + marginRight)
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

  fun getAttributes() = contentParams

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedSpan = this

  companion object {
    fun createEnrichedContentSpan(
      title: String,
      description: String?,
      subtitle: String?,
      subDescription: String?,
      type: String,
      src: String?,
      attributes: Map<String, String>?,
      htmlStyle: HtmlStyle,
    ): EnrichedContentSpan {
      val params = ContentParams(title, description, subtitle, subDescription, type, src, attributes)

      return EnrichedContentSpan(params, htmlStyle)
    }

    data class ContentParams(
      val title: String,
      val description: String?,
      val subtitle: String?,
      val subDescription: String?,
      val type: String,
      val src: String?,
      val attributes: Map<String, String>?,
    )
  }
}
