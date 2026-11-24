#import "EnrichedTextMeasurer.h"
#import "EnrichedTextBuilder.h"

@implementation EnrichedTextMeasurer

+ (CGSize)sizeOfText:(NSAttributedString *)text
      constrainedToWidth:(CGFloat)width
    maximumNumberOfLines:(NSInteger)maximumNumberOfLines
           lineBreakMode:(NSLineBreakMode)lineBreakMode {
  CGFloat containerWidth = isfinite(width) ? width : CGFLOAT_MAX;

  // Not kept: a layout per text would take memory for the text's lifetime
  NSTextStorage *textStorage =
      [[NSTextStorage alloc] initWithAttributedString:text];
  NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
  NSTextContainer *textContainer = [[NSTextContainer alloc]
      initWithSize:CGSizeMake(containerWidth, CGFLOAT_MAX)];

  [EnrichedTextBuilder configureTextContainer:textContainer
                         maximumNumberOfLines:maximumNumberOfLines
                                lineBreakMode:lineBreakMode];

  [layoutManager addTextContainer:textContainer];
  [textStorage addLayoutManager:layoutManager];
  [layoutManager ensureLayoutForTextContainer:textContainer];

  CGRect usedRect = [layoutManager usedRectForTextContainer:textContainer];

  // The widest line, as React Native's <Text>: a short text doesn't take the
  // whole width
  CGFloat textWidth =
      MAX(usedRect.size.width, [self widestLineInLayoutManager:layoutManager
                                                 textContainer:textContainer]);
  return CGSizeMake(MIN(ceil(textWidth), containerWidth),
                    ceil(usedRect.size.height));
}

// The lines with the room their paragraphs keep after them (a negative tail
// indent, e.g. of the lists and the quotes): laid out again for this width, a
// line doesn't wrap earlier than measured
+ (CGFloat)widestLineInLayoutManager:(NSLayoutManager *)layoutManager
                       textContainer:(NSTextContainer *)textContainer {
  NSTextStorage *textStorage = layoutManager.textStorage;
  NSString *string = textStorage.string;
  NSUInteger length = textStorage.length;

  __block CGFloat width = 0;
  __block NSRange paragraphRange = NSMakeRange(NSNotFound, 0);
  __block CGFloat trailingRoom = 0;

  NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];

  [layoutManager
      enumerateLineFragmentsForGlyphRange:glyphRange
                               usingBlock:^(CGRect rect, CGRect usedRect,
                                            NSTextContainer *container,
                                            NSRange lineGlyphRange,
                                            BOOL *stop) {
                                 NSUInteger index = [layoutManager
                                     characterIndexForGlyphAtIndex:
                                         lineGlyphRange.location];

                                 if (!NSLocationInRange(index,
                                                        paragraphRange)) {
                                   paragraphRange = [string
                                       paragraphRangeForRange:NSMakeRange(index,
                                                                          0)];
                                   NSParagraphStyle *style =
                                       index < length
                                           ? [textStorage
                                                      attribute:
                                                          NSParagraphStyleAttributeName
                                                        atIndex:index
                                                 effectiveRange:NULL]
                                           : nil;
                                   trailingRoom = style.tailIndent < 0
                                                      ? -style.tailIndent
                                                      : 0;
                                 }

                                 width = MAX(width, CGRectGetMaxX(usedRect) +
                                                        trailingRoom);
                               }];

  return width;
}

@end
