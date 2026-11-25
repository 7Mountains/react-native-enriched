#import "EnrichedLaidOutText.h"

@implementation EnrichedLaidOutText

- (instancetype)initWithTextStorage:(NSTextStorage *)textStorage
                      layoutManager:(NSLayoutManager *)layoutManager
                      textContainer:(NSTextContainer *)textContainer
                               size:(CGSize)size {
  if (self = [super init]) {
    _textStorage = textStorage;
    _layoutManager = layoutManager;
    _textContainer = textContainer;
    _size = size;
  }
  return self;
}

@end
