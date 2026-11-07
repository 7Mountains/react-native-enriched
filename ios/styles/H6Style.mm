#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

@implementation H6Style
+ (StyleType)getStyleType {
  return H6;
}
+ (BOOL)isParagraphStyle {
  return YES;
}
+ (const char *)tagName {
  return "h6";
}
+ (EnrichedHeadingLevel)headingLevel {
  return EnrichedHeadingH6;
}
- (CGFloat)getHeadingFontSize {
  return [((id<EnrichedStyleHost>)input).config h6FontSize];
}
- (BOOL)isHeadingBold {
  return [((id<EnrichedStyleHost>)input).config h6Bold];
}
@end
