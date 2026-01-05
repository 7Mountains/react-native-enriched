#import "HeadingsParagraphInvariantUtils.h"
#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

@implementation HeadingsParagraphInvariantUtils

// backspacing a line after a heading "into" a heading will not result in the
// text attaining heading attributes so, we do it manually
+ (void)handleImproperHeadingStyles:(NSArray<HeadingStyleBase *> *)styles
                              input:(EnrichedTextInputView *)input {

  if (styles.count == 0 || input == nullptr)
    return;

  NSTextStorage *storage = input->textView.textStorage;
  NSString *string = storage.string;
  NSUInteger length = string.length;

  if (length == 0)
    return;

  NSRange fullRange = NSMakeRange(0, length);

  NSAttributedStringKey key = [[[styles firstObject] class] attributeKey];

  __block NSRange currentParagraphRange = NSMakeRange(NSNotFound, 0);
  __block NSRange headingOccurenceRange = NSMakeRange(NSNotFound, 0);
  __block HeadingStyleBase *paragraphHeading = nil;
  __block BOOL paragraphHasHeading = NO;

  [storage
      enumerateAttribute:key
                 inRange:fullRange
                 options:0
              usingBlock:^(id value, NSRange range, BOOL *stop) {
                if (!value)
                  return;

                HeadingStyleBase *matchedStyle = nil;
                for (HeadingStyleBase *style in styles) {
                  if ([style styleCondition:value range:range]) {
                    matchedStyle = style;
                    break;
                  }
                }

                if (!matchedStyle)
                  return;

                NSRange paragraphRange = [string paragraphRangeForRange:range];

                if (!NSEqualRanges(paragraphRange, currentParagraphRange)) {

                  if (paragraphHasHeading &&
                      !NSEqualRanges(headingOccurenceRange,
                                     currentParagraphRange)) {

                    [paragraphHeading addAttributes:currentParagraphRange
                               withTypingAttributes:NO];
                  }

                  currentParagraphRange = paragraphRange;
                  headingOccurenceRange = range;
                  paragraphHeading = matchedStyle;
                  paragraphHasHeading = YES;
                  return;
                }

                headingOccurenceRange =
                    NSUnionRange(headingOccurenceRange, range);
              }];

  // tail paragraph
  if (paragraphHasHeading &&
      !NSEqualRanges(headingOccurenceRange, currentParagraphRange)) {

    [paragraphHeading addAttributes:currentParagraphRange
               withTypingAttributes:NO];
  }
}

@end
