#import "CheckboxHitTestUtils.h"
#import "EnrichedTextInputView.h"
#import "InputConfig.h"
#import "StyleHeaders.h"

static const CGFloat kCheckboxHitSlopLeft = 8.0;
static const CGFloat kCheckboxHitSlopRight = 0.0;
static const CGFloat kCheckboxHitSlopVertical = 6.0;

@implementation CheckboxHitTestUtils

+ (CGRect)checkboxRectAtGlyphIndex:(NSUInteger)glyphIndex
                           inInput:(EnrichedTextInputView *)input {
  UITextView *textView = input->textView;
  NSLayoutManager *layoutManager = textView.layoutManager;
  NSTextStorage *storage = textView.textStorage;

  NSUInteger charIndex =
      [layoutManager characterIndexForGlyphAtIndex:glyphIndex];

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

  CGRect lineRect = [layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex
                                                    effectiveRange:nil];

  lineRect.origin.x += textView.textContainerInset.left;
  lineRect.origin.y += textView.textContainerInset.top;

  CGFloat checkboxWidth = config.checkBoxWidth;
  CGFloat checkboxHeight = config.checkBoxHeight;

  CGFloat originY =
      lineRect.origin.y + (lineRect.size.height - checkboxHeight) / 2.0;

  CGFloat originX = lineRect.origin.x + config.checkboxListMarginLeft +
                    config.checkboxListGapWidth;

  return CGRectMake(originX, originY, checkboxWidth, checkboxHeight);
}

+ (CGRect)expandedHitRectForCheckboxRect:(CGRect)rect {
  if (CGRectIsNull(rect)) {
    return rect;
  }

  return CGRectMake(rect.origin.x - kCheckboxHitSlopLeft,
                    rect.origin.y - kCheckboxHitSlopVertical,
                    rect.size.width + kCheckboxHitSlopLeft +
                        kCheckboxHitSlopRight,
                    rect.size.height + 2 * kCheckboxHitSlopVertical);
}

+ (NSInteger)hitTestCheckboxAtPoint:(CGPoint)point
                            inInput:(EnrichedTextInputView *)input {
  UITextView *textView = input->textView;
  NSLayoutManager *layoutManager = textView.layoutManager;

  CGPoint containerPoint = point;
  containerPoint.x -= textView.textContainerInset.left;
  containerPoint.y -= textView.textContainerInset.top;
  containerPoint.x += textView.contentOffset.x;
  containerPoint.y += textView.contentOffset.y;

  NSUInteger glyphIndex =
      [layoutManager glyphIndexForPoint:containerPoint
                         inTextContainer:textView.textContainer
          fractionOfDistanceThroughGlyph:nil];

  if (glyphIndex == NSNotFound) {
    return -1;
  }

  NSRange lineGlyphRange;
  [layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex
                                  effectiveRange:&lineGlyphRange];

  CGRect checkboxRect = [self checkboxRectAtGlyphIndex:lineGlyphRange.location
                                               inInput:input];

  if (CGRectIsNull(checkboxRect)) {
    return -1;
  }

  CGRect hitRect = [self expandedHitRectForCheckboxRect:checkboxRect];

  if (!CGRectContainsPoint(hitRect, point)) {
    return -1;
  }

  return [layoutManager characterIndexForGlyphAtIndex:lineGlyphRange.location];
}

@end
