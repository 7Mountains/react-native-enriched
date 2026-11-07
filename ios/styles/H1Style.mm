#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

@implementation H1Style
+ (StyleType)getStyleType {
  return H1;
}
+ (BOOL)isParagraphStyle {
  return YES;
}
+ (const char *)tagName {
  return "h1";
}
+ (EnrichedHeadingLevel)headingLevel {
  return EnrichedHeadingH1;
}
- (CGFloat)getHeadingFontSize {
  return [((id<EnrichedStyleHost>)input).config h1FontSize];
}
- (BOOL)isHeadingBold {
  return [((id<EnrichedStyleHost>)input).config h1Bold];
}
@end
