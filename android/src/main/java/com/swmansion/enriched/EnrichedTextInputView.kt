package com.swmansion.enriched

import android.content.Context
import android.graphics.BlendMode
import android.graphics.BlendModeColorFilter
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Rect
import android.graphics.text.LineBreaker
import android.os.Build
import android.text.InputType
import android.text.Spannable
import android.text.SpannableString
import android.text.SpannableStringBuilder
import android.util.AttributeSet
import android.util.Log
import android.util.TypedValue
import android.view.ActionMode
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputConnection
import android.view.inputmethod.InputMethodManager
import androidx.appcompat.widget.AppCompatEditText
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.common.ReactConstants
import com.facebook.react.uimanager.PixelUtil
import com.facebook.react.uimanager.StateWrapper
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.Event
import com.facebook.react.views.text.ReactTypefaceUtils.applyStyles
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontStyle
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontWeight
import com.swmansion.enriched.constants.Strings
import com.swmansion.enriched.events.MentionHandler
import com.swmansion.enriched.events.OnInputBlurEvent
import com.swmansion.enriched.events.OnInputFocusEvent
import com.swmansion.enriched.events.OnRequestHtmlResultEvent
import com.swmansion.enriched.inputFilters.NonEditableParagraphFilter
import com.swmansion.enriched.inputFilters.ParagraphLimitFilter
import com.swmansion.enriched.loaders.EnrichedImageLoader
import com.swmansion.enriched.parser.EnrichedParser
import com.swmansion.enriched.spans.EnrichedH1Span
import com.swmansion.enriched.spans.EnrichedH2Span
import com.swmansion.enriched.spans.EnrichedH3Span
import com.swmansion.enriched.spans.EnrichedImageSpan
import com.swmansion.enriched.spans.EnrichedSpans
import com.swmansion.enriched.spans.ISpanConfig
import com.swmansion.enriched.spans.TextStyle
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.spans.utils.ForceRedrawSpan
import com.swmansion.enriched.styles.HtmlStyle
import com.swmansion.enriched.textinput.utils.EnrichedEditableFactory
import com.swmansion.enriched.utils.EnrichedSelection
import com.swmansion.enriched.utils.EnrichedSpanState
import com.swmansion.enriched.utils.mergeSpannables
import com.swmansion.enriched.watchers.EnrichedScrollWatcher
import com.swmansion.enriched.watchers.EnrichedSpanWatcher
import com.swmansion.enriched.watchers.EnrichedTextWatcher
import kotlin.math.ceil

class EnrichedTextInputView : AppCompatEditText {
  var stateWrapper: StateWrapper? = null
  val selection: EnrichedSelection? = EnrichedSelection(this)
  val spanState: EnrichedSpanState? = EnrichedSpanState(this)
  val styleManipulator: EnrichedStyleManipulator? = EnrichedStyleManipulator(this)

  var isDuringTransaction: Boolean = false
  var isRemovingMany: Boolean = false
  var blockTextEventEmitting: Boolean = false

  var availableStyles: Map<TextStyle, ISpanConfig> = EnrichedSpans.allSpans
  var paragraphsLimit: Int = -1

  var shouldEmitHtml: Boolean = false
  var shouldEmitOnChangeText: Boolean = false
  var experimentalSynchronousEvents: Boolean = false

  var fontSize: Float? = null
  private var fontFamily: String? = null
  private var fontStyle: Int = ReactConstants.UNSET
  private var fontWeight: Int = ReactConstants.UNSET

  var htmlStyle: HtmlStyle = HtmlStyle(this, null)
    set(value) {
      if (field != value) {
        val prev = field
        field = value
        reApplyHtmlStyleForSpans(prev, value)
      }
    }

  var layoutManager = EnrichedTextInputViewLayoutManager(this)

  var editorWidth: Int = getInitialWidth()
    private set

  private var typefaceDirty = false

  private var inputMethodManager: InputMethodManager? = null
  private var autoFocus = false
  private var didAttachToWindow = false

  private var defaultValue: CharSequence? = null
  private var defaultValueDirty = false

  private val clipboardManager by lazy {
    EnrichedClipboardManager(context, this)
  }

  private var contextMenuItems: List<EnrichedActionModeCallback.Companion.CallbackMenuItemData> = emptyList()

  var scrollEnabled: Boolean = true
  private var detectScrollMovement = false
  private var scrollWatcher: EnrichedScrollWatcher? = null

  val mentionHandler: MentionHandler? = MentionHandler(this)

  private val checkboxClickHandler by lazy {
    CheckListClickHandler(this)
  }

  var spanWatcher: EnrichedSpanWatcher? = null

  constructor(context: Context) : super(context) {
    prepareComponent()
  }

  constructor(context: Context, attrs: AttributeSet) : super(context, attrs) {
    prepareComponent()
  }

  constructor(context: Context, attrs: AttributeSet, defStyleAttr: Int) : super(
    context,
    attrs,
    defStyleAttr,
  ) {
    prepareComponent()
  }

  init {
    inputMethodManager = context.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
    EnrichedImageLoader.init(context as ReactContext)
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()

    // Used to ensure that text is selectable inside of removeClippedSubviews
    // See https://github.com/facebook/react-native/issues/6805 for original
    // fix that was ported to here.
    runAsATransaction {
      blockTextEventEmitting = true
      super.setTextIsSelectable(true)
      blockTextEventEmitting = false
    }

    if (autoFocus && !didAttachToWindow) {
      requestFocusProgrammatically()
    }

    didAttachToWindow = true
  }

  private fun prepareComponent() {
    isSingleLine = false
    isHorizontalScrollBarEnabled = false
    isVerticalScrollBarEnabled = true
    gravity = Gravity.TOP or Gravity.START
    inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_MULTI_LINE

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      breakStrategy = LineBreaker.BREAK_STRATEGY_HIGH_QUALITY
    }

    setPadding(0, 0, 0, 0)
    setBackgroundColor(Color.TRANSPARENT)

    val spanWatcher = EnrichedSpanWatcher(this)
    this.spanWatcher = spanWatcher
    setEditableFactory(EnrichedEditableFactory(spanWatcher))
    addTextChangedListener(EnrichedTextWatcher(this))
    filters = arrayOf(NonEditableParagraphFilter(), ParagraphLimitFilter(this))
  }

  override fun onLayout(
    changed: Boolean,
    l: Int,
    t: Int,
    r: Int,
    b: Int,
  ) {
    super.onLayout(changed, l, t, r, b)
    val textLayoutWidth = layout?.width ?: return
    if (textLayoutWidth != editorWidth) {
      editorWidth = textLayoutWidth
      htmlStyle.invalidateStyles()
    }
  }

  override fun onDraw(canvas: Canvas) {
    super.onDraw(canvas)
    layoutManager.invalidateLayoutIfNeeded()
  }

  // https://github.com/facebook/react-native/blob/36df97f500aa0aa8031098caf7526db358b6ddc1/packages/react-native/ReactAndroid/src/main/java/com/facebook/react/views/textinput/ReactEditText.kt#L295C1-L296C1
  override fun onTouchEvent(event: MotionEvent): Boolean {
    if (checkboxClickHandler.handleTouch(event)) return true
    when (event.action) {
      MotionEvent.ACTION_DOWN -> {
        detectScrollMovement = true
        // Disallow parent views to intercept touch events, until we can detect if we should be
        // capturing these touches or not.
        parent.requestDisallowInterceptTouchEvent(true)
      }

      MotionEvent.ACTION_MOVE -> {
        if (detectScrollMovement) {
          if (!canScrollVertically(-1) &&
            !canScrollVertically(1) &&
            !canScrollHorizontally(-1) &&
            !canScrollHorizontally(1)
          ) {
            // We cannot scroll, let parent views take care of these touches.
            parent.requestDisallowInterceptTouchEvent(false)
          }
          detectScrollMovement = false
        }
      }
    }

    return super.onTouchEvent(event)
  }

  override fun canScrollVertically(direction: Int): Boolean = scrollEnabled

  override fun canScrollHorizontally(direction: Int): Boolean = scrollEnabled

  override fun onScrollChanged(
    horiz: Int,
    vert: Int,
    oldHoriz: Int,
    oldVert: Int,
  ) {
    super.onScrollChanged(horiz, vert, oldHoriz, oldVert)
    scrollWatcher?.onScrollChanged(horiz, vert, oldHoriz, oldVert)
  }

  fun setScrollWatcher(scrollWatcher: EnrichedScrollWatcher?) {
    this.scrollWatcher = scrollWatcher
  }

  override fun onSelectionChanged(
    selStart: Int,
    selEnd: Int,
  ) {
    super.onSelectionChanged(selStart, selEnd)
    selection?.onSelection(selStart, selEnd)
  }

  override fun clearFocus() {
    super.clearFocus()
    inputMethodManager?.hideSoftInputFromWindow(windowToken, 0)
  }

  override fun onFocusChanged(
    focused: Boolean,
    direction: Int,
    previouslyFocusedRect: Rect?,
  ) {
    super.onFocusChanged(focused, direction, previouslyFocusedRect)
    val context = context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, id)

    if (focused) {
      inputMethodManager?.showSoftInput(this, 0)
      dispatcher?.dispatchEvent(OnInputFocusEvent(surfaceId, id, experimentalSynchronousEvents))
    } else {
      dispatcher?.dispatchEvent(OnInputBlurEvent(surfaceId, id, experimentalSynchronousEvents))
    }
  }

  override fun onTextContextMenuItem(id: Int): Boolean {
    when (id) {
      android.R.id.copy -> {
        clipboardManager.copy()
        return true
      }

      android.R.id.paste -> {
        clipboardManager.paste()
        return true
      }

      android.R.id.cut -> {
        clipboardManager.cut()
        return true
      }
    }
    return super.onTextContextMenuItem(id)
  }

  override fun onCreateInputConnection(outAttrs: EditorInfo): InputConnection? {
    var inputConnection = super.onCreateInputConnection(outAttrs)
    if (inputConnection != null) {
      inputConnection =
        EnrichedTextInputConnectionWrapper(
          inputConnection,
          context as ReactContext,
          this,
          experimentalSynchronousEvents,
        )
    }

    return inputConnection
  }

  fun insertSpannable(
    spannable: Spannable,
    at: Int? = null,
  ) {
    val currentText = (text as? SpannableStringBuilder) ?: return
    val length = currentText.length

    val insertionStart = selection?.start ?: 0
    val insertionEnd = selection?.end ?: 0

    val rawStart = at ?: minOf(insertionStart, insertionEnd)
    val rawEnd = at ?: maxOf(insertionStart, insertionEnd)

    val start = rawStart.coerceIn(0, length)
    val end = rawEnd.coerceIn(start, length)

    val result = currentText.mergeSpannables(start, end, spannable)

    currentText.replace(start, end, spannable)

    val lengthAfter = currentText.length

    val cursor = (start + result.insertedCharactersAmount).coerceIn(0, lengthAfter)
    setSelection(cursor, cursor)
  }

  fun insertText(
    insertedText: String,
    at: Int? = null,
  ) {
    val parsedText = parseText(insertedText)

    val spannable =
      parsedText as? Spannable ?: SpannableString(parsedText)

    insertSpannable(spannable, at)
  }

  fun requestFocusProgrammatically(withSelection: Boolean = true) {
    requestFocus()
    inputMethodManager?.showSoftInput(this, 0)
    if (withSelection) {
      setSelection(selection?.start ?: text?.length ?: 0)
    }
  }

  private fun parseText(text: CharSequence): CharSequence {
    val stringText = text.toString()
    if (!EnrichedParser.isHtml(stringText)) return text

    try {
      return EnrichedParser.fromHtml(stringText, htmlStyle, null, this)
    } catch (e: Exception) {
      Log.e("EnrichedTextInputView", "Error parsing HTML: ${e.message}")
      return text
    }
  }

  fun setValue(
    value: CharSequence?,
    withSelection: Boolean = false,
  ) {
    if (value == null) return
    runAsATransaction {
      blockTextEventEmitting = true
      val newText = parseText(value)

      val spannable = text as SpannableStringBuilder?

      if (spannable == null) {
        setText(newText)
      } else {
        spannable.replace(0, spannable.length, newText)
      }

      observeAsyncImages()
      if (withSelection) {
        // Scroll to the last line of text
        setSelection(text?.length ?: 0, text?.length ?: 0)
      }
      blockTextEventEmitting = false
    }
  }

  override fun setSelection(
    start: Int,
    stop: Int,
  ) {
    val textLength = text?.length ?: 0
    val safeStart = start.coerceIn(0, textLength)
    val safeEnd = stop.coerceIn(0, textLength)
    super.setSelection(safeStart, safeEnd)
  }

  override fun setSelection(index: Int) {
    val safeIndex = index.coerceIn(0, text?.length ?: 0)
    super.setSelection(safeIndex)
  }

  fun setCustomSelection(
    visibleStart: Int,
    visibleEnd: Int,
  ) {
    val actualStart = getActualIndex(visibleStart)
    val actualEnd = getActualIndex(visibleEnd)

    setSelection(actualStart, actualEnd)
  }

  // this method is used to update the draw state of span
  fun redrawSpan(span: EnrichedSpan) {
    val text = text
    if (text !is Spannable) return

    val start = text.getSpanStart(span)
    val end = text.getSpanEnd(span)

    if (start == -1 || end == -1) return

    val marker = ForceRedrawSpan()

    runAsATransaction {
      text.setSpan(marker, start, end, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
      text.removeSpan(marker)
    }
  }

  private fun getActualIndex(visibleIndex: Int): Int {
    val currentText = text as Spannable
    var currentVisibleCount = 0
    var actualIndex = 0

    while (actualIndex < currentText.length) {
      if (currentVisibleCount == visibleIndex) {
        return actualIndex
      }

      // If the current char is not a hidden space, it counts towards our visible index
      if (currentText[actualIndex] != Strings.ZERO_WIDTH_SPACE_CHAR) {
        currentVisibleCount++
      }
      actualIndex++
    }

    return actualIndex
  }

  /**
   * Finds all async images in the current text and sets up listeners
   * to redraw the text layout when they finish downloading.
   */
  private fun observeAsyncImages() {
    val liveText = text ?: return

    liveText.getSpans(0, liveText.length, EnrichedImageSpan::class.java).forEach {
      it.observeAsyncDrawableLoaded(liveText)
    }
  }

  fun setAutoFocus(autoFocus: Boolean) {
    this.autoFocus = autoFocus
  }

  fun setPlaceholder(placeholder: String?) {
    if (placeholder == null) return

    hint = placeholder
  }

  fun setPlaceholderTextColor(colorInt: Int?) {
    if (colorInt == null) return

    setHintTextColor(colorInt)
  }

  fun setSelectionColor(colorInt: Int?) {
    if (colorInt == null) return

    highlightColor = colorInt
  }

  fun setCursorColor(colorInt: Int?) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      val cursorDrawable = textCursorDrawable ?: return

      if (colorInt != null) {
        cursorDrawable.colorFilter = BlendModeColorFilter(colorInt, BlendMode.SRC_IN)
      } else {
        cursorDrawable.clearColorFilter()
      }

      textCursorDrawable = cursorDrawable
    }
  }

  fun setContextMenuItems(items: ReadableArray?) {
    if (items == null) {
      contextMenuItems = emptyList()
      return
    }

    val result = mutableListOf<EnrichedActionModeCallback.Companion.CallbackMenuItemData>()
    for (i in 0 until items.size()) {
      val item = items.getMap(i) ?: continue
      val text = item.getString("text") ?: continue
      val key = item.getString("key") ?: continue
      result.add(EnrichedActionModeCallback.Companion.CallbackMenuItemData(key = key, text = text))
    }

    contextMenuItems = result
  }

  override fun startActionMode(
    callback: ActionMode.Callback?,
    type: Int,
  ): ActionMode? {
    val menuItems = contextMenuItems
    if (menuItems.isEmpty()) {
      return super.startActionMode(callback, type)
    }

    val wrappedCallback =
      EnrichedActionModeCallback(
        editText = this,
        original = callback,
        contextMenuItems = menuItems,
      )

    return super.startActionMode(wrappedCallback, type)
  }

  fun setColor(colorInt: Int?) {
    if (colorInt == null) {
      setTextColor(Color.BLACK)
      return
    }

    setTextColor(colorInt)
  }

  fun setFontSize(size: Float) {
    if (size == 0f) return

    val sizeInt = ceil(PixelUtil.toPixelFromSP(size))
    fontSize = sizeInt
    setTextSize(TypedValue.COMPLEX_UNIT_PX, sizeInt)

    // This ensured that newly created spans will take the new font size into account
    htmlStyle.invalidateStyles()
    forceScrollToSelection()
  }

  fun setFontFamily(family: String?) {
    if (family != fontFamily) {
      fontFamily = family
      typefaceDirty = true
    }
  }

  fun setFontWeight(weight: String?) {
    val fontWeight = parseFontWeight(weight)

    if (fontWeight != fontStyle) {
      this.fontWeight = fontWeight
      typefaceDirty = true
    }
  }

  fun setFontStyle(style: String?) {
    val fontStyle = parseFontStyle(style)

    if (fontStyle != this.fontStyle) {
      this.fontStyle = fontStyle
      typefaceDirty = true
    }
  }

  fun setAutoCapitalize(flagName: String?) {
    val flag =
      when (flagName) {
        "none" -> InputType.TYPE_NULL
        "sentences" -> InputType.TYPE_TEXT_FLAG_CAP_SENTENCES
        "words" -> InputType.TYPE_TEXT_FLAG_CAP_WORDS
        "characters" -> InputType.TYPE_TEXT_FLAG_CAP_CHARACTERS
        else -> InputType.TYPE_NULL
      }

    inputType = (
      inputType and
        InputType.TYPE_TEXT_FLAG_CAP_CHARACTERS.inv() and
        InputType.TYPE_TEXT_FLAG_CAP_WORDS.inv() and
        InputType.TYPE_TEXT_FLAG_CAP_SENTENCES.inv()
    ) or if (flag == InputType.TYPE_NULL) 0 else flag
  }

  fun setStylesConfig(styles: List<String>?) {
    availableStyles =
      EnrichedSpans.filterStyles(
        EnrichedSpans.allSpans,
        styles,
      )
  }

  // https://github.com/facebook/react-native/blob/36df97f500aa0aa8031098caf7526db358b6ddc1/packages/react-native/ReactAndroid/src/main/java/com/facebook/react/views/textinput/ReactEditText.kt#L283C2-L284C1
  // After the text changes inside an EditText, TextView checks if a layout() has been requested.
  // If it has, it will not scroll the text to the end of the new text inserted, but wait for the
  // next layout() to be called. However, we do not perform a layout() after a requestLayout(), so
  // we need to override isLayoutRequested to force EditText to scroll to the end of the new text
  // immediately.
  // Ivan Ihnatsiuk: let android calculate layout to avoid jumping behavior when we insert a new line.
//  override fun isLayoutRequested(): Boolean = false

  fun afterUpdateTransaction() {
    updateTypeface()
    updateDefaultValue()
  }

  fun setDefaultValue(value: CharSequence?) {
    defaultValue = value
    defaultValueDirty = true
  }

  private fun updateDefaultValue() {
    if (!defaultValueDirty) return

    defaultValueDirty = false
    setValue(defaultValue ?: "")
  }

  private fun updateTypeface() {
    if (!typefaceDirty) return
    typefaceDirty = false

    val newTypeface = applyStyles(typeface, fontStyle, fontWeight, fontFamily, context.assets)
    typeface = newTypeface
    paint.typeface = newTypeface
  }

  fun verifyAndToggleStyle(name: TextStyle) {
    val isValid = styleManipulator?.verifyStyle(name) ?: false
    if (!isValid) return

    runAsATransaction {
      styleManipulator.toggleStyle(name)
    }
  }

  fun requestHTML(
    requestId: Int,
    prettify: Boolean,
  ) {
    val html =
      try {
        EnrichedParser.toHtmlWithDefault(text, prettify)
      } catch (_: Exception) {
        null
      }

    val reactContext = context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(reactContext)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(reactContext, id)
    dispatcher?.dispatchEvent(OnRequestHtmlResultEvent(surfaceId, id, requestId, html, experimentalSynchronousEvents))
  }

  // Sometimes setting up style triggers many changes in sequence
  // Eg. removing conflicting styles -> changing text -> applying spans
  // In such scenario we want to prevent from handling side effects (eg. onTextChanged)
  fun runAsATransaction(block: () -> Unit) {
    try {
      isDuringTransaction = true
      block()
    } finally {
      isDuringTransaction = false
    }
  }

  fun <T : Event<T>> dispatchTextRelatedEvent(event: T) {
    if (blockTextEventEmitting) return
    val reactContext = context as ReactContext
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(reactContext, id)
    dispatcher?.dispatchEvent(event)
  }

  private fun forceScrollToSelection() {
    val textLayout = layout ?: return
    val cursorOffset = selectionStart
    if (cursorOffset <= 0) return

    val selectedLineIndex = textLayout.getLineForOffset(cursorOffset)
    val selectedLineTop = textLayout.getLineTop(selectedLineIndex)
    val selectedLineBottom = textLayout.getLineBottom(selectedLineIndex)
    val visibleTextHeight = height - paddingTop - paddingBottom

    if (visibleTextHeight <= 0) return

    val visibleTop = scrollY
    val visibleBottom = scrollY + visibleTextHeight
    var targetScrollY = scrollY

    if (selectedLineTop < visibleTop) {
      targetScrollY = selectedLineTop
    } else if (selectedLineBottom > visibleBottom) {
      targetScrollY = selectedLineBottom - visibleTextHeight
    }

    val maxScrollY = (textLayout.height - visibleTextHeight).coerceAtLeast(0)
    targetScrollY = targetScrollY.coerceIn(0, maxScrollY)
    scrollTo(scrollX, targetScrollY)
  }

  private fun reApplyHtmlStyleForSpans(
    previousHtmlStyle: HtmlStyle,
    nextHtmlStyle: HtmlStyle,
  ) {
    blockTextEventEmitting = true
    val shouldRemoveBoldSpanFromH1Span = !previousHtmlStyle.h1Bold && nextHtmlStyle.h1Bold
    val shouldRemoveBoldSpanFromH2Span = !previousHtmlStyle.h2Bold && nextHtmlStyle.h2Bold
    val shouldRemoveBoldSpanFromH3Span = !previousHtmlStyle.h3Bold && nextHtmlStyle.h3Bold

    val spannable = text as? Spannable ?: return
    if (spannable.isEmpty()) return

    var shouldEmitStateChange = false

    runAsATransaction {
      val spans = spannable.getSpans(0, spannable.length, EnrichedSpan::class.java)
      for (span in spans) {
        if (!span.dependsOnHtmlStyle) continue

        val start = spannable.getSpanStart(span)
        val end = spannable.getSpanEnd(span)
        val flags = spannable.getSpanFlags(span)

        if (start == -1 || end == -1) continue

        if ((span is EnrichedH1Span && shouldRemoveBoldSpanFromH1Span) || (span is EnrichedH2Span && shouldRemoveBoldSpanFromH2Span) ||
          (span is EnrichedH3Span && shouldRemoveBoldSpanFromH3Span)
        ) {
          val isRemoved = styleManipulator?.removeStyle(TextStyle.BOLD, start, end) ?: false
          if (isRemoved) shouldEmitStateChange = true
        }

        spannable.removeSpan(span)
        val newSpan = span.rebuildWithStyle(htmlStyle)
        spannable.setSpan(newSpan, start, end, flags)
      }

      if (shouldEmitStateChange) {
        selection?.validateStyles()
      }
    }
    forceScrollToSelection()
    blockTextEventEmitting = false
  }

  private fun getInitialWidth(): Int {
    val parentWidth = (parent as? View)?.width ?: 0

    return if (parentWidth > 0) return parentWidth - paddingLeft - paddingRight else 0
  }

  companion object {
    const val CLIPBOARD_TAG = "react-native-enriched-clipboard"
  }
}
