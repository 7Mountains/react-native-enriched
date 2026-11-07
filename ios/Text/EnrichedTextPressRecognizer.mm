#import "EnrichedTextPressRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

// As UILongPressGestureRecognizer
static const NSTimeInterval kMinimumPressDuration = 0.5;
static const CGFloat kAllowableMovement = 10;

@implementation EnrichedTextPressableRange
@end

@implementation EnrichedTextPressRecognizer {
  EnrichedTextPressableRange *_pressedRange;
  CGPoint _touchDownPoint;
  BOOL _didLongPress;
  // Invalidates the long press timer of a previous press
  NSUInteger _pressId;
}

- (instancetype)init {
  return [super initWithTarget:nil action:nil];
}

- (EnrichedTextPressableRange *)pressedRange {
  return _pressedRange;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  [super touchesBegan:touches withEvent:event];

  // Another finger: the press goes on, the new touch isn't a press
  if (_pressedRange != nil) {
    return;
  }

  if (touches.count != 1 || event.allTouches.count > 1) {
    self.state = UIGestureRecognizerStateFailed;
    return;
  }

  CGPoint point = [touches.anyObject locationInView:self.view];
  EnrichedTextPressableRange *range =
      [self.pressDelegate pressRecognizer:self pressableRangeAtPoint:point];

  if (range == nil) {
    self.state = UIGestureRecognizerStateFailed;
    return;
  }

  _pressedRange = range;
  _touchDownPoint = point;
  _didLongPress = NO;
  NSUInteger pressId = ++_pressId;

  self.state = UIGestureRecognizerStateBegan;
  [self.pressDelegate pressRecognizer:self didBeginPressingRange:range];

  __weak EnrichedTextPressRecognizer *weakSelf = self;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                               (int64_t)(kMinimumPressDuration * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
                   [weakSelf longPressTimerFiredForPressId:pressId];
                 });
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  [super touchesMoved:touches withEvent:event];

  if (_pressedRange == nil) {
    return;
  }

  CGPoint point = [touches.anyObject locationInView:self.view];
  BOOL didMove = hypot(point.x - _touchDownPoint.x,
                       point.y - _touchDownPoint.y) > kAllowableMovement;

  if (didMove || ![self.pressDelegate pressRecognizer:self
                                                range:_pressedRange
                                        containsPoint:point]) {
    [self cancelPress];
  }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  [super touchesEnded:touches withEvent:event];

  if (_pressedRange == nil) {
    return;
  }

  EnrichedTextPressableRange *range = _pressedRange;
  BOOL didLongPress = _didLongPress;
  CGPoint point = [touches.anyObject locationInView:self.view];

  [self finishPress];
  self.state = UIGestureRecognizerStateEnded;

  if (!didLongPress && [self.pressDelegate pressRecognizer:self
                                                     range:range
                                             containsPoint:point]) {
    [self.pressDelegate pressRecognizer:self didTapRange:range];
  }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches
               withEvent:(UIEvent *)event {
  [super touchesCancelled:touches withEvent:event];

  if (_pressedRange != nil) {
    [self cancelPress];
  }
}

- (void)reset {
  [super reset];

  _pressedRange = nil;
  _didLongPress = NO;
  _pressId++;
}

- (void)longPressTimerFiredForPressId:(NSUInteger)pressId {
  if (pressId != _pressId || _pressedRange == nil || _didLongPress) {
    return;
  }

  if ([self.pressDelegate pressRecognizer:self
                        canLongPressRange:_pressedRange]) {
    _didLongPress = YES;
    [self.pressDelegate pressRecognizer:self didLongPressRange:_pressedRange];
  } else if ([self releasesLongPressForTextSelection]) {
    // The text view selects the text held
    [self cancelPress];
  }
}

- (BOOL)releasesLongPressForTextSelection {
  return [self.view isKindOfClass:[UITextView class]] &&
         ((UITextView *)self.view).selectable;
}

- (void)cancelPress {
  [self finishPress];
  self.state = UIGestureRecognizerStateCancelled;
}

- (void)finishPress {
  EnrichedTextPressableRange *range = _pressedRange;

  _pressedRange = nil;
  _pressId++;

  [self.pressDelegate pressRecognizer:self didEndPressingRange:range];
}

@end
