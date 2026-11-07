#pragma once
#include <folly/dynamic.h>
#include <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>
#include <react/renderer/graphics/Color.h>

#include <memory>
#include <string>

namespace facebook::react {

// What the text of <EnrichedTextView> is built from: the props, and the font
// scale of the system
struct EnrichedTextKey {
  std::string text;
  folly::dynamic htmlStyle;
  SharedColor color;
  Float fontSize{0};
  Float lineHeight{0};
  std::string fontFamily;
  std::string fontWeight;
  std::string fontStyle;
  bool allowFontScaling{true};
  Float fontSizeMultiplier{1};

  static EnrichedTextKey fromProps(const EnrichedTextViewProps &props,
                                   Float fontSizeMultiplier) {
    return {
        .text = props.text,
        .htmlStyle = props.htmlStyle,
        .color = props.color,
        .fontSize = props.fontSize,
        .lineHeight = props.lineHeight,
        .fontFamily = props.fontFamily,
        .fontWeight = props.fontWeight,
        .fontStyle = props.fontStyle,
        .allowFontScaling = props.allowFontScaling,
        .fontSizeMultiplier = fontSizeMultiplier,
    };
  }

  bool operator==(const EnrichedTextKey &other) const {
    return text == other.text && htmlStyle == other.htmlStyle &&
           color == other.color && fontSize == other.fontSize &&
           lineHeight == other.lineHeight && fontFamily == other.fontFamily &&
           fontWeight == other.fontWeight && fontStyle == other.fontStyle &&
           allowFontScaling == other.allowFontScaling &&
           fontSizeMultiplier == other.fontSizeMultiplier;
  }

  bool operator!=(const EnrichedTextKey &other) const {
    return !(*this == other);
  }
};

// The text built by the measurement (an EnrichedPreparedText), for the view to
// show without parsing the HTML on the main thread
class EnrichedTextViewState {
public:
  EnrichedTextViewState() = default;

  EnrichedTextViewState(EnrichedTextKey key, std::shared_ptr<void> preparedText)
      : key_(std::move(key)), preparedText_(std::move(preparedText)) {}

  const EnrichedTextKey &getKey() const { return key_; }

  const std::shared_ptr<void> &getPreparedText() const { return preparedText_; }

private:
  EnrichedTextKey key_{};
  std::shared_ptr<void> preparedText_{};
};

} // namespace facebook::react
