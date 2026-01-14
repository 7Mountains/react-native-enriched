package com.swmansion.enriched.utils

import android.text.Layout

fun String.toAlignment(): Layout.Alignment =
  when (this.lowercase()) {
    "left" -> Layout.Alignment.ALIGN_NORMAL

    "right" -> Layout.Alignment.ALIGN_OPPOSITE

    "center" -> Layout.Alignment.ALIGN_CENTER

    "justify" -> Layout.Alignment.ALIGN_NORMAL

    // justify is not supported by android
    "default" -> Layout.Alignment.ALIGN_NORMAL

    else -> Layout.Alignment.ALIGN_NORMAL
  }

fun Layout.Alignment.toStringName(): String =
  when (this) {
    Layout.Alignment.ALIGN_NORMAL -> "left"
    Layout.Alignment.ALIGN_OPPOSITE -> "right"
    Layout.Alignment.ALIGN_CENTER -> "center"
    else -> "default"
  }
