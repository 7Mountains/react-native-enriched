#import "EnrichedPreparedText.h"
#import "EnrichedTextDirection.h"
#import "EnrichedTextMeasurer.h"
#import "InputConfig.h"

#import <os/lock.h>

@implementation EnrichedPreparedText {
  // The last measurement, guarded by `_lock`: the text is measured on the
  // layout threads
  os_unfair_lock _lock;
  BOOL _hasMeasured;
  CGFloat _measuredWidth;
  NSInteger _measuredNumberOfLines;
  NSLineBreakMode _measuredLineBreakMode;
  CGSize _measuredSize;
  EnrichedLaidOutText *_laidOutText;
}

- (instancetype)initWithText:(NSAttributedString *)text
                      config:(InputConfig *)config {
  if (self = [super init]) {
    _text = text;
    _config = config;
    _lock = OS_UNFAIR_LOCK_INIT;
    _isLaidOutAtAnyWidth = EnrichedIsTextLaidOutAtAnyWidth(text);
  }
  return self;
}

- (CGSize)sizeConstrainedToWidth:(CGFloat)width
            maximumNumberOfLines:(NSInteger)maximumNumberOfLines
                   lineBreakMode:(NSLineBreakMode)lineBreakMode {
  os_unfair_lock_lock(&_lock);
  BOOL isMeasured = _hasMeasured && _measuredWidth == width &&
                    _measuredNumberOfLines == maximumNumberOfLines &&
                    _measuredLineBreakMode == lineBreakMode;
  CGSize measuredSize = _measuredSize;
  os_unfair_lock_unlock(&_lock);

  if (isMeasured) {
    return measuredSize;
  }

  EnrichedLaidOutText *laidOutText =
      [EnrichedTextMeasurer layOutText:_text
                    constrainedToWidth:width
                  maximumNumberOfLines:maximumNumberOfLines
                         lineBreakMode:lineBreakMode];
  CGSize size = laidOutText.size;

  os_unfair_lock_lock(&_lock);
  _measuredWidth = width;
  _measuredNumberOfLines = maximumNumberOfLines;
  _measuredLineBreakMode = lineBreakMode;
  _measuredSize = size;
  _hasMeasured = YES;
  _laidOutText = laidOutText;
  os_unfair_lock_unlock(&_lock);

  return size;
}

- (EnrichedLaidOutText *)takeLaidOutTextForSize:(CGSize)size
                           maximumNumberOfLines:(NSInteger)maximumNumberOfLines
                                  lineBreakMode:(NSLineBreakMode)lineBreakMode {
  // Up to the pixel grid the layout rounds the size to
  const CGFloat tolerance = 0.5;

  os_unfair_lock_lock(&_lock);
  EnrichedLaidOutText *laidOutText = _laidOutText;
  CGFloat containerWidth = laidOutText.textContainer.size.width;
  BOOL fits =
      laidOutText != nil && _measuredNumberOfLines == maximumNumberOfLines &&
      _measuredLineBreakMode == lineBreakMode &&
      fabs(size.height - laidOutText.size.height) <= tolerance &&
      (_isLaidOutAtAnyWidth && containerWidth < CGFLOAT_MAX
           // Drawn in a container wider than the view, as wide as it can be
           ? size.width >= laidOutText.size.width - tolerance &&
                 size.width <= containerWidth + tolerance
           : fabs(size.width - containerWidth) <= tolerance);
  if (fits) {
    _laidOutText = nil;
  }
  os_unfair_lock_unlock(&_lock);

  return fits ? laidOutText : nil;
}

@end
