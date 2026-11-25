#import "EnrichedTextDrawingView.h"

@implementation EnrichedTextDrawingView

- (instancetype)initWithTextContainer:(NSTextContainer *)textContainer {
  if (self = [super initWithFrame:CGRectZero]) {
    _textContainer = textContainer;
    self.opaque = NO;
    self.backgroundColor = UIColor.clearColor;
    // Drawn again at its new size, not stretched
    self.contentMode = UIViewContentModeRedraw;
  }
  return self;
}

- (void)drawRect:(CGRect)rect {
  NSLayoutManager *layoutManager = _textContainer.layoutManager;
  if (layoutManager == nil) {
    return;
  }

  // As a text view draws it, at the origin of its container
  NSRange glyphRange = [layoutManager glyphRangeForBoundingRect:rect
                                                inTextContainer:_textContainer];
  [layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:CGPointZero];
  [layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:CGPointZero];
}

@end
