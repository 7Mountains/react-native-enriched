#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

@implementation H2Style
+ (StyleType)getStyleType {
  return H2;
}
+ (BOOL)isParagraphStyle {
  return YES;
}
+ (const char *)tagName {
  return "h2";
}
+ (EnrichedHeadingLevel)headingLevel {
  return EnrichedHeadingH2;
}
- (CGFloat)getHeadingFontSize {
  return [((id<EnrichedStyleHost>)input).config h2FontSize];
}
- (BOOL)isHeadingBold {
  return [((id<EnrichedStyleHost>)input).config h2Bold];
}
@end
