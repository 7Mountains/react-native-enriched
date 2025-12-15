#import "DividerHitTestUtils.h"
#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

@implementation DividerHitTestUtils

+ (CGRect)dividerRectAtGlyphIndex:(NSUInteger)glyphIndex
                          inInput:(EnrichedTextInputView *)input {
  if (!input || !input->textView) {
    return CGRectNull;
  }

  UITextView *textView = input->textView;
  NSLayoutManager *layoutManager = textView.layoutManager;
  NSTextStorage *textStorage = textView.textStorage;

  NSUInteger charIndex =
      [layoutManager characterIndexForGlyphAtIndex:glyphIndex];

  if (charIndex >= textStorage.length) {
    return CGRectNull;
  }

  id attachment = [textStorage attribute:NSAttachmentAttributeName
                                 atIndex:charIndex
                          effectiveRange:nil];

  if (![attachment isKindOfClass:[DividerAttachment class]]) {
    return CGRectNull;
  }

  DividerAttachment *dividerAttachment = (DividerAttachment *)attachment;

  // Position of the text line where the divider lives
  CGRect lineFragmentRect =
      [layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex
                                      effectiveRange:nil];

  CGFloat dividerHeight = dividerAttachment.height;
  CGFloat dividerY = lineFragmentRect.origin.y +
                     (lineFragmentRect.size.height - dividerHeight) / 2.0;

  return CGRectMake(lineFragmentRect.origin.x, dividerY,
                    lineFragmentRect.size.width, dividerHeight);
}

+ (NSInteger)hitTestDividerAtPoint:(CGPoint)point
                           inInput:(EnrichedTextInputView *)input {
  if (!input || !input->textView) {
    return -1;
  }

  UITextView *textView = input->textView;
  NSLayoutManager *layoutManager = textView.layoutManager;
  NSTextContainer *textContainer = textView.textContainer;

  NSUInteger glyphIndex = [layoutManager glyphIndexForPoint:point
                                            inTextContainer:textContainer
                             fractionOfDistanceThroughGlyph:nil];

  if (glyphIndex == NSNotFound) {
    return -1;
  }

  CGRect dividerRect = [self dividerRectAtGlyphIndex:glyphIndex inInput:input];

  if (CGRectIsNull(dividerRect)) {
    return -1;
  }
  if (!CGRectContainsPoint(dividerRect, point)) {
    return -1;
  }

  return (NSInteger)[layoutManager characterIndexForGlyphAtIndex:glyphIndex];
}

@end
