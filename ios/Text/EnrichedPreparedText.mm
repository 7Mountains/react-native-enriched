#import "EnrichedPreparedText.h"
#import "EnrichedTextMeasurer.h"
#import "InputConfig.h"

@implementation EnrichedPreparedText {
  // The last measurement, guarded by `self`: the text is measured on the
  // layout threads
  BOOL _hasMeasured;
  CGFloat _measuredWidth;
  NSInteger _measuredNumberOfLines;
  NSLineBreakMode _measuredLineBreakMode;
  CGSize _measuredSize;
}

- (instancetype)initWithText:(NSAttributedString *)text
                      config:(InputConfig *)config {
  if (self = [super init]) {
    _text = text;
    _config = config;
  }
  return self;
}

- (CGSize)sizeConstrainedToWidth:(CGFloat)width
            maximumNumberOfLines:(NSInteger)maximumNumberOfLines
                   lineBreakMode:(NSLineBreakMode)lineBreakMode {
  @synchronized(self) {
    if (_hasMeasured && _measuredWidth == width &&
        _measuredNumberOfLines == maximumNumberOfLines &&
        _measuredLineBreakMode == lineBreakMode) {
      return _measuredSize;
    }
  }

  CGSize size = [EnrichedTextMeasurer sizeOfText:_text
                              constrainedToWidth:width
                            maximumNumberOfLines:maximumNumberOfLines
                                   lineBreakMode:lineBreakMode];

  @synchronized(self) {
    _measuredWidth = width;
    _measuredNumberOfLines = maximumNumberOfLines;
    _measuredLineBreakMode = lineBreakMode;
    _measuredSize = size;
    _hasMeasured = YES;
  }

  return size;
}

@end
