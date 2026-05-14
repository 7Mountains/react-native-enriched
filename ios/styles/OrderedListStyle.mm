#import "EnrichedTextInputView.h"
#import "InputConfig.h"
#import "StyleHeaders.h"

static NSTextList *const NumberBulletList =
    [[NSTextList alloc] initWithMarkerFormat:NSTextListMarkerDecimal options:0];

static NSArray<NSTextList *> *const TextLists = @[ NumberBulletList ];

@implementation OrderedListStyle

+ (StyleType)getStyleType {
  return OrderedList;
}

+ (const char *)tagName {
  return "ol";
}

+ (NSArray<NSTextList *> *)textLists {
  return TextLists;
}

+ (NSString *)shortcut {
  return @".";
}

+ (unichar)shortcutPrefix {
  return '1';
}

- (CGFloat)getHeadIndent {
  InputConfig *config = _input->config;

  // lists are drawn manually
  // margin before marker + gap between marker and paragraph
  return [config orderedListMarginLeft] + [config orderedListGapWidth];
}

@end
