package com.swmansion.enriched

import android.graphics.Rect
import android.view.ActionMode
import android.view.Menu
import android.view.MenuItem
import android.view.View
import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.enriched.events.OnContextMenuItemPressEvent

class EnrichedActionModeCallback(
  private val editText: EnrichedTextInputView,
  private val original: ActionMode.Callback?,
  private val contextMenuItems: List<CallbackMenuItemData>,
) : ActionMode.Callback2() {
  override fun onCreateActionMode(
    mode: ActionMode,
    menu: Menu,
  ): Boolean {
    val result = original?.onCreateActionMode(mode, menu) ?: false

    contextMenuItems.forEachIndexed { index, item ->
      menu.add(Menu.NONE, CONTEXT_MENU_ITEM_ID + index, Menu.NONE, item.text)
    }

    return result
  }

  override fun onPrepareActionMode(
    mode: ActionMode,
    menu: Menu,
  ): Boolean = original?.onPrepareActionMode(mode, menu) ?: false

  override fun onActionItemClicked(
    mode: ActionMode,
    menuItem: MenuItem,
  ): Boolean {
    val itemId = menuItem.itemId

    if (itemId < CONTEXT_MENU_ITEM_ID) {
      return original?.onActionItemClicked(mode, menuItem) ?: false
    }

    val index = itemId - CONTEXT_MENU_ITEM_ID
    val item = contextMenuItems.getOrNull(index) ?: return false

    emitContextMenuItemPressEvent(item)

    mode.finish()

    return true
  }

  override fun onDestroyActionMode(mode: ActionMode) {
    original?.onDestroyActionMode(mode)
  }

  override fun onGetContentRect(
    mode: ActionMode?,
    view: View?,
    outRect: Rect,
  ) {
    val layout = editText.layout
    val start = editText.selectionStart
    val end = editText.selectionEnd

    if (layout == null || start < 0 || end < 0) {
      outRect.set(0, 0, editText.width, editText.height)
      return
    }

    val selStart = minOf(start, end)
    val selEnd = maxOf(start, end)

    val startLine = layout.getLineForOffset(selStart)
    val endLine = layout.getLineForOffset(selEnd)

    val left =
      if (startLine == endLine) {
        minOf(
          layout.getPrimaryHorizontal(selStart),
          layout.getPrimaryHorizontal(selEnd),
        ).toInt()
      } else {
        0
      }

    val right =
      if (startLine == endLine) {
        maxOf(
          layout.getPrimaryHorizontal(selStart),
          layout.getPrimaryHorizontal(selEnd),
        ).toInt()
      } else {
        editText.width
      }

    outRect.set(
      left,
      layout.getLineTop(startLine),
      right,
      layout.getLineBottom(endLine),
    )

    outRect.offset(
      editText.totalPaddingLeft - editText.scrollX,
      editText.totalPaddingTop - editText.scrollY,
    )
  }

  private fun emitContextMenuItemPressEvent(item: CallbackMenuItemData) {
    val selection = editText.selection
    val start = selection?.start ?: return
    val end = selection.end

    val reactContext = editText.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(reactContext)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(reactContext, editText.id)
    val (key, text) = item
    dispatcher?.dispatchEvent(
      OnContextMenuItemPressEvent(
        surfaceId,
        editText.id,
        text,
        key,
        start,
        end,
        editText.experimentalSynchronousEvents,
      ),
    )
  }

  companion object {
    private const val CONTEXT_MENU_ITEM_ID = 10000

    data class CallbackMenuItemData(
      val key: String,
      val text: String,
    )
  }
}
