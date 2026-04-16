package com.swmansion.enriched.contextmenu

import android.view.ActionMode
import com.facebook.react.bridge.ReadableArray
import com.swmansion.enriched.EnrichedClipboardManager
import com.swmansion.enriched.EnrichedTextInputView

class EnrichedContextMenuController(
  private val editText: EnrichedTextInputView,
  private val clipboardManager: EnrichedClipboardManager,
) {
  private var currentActionMode: ActionMode? = null
  private var contextMenuItems: List<EnrichedActionModeCallback.Companion.CallbackMenuItemData> =
    emptyList()

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
      result.add(
        EnrichedActionModeCallback.Companion.CallbackMenuItemData(
          key = key,
          text = text,
        ),
      )
    }

    contextMenuItems = result
  }

  fun onTextContextMenuItem(id: Int): Boolean =
    when (id) {
      android.R.id.copy -> {
        clipboardManager.copy()
        true
      }

      android.R.id.paste -> {
        clipboardManager.paste()
        true
      }

      android.R.id.cut -> {
        clipboardManager.cut()
        true
      }

      else -> {
        false
      }
    }

  fun onActionModeStarted(actionMode: ActionMode?) {
    this.currentActionMode = actionMode
  }

  fun onActionModeDestroyed() {
    currentActionMode = null
  }

  fun hideContextMenu() {
    currentActionMode?.let {
      val prevStart = editText.selectionStart
      val prevEnd = editText.selectionEnd
      it.finish()
      currentActionMode = null
      editText.setSelection(prevStart, prevEnd)
    }
  }

  fun wrapActionModeCallback(callback: ActionMode.Callback?): ActionMode.Callback? {
    val menuItems = contextMenuItems
    if (menuItems.isEmpty()) {
      return callback
    }

    return EnrichedActionModeCallback(
      editText = editText,
      original = callback,
      contextMenuItems = menuItems,
      controller = this,
    )
  }
}
