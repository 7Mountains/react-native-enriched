#pragma once

#include <fbjni/fbjni.h>
#include <folly/dynamic.h>
#include <react/jni/SafeReleaseJniRef.h>
#include <react/renderer/graphics/Float.h>

#include <cmath>
#include <limits>

namespace facebook::react {

// A text built by the measurement (an immutable CharSequence). Released on
// any thread: e.g. Hermes' GC thread destroys shadow nodes
using EnrichedTextRef = SafeReleaseJniRef<jni::global_ref<jobject>>;

// The text of <EnrichedTextView> built by its measurement
struct EnrichedPreparedText {
  EnrichedTextRef text;

  // The width (dp) the text is laid out for, NaN when it doesn't depend on it
  // (spans taking the width of their host, e.g. the horizontal rule)
  Float width{std::numeric_limits<Float>::quiet_NaN()};

  // The display configuration used to convert the text and its spans to
  // pixels. A prepared text can't be reused after either scale changes.
  Float pointScaleFactor{std::numeric_limits<Float>::quiet_NaN()};
  Float fontSizeMultiplier{std::numeric_limits<Float>::quiet_NaN()};

  // Whether a measurement can lay it out again once its view owns it: not
  // with spans that aren't thread safe (see `EnrichedTextContent.isReusable`)
  bool isReusable{false};

  // Whether the text is built for the display configuration and laid out for
  // the width, up to the pixel grid
  bool fits(Float otherWidth, Float otherPointScaleFactor,
            Float otherFontSizeMultiplier) const {
    return pointScaleFactor == otherPointScaleFactor &&
           fontSizeMultiplier == otherFontSizeMultiplier &&
           (std::isnan(width) ||
            std::abs(width - otherWidth) <= 1 / otherPointScaleFactor);
  }
};

// The text built by the measurement, for the view to show without parsing
// the HTML on the UI thread
class EnrichedTextState {
public:
  EnrichedTextState() = default;

  EnrichedTextState(folly::dynamic layoutProps, EnrichedPreparedText prepared)
      : layoutProps(std::move(layoutProps)), prepared(std::move(prepared)) {}

  // Not updated from Kotlin
  EnrichedTextState(const EnrichedTextState &previousState,
                    folly::dynamic /*data*/)
      : EnrichedTextState(previousState) {}

  // The props the text is built from (see `toDynamic`)
  folly::dynamic layoutProps;

  EnrichedPreparedText prepared;

  folly::dynamic getDynamic() const { return {}; }

  jni::local_ref<jobject> getJNIReference() const {
    return jni::make_local(prepared.text.get());
  }
};

} // namespace facebook::react
