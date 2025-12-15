#import "ContentHitTestUtils.h"
#import "EnrichedTextInputView.h"

@implementation ContentHitTestUtils

+ (CGRect)contentRectAtGlyphIndex:(NSUInteger)glyphIndex
                          inInput:(EnrichedTextInputView *)input {
  if (!input || !input->textView) {
    return CGRectNull;
  }

  NSLayoutManager *layoutManager = input->textView.layoutManager;
  NSTextContainer *textContainer = input->textView.textContainer;

  if (glyphIndex == NSNotFound || glyphIndex >= layoutManager.numberOfGlyphs) {
    return CGRectNull;
  }

  CGRect glyphRect =
      [layoutManager boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1)
                               inTextContainer:textContainer];

  CGFloat hitboxPadding = 1.0;
  return CGRectInset(glyphRect, -hitboxPadding, -hitboxPadding);
}

+ (NSInteger)hitTestContentAtPoint:(CGPoint)point
                           inInput:(EnrichedTextInputView *)input {
  if (!input || !input->textView) {
    return -1;
  }

  UITextView *textView = input->textView;
  NSLayoutManager *layoutManager = textView.layoutManager;
  NSTextContainer *textContainer = textView.textContainer;

  CGFloat fraction = 0.0;

  NSUInteger glyphIndex = [layoutManager glyphIndexForPoint:point
                                            inTextContainer:textContainer
                             fractionOfDistanceThroughGlyph:&fraction];

  if (glyphIndex == NSNotFound) {
    return -1;
  }

  NSUInteger charIndex =
      [layoutManager characterIndexForGlyphAtIndex:glyphIndex];

  if (charIndex == NSNotFound || charIndex >= textView.textStorage.length) {
    return -1;
  }

  unichar character = [textView.textStorage.string characterAtIndex:charIndex];

  if (character != 0xFFFC) { // attachment object replacement char
    return -1;
  }

  id attachment = [textView.textStorage attribute:NSAttachmentAttributeName
                                          atIndex:charIndex
                                   effectiveRange:nil];

  if (!attachment) {
    return -1;
  }

  CGRect contentRect = [self contentRectAtGlyphIndex:glyphIndex inInput:input];

  if (CGRectIsNull(contentRect) || !CGRectContainsPoint(contentRect, point)) {
    return -1;
  }

  return (NSInteger)charIndex;
}

@end
