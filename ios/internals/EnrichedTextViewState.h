#pragma once
#include <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>
#include <react/renderer/graphics/Color.h>

#include <memory>
#include <string>

namespace facebook::react {

// What the text of <EnrichedTextView> is built from: the props, and the font
// scale of the system
struct EnrichedTextKey {
  // Shared, not copied: the key is made for every measurement, and the html
  // can be long
  std::shared_ptr<const EnrichedTextViewProps> props;
  Float fontSizeMultiplier{1};

  static EnrichedTextKey
  fromProps(std::shared_ptr<const EnrichedTextViewProps> props,
            Float fontSizeMultiplier) {
    return {
        .props = std::move(props),
        .fontSizeMultiplier = fontSizeMultiplier,
    };
  }

  bool operator==(const EnrichedTextKey &other) const {
    if (fontSizeMultiplier != other.fontSizeMultiplier) {
      return false;
    }
    // The same props (e.g. measured again, or a clone of the node): equal
    // without reading the html
    if (props == other.props) {
      return true;
    }
    if (props == nullptr || other.props == nullptr) {
      return false;
    }

    const auto &a = *props;
    const auto &b = *other.props;
    return a.text == b.text && a.htmlStyleId == b.htmlStyleId &&
           a.color == b.color && a.fontSize == b.fontSize &&
           a.lineHeight == b.lineHeight && a.fontFamily == b.fontFamily &&
           a.fontWeight == b.fontWeight && a.fontStyle == b.fontStyle &&
           a.allowFontScaling == b.allowFontScaling;
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
