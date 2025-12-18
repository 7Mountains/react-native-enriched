#import "CheckboxHitTestUtils.h"
#import "EnrichedTextInputView.h"
#import "InputConfig.h"
#import "StyleHeaders.h"

@implementation CheckboxHitTestUtils

+ (CGRect)checkboxRectAtGlyphIndex:(NSUInteger)glyphIndex
                           inInput:(EnrichedTextInputView *)input {
  InputTextView *textView = input->textView;
  NSTextStorage *storage = textView.textStorage;

  NSUInteger charIndex =
      [textView.layoutManager characterIndexForGlyphAtIndex:glyphIndex];

  if (charIndex >= storage.length) {
    return CGRectNull;
  }

  CheckBoxStyle *checkboxStyle =
      (CheckBoxStyle *)input->stylesDict[@([CheckBoxStyle getStyleType])];

  if (!checkboxStyle ||
      ![checkboxStyle detectStyle:NSMakeRange(charIndex, 0)]) {
    return CGRectNull;
  }

  InputConfig *config = input->config;
  if (!config) {
    return CGRectNull;
  }

  CGRect lineRect =
      [textView.layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex
                                               effectiveRange:nil];

  CGFloat checkboxWidth = config.checkBoxWidth;
  CGFloat checkboxHeight = config.checkBoxHeight;
  CGFloat marginLeft = config.checkboxListMarginLeft;
  CGFloat checkboxGap = config.checkboxListGapWidth;

  CGFloat originY =
      lineRect.origin.y + (lineRect.size.height - checkboxHeight) / 2.0;

  return CGRectMake(marginLeft + checkboxGap, originY, checkboxWidth,
                    checkboxHeight);
}

+ (NSInteger)hitTestCheckboxAtPoint:(CGPoint)point
                            inInput:(EnrichedTextInputView *)input {
  UITextView *textView = input->textView;

  NSUInteger glyphIndex =
      [textView.layoutManager glyphIndexForPoint:point
                                 inTextContainer:textView.textContainer
                  fractionOfDistanceThroughGlyph:nil];

  if (glyphIndex == NSNotFound) {
    return -1;
  }

  NSRange lineGlyphRange;
  [textView.layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex
                                           effectiveRange:&lineGlyphRange];

  CGRect checkboxRect =
      [self checkboxRectAtGlyphIndex:lineGlyphRange.location
                             inInput:input];

  if (CGRectIsNull(checkboxRect)) {
    return -1;
  }

  if (!CGRectContainsPoint(checkboxRect, point)) {
    return -1;
  }

  return [textView.layoutManager
      characterIndexForGlyphAtIndex:lineGlyphRange.location];
}


@end
