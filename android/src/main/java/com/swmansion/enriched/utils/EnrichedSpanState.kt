package com.swmansion.enriched.utils

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.events.OnAlignmentChangeEvent
import com.swmansion.enriched.events.OnChangeStateEvent
import com.swmansion.enriched.events.OnColorChangeEvent
import com.swmansion.enriched.spans.EnrichedSpans
import com.swmansion.enriched.spans.TextStyle

class EnrichedSpanState(
  private val view: EnrichedTextInputView,
) {
  private var previousPayload: WritableMap? = null
  private var previousDispatchedColor: Int? = null
  private var previousDispatchedAlignment: String? = null

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
  var paragraphAlignment: String? = null
    private set
  var alignmentStart: Int? = null
    private set
  var contentStart: Int? = null
    private set

  fun setContentStart(start: Int?) {
    contentStart = start
  }

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
    emitStateChangeEvent()
    setTypingColor(color)
  }

  fun setAlignment(alignment: String?) {
    paragraphAlignment = alignment
    emitAlignmentChangeEvent(alignment)
  }

  fun setAlignmentStart(start: Int?) {
    if (start == null) {
      setAlignmentStart(null, null)
    } else {
      setAlignmentStart(start, paragraphAlignment)
    }
  }

  fun setAlignmentStart(
    start: Int?,
    alignment: String?,
  ) {
    this.alignmentStart = start
    setAlignment(alignment)
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
        TextStyle.ALIGNMENT -> alignmentStart
        TextStyle.BOLD -> boldStart
        TextStyle.ITALIC -> italicStart
        TextStyle.UNDERLINE -> underlineStart
        TextStyle.STRIKETHROUGH -> strikethroughStart
        TextStyle.INLINE_CODE -> inlineCodeStart
        TextStyle.COLOR -> colorStart
        TextStyle.CONTENT -> contentStart
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
      }

    return start
  }

  fun setStart(
    name: TextStyle,
    start: Int?,
  ) {
    when (name) {
      TextStyle.ALIGNMENT -> {
        setAlignmentStart(start)
      }

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

      TextStyle.CONTENT -> {
        setContentStart(start)
      }
    }
  }

  private fun emitAlignmentChangeEvent(alignment: String?) {
    val resolvedAlignment = alignment ?: "default"

    if (previousDispatchedAlignment == alignment) return

    previousDispatchedAlignment = alignment

    val context = view.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)

    dispatcher?.dispatchEvent(
      OnAlignmentChangeEvent(
        surfaceId,
        view.id,
        view.experimentalSynchronousEvents,
        resolvedAlignment,
      ),
    )
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
    val activeStyles =
      listOfNotNull(
        if (boldStart != null) TextStyle.BOLD else null,
        if (colorStart != null) TextStyle.COLOR else null,
        if (italicStart != null) TextStyle.ITALIC else null,
        if (underlineStart != null) TextStyle.UNDERLINE else null,
        if (strikethroughStart != null) TextStyle.STRIKETHROUGH else null,
        if (inlineCodeStart != null) TextStyle.INLINE_CODE else null,
        if (h1Start != null) TextStyle.H1 else null,
        if (h2Start != null) TextStyle.H2 else null,
        if (h3Start != null) TextStyle.H3 else null,
        if (h4Start != null) TextStyle.H4 else null,
        if (h5Start != null) TextStyle.H5 else null,
        if (h6Start != null) TextStyle.H6 else null,
        if (codeBlockStart != null) TextStyle.CODE_BLOCK else null,
        if (blockQuoteStart != null) TextStyle.BLOCK_QUOTE else null,
        if (orderedListStart != null) TextStyle.ORDERED_LIST else null,
        if (unorderedListStart != null) TextStyle.UNORDERED_LIST else null,
        if (checklistStart != null) TextStyle.CHECK_LIST else null,
        if (dividerStart != null) TextStyle.DIVIDER else null,
        if (contentStart != null) TextStyle.CONTENT else null,
        if (linkStart != null) TextStyle.LINK else null,
        if (imageStart != null) TextStyle.IMAGE else null,
        if (mentionStart != null) TextStyle.MENTION else null,
      )
    val payload = Arguments.createMap()
    payload.putMap("bold", getStyleState(activeStyles, TextStyle.BOLD))
    payload.putMap("colored", getStyleState(activeStyles, TextStyle.COLOR))
    payload.putMap("italic", getStyleState(activeStyles, TextStyle.ITALIC))
    payload.putMap("underline", getStyleState(activeStyles, TextStyle.UNDERLINE))
    payload.putMap("strikeThrough", getStyleState(activeStyles, TextStyle.STRIKETHROUGH))
    payload.putMap("inlineCode", getStyleState(activeStyles, TextStyle.INLINE_CODE))
    payload.putMap("h1", getStyleState(activeStyles, TextStyle.H1))
    payload.putMap("h2", getStyleState(activeStyles, TextStyle.H2))
    payload.putMap("h3", getStyleState(activeStyles, TextStyle.H3))
    payload.putMap("h4", getStyleState(activeStyles, TextStyle.H4))
    payload.putMap("h5", getStyleState(activeStyles, TextStyle.H5))
    payload.putMap("h6", getStyleState(activeStyles, TextStyle.H6))
    payload.putMap("codeBlock", getStyleState(activeStyles, TextStyle.CODE_BLOCK))
    payload.putMap("blockQuote", getStyleState(activeStyles, TextStyle.BLOCK_QUOTE))
    payload.putMap("orderedList", getStyleState(activeStyles, TextStyle.ORDERED_LIST))
    payload.putMap("unorderedList", getStyleState(activeStyles, TextStyle.UNORDERED_LIST))
    payload.putMap("link", getStyleState(activeStyles, TextStyle.LINK))
    payload.putMap("image", getStyleState(activeStyles, TextStyle.IMAGE))
    payload.putMap("mention", getStyleState(activeStyles, TextStyle.MENTION))
    payload.putMap("checkList", getStyleState(activeStyles, TextStyle.CHECK_LIST))
    payload.putMap("content", getStyleState(activeStyles, TextStyle.CONTENT))

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

  private fun getStyleState(
    activeStyles: List<TextStyle>,
    type: TextStyle,
  ): WritableMap {
    val mergingConfig = EnrichedSpans.getMergingConfigForStyle(type, view.htmlStyle)
    val blockingList = mergingConfig?.blockingStyles
    val conflictingList = mergingConfig?.conflictingStyles

    val state = Arguments.createMap()

    state.putBoolean("isActive", activeStyles.contains(type))

    val hasBlockingStyles = blockingList?.any { activeStyles.contains(it) } ?: false
    state.putBoolean("canBeApplied", hasBlockingStyles)

    val isConflicting = conflictingList?.any { activeStyles.contains(it) } ?: false
    state.putBoolean("isConflicting", isConflicting)

    return state
  }

  companion object {
    const val NAME = "ReactNativeEnrichedView"
  }
}
