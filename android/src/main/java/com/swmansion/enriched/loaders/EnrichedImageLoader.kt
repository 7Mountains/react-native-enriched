package com.swmansion.enriched.loaders

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Handler
import android.os.Looper
import androidx.core.graphics.createBitmap
import androidx.core.net.toUri
import com.facebook.common.executors.CallerThreadExecutor
import com.facebook.common.references.CloseableReference
import com.facebook.datasource.DataSource
import com.facebook.datasource.DataSubscriber
import com.facebook.drawee.backends.pipeline.Fresco
import com.facebook.imagepipeline.image.CloseableBitmap
import com.facebook.imagepipeline.image.CloseableImage
import com.facebook.imagepipeline.request.ImageRequestBuilder
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.modules.fresco.ReactNetworkImageRequest
import com.facebook.react.views.imagehelper.ResourceDrawableIdHelper

class EnrichedImageLoader private constructor(
  private val reactContext: ReactContext,
) {
  private val mainHandler = Handler(Looper.getMainLooper())

  companion object {
    lateinit var instance: EnrichedImageLoader

    fun init(context: ReactContext) {
      instance = EnrichedImageLoader(context)
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap {
      if (drawable is BitmapDrawable) return drawable.bitmap

      val bmp =
        createBitmap(
          drawable.intrinsicWidth.takeIf { it > 0 } ?: 1,
          drawable.intrinsicHeight.takeIf { it > 0 } ?: 1,
        )
      val canvas = Canvas(bmp)
      drawable.setBounds(0, 0, canvas.width, canvas.height)
      drawable.draw(canvas)
      return bmp
    }
  }

  fun load(
    url: String?,
    callback: (Bitmap?) -> Unit,
  ) {
    if (url == null) {
      callback(null)
      return
    }

    if (!url.startsWith("http", ignoreCase = true)) {
      loadLocalImage(url, callback)
    } else {
      loadRemoteImage(url, callback)
    }
  }

  fun loadLocalImage(
    name: String,
    callback: (Bitmap?) -> Unit,
  ) {
    val drawable = ResourceDrawableIdHelper.getResourceDrawable(reactContext, name)

    if (drawable != null) {
      val bmp = drawableToBitmap(drawable)
      mainHandler.post { callback(bmp) }
    } else {
      mainHandler.post { callback(null) }
    }
  }

  fun getLocalImage(name: String): Drawable? = ResourceDrawableIdHelper.getResourceDrawable(reactContext, name)

  fun loadRemoteImage(
    url: String,
    callback: (Bitmap?) -> Unit,
  ) {
    val uri = url.toUri()

    val requestBuilder =
      ImageRequestBuilder.newBuilderWithSource(uri)
    val cookieHeader =
      EnrichedCookieManager.cookieHeaderForUrl(url)

    val headersMap = Arguments.createMap()
    if (cookieHeader != null) {
      headersMap.putString("Cookie", cookieHeader)
    }

    val imageRequest =
      ReactNetworkImageRequest
        .fromBuilderWithHeaders(requestBuilder, headersMap)

    val dataSource =
      Fresco.getImagePipeline().fetchDecodedImage(imageRequest, null)

    dataSource.subscribe(
      object : DataSubscriber<CloseableReference<CloseableImage>> {
        override fun onNewResult(dataSource: DataSource<CloseableReference<CloseableImage>?>) {
          if (!dataSource.isFinished) return

          val ref = dataSource.result ?: return
          val image = ref.get()

          val bmp = (image as? CloseableBitmap)?.underlyingBitmap
          val safeBitmap =
            bmp?.copy(bmp.config ?: Bitmap.Config.ARGB_8888, false)

          mainHandler.post { callback(safeBitmap) }
          CloseableReference.closeSafely(ref)
        }

        override fun onFailure(dataSource: DataSource<CloseableReference<CloseableImage>?>) {
          mainHandler.post { callback(null) }
        }

        override fun onCancellation(dataSource: DataSource<CloseableReference<CloseableImage>?>) {
          mainHandler.post { callback(null) }
        }

        override fun onProgressUpdate(dataSource: DataSource<CloseableReference<CloseableImage>?>) {}
      },
      CallerThreadExecutor.getInstance(),
    )
  }
}
