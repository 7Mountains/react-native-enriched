#import "EnrichedTextStyleCache.h"
#import "EnrichedHtmlStyleRegistry.h"
#import "EnrichedTextConfigBuilder.h"
#import "EnrichedTypingAttributesBuilder.h"
#import "InputConfig.h"

#include <mutex>
#include <string>
#include <vector>

using namespace facebook::react;

namespace {

// What the config and the typing attributes of a text are built from: the
// same for the texts with the same style and font, which share them
struct SharedStyleKey {
  int htmlStyleId;
  SharedColor color;
  Float fontSize;
  Float lineHeight;
  std::string fontFamily;
  std::string fontWeight;
  std::string fontStyle;
  Float scale;

  bool operator==(const SharedStyleKey &other) const {
    return htmlStyleId == other.htmlStyleId && color == other.color &&
           fontSize == other.fontSize && lineHeight == other.lineHeight &&
           fontFamily == other.fontFamily && fontWeight == other.fontWeight &&
           fontStyle == other.fontStyle && scale == other.scale;
  }
};

struct SharedStyle {
  SharedStyleKey key;
  InputConfig *config;
  NSDictionary<NSAttributedStringKey, id> *attributes;
};

// A few: the texts of an app share a handful of styles
constexpr size_t kMaxStyles = 8;

std::mutex stylesMutex;

std::vector<SharedStyle> &styles() {
  // Never destroyed: read by the shadow nodes until the app exits
  static auto *styles = new std::vector<SharedStyle>();
  return *styles;
}

} // namespace

static const Float kDefaultFontSize = 14;

// The props of the input the config and the typing attributes are built from
static void fillInputProps(EnrichedTextInputViewProps &inputProps,
                           const EnrichedTextViewProps &props,
                           CGFloat fontSizeMultiplier) {
  if (auto htmlStyle = EnrichedHtmlStyleRegistry::get(props.htmlStyleId)) {
    inputProps.htmlStyle = *htmlStyle;
  }

  Float scale = props.allowFontScaling ? fontSizeMultiplier : 1;

  auto &htmlStyle = inputProps.htmlStyle;
  for (Float *headingFontSize :
       {&htmlStyle.h1.fontSize, &htmlStyle.h2.fontSize, &htmlStyle.h3.fontSize,
        &htmlStyle.h4.fontSize, &htmlStyle.h5.fontSize,
        &htmlStyle.h6.fontSize}) {
    *headingFontSize *= scale;
  }

  inputProps.color = props.color;
  inputProps.fontSize =
      (props.fontSize > 0 ? props.fontSize : kDefaultFontSize) * scale;
  inputProps.lineHeight = props.lineHeight * scale;
  inputProps.fontFamily = props.fontFamily;
  inputProps.fontWeight = props.fontWeight;
  inputProps.fontStyle = props.fontStyle;
}

static SharedStyle styleWithProps(const EnrichedTextViewProps &props,
                                  CGFloat fontSizeMultiplier) {
  SharedStyleKey key{
      .htmlStyleId = props.htmlStyleId,
      .color = props.color,
      .fontSize = props.fontSize,
      .lineHeight = props.lineHeight,
      .fontFamily = props.fontFamily,
      .fontWeight = props.fontWeight,
      .fontStyle = props.fontStyle,
      .scale = props.allowFontScaling ? (Float)fontSizeMultiplier : 1,
  };

  {
    std::lock_guard<std::mutex> lock(stylesMutex);
    for (const auto &style : styles()) {
      if (style.key == key) {
        return style;
      }
    }
  }

  static const EnrichedTextInputViewProps defaultProps{};
  EnrichedTextInputViewProps inputProps;
  fillInputProps(inputProps, props, fontSizeMultiplier);

  // As the input on its first mount: the props differing from the defaults
  InputConfig *config =
      [EnrichedTextConfigBuilder makeConfigFromProps:inputProps
                                        oldViewProps:defaultProps
                                      previousConfig:nil]
          ?: [[InputConfig alloc] init];

  // The fonts are created lazily: before the config is shared between threads
  [config primaryFont];
  [config monospacedFont];
  [config orderedListMarkerFont];

  NSDictionary<NSAttributedStringKey, id> *attributes =
      [[EnrichedTypingAttributesBuilder buildWithConfig:config
                                                  props:inputProps] copy];

  SharedStyle style{
      .key = std::move(key), .config = config, .attributes = attributes};

  std::lock_guard<std::mutex> lock(stylesMutex);
  if (styles().size() >= kMaxStyles) {
    styles().erase(styles().begin());
  }
  styles().push_back(style);
  return style;
}

EnrichedTextStyle EnrichedTextStyleForProps(const EnrichedTextViewProps &props,
                                            CGFloat fontSizeMultiplier) {
  SharedStyle style = styleWithProps(props, fontSizeMultiplier);
  return {.config = style.config, .attributes = style.attributes};
}
