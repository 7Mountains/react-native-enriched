package com.swmansion.enriched.text

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.CornerPathEffect
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.text.Layout
import android.text.Spanned
import android.text.TextPaint
import android.text.style.ClickableSpan
import android.util.TypedValue
import android.view.MotionEvent
import android.view.ViewConfiguration
import androidx.appcompat.widget.AppCompatTextView
import androidx.core.graphics.ColorUtils
import androidx.core.graphics.withTranslation
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.PixelUtil
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.NativeGestureUtil
import com.facebook.react.views.text.ReactTypefaceUtils
import com.swmansion.enriched.EnrichedHtmlHost
import com.swmansion.enriched.spans.EnrichedImageSpan
import com.swmansion.enriched.spans.EnrichedLinkSpan
import com.swmansion.enriched.spans.EnrichedMentionSpan
import com.swmansion.enriched.spans.interfaces.EnrichedFullWidthSpan
import com.swmansion.enriched.spans.interfaces.EnrichedHostBoundSpan
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.text.events.EnrichedTextSpanPressEvent
import com.swmansion.enriched.text.events.SpanPressPhase
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

/**
 * Shows the HTML of `EnrichedTextInput` (read-only), with the input's spans.
 * The text is built and laid out as by `EnrichedTextMeasurement`, so the view
 * draws exactly what was measured.
 */
@SuppressLint("ViewConstructor")
class EnrichedTextView(
  context: Context,
) : AppCompatTextView(context),
  EnrichedHtmlHost {
  private var params = EnrichedTextParams()
  private var preparedText: CharSequence? = null
  private var isContentDirty = true
  private var pressedSpan: ClickableSpan? = null
  private var isTrackingPress = false
  private var isLongPressed = false
  private var isOwningGesture = false
  private var pressDownX = 0f
  private var pressDownY = 0f
  private val touchSlop = ViewConfiguration.get(context).scaledTouchSlop
  private val pressPath = Path()
  private val hitPath = Path()
  private val hitBounds = RectF()
  private val pressPaint = TextPaint(Paint.ANTI_ALIAS_FLAG)
  private val pressCorners = CornerPathEffect(PixelUtil.toPixelFromDIP(PRESSED_CORNER_RADIUS))
  private val defaultHighlightColor = highlightColor
  private val longPressRunnable = Runnable { longPressSpan() }

  // Set from the handlers given in JS: a span without them leaves the touches
  // to the views below
  var pressableLinks = false
  var pressableMentions = false
  var longPressableLinks = false
  var longPressableMentions = false

  override val hostContext: Context
    get() = context

  override var editorWidth: Int = 0
    private set

  override val fontSize: Float
    get() = textSize

  init {
    setPadding(0, 0, 0, 0)
    EnrichedTextLayout.applyTo(this)
    setTextColor(Color.BLACK)
  }

  fun setValue(text: String?) = update { copy(text = text ?: "") }

  fun setHtmlStyle(style: ReadableMap?) = update { copy(htmlStyle = style) }

  fun setFontSize(size: Float) = update { copy(fontSize = size) }

  fun setLineHeightValue(height: Float) = update { copy(lineHeight = height) }

  fun setFontFamily(family: String?) = update { copy(fontFamily = family?.takeIf { it.isNotEmpty() }) }

  fun setFontWeight(weight: String?) = update { copy(fontWeight = ReactTypefaceUtils.parseFontWeight(weight?.takeIf { it.isNotEmpty() })) }

  fun setFontStyle(style: String?) = update { copy(fontStyle = ReactTypefaceUtils.parseFontStyle(style?.takeIf { it.isNotEmpty() })) }

  fun setAllowFontScaling(allow: Boolean) = update { copy(allowFontScaling = allow) }

  fun setNumberOfLines(lines: Int) = update { copy(numberOfLines = lines) }

  fun setEllipsizeMode(mode: String?) = update { copy(ellipsizeMode = mode) }

  fun setColor(color: Int?) {
    setTextColor(color ?: Color.BLACK)
  }

  fun setSelectionColor(color: Int?) {
    if (color != null) highlightColor = color
  }

  /**
   * Shows the text built by the measurement, from the state of the shadow
   * node: it comes with every change of the props the text depends on, after
   * the props
   *
   * @param text The text, `null` for a text the view builds (e.g. with images)
   */
  fun setPreparedText(text: CharSequence?) {
    preparedText = text
    isContentDirty = true
    applyUpdates()
  }

  private fun applyUpdates() {
    if (!isContentDirty) return
    isContentDirty = false

    typeface = params.typeface(context.assets)
    // Before the text is built: the html style reads the font size (e.g. the
    // margin of the ordered lists)
    setTextSize(TypedValue.COMPLEX_UNIT_PX, params.fontSizePx)
    maxLines = if (params.numberOfLines > 0) params.numberOfLines else Int.MAX_VALUE
    ellipsize = if (params.numberOfLines > 0) params.ellipsize else null

    detachImageSpans()

    // NORMAL: the prepared text is immutable, laid out by a StaticLayout (a
    // spannable one gets a DynamicLayout watching its spans). Selectable, the
    // TextView shows a copy it can select
    setText(preparedText ?: EnrichedTextContent.build(params, this), BufferType.NORMAL)

    attachSpans()
  }

  /** Resets the view for another text, as a new one */
  fun prepareForRecycle() {
    detachImageSpans()

    params = EnrichedTextParams()
    preparedText = null
    isContentDirty = true
    removeCallbacks(longPressRunnable)
    pressedSpan = null
    isTrackingPress = false
    isLongPressed = false
    isOwningGesture = false
    pressableLinks = false
    pressableMentions = false
    longPressableLinks = false
    longPressableMentions = false
    editorWidth = 0

    setText("", BufferType.NORMAL)
    setTextColor(Color.BLACK)
    highlightColor = defaultHighlightColor
    setPadding(0, 0, 0, 0)

    setSelectable(false)
  }

  private inline fun update(change: EnrichedTextParams.() -> EnrichedTextParams) {
    val next = params.change()

    if (next != params) {
      params = next
      isContentDirty = true
    }
  }

  override fun onSizeChanged(
    width: Int,
    height: Int,
    oldWidth: Int,
    oldHeight: Int,
  ) {
    super.onSizeChanged(width, height, oldWidth, oldHeight)

    val contentWidth = width - totalPaddingLeft - totalPaddingRight
    if (contentWidth == editorWidth) return

    editorWidth = contentWidth

    // A text the view builds: its full-width spans (e.g. the horizontal rule)
    // take the new width. A prepared one comes for the width, with the state
    if (preparedText != null) return

    val content = text as? Spanned ?: return
    if (content.getSpans(0, content.length, EnrichedFullWidthSpan::class.java).isNotEmpty()) {
      isContentDirty = true
      post { applyUpdates() }
    }
  }

  // These spans keep their size when their visual content changes, so a redraw
  // is enough and preserves the current text layout and selection.
  override fun redrawSpan(span: EnrichedSpan) {
    post {
      if (containsSpan(span)) invalidate()
    }
  }

  // The spans redrawn once their images load: the ones of a prepared text
  // were built for a host without a view
  private fun attachSpans() {
    val content = text as? Spanned ?: return

    content.getSpans(0, content.length, EnrichedImageSpan::class.java).forEach { span ->
      span.observeAsyncDrawableLoaded {
        redrawSpan(span)
      }
    }
    content.getSpans(0, content.length, EnrichedHostBoundSpan::class.java).forEach { it.attachTo(this) }
  }

  private fun detachImageSpans() {
    val content = text as? Spanned ?: return
    content.getSpans(0, content.length, EnrichedImageSpan::class.java).forEach {
      it.stopObservingAsyncDrawableLoaded()
    }
  }

  private fun containsSpan(span: Any): Boolean = (text as? Spanned)?.getSpanStart(span)?.let { it != -1 } ?: false

  /** Selectable: the text can be selected, its links and mentions still pressed */
  fun setSelectable(selectable: Boolean) {
    // Setting it lays the text out again, even when it doesn't change
    if (isTextSelectable == selectable) return

    setTextIsSelectable(selectable)

    if (selectable) {
      movementMethod = EnrichedTextMovementMethod
    }
  }

  // Not selectable: only the links and the mentions take the touches, the
  // others go to the views below (e.g. a pressable message). Selectable: the
  // movement method takes them
  @SuppressLint("ClickableViewAccessibility")
  override fun onTouchEvent(event: MotionEvent): Boolean {
    if (!isTextSelectable && handleSpanPress(event)) return true

    return super.onTouchEvent(event)
  }

  /**
   * Tracks a press on a link or a mention: press in on the touch, press out
   * once released or moved away, press when released on it, or long press
   * when held.
   *
   * The view owns the touch on a span from its start: the gesture handlers
   * and the JS responders of the views below (e.g. a pressable message) are
   * cancelled, so a press on a link isn't a press on the message too.
   *
   * @return Whether the touch belongs to a press on a span
   */
  internal fun handleSpanPress(event: MotionEvent): Boolean {
    when (event.actionMasked) {
      MotionEvent.ACTION_DOWN -> {
        val span = findPressableSpan(event) ?: return false

        isTrackingPress = true
        isLongPressed = false
        pressDownX = event.x
        pressDownY = event.y
        pressedSpan = span
        ownGesture(event)

        if (isLongPressable(span)) {
          postDelayed(longPressRunnable, ViewConfiguration.getLongPressTimeout().toLong())
        }

        dispatchSpanPress(span, SpanPressPhase.PRESS_IN)
        invalidate()
        return true
      }

      MotionEvent.ACTION_MOVE -> {
        if (!isTrackingPress) return false

        val span = pressedSpan
        val hasMoved = abs(event.x - pressDownX) > touchSlop || abs(event.y - pressDownY) > touchSlop

        // Moved away: the touch is a scroll, e.g. of the list
        if (span != null && (hasMoved || findPressableSpan(event) !== span)) {
          parent?.requestDisallowInterceptTouchEvent(false)
          cancelPress()
        }
        return true
      }

      MotionEvent.ACTION_UP -> {
        endGesture(event)
        if (!isTrackingPress) return false

        isTrackingPress = false
        val span = pressedSpan
        val wasLongPressed = isLongPressed
        cancelPress()

        if (span != null && !wasLongPressed && findPressableSpan(event) === span) {
          dispatchSpanPress(span, SpanPressPhase.PRESS)
        }
        return true
      }

      MotionEvent.ACTION_CANCEL -> {
        endGesture(event)
        if (!isTrackingPress) return false

        isTrackingPress = false
        cancelPress()
        return true
      }
    }

    return isTrackingPress
  }

  // Selectable: a long press on a span with a long press handler is that
  // handler's, on the others it selects the text
  override fun performLongClick(): Boolean {
    val span = pressedSpan

    if (isTrackingPress && span != null) {
      if (isLongPressable(span)) return true

      isTrackingPress = false
      cancelPress()
    }

    return super.performLongClick()
  }

  override fun onDetachedFromWindow() {
    super.onDetachedFromWindow()
    removeCallbacks(longPressRunnable)
  }

  private fun ownGesture(event: MotionEvent) {
    parent?.requestDisallowInterceptTouchEvent(true)
    NativeGestureUtil.notifyNativeGestureStarted(this, event)
    isOwningGesture = true
  }

  private fun endGesture(event: MotionEvent) {
    if (!isOwningGesture) return

    isOwningGesture = false
    NativeGestureUtil.notifyNativeGestureEnded(this, event)
  }

  private fun longPressSpan() {
    val span = pressedSpan ?: return

    isLongPressed = true
    dispatchSpanPress(span, SpanPressPhase.LONG_PRESS)
  }

  private fun cancelPress() {
    removeCallbacks(longPressRunnable)

    val span = pressedSpan ?: return

    pressedSpan = null
    dispatchSpanPress(span, SpanPressPhase.PRESS_OUT)
    invalidate()
  }

  private fun isPressable(span: ClickableSpan): Boolean =
    when (span) {
      is EnrichedLinkSpan -> pressableLinks
      is EnrichedMentionSpan -> pressableMentions
      else -> false
    }

  /** Handles a ClickableSpan activated without a touch, e.g. by TalkBack. */
  internal fun performSpanClick(span: ClickableSpan) {
    if (isPressable(span)) {
      dispatchSpanPress(span, SpanPressPhase.PRESS)
    }
  }

  private fun isLongPressable(span: ClickableSpan): Boolean =
    when (span) {
      is EnrichedLinkSpan -> longPressableLinks
      is EnrichedMentionSpan -> longPressableMentions
      else -> false
    }

  private fun findPressableSpan(event: MotionEvent): ClickableSpan? {
    val textLayout = layout ?: return null
    val content = text as? Spanned ?: return null

    val x = event.x - totalPaddingLeft + scrollX
    val y = event.y - totalPaddingTop + scrollY

    if (y < 0 || y > textLayout.height) return null

    val line = textLayout.getLineForVertical(y.toInt())
    val lineLeft: Float
    val lineRight: Float

    if (textLayout.alignment == Layout.Alignment.ALIGN_CENTER) {
      lineLeft = textLayout.getLineLeft(line)
      lineRight = textLayout.getLineRight(line)
    } else {
      // getLineLeft/Right don't account for paragraph margins here
      val isRtl = textLayout.getParagraphDirection(line) == Layout.DIR_RIGHT_TO_LEFT
      lineLeft = if (isRtl) textLayout.width - textLayout.getLineMax(line) else textLayout.getParagraphLeft(line).toFloat()
      lineRight = if (isRtl) textLayout.getParagraphRight(line).toFloat() else textLayout.getLineMax(line)
    }

    if (x < lineLeft || x > lineRight) return null

    // Android 7-8 can throw for bidi text (see React Native's text hit testing)
    val offset =
      try {
        textLayout.getOffsetForHorizontal(line, x)
      } catch (_: ArrayIndexOutOfBoundsException) {
        return null
      }

    return content
      .getSpans(offset, offset, ClickableSpan::class.java)
      .firstOrNull { isPressable(it) && isOnSpan(it, content, textLayout, line, x) }
  }

  // The offset nearest to the touch also finds the spans ending or starting
  // there, up to half a character away: the touch has to be on the span's
  // text on the line, the area that is highlighted
  private fun isOnSpan(
    span: ClickableSpan,
    content: Spanned,
    textLayout: Layout,
    line: Int,
    x: Float,
  ): Boolean {
    val start = max(content.getSpanStart(span), textLayout.getLineStart(line))
    val end = min(content.getSpanEnd(span), textLayout.getLineEnd(line))

    if (start >= end) return false

    hitPath.reset()
    textLayout.getSelectionPath(start, end, hitPath)
    hitPath.computeBounds(hitBounds, true)

    return x >= hitBounds.left && x <= hitBounds.right
  }

  private fun dispatchSpanPress(
    span: ClickableSpan,
    phase: SpanPressPhase,
  ) {
    val reactContext = context as? ReactContext ?: return
    val surfaceId = UIManagerHelper.getSurfaceId(reactContext)

    val event =
      when (span) {
        is EnrichedLinkSpan -> EnrichedTextSpanPressEvent.forLink(surfaceId, id, phase, span)
        is EnrichedMentionSpan -> EnrichedTextSpanPressEvent.forMention(surfaceId, id, phase, span)
        else -> return
      }

    UIManagerHelper.getEventDispatcher(reactContext)?.dispatchEvent(event)
  }

  // The pressed link or mention is highlighted behind its text, in its color:
  // the text stays immutable, it isn't laid out again
  override fun onDraw(canvas: Canvas) {
    drawPressedSpan(canvas)
    super.onDraw(canvas)
  }

  private fun drawPressedSpan(canvas: Canvas) {
    val span = pressedSpan ?: return
    val textLayout = layout ?: return
    val content = text as? Spanned ?: return
    val start = content.getSpanStart(span)
    val end = content.getSpanEnd(span)

    if (start == -1 || end == -1) return

    pressPath.reset()
    textLayout.getSelectionPath(start, end, pressPath)

    pressPaint.set(paint)
    span.updateDrawState(pressPaint)
    pressPaint.color = ColorUtils.setAlphaComponent(pressPaint.color, PRESSED_ALPHA)
    pressPaint.style = Paint.Style.FILL
    pressPaint.pathEffect = pressCorners

    canvas.withTranslation(totalPaddingLeft.toFloat(), totalPaddingTop.toFloat()) {
      drawPath(pressPath, pressPaint)
    }
  }

  companion object {
    private const val PRESSED_ALPHA = 0x33
    private const val PRESSED_CORNER_RADIUS = 4.0
  }
}
