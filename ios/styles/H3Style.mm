#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

@implementation H3Style
+ (StyleType)getStyleType {
  return H3;
}
+ (BOOL)isParagraphStyle {
  return YES;
}
+ (const char *)tagName {
  return "h3";
}
+ (EnrichedHeadingLevel)headingLevel {
  return EnrichedHeadingH3;
}
- (CGFloat)getHeadingFontSize {
  return [((id<EnrichedStyleHost>)input).config h3FontSize];
}
- (BOOL)isHeadingBold {
  return [((id<EnrichedStyleHost>)input).config h3Bold];
}
@end
