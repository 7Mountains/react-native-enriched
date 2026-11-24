#pragma once

#include <fbjni/fbjni.h>
#include <folly/dynamic.h>
#include <react/jni/SafeReleaseJniRef.h>
#include <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>
#include <react/renderer/graphics/Float.h>

#include <cmath>
#include <limits>
#include <memory>

namespace facebook::react {

// Whether the props lay the text out the same way
inline bool hasSameTextLayout(const EnrichedTextViewProps &props,
                              const EnrichedTextViewProps &otherProps) {
  return props.text == otherProps.text &&
         props.htmlStyleId == otherProps.htmlStyleId &&
         props.fontSize == otherProps.fontSize &&
         props.lineHeight == otherProps.lineHeight &&
         props.fontFamily == otherProps.fontFamily &&
         props.fontWeight == otherProps.fontWeight &&
         props.fontStyle == otherProps.fontStyle &&
         props.allowFontScaling == otherProps.allowFontScaling &&
         props.numberOfLines == otherProps.numberOfLines &&
         props.ellipsizeMode == otherProps.ellipsizeMode;
}

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

  EnrichedTextState(std::shared_ptr<const EnrichedTextViewProps> props,
                    EnrichedPreparedText prepared)
      : props(std::move(props)), prepared(std::move(prepared)) {}

  // Not updated from Kotlin
  EnrichedTextState(const EnrichedTextState &previousState,
                    folly::dynamic /*data*/)
      : EnrichedTextState(previousState) {}

  // The props the text is built from
  std::shared_ptr<const EnrichedTextViewProps> props;

  EnrichedPreparedText prepared;

  // Whether the text is built from these props: the same ones in most cases
  bool isBuiltFrom(const EnrichedTextViewProps &otherProps) const {
    return props != nullptr && (props.get() == &otherProps ||
                                hasSameTextLayout(*props, otherProps));
  }

  folly::dynamic getDynamic() const { return {}; }

  jni::local_ref<jobject> getJNIReference() const {
    return jni::make_local(prepared.text.get());
  }
};

} // namespace facebook::react
