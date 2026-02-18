#import "ParagraphsUtils.h"
#import "StyleHeaders.h"

@implementation ParagraphsUtils

#pragma mark - Public

+ (NSArray<NSValue *> *)getSeparateParagraphsRangesIn:(UITextView *)textView
                                                range:(NSRange)range {
  return [self separateParagraphRangesInString:textView.textStorage.string
                                         range:range];
}

+ (NSArray<NSValue *> *)
    getSeparateParagraphsRangesInAttributedString:
        (NSAttributedString *)attributedString
                                            range:(NSRange)range {
  return [self separateParagraphRangesInString:attributedString.string
                                         range:range];
}

+ (NSArray<NSValue *> *)getNonNewlineRangesIn:(UITextView *)textView
                                        range:(NSRange)range {
  NSMutableArray<NSValue *> *nonNewlineRanges = [[NSMutableArray alloc] init];
  NSString *string = textView.textStorage.string;

  NSUInteger lastRangeLocation = range.location;
  NSUInteger end = NSMaxRange(range);

  for (NSUInteger i = range.location; i < end; i++) {
    unichar currentChar = [string characterAtIndex:i];
    if ([[NSCharacterSet newlineCharacterSet] characterIsMember:currentChar]) {
      if (i > lastRangeLocation) {
        [nonNewlineRanges
            addObject:[NSValue
                          valueWithRange:NSMakeRange(lastRangeLocation,
                                                     i - lastRangeLocation)]];
      }
      lastRangeLocation = i + 1;
    }
  }

  if (lastRangeLocation < end) {
    [nonNewlineRanges
        addObject:[NSValue
                      valueWithRange:NSMakeRange(lastRangeLocation,
                                                 end - lastRangeLocation)]];
  }

  return nonNewlineRanges;
}

+ (BOOL)isReadOnlyParagraphAtLocation:(NSAttributedString *)attributedString
                             location:(NSUInteger)location {
  NSUInteger length = attributedString.length;
  if (length == 0)
    return NO;

  if (location > 0) {
    if ([attributedString attribute:ReadOnlyParagraphKey
                            atIndex:location - 1
                     effectiveRange:nil]) {
      return YES;
    }
  }

  if (location < length) {
    if ([attributedString attribute:ReadOnlyParagraphKey
                            atIndex:location
                     effectiveRange:nil]) {
      return YES;
    }
  }

  return NO;
}

+ (NSArray<NSValue *> *)separateParagraphRangesInString:(NSString *)string
                                                  range:(NSRange)range {
  if (string.length == 0) {
    return @[];
  }

  NSRange fullRange = [string paragraphRangeForRange:range];

  if (fullRange.length == 0) {
    return @[ [NSValue valueWithRange:fullRange] ];
  }

  NSMutableArray<NSValue *> *results = [[NSMutableArray alloc] init];

  NSUInteger lastStart = fullRange.location;
  NSUInteger end = NSMaxRange(fullRange);

  for (NSUInteger i = fullRange.location; i < end; i++) {
    unichar currentChar = [string characterAtIndex:i];
    if ([[NSCharacterSet newlineCharacterSet] characterIsMember:currentChar]) {
      NSRange paragraphRange =
          [string paragraphRangeForRange:NSMakeRange(lastStart, i - lastStart)];
      [results addObject:[NSValue valueWithRange:paragraphRange]];
      lastStart = i + 1;
    }
  }

  if (lastStart < end) {
    NSRange paragraphRange =
        [string paragraphRangeForRange:NSMakeRange(lastStart, end - lastStart)];
    [results addObject:[NSValue valueWithRange:paragraphRange]];
  }

  return results;
}

+ (NSAttributedString *)firstParagraph:(NSAttributedString *)attributedString {
  NSString *string = attributedString.string;
  NSRange range = [string paragraphRangeForRange:NSRange(0, 0)];
  return [attributedString attributedSubstringFromRange:range];
}

@end
