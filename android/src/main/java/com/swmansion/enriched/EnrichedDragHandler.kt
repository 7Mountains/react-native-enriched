package com.swmansion.enriched

import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.text.SpannableStringBuilder
import android.util.TypedValue
import android.view.DragEvent
import android.view.Gravity
import android.view.HapticFeedbackConstants
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import com.swmansion.enriched.utils.dp

class EnrichedDragHandler(
  private val view: EnrichedTextInputView,
  private val clipboardManager: EnrichedClipboardManager,
) {
  private data class EnrichedDragLocalState(
    val sourceView: EnrichedTextInputView,
    val start: Int,
    val end: Int,
  )

  private var lastTouchDownX = 0f
  private var lastTouchDownY = 0f
  private var blockNextActionUpAfterDrag = false

  fun onDragEvent(event: DragEvent): Boolean? {
    if (event.action != DragEvent.ACTION_DROP) {
      return null
    }

    return handleDrop(event)
  }

  fun performLongClick(): Boolean {
    if (!isLastTouchWithinSelection()) {
      return false
    }

    if (!startEnrichedSelectionDrag()) {
      return false
    }

    blockNextActionUpAfterDrag = true
    view.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
    return true
  }

  fun onTouchEvent(event: MotionEvent): Boolean {
    if (
      blockNextActionUpAfterDrag &&
      (
        event.actionMasked == MotionEvent.ACTION_UP ||
          event.actionMasked == MotionEvent.ACTION_CANCEL
      )
    ) {
      blockNextActionUpAfterDrag = false
      return true
    }

    if (event.actionMasked == MotionEvent.ACTION_DOWN) {
      lastTouchDownX = event.x
      lastTouchDownY = event.y
    }

    return false
  }

  private fun handleDrop(event: DragEvent): Boolean? {
    val localState = event.localState
    val enrichedLocalState = localState as? EnrichedDragLocalState ?: return null

    val clip = event.clipData ?: return null
    val dropOffset = view.getOffsetForPosition(event.x, event.y)
    val sameViewLocalState = enrichedLocalState.takeIf { it.sourceView == view }
    if (
      sameViewLocalState != null &&
      dropOffset >= sameViewLocalState.start &&
      dropOffset < sameViewLocalState.end
    ) {
      return true
    }

    val lengthBeforeDrop = view.text?.length ?: 0
    val didInsert = clipboardManager.insertClipData(clip, dropOffset, dropOffset)
    if (!didInsert) {
      return null
    }

    if (sameViewLocalState != null) {
      deleteSourceAfterLocalDrop(sameViewLocalState, dropOffset, lengthBeforeDrop)
    }

    return true
  }

  private fun isLastTouchWithinSelection(): Boolean {
    val start = minOf(view.selectionStart, view.selectionEnd)
    val end = maxOf(view.selectionStart, view.selectionEnd)
    if (start >= end) return false

    val touchOffset = view.getOffsetForPosition(lastTouchDownX, lastTouchDownY)
    return touchOffset >= start && touchOffset < end
  }

  private fun startEnrichedSelectionDrag(): Boolean {
    val start = minOf(view.selectionStart, view.selectionEnd)
    val end = maxOf(view.selectionStart, view.selectionEnd)
    if (start >= end) return false

    val clip = clipboardManager.createSelectedTextClipData(start, end) ?: return false
    val started =
      view.startDragAndDrop(
        clip,
        createTextDragShadow(start, end),
        EnrichedDragLocalState(view, start, end),
        View.DRAG_FLAG_GLOBAL,
      )

    if (started) {
      view.setSelection(end)
    }

    return started
  }

  private fun createTextDragBackgroundDrawable(): GradientDrawable =
    GradientDrawable().apply {
      shape = GradientDrawable.RECTANGLE
      cornerRadius = 10.dp.toFloat()
      setColor(Color.LTGRAY)
    }

  private fun createTextDragShadow(
    start: Int,
    end: Int,
  ): View.DragShadowBuilder {
    val shadowView = TextView(view.context)

    val padding = 10.dp

    shadowView.apply {
      text = view.editableText?.subSequence(start, end) ?: ""
      setTextColor(view.textColors)
      setTextSize(TypedValue.COMPLEX_UNIT_PX, view.textSize)
      gravity = Gravity.CENTER
      layoutParams =
        ViewGroup.LayoutParams(
          ViewGroup.LayoutParams.WRAP_CONTENT,
          ViewGroup.LayoutParams.WRAP_CONTENT,
        )
      maxWidth = view.width
      background = createTextDragBackgroundDrawable()
      setPadding(padding, padding / 2, padding, padding / 2)
    }

    val size = View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)
    shadowView.measure(size, size)
    shadowView.layout(0, 0, shadowView.measuredWidth, shadowView.measuredHeight)

    return View.DragShadowBuilder(shadowView)
  }

  private fun deleteSourceAfterLocalDrop(
    localState: EnrichedDragLocalState,
    dropOffset: Int,
    lengthBeforeDrop: Int,
  ) {
    val editable = view.text as? SpannableStringBuilder ?: return
    var dragSourceStart = localState.start
    var dragSourceEnd = localState.end

    if (dropOffset <= dragSourceStart) {
      val shift = editable.length - lengthBeforeDrop
      dragSourceStart += shift
      dragSourceEnd += shift
    }

    val safeStart = dragSourceStart.coerceIn(0, editable.length)
    val safeEnd = dragSourceEnd.coerceIn(safeStart, editable.length)
    if (safeStart >= safeEnd) return

    view.transactionManager.runSilently {
      editable.replace(safeStart, safeEnd, "")
    }
  }
}
