package com.swmansion.enriched.utils

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.events.OnChangeStateEvent
import com.swmansion.enriched.events.OnColorChangeEvent
import com.swmansion.enriched.spans.EnrichedSpans
import com.swmansion.enriched.spans.TextStyle

class EnrichedSpanState(
  private val view: EnrichedTextInputView,
) {
  private var previousPayload: WritableMap? = null
  private var previousDispatchedColor: Int? = null

  var boldStart: Int? = null
    private set
  var italicStart: Int? = null
    private set
  var underlineStart: Int? = null
    private set
  var strikethroughStart: Int? = null
    private set
  var inlineCodeStart: Int? = null
    private set
  var h1Start: Int? = null
    private set
  var h2Start: Int? = null
    private set
  var h3Start: Int? = null
    private set
  var h4Start: Int? = null
    private set
  var h5Start: Int? = null
    private set
  var h6Start: Int? = null
    private set
  var codeBlockStart: Int? = null
    private set
  var blockQuoteStart: Int? = null
    private set
  var orderedListStart: Int? = null
    private set
  var unorderedListStart: Int? = null
    private set
  var linkStart: Int? = null
    private set
  var imageStart: Int? = null
    private set
  var mentionStart: Int? = null
    private set
  var dividerStart: Int? = null
    private set
  var checklistStart: Int? = null
    private set
  var colorStart: Int? = null
    private set
  var typingColor: Int? = null
    private set

  fun setTypingColor(color: Int?) {
    typingColor = color
    emitColorChangeEvent(color)
  }

  fun setColorStart(start: Int?) {
    if (start == null) {
      setColorStart(null, null)
    } else {
      setColorStart(start, typingColor)
    }
  }

  fun setColorStart(
    start: Int?,
    color: Int?,
  ) {
    colorStart = start
    typingColor = null
    emitStateChangeEvent()
    setTypingColor(color)
  }

  fun setBoldStart(start: Int?) {
    this.boldStart = start
    emitStateChangeEvent()
  }

  fun setItalicStart(start: Int?) {
    this.italicStart = start
    emitStateChangeEvent()
  }

  fun setUnderlineStart(start: Int?) {
    this.underlineStart = start
    emitStateChangeEvent()
  }

  fun setStrikethroughStart(start: Int?) {
    this.strikethroughStart = start
    emitStateChangeEvent()
  }

  fun setInlineCodeStart(start: Int?) {
    this.inlineCodeStart = start
    emitStateChangeEvent()
  }

  fun setH1Start(start: Int?) {
    this.h1Start = start
    emitStateChangeEvent()
  }

  fun setH2Start(start: Int?) {
    this.h2Start = start
    emitStateChangeEvent()
  }

  fun setH3Start(start: Int?) {
    this.h3Start = start
    emitStateChangeEvent()
  }

  fun setH4Start(start: Int?) {
    this.h4Start = start
    emitStateChangeEvent()
  }

  fun setH5Start(start: Int?) {
    this.h5Start = start
    emitStateChangeEvent()
  }

  fun setH6Start(start: Int?) {
    this.h6Start = start
    emitStateChangeEvent()
  }

  fun setCodeBlockStart(start: Int?) {
    this.codeBlockStart = start
    emitStateChangeEvent()
  }

  fun setBlockQuoteStart(start: Int?) {
    this.blockQuoteStart = start
    emitStateChangeEvent()
  }

  fun setOrderedListStart(start: Int?) {
    this.orderedListStart = start
    emitStateChangeEvent()
  }

  fun setUnorderedListStart(start: Int?) {
    this.unorderedListStart = start
    emitStateChangeEvent()
  }

  fun setLinkStart(start: Int?) {
    this.linkStart = start
    emitStateChangeEvent()
  }

  fun setImageStart(start: Int?) {
    this.imageStart = start
    emitStateChangeEvent()
  }

  fun setMentionStart(start: Int?) {
    this.mentionStart = start
    emitStateChangeEvent()
  }

  fun setDividerStart(start: Int?) {
    this.dividerStart = start
  }

  fun setChecklistStart(start: Int?) {
    this.checklistStart = start
  }

  fun getStart(name: TextStyle): Int? {
    val start =
      when (name) {
        TextStyle.BOLD -> boldStart
        TextStyle.ITALIC -> italicStart
        TextStyle.UNDERLINE -> underlineStart
        TextStyle.STRIKETHROUGH -> strikethroughStart
        TextStyle.INLINE_CODE -> inlineCodeStart
        TextStyle.COLOR -> colorStart
        TextStyle.H1 -> h1Start
        TextStyle.H2 -> h2Start
        TextStyle.H3 -> h3Start
        TextStyle.H4 -> h4Start
        TextStyle.H5 -> h5Start
        TextStyle.H6 -> h6Start
        TextStyle.CODE_BLOCK -> codeBlockStart
        TextStyle.BLOCK_QUOTE -> blockQuoteStart
        TextStyle.ORDERED_LIST -> orderedListStart
        TextStyle.UNORDERED_LIST -> unorderedListStart
        TextStyle.CHECK_LIST -> checklistStart
        TextStyle.LINK -> linkStart
        TextStyle.IMAGE -> imageStart
        TextStyle.MENTION -> mentionStart
        TextStyle.DIVIDER -> dividerStart
        else -> null
      }

    return start
  }

  fun setStart(
    name: TextStyle,
    start: Int?,
  ) {
    when (name) {
      TextStyle.BOLD -> {
        setBoldStart(start)
      }

      TextStyle.ITALIC -> {
        setItalicStart(start)
      }

      TextStyle.UNDERLINE -> {
        setUnderlineStart(start)
      }

      TextStyle.COLOR -> {
        setColorStart(start)
      }

      TextStyle.STRIKETHROUGH -> {
        setStrikethroughStart(start)
      }

      TextStyle.INLINE_CODE -> {
        setInlineCodeStart(start)
      }

      TextStyle.H1 -> {
        setH1Start(start)
      }

      TextStyle.H2 -> {
        setH2Start(start)
      }

      TextStyle.H3 -> {
        setH3Start(start)
      }

      TextStyle.H4 -> {
        setH4Start(start)
      }

      TextStyle.H5 -> {
        setH5Start(start)
      }

      TextStyle.H6 -> {
        setH6Start(start)
      }

      TextStyle.CODE_BLOCK -> {
        setCodeBlockStart(start)
      }

      TextStyle.BLOCK_QUOTE -> {
        setBlockQuoteStart(start)
      }

      TextStyle.ORDERED_LIST -> {
        setOrderedListStart(start)
      }

      TextStyle.UNORDERED_LIST -> {
        setUnorderedListStart(start)
      }

      TextStyle.CHECK_LIST -> {
        setChecklistStart(start)
      }

      TextStyle.LINK -> {
        setLinkStart(start)
      }

      TextStyle.IMAGE -> {
        setImageStart(start)
      }

      TextStyle.MENTION -> {
        setMentionStart(start)
      }

      TextStyle.DIVIDER -> {
        setDividerStart(start)
      }

      else -> {}
    }
  }

  private fun emitColorChangeEvent(color: Int?) {
    val resolvedColor = color ?: view.currentTextColor

    if (previousDispatchedColor == resolvedColor) {
      return
    }

    previousDispatchedColor = resolvedColor

    val colorToDispatch = String.format("#%06X", resolvedColor and 0x00FFFFFF)

    val context = view.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)

    dispatcher?.dispatchEvent(
      OnColorChangeEvent(
        surfaceId,
        view.id,
        view.experimentalSynchronousEvents,
        colorToDispatch,
      ),
    )
  }

  private fun emitStateChangeEvent() {
    val payload: WritableMap = Arguments.createMap()
    payload.putBoolean("isBold", boldStart != null)
    payload.putBoolean("isItalic", italicStart != null)
    payload.putBoolean("isUnderline", underlineStart != null)
    payload.putBoolean("isStrikeThrough", strikethroughStart != null)
    payload.putBoolean("isInlineCode", inlineCodeStart != null)
    payload.putBoolean("isH1", h1Start != null)
    payload.putBoolean("isH2", h2Start != null)
    payload.putBoolean("isH3", h3Start != null)
    payload.putBoolean("isH4", h4Start != null)
    payload.putBoolean("isH5", h5Start != null)
    payload.putBoolean("isH6", h6Start != null)
    payload.putBoolean("isCodeBlock", codeBlockStart != null)
    payload.putBoolean("isBlockQuote", blockQuoteStart != null)
    payload.putBoolean("isOrderedList", orderedListStart != null)
    payload.putBoolean("isUnorderedList", unorderedListStart != null)
    payload.putBoolean("isLink", linkStart != null)
    payload.putBoolean("isImage", imageStart != null)
    payload.putBoolean("isMention", mentionStart != null)
    payload.putBoolean("isCheckList", checklistStart != null)
    payload.putBoolean("isColored", colorStart != null)

    // Do not emit event if payload is the same
    if (previousPayload == payload) {
      return
    }

    previousPayload =
      Arguments.createMap().apply {
        merge(payload)
      }

    val context = view.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)
    dispatcher?.dispatchEvent(
      OnChangeStateEvent(
        surfaceId,
        view.id,
        payload,
        view.experimentalSynchronousEvents,
      ),
    )
  }

  companion object {
    const val NAME = "ReactNativeEnrichedView"
  }
}
