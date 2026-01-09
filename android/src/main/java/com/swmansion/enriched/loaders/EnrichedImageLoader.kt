package com.swmansion.enriched.loaders

import android.graphics.Bitmap
import android.os.Handler
import android.os.Looper
import androidx.core.net.toUri
import com.facebook.common.executors.CallerThreadExecutor
import com.facebook.common.references.CloseableReference
import com.facebook.datasource.DataSource
import com.facebook.datasource.DataSubscriber
import com.facebook.drawee.backends.pipeline.Fresco
import com.facebook.imagepipeline.image.CloseableBitmap
import com.facebook.imagepipeline.image.CloseableImage
import com.facebook.imagepipeline.request.ImageRequestBuilder

class EnrichedImageLoader private constructor() {
  private val mainHandler = Handler(Looper.getMainLooper())

  companion object {
    val instance: EnrichedImageLoader by lazy { EnrichedImageLoader() }
  }

  fun load(
    url: String,
    callback: (Bitmap?) -> Unit,
  ) {
    val uri = url.toUri()

    val request =
      ImageRequestBuilder
        .newBuilderWithSource(uri)
        .build()

    val dataSource = Fresco.getImagePipeline().fetchDecodedImage(request, null)

    dataSource.subscribe(
      object : DataSubscriber<CloseableReference<CloseableImage>> {
        override fun onNewResult(dataSource: DataSource<CloseableReference<CloseableImage>?>) {
          if (dataSource == null || !dataSource.isFinished) return

          val ref = dataSource.result ?: return
          val image = ref.get()

          val bmp =
            if (image is CloseableBitmap) {
              image.underlyingBitmap
            } else {
              null
            }

          mainHandler.post { callback(bmp) }

          CloseableReference.closeSafely(ref)
        }

        override fun onFailure(dataSource: DataSource<CloseableReference<CloseableImage>?>) {
          mainHandler.post { callback(null) }
        }

        override fun onCancellation(dataSource: DataSource<CloseableReference<CloseableImage>?>) {
          mainHandler.post { callback(null) }
        }

        override fun onProgressUpdate(dataSource: DataSource<CloseableReference<CloseableImage>?>) {
          // no-op
        }
      },
      CallerThreadExecutor.getInstance(),
    )
  }
}
