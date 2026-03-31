#pragma once
#import <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>

namespace facebook {
namespace react {

inline bool operator==(const EnrichedTextInputViewHtmlStyleMdfTitleStruct &a,
                       const EnrichedTextInputViewHtmlStyleMdfTitleStruct &b) {
  return a.color == b.color && a.fontWeight == b.fontWeight &&
         a.fontSize == b.fontSize && a.fontFamily == b.fontFamily;
}

inline bool
operator==(const EnrichedTextInputViewHtmlStyleMdfImageContainerStruct &a,
           const EnrichedTextInputViewHtmlStyleMdfImageContainerStruct &b) {
  return a.width == b.width && a.height == b.height &&
         a.borderRadius == b.borderRadius;
}

inline bool
operator==(const EnrichedTextInputViewHtmlStyleMdfContainerStruct &a,
           const EnrichedTextInputViewHtmlStyleMdfContainerStruct &b) {
  return a.minHeight == b.minHeight && a.borderWidth == b.borderWidth &&
         a.borderColor == b.borderColor && a.paddingTop == b.paddingTop &&
         a.paddingBottom == b.paddingBottom &&
         a.paddingRight == b.paddingRight && a.paddingLeft == b.paddingLeft &&
         a.marginLeft == b.marginLeft && a.marginRight == b.marginRight &&
         a.marginTop == b.marginTop && a.marginBottom == b.marginBottom &&
         a.backgroundColor == b.backgroundColor &&
         a.borderStyle == b.borderStyle && a.borderRadius == b.borderRadius &&
         a.borderLeftWidth == b.borderLeftWidth;
}

inline bool operator==(const EnrichedTextInputViewHtmlStyleMdfImageStruct &a,
                       const EnrichedTextInputViewHtmlStyleMdfImageStruct &b) {
  return a.width == b.width && a.height == b.height &&
         a.resizeMode == b.resizeMode;
}

inline bool
operator==(const EnrichedTextInputViewHtmlStyleMdfTextContainerStruct &a,
           const EnrichedTextInputViewHtmlStyleMdfTextContainerStruct &b) {
  return a.paddingTop == b.paddingTop && a.paddingBottom == b.paddingBottom &&
         a.paddingRight == b.paddingRight && a.paddingLeft == b.paddingLeft &&
         a.marginLeft == b.marginLeft && a.marginRight == b.marginRight &&
         a.marginTop == b.marginTop && a.marginBottom == b.marginBottom;
}

inline bool operator==(const EnrichedTextInputViewHtmlStyleMdfStruct &a,
                       const EnrichedTextInputViewHtmlStyleMdfStruct &b) {
  return a.imageUri == b.imageUri && a.title == b.title &&
         a.container == b.container && a.imageContainer == b.imageContainer &&
         a.image == b.image && a.textContainer == b.textContainer;
}

inline bool operator!=(const EnrichedTextInputViewHtmlStyleMdfStruct &a,
                       const EnrichedTextInputViewHtmlStyleMdfStruct &b) {
  return !(a == b);
}

} // namespace react
} // namespace facebook
