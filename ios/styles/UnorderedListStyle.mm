// UnorderedListStyle.m

#import "EnrichedTextInputView.h"
#import "InputConfig.h"
#import "StyleHeaders.h"

static NSTextList *const Bullet =
    [[NSTextList alloc] initWithMarkerFormat:NSTextListMarkerDisc options:0];

static NSArray<NSTextList *> *const TextLists = @[ Bullet ];

@implementation UnorderedListStyle

+ (StyleType)getStyleType {
  return UnorderedList;
}

+ (const char *)tagName {
  return "ul";
}

+ (NSArray<NSTextList *> *)textLists {
  return TextLists;
}

+ (NSString *)shortcut {
  return @" ";
}

+ (unichar)shortcutPrefix {
  return '-';
}

- (CGFloat)getHeadIndent {
  InputConfig *config = _input->config;

  // lists are drawn manually
  // margin before bullet + gap between bullet and paragraph
  return [config unorderedListMarginLeft] + [config unorderedListGapWidth];
}

@end
