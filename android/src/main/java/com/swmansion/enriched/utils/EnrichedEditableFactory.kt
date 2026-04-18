package com.swmansion.enriched.textinput.utils

import android.text.Editable
import android.text.Spannable
import com.swmansion.enriched.watchers.EnrichedSpanWatcher

class EnrichedEditableFactory(
  private val watcher: EnrichedSpanWatcher,
) : Editable.Factory() {
  override fun newEditable(source: CharSequence): Editable {
    val editable = super.newEditable(source)
    editable.removeSpan(watcher)
    editable.setSpan(watcher, 0, editable.length, Spannable.SPAN_INCLUSIVE_INCLUSIVE)
    return editable
  }
}
