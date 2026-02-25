#import "SelectionUtils.h"

@implementation SelectionUtils

+ (UIColor *_Nullable)effectiveForegroundColorForSelectionInTextView:
    (UITextView *)textView {
  NSRange selectedRange = textView.selectedRange;
  UIColor *selectionColor = nil;

  if (selectedRange.length == 0) {
    selectionColor =
        textView.typingAttributes[NSForegroundColorAttributeName] ?: nil;
  } else {
    // Selection range: check for uniform color
    __block UIColor *firstColor = nil;
    __block BOOL hasMultiple = NO;

    [textView.textStorage
        enumerateAttribute:NSForegroundColorAttributeName
                   inRange:selectedRange
                   options:0
                usingBlock:^(id _Nullable value, NSRange range,
                             BOOL *_Nonnull stop) {
                  UIColor *thisColor = (UIColor *)value ?: nil;
                  if (firstColor == nil) {
                    firstColor = thisColor;
                  } else if (![firstColor isEqual:thisColor]) {
                    hasMultiple = YES;
                    *stop = YES;
                  }
                }];

    if (!hasMultiple && firstColor != nil) {
      selectionColor = firstColor;
    }
  }
  return selectionColor;
}

+ (NSTextAlignment)effectiveParagraphAlignmentForSelectionInTextView:
    (UITextView *)textView {
  NSRange selectedRange = textView.selectedRange;
  NSTextAlignment alignment = NSTextAlignmentNatural;

  if (selectedRange.length == 0) {
    NSParagraphStyle *paragraphStyle =
        textView.typingAttributes[NSParagraphStyleAttributeName];
    alignment =
        paragraphStyle ? paragraphStyle.alignment : NSTextAlignmentNatural;
  } else {
    NSTextStorage *storage = textView.textStorage;

    NSUInteger start = selectedRange.location;

    if (storage.length == 0 || start >= storage.length) {
      alignment = NSTextAlignmentNatural;
    } else {
      NSRange effectiveRange = NSMakeRange(0, 0);
      NSParagraphStyle *paragraphStyle =
          [storage attribute:NSParagraphStyleAttributeName
                            atIndex:start
              longestEffectiveRange:&effectiveRange
                            inRange:selectedRange];

      BOOL coversWholeSelection =
          (NSMaxRange(effectiveRange) >= NSMaxRange(selectedRange));

      if (coversWholeSelection) {
        alignment =
            paragraphStyle ? paragraphStyle.alignment : NSTextAlignmentNatural;
      } else {
        alignment = NSTextAlignmentNatural;
      }
    }
  }
  return alignment;
}

@end
