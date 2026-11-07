package com.swmansion.enriched.text

import com.facebook.proguard.annotations.DoNotStrip

/**
 * Passes the text to and from the measurement of `EnrichedTextViewManager`,
 * which returns only the size: the shadow node (C++) offers the text built by
 * a previous measurement and takes the one built by this measurement, for the
 * view through its state. The measurement runs on the thread of the shadow
 * node, between the calls.
 */
@DoNotStrip
internal object EnrichedTextHandoff {
  private val offered = ThreadLocal<CharSequence?>()
  private val built = ThreadLocal<BuiltText?>()

  private class BuiltText(
    val text: CharSequence,
    val width: Float,
    val isReusable: Boolean,
  )

  /** Before the measurement: the text built for the same props and width, or `null` */
  @JvmStatic
  @DoNotStrip
  fun offer(text: Any?) {
    offered.set(text as? CharSequence)
    built.remove()
  }

  /** After the measurement: the width (dp) the text is laid out for, NaN when it doesn't depend on it */
  @JvmStatic
  @DoNotStrip
  fun builtWidth(): Float = built.get()?.width ?: Float.NaN

  /** After the measurement: whether another measurement can lay the text out again */
  @JvmStatic
  @DoNotStrip
  fun isBuiltReusable(): Boolean = built.get()?.isReusable ?: false

  /** After the measurement: the text for the view */
  @JvmStatic
  @DoNotStrip
  fun take(): Any? {
    val text = built.get()?.text
    offered.remove()
    built.remove()
    return text
  }

  fun takeOffered(): CharSequence? = offered.get().also { offered.remove() }

  fun putBuilt(
    text: CharSequence,
    width: Float,
    isReusable: Boolean,
  ) = built.set(BuiltText(text, width, isReusable))
}
