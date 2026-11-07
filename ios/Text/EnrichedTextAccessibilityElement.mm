#import "EnrichedTextAccessibilityElement.h"

@implementation EnrichedTextAccessibilityElement

- (CGPoint)accessibilityActivationPoint {
  CGRect point = CGRectMake(_activationPointInContainerSpace.x,
                            _activationPointInContainerSpace.y, 0, 0);
  return UIAccessibilityConvertFrameToScreenCoordinates(
             point, (UIView *)self.accessibilityContainer)
      .origin;
}

- (BOOL)accessibilityActivate {
  id container = self.accessibilityContainer;

  // The text: VoiceOver touches it, the views around get the touch
  if (_pressableRange == nil ||
      ![container
          conformsToProtocol:@protocol(EnrichedTextAccessibilityContainer)]) {
    return NO;
  }

  [(id<EnrichedTextAccessibilityContainer>)container
      activatePressableRange:_pressableRange];
  return YES;
}

@end
