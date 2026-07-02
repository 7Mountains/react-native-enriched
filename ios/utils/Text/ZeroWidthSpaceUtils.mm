#import "ZeroWidthSpaceUtils.h"
#import "EnrichedTextInputView.h"
#import "Strings.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"
#import "UIView+React.h"

@implementation ZWSAdjustedRange
- (instancetype)initWithRange:(NSRange)range
                  offsetDelta:(NSInteger)offsetDelta {
  if (self = [super init]) {
    _range = range;
    _offsetDelta = offsetDelta;
  }
  return self;
}
@end

@implementation ZeroWidthSpaceUtils
+ (void)handleZeroWidthSpacesInInput:(id)input {
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)input;
  if (typedInput == nil) {
    return;
  }

  NSArray<id<BaseStyleProtocol>> *zwsStyles =
      [self ZWSStylesForInput:typedInput];

  typedInput->blockEmitting = YES;
  [self removeSpacesIfNeededinInput:typedInput zwsStyles:zwsStyles];
  [self addSpacesIfNeededinInput:typedInput zwsStyles:zwsStyles];
  typedInput->blockEmitting = NO;
}

+ (NSString *)stringByRemovingZWS:(NSString *)string {
  return [string stringByReplacingOccurrencesOfString:ZWS withString:@""];
}

+ (void)removeZWSFromAttributedString:(NSMutableAttributedString *)string {
  [string.mutableString
      replaceOccurrencesOfString:ZWS
                      withString:@""
                         options:0
                           range:NSMakeRange(0, string.length)];
}

+ (BOOL)styleNeedsZWS:(id<BaseStyleProtocol>)style {
  Class cls = [style class];
  SEL selector = @selector(needsZeroWidthSpace);
  if (![cls respondsToSelector:selector]) {
    return NO;
  }

  BOOL (*impl)(id, SEL) = (BOOL(*)(id, SEL))[cls methodForSelector:selector];
  return impl(cls, selector);
}

+ (NSArray<id<BaseStyleProtocol>> *)ZWSStylesForInput:
    (EnrichedTextInputView *)input {

  NSMutableArray *result = [NSMutableArray array];

  for (NSNumber *type in input->stylesDict) {
    id<BaseStyleProtocol> style = input->stylesDict[type];
    if (style && [self styleNeedsZWS:style]) {
      [result addObject:style];
    }
  }

  return result;
}

+ (BOOL)handleParagraphBoundaryBackspaceInRange:(NSRange)range
                                          input:(EnrichedTextInputView *)input {
  NSRange selectedRange = input->textView.selectedRange;
  NSString *string = input->textView.textStorage.string;
  NSRange paragraphRange = [string paragraphRangeForRange:selectedRange];

  BOOL isFirst = NSEqualRanges(selectedRange, NSMakeRange(0, 0));
  BOOL isBeforeParagraph = paragraphRange.location > 0 &&
                           range.location == paragraphRange.location - 1;

  if (!isFirst && !isBeforeParagraph) {
    return NO;
  }

  for (id<BaseStyleProtocol> style in [self ZWSStylesForInput:input]) {
    if ([style detectStyle:selectedRange]) {
      [style removeAttributes:paragraphRange];
      return YES;
    }
  }

  return NO;
}

+ (BOOL)findAnyZWSStylesInInput:(EnrichedTextInputView *)input
                          range:(NSRange)range {
  NSTextStorage *storage = input->textView.textStorage;
  NSUInteger length = storage.length;

  NSUInteger attributeIndex = (range.location < length)
                                  ? range.location
                                  : (length > 0 ? length - 1 : NSNotFound);

  if (attributeIndex == NSNotFound)
    return NO;

  id value = [storage attribute:NSParagraphStyleAttributeName
                        atIndex:attributeIndex
                 effectiveRange:nil];

  for (id<BaseStyleProtocol> style in [self ZWSStylesForInput:input]) {
    if ([style styleCondition:value range:range]) {
      return YES;
    }
  }
  return NO;
}

+ (BOOL)findAnyZWSStylesInInput:(EnrichedTextInputView *)input
                          range:(NSRange)range
                      zwsStyles:(NSArray<id<BaseStyleProtocol>> *)zwsStyles {
  NSTextStorage *storage = input->textView.textStorage;
  NSUInteger length = storage.length;

  NSUInteger attributeIndex = (range.location < length)
                                  ? range.location
                                  : (length > 0 ? length - 1 : NSNotFound);

  id value = [storage attribute:NSParagraphStyleAttributeName
                        atIndex:attributeIndex
                 effectiveRange:nil];

  if (attributeIndex == NSNotFound)
    return NO;

  for (id<BaseStyleProtocol> style in zwsStyles) {
    if ([style styleCondition:value range:range]) {
      return YES;
    }
  }
  return NO;
}

+ (ZWSAdjustedRange *)rangeByEnsuringEmptyParagraphHasZWS:(NSRange)range
                                                    input:(id)input {
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)input;
  if (typedInput == nullptr) {
    return [[ZWSAdjustedRange alloc] initWithRange:range offsetDelta:0];
  }

  NSString *string = typedInput->textView.textStorage.string;
  BOOL isEmptyParagraph =
      range.length == 0 ||
      (range.length == 1 && range.location < string.length &&
       [[NSCharacterSet newlineCharacterSet]
           characterIsMember:[string characterAtIndex:range.location]]);

  if (!isEmptyParagraph) {
    return [[ZWSAdjustedRange alloc] initWithRange:range offsetDelta:0];
  }

  [TextInsertionUtils insertText:ZWS
                              at:range.location
            additionalAttributes:nullptr
                           input:typedInput
                   withSelection:NO];

  return [[ZWSAdjustedRange alloc]
      initWithRange:NSMakeRange(range.location, range.length + 1)
        offsetDelta:1];
}

+ (void)removeSpacesIfNeededinInput:(EnrichedTextInputView *)input
                          zwsStyles:
                              (NSArray<id<BaseStyleProtocol>> *)zwsStyles {
  NSTextStorage *storage = input->textView.textStorage;
  NSString *string = storage.string;
  NSUInteger length = string.length;

  if (length == 0)
    return;

  NSMutableIndexSet *indexesToRemove = [NSMutableIndexSet indexSet];
  NSRange preRemoveSelection = input->textView.selectedRange;

  CFStringInlineBuffer buffer;
  CFStringInitInlineBuffer((CFStringRef)string, &buffer,
                           CFRangeMake(0, length));

  for (NSUInteger i = 0; i < length; i++) {
    unichar ch = CFStringGetCharacterFromInlineBuffer(&buffer, i);
    if (ch != ZWSChar)
      continue;

    NSRange range = NSMakeRange(i, 1);
    NSRange paragraphRange = [string paragraphRangeForRange:range];

    BOOL removeSpace = paragraphRange.length > 1;

    // exception: ZWSP + newline only
    if (paragraphRange.length == 2 && paragraphRange.location == i &&
        i + 1 < length) {

      unichar nextChar = CFStringGetCharacterFromInlineBuffer(&buffer, i + 1);

      if ([[NSCharacterSet newlineCharacterSet] characterIsMember:nextChar]) {
        removeSpace = NO;
      }
    }

    if (!removeSpace) {
      if (![self findAnyZWSStylesInInput:input
                                   range:range
                               zwsStyles:zwsStyles]) {
        removeSpace = YES;
      }
    }

    if (removeSpace) {
      [indexesToRemove addIndex:i];
    }
  }
  NSTextStorage *textStorage = input->textView.textStorage;
  [textStorage beginEditing];
  // do the removing
  [indexesToRemove
      enumerateIndexesWithOptions:NSEnumerationReverse
                       usingBlock:^(NSUInteger idx, BOOL *stop) {
                         [TextInsertionUtils replaceText:@""
                                                      at:NSMakeRange(idx, 1)
                                    additionalAttributes:input->textView
                                                             .typingAttributes
                                                   input:input
                                           withSelection:NO];
                       }];
  [textStorage endEditing];

  // fix the selection if needed
  if ([input->textView isFirstResponder]) {
    NSUInteger removedBefore = [indexesToRemove
        countOfIndexesInRange:NSMakeRange(0, preRemoveSelection.location)];

    NSUInteger removedInside =
        [indexesToRemove countOfIndexesInRange:preRemoveSelection];

    input->textView.selectedRange =
        NSMakeRange(preRemoveSelection.location - removedBefore,
                    preRemoveSelection.length - removedInside);
  }
}

+ (void)addSpacesIfNeededinInput:(EnrichedTextInputView *)input
                       zwsStyles:(NSArray<id<BaseStyleProtocol>> *)zwsStyles {
  NSTextStorage *storage = input->textView.textStorage;
  NSString *string = storage.string;
  NSUInteger length = string.length;

  if (length == 0)
    return;

  NSRange preAddSelection = input->textView.selectedRange;
  NSMutableIndexSet *indexesToInsert = [NSMutableIndexSet indexSet];

  CFStringInlineBuffer buffer;
  CFStringInitInlineBuffer((CFStringRef)string, &buffer,
                           CFRangeMake(0, length));

  NSUInteger paragraphStart = 0;

  for (NSUInteger i = 0; i <= length; i++) {
    BOOL isEnd = (i == length);
    unichar ch = isEnd ? 0 : CFStringGetCharacterFromInlineBuffer(&buffer, i);

    if (!isEnd && ch != NewLineUnsinedChar)
      continue;

    NSUInteger paragraphLength = i - paragraphStart + (isEnd ? 0 : 1);

    BOOL isEmptyParagraph =
        (paragraphLength == 1 && !isEnd) || (isEnd && paragraphLength == 0);

    if (isEmptyParagraph) {
      NSRange checkRange = NSMakeRange(paragraphStart, 1);
      BOOL found = [self findAnyZWSStylesInInput:input
                                           range:checkRange
                                       zwsStyles:zwsStyles];
      if (found) {
        [indexesToInsert addIndex:paragraphStart];
      }
    }

    paragraphStart = i + 1;
  }
  NSTextStorage *textStorage = input->textView.textStorage;
  [textStorage beginEditing];

  [indexesToInsert
      enumerateIndexesWithOptions:NSEnumerationReverse
                       usingBlock:^(NSUInteger idx, BOOL *stop) {
                         BOOL isAtEnd = (idx == length);
                         NSString *text = isAtEnd ? ZWS : ZWSWithNewLine;

                         if (isAtEnd) {
                           [TextInsertionUtils insertText:text
                                                       at:idx
                                     additionalAttributes:nullptr
                                                    input:input
                                            withSelection:NO];
                         } else {
                           [TextInsertionUtils replaceText:text
                                                        at:NSMakeRange(idx, 1)
                                      additionalAttributes:nullptr
                                                     input:input
                                             withSelection:NO];
                         }
                       }];
  [textStorage endEditing];

  // fix selection
  if ([input->textView isFirstResponder]) {
    NSUInteger addedBefore = [indexesToInsert
        countOfIndexesInRange:NSMakeRange(0, preAddSelection.location)];

    NSUInteger addedInside =
        [indexesToInsert countOfIndexesInRange:preAddSelection];

    input->textView.selectedRange =
        NSMakeRange(preAddSelection.location + addedBefore,
                    preAddSelection.length + addedInside);
  }
}

+ (BOOL)handleBackspaceInRange:(NSRange)range
               replacementText:(NSString *)text
                         input:(id)input {
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)input;
  if (typedInput == nullptr) {
    return NO;
  }

  if (text.length != 0) {
    return NO;
  }

  if ([self handleParagraphBoundaryBackspaceInRange:range input:typedInput]) {
    return YES;
  }

  if (range.length != 1) {
    return NO;
  }

  unichar character =
      [typedInput->textView.textStorage.string characterAtIndex:range.location];
  // zero-width space got backspaced
  if (character == ZWSChar) {
    // in such case: remove the whole line without the endline if there is one

    NSRange paragraphRange =
        [typedInput->textView.textStorage.string paragraphRangeForRange:range];
    NSRange removalRange = paragraphRange;
    // if whole paragraph gets removed then 0 length for style removal
    NSRange styleRemovalRange = NSMakeRange(paragraphRange.location, 0);

    if ([[NSCharacterSet newlineCharacterSet]
            characterIsMember:[typedInput->textView.textStorage.string
                                  characterAtIndex:NSMaxRange(paragraphRange) -
                                                   1]]) {
      // if endline is there, don't remove it
      removalRange =
          NSMakeRange(paragraphRange.location, paragraphRange.length - 1);
      // if endline is left then 1 length for style removal
      styleRemovalRange = NSMakeRange(paragraphRange.location, 1);
    }

    for (id<BaseStyleProtocol> style in [self ZWSStylesForInput:typedInput]) {
      if ([style detectStyle:styleRemovalRange]) {
        [style removeAttributes:styleRemovalRange];
      }
    }

    return NO;
  }
  return NO;
}

+ (NSUInteger)actualIndexFromVisibleIndex:(NSInteger)visibleIndex
                                     text:(NSString *)text {
  NSUInteger currentVisibleCount = 0;
  NSUInteger actualIndex = 0;

  while (actualIndex < text.length) {
    if (currentVisibleCount == visibleIndex) {
      return actualIndex;
    }

    if ([text characterAtIndex:actualIndex] != ZWSChar) {
      currentVisibleCount++;
    }

    actualIndex++;
  }

  return actualIndex;
}

@end
