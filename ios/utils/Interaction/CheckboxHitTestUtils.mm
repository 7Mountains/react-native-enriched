#import "CheckboxHitTestUtils.h"
#import "EnrichedTextInputView.h"
#import "InputConfig.h"
#import "StyleHeaders.h"

static const CGFloat kCheckboxHitSlopLeft = 8.0;
static const CGFloat kCheckboxHitSlopVertical = 6.0;

@implementation CheckboxHitTestUtils

#pragma mark - Coordinate helpers

+ (CGPoint)containerPointFromViewPoint:(CGPoint)point
                              textView:(UITextView *)textView {
  return CGPointMake(point.x - textView.textContainerInset.left,
                     point.y - textView.textContainerInset.top);
}

#pragma mark - Glyph lookup

+ (NSUInteger)glyphIndexAtContainerPoint:(CGPoint)point
                                textView:(UITextView *)textView {
  return [textView.layoutManager glyphIndexForPoint:point
                                    inTextContainer:textView.textContainer
                     fractionOfDistanceThroughGlyph:nil];
}

#pragma mark - Checkbox detection

+ (BOOL)isCheckboxGlyph:(NSUInteger)glyphIndex
                inInput:(EnrichedTextInputView *)input {
  UITextView *textView = input->textView;
  NSLayoutManager *layoutManager = textView.layoutManager;
  NSTextStorage *storage = textView.textStorage;

  NSUInteger charIndex =
      [layoutManager characterIndexForGlyphAtIndex:glyphIndex];

  if (charIndex >= storage.length) {
    return NO;
  }

  CheckBoxStyle *checkboxStyle =
      (CheckBoxStyle *)input->stylesDict[@([CheckBoxStyle getStyleType])];

  if (!checkboxStyle) {
    return NO;
  }

  return [checkboxStyle detectStyle:NSMakeRange(charIndex, 0)];
}

#pragma mark - Checkbox rect

+ (CGRect)checkboxRectForGlyphIndex:(NSUInteger)glyphIndex
                            inInput:(EnrichedTextInputView *)input {
  UITextView *textView = input->textView;
  NSLayoutManager *layoutManager = textView.layoutManager;
  InputConfig *config = input->config;

  if (!config) {
    return CGRectNull;
  }

  CGRect lineRect = [layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex
                                                    effectiveRange:nil];

  CGFloat originX = lineRect.origin.x + config.checkboxListMarginLeft +
                    config.checkboxListGapWidth;

  CGFloat originY =
      lineRect.origin.y + (lineRect.size.height - config.checkBoxHeight) / 2.0;

  return CGRectMake(originX, originY, config.checkBoxWidth,
                    config.checkBoxHeight);
}

#pragma mark - Hit rect

+ (CGRect)expandedHitRectFromCheckboxRect:(CGRect)rect {
  if (CGRectIsNull(rect))
    return rect;

  return CGRectInset(rect, -kCheckboxHitSlopLeft, -kCheckboxHitSlopVertical);
}

#pragma mark - Public API

+ (NSInteger)hitTestCheckboxAtPoint:(CGPoint)point
                            inInput:(EnrichedTextInputView *)input {
  UITextView *textView = input->textView;

  CGPoint containerPoint = [self containerPointFromViewPoint:point
                                                    textView:textView];

  NSUInteger glyphIndex = [self glyphIndexAtContainerPoint:containerPoint
                                                  textView:textView];

  if (glyphIndex == NSNotFound) {
    return -1;
  }

  if (![self isCheckboxGlyph:glyphIndex inInput:input]) {
    return -1;
  }

  CGRect checkboxRect = [self checkboxRectForGlyphIndex:glyphIndex
                                                inInput:input];

  if (CGRectIsNull(checkboxRect)) {
    return -1;
  }

  CGRect hitRect = [self expandedHitRectFromCheckboxRect:checkboxRect];

  if (!CGRectContainsPoint(hitRect, containerPoint)) {
    return -1;
  }

  return [textView.layoutManager characterIndexForGlyphAtIndex:glyphIndex];
}

@end
