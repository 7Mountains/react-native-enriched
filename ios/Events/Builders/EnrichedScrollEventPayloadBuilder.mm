#import "EnrichedScrollEventPayloadBuilder.h"

using namespace facebook::react;

@implementation EnrichedScrollEventPayloadBuilder

+ (const EnrichedTextInputViewEventEmitter::OnInputScroll)
    buildFromScrollView:(UIScrollView *)scrollView
                 target:(NSNumber *)reactTag {
  UIEdgeInsets inset = scrollView.contentInset;
  CGPoint offset = scrollView.contentOffset;
  CGSize contentSize = scrollView.contentSize;
  CGSize layoutSize = scrollView.bounds.size;

  CGPoint velocity = CGPointZero;
  if (scrollView.panGestureRecognizer) {
    velocity = [scrollView.panGestureRecognizer velocityInView:scrollView];
  }

  return {
      .contentInset =
          {
              .top = inset.top,
              .bottom = inset.bottom,
              .left = inset.left,
              .right = inset.right,
          },
      .contentOffset =
          {
              .x = offset.x,
              .y = offset.y,
          },
      .contentSize =
          {
              .width = contentSize.width,
              .height = contentSize.height,
          },
      .layoutMeasurement =
          {
              .width = layoutSize.width,
              .height = layoutSize.height,
          },
      .velocity =
          {
              .x = velocity.x,
              .y = velocity.y,
          },
      .target = (int)[reactTag integerValue],
  };
}

@end
