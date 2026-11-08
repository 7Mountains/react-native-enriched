#pragma once

#include <folly/dynamic.h>
#include <react/renderer/components/FBReactNativeSpec/Props.h>
#include <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>
#include <react/renderer/core/propsConversions.h>

namespace facebook::react {

#ifdef RN_SERIALIZABLE_STATE
inline folly::dynamic toDynamic(const EnrichedTextInputViewProps &props) {
  // Serialize only metrics affecting props
  folly::dynamic serializedProps = folly::dynamic::object();
  serializedProps["defaultValue"] = props.defaultValue;
  serializedProps["placeholder"] = props.placeholder;
  serializedProps["fontSize"] = props.fontSize;
  serializedProps["fontWeight"] = props.fontWeight;
  serializedProps["fontStyle"] = props.fontStyle;
  serializedProps["fontFamily"] = props.fontFamily;
  serializedProps["htmlStyle"] = toDynamic(props.htmlStyle);

  return serializedProps;
}

inline folly::dynamic toDynamic(const EnrichedTextViewProps &props) {
  // Serialize only metrics affecting props
  folly::dynamic serializedProps = folly::dynamic::object();
  serializedProps["text"] = props.text;
  serializedProps["htmlStyle"] = props.htmlStyle;
  serializedProps["numberOfLines"] = props.numberOfLines;
  serializedProps["ellipsizeMode"] = props.ellipsizeMode;
  serializedProps["allowFontScaling"] = props.allowFontScaling;
  serializedProps["fontSize"] = props.fontSize;
  serializedProps["lineHeight"] = props.lineHeight;
  serializedProps["fontFamily"] = props.fontFamily;
  serializedProps["fontWeight"] = props.fontWeight;
  serializedProps["fontStyle"] = props.fontStyle;

  return serializedProps;
}

inline folly::dynamic toDynamic(const EnrichedTextProps &props) {
  folly::dynamic serializedProps = folly::dynamic::object();
  serializedProps["text"] = props.text;
  serializedProps["htmlStyle"] = props.htmlStyle;
  serializedProps["numberOfLines"] = props.numberOfLines;
  serializedProps["ellipsizeMode"] = props.ellipsizeMode;
  serializedProps["allowFontScaling"] = props.allowFontScaling;
  serializedProps["fontSize"] = props.fontSize;
  serializedProps["lineHeight"] = props.lineHeight;
  serializedProps["fontFamily"] = props.fontFamily;
  serializedProps["fontWeight"] = props.fontWeight;
  serializedProps["fontStyle"] = props.fontStyle;

  return serializedProps;
}
#endif

} // namespace facebook::react
