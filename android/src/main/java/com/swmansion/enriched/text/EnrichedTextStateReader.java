package com.swmansion.enriched.text;

import androidx.annotation.Nullable;
import com.facebook.react.uimanager.ReferenceStateWrapper;
import com.facebook.react.uimanager.StateWrapper;

/**
 * Reads the text from the state of the shadow node (`EnrichedTextState`). In Java: React Native's
 * interface of the states backed by a JNI reference is internal to its Kotlin module, as for the
 * prepared layout of its text.
 */
final class EnrichedTextStateReader {
  private EnrichedTextStateReader() {}

  static @Nullable CharSequence readText(@Nullable StateWrapper stateWrapper) {
    if (!(stateWrapper instanceof ReferenceStateWrapper)) {
      return null;
    }

    Object text = ((ReferenceStateWrapper) stateWrapper).getStateDataReference();
    return text instanceof CharSequence ? (CharSequence) text : null;
  }
}
