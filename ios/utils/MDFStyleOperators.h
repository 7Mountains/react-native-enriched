#pragma once
#import <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>

namespace facebook {
namespace react {

inline bool operator==(const EnrichedTextInputViewHtmlStyleMdfStruct &a,
                       const EnrichedTextInputViewHtmlStyleMdfStruct &b) {

  return a.height == b.height && a.imageUri == b.imageUri &&
         a.borderRadius == b.borderRadius && a.borderWidth == b.borderWidth &&
         a.borderColor == b.borderColor && a.stripeWidth == b.stripeWidth &&
         a.fontSize == b.fontSize && a.fontWeight == b.fontWeight &&
         a.marginLeft == b.marginLeft && a.marginRight == b.marginRight &&
         a.marginTop == b.marginTop && a.marginBottom == b.marginBottom &&
         a.textColor == b.textColor && a.backgroundColor == b.backgroundColor &&
         a.imageHeight == b.imageHeight && a.imageWidth == b.imageWidth &&
         a.imageBorderRadius == b.imageBorderRadius &&
         a.paddingTop == b.paddingTop && a.paddingBottom == b.paddingBottom &&
         a.paddingRight == b.paddingRight && a.paddingLeft == b.paddingLeft &&
         a.imageContainerWidth == b.imageContainerWidth &&
         a.imageContainerHeight == b.imageContainerHeight;
}

inline bool operator!=(const EnrichedTextInputViewHtmlStyleMdfStruct &a,
                       const EnrichedTextInputViewHtmlStyleMdfStruct &b) {
  return !(a == b);
}

} // namespace react
} // namespace facebook
