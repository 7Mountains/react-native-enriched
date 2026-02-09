package com.swmansion.enriched.spans

import android.text.TextPaint
import android.text.style.ClickableSpan
import android.view.View
import com.swmansion.enriched.spans.interfaces.EnrichedInlineSpan
import com.swmansion.enriched.styles.HtmlStyle

class EnrichedMentionSpan(
  private val text: String,
  private val indicator: String,
  private val type: String,
  private val attributes: Map<String, String>,
  private val htmlStyle: HtmlStyle,
) : ClickableSpan(),
  EnrichedInlineSpan {
  override val dependsOnHtmlStyle: Boolean = true

  override fun onClick(view: View) {
    // Do nothing. Mentions inside the input are not clickable.
    // We are using `ClickableSpan` to allow the text to be styled as a clickable element.
  }

  override fun updateDrawState(textPaint: TextPaint) {
    super.updateDrawState(textPaint)

    val mentionsStyle = htmlStyle.mentionsStyle[type] ?: return
    textPaint.color = mentionsStyle.color
    textPaint.bgColor = mentionsStyle.backgroundColor
    textPaint.isUnderlineText = mentionsStyle.underline
  }

  fun getAttributes(): Map<String, String> = attributes

  fun getText(): String = text

  fun getIndicator(): String = indicator

  fun getType(): String = type

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedMentionSpan =
    EnrichedMentionSpan(text, indicator, type, attributes, htmlStyle)

  override fun copy() = EnrichedMentionSpan(text = text, type = type, indicator = indicator, attributes = attributes, htmlStyle = htmlStyle)
}
