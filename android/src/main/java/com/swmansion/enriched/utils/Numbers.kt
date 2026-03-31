package com.swmansion.enriched.utils

import android.content.res.Resources

object Dimens {
  val density = Resources.getSystem().displayMetrics.density
}

val Float.dp: Float
  get() = this * Dimens.density

val Int.dp: Float
  get() = this * Dimens.density
