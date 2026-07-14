package com.swmansion.enriched.utils

import android.content.res.Resources

object Dimens {
  val density = Resources.getSystem().displayMetrics.density
}

val Float.dp: Float
  get() = this * Dimens.density

val Int.dp: Int
  get() = (this * Resources.getSystem().displayMetrics.density).toInt()
