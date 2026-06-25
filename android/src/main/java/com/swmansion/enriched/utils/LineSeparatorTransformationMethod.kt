package com.swmansion.enriched.utils

import android.text.method.ReplacementTransformationMethod
import com.swmansion.enriched.constants.Strings

class LineSeparatorTransformationMethod : ReplacementTransformationMethod() {
  override fun getOriginal(): CharArray = charArrayOf(Strings.LINE_SEPARATOR)

  override fun getReplacement(): CharArray = charArrayOf(Strings.NEWLINE)
}
