#import "ZeroWidthSpaceUtils.h"
#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"
#import "UIView+React.h"

static NSString *const kZWSP = @"\u200B";

@implementation ZeroWidthSpaceUtils
+ (void)handleZeroWidthSpacesInInput:(id)input {
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)input;
  if (typedInput == nullptr) {
    return;
  }

  [self removeSpacesIfNeededinInput:typedInput];
  [self addSpacesIfNeededinInput:typedInput];
}

+ (NSArray<id<BaseStyleProtocol>> *)ZWSStylesForInput:
    (EnrichedTextInputView *)input {

  NSMutableArray *result = [NSMutableArray array];

  for (NSNumber *type in [self ZWSStyleTypes]) {
    id<BaseStyleProtocol> style = input->stylesDict[type];
    if (style) {
      [result addObject:style];
    }
  }

  return result;
}

+ (NSArray<NSNumber *> *)ZWSStyleTypes {
  static NSArray<NSNumber *> *types;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    types = @[
      @([UnorderedListStyle getStyleType]), @([OrderedListStyle getStyleType]),
      @([BlockQuoteStyle getStyleType]), @([CodeBlockStyle getStyleType]),
      @([CheckBoxStyle getStyleType])
    ];
  });
  return types;
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

  for (id<BaseStyleProtocol> style in [self ZWSStylesForInput:input]) {
    NSAttributedStringKey key = [[style class] attributeKey];
    id value = [storage attribute:key
                          atIndex:attributeIndex
                   effectiveRange:nil];

    if ([style styleCondition:value range:range]) {
      return YES;
    }
  }
  return NO;
}

+ (void)removeSpacesIfNeededinInput:(EnrichedTextInputView *)input {
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
    if (ch != 0x200B)
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
      if (![self findAnyZWSStylesInInput:input range:range]) {
        removeSpace = YES;
      }
    }

    if (removeSpace) {
      [indexesToRemove addIndex:i];
    }
  }

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

+ (void)addSpacesIfNeededinInput:(EnrichedTextInputView *)input {
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

    if (!isEnd && ch != '\n')
      continue;

    NSUInteger paragraphLength = i - paragraphStart + (isEnd ? 0 : 1);

    BOOL isEmptyParagraph =
        (paragraphLength == 1 && !isEnd) || (isEnd && paragraphLength == 0);

    if (isEmptyParagraph) {
      NSRange checkRange = NSMakeRange(paragraphStart, 1);
      BOOL found = [self findAnyZWSStylesInInput:input range:checkRange];
      if (found) {
        [indexesToInsert addIndex:paragraphStart];
      }
    }

    paragraphStart = i + 1;
  }

  [indexesToInsert
      enumerateIndexesWithOptions:NSEnumerationReverse
                       usingBlock:^(NSUInteger idx, BOOL *stop) {
                         BOOL isAtEnd = (idx == length);
                         NSString *text = isAtEnd ? kZWSP : @"\u200B\n";

                         if (isAtEnd) {
                           [TextInsertionUtils insertText:text
                                                       at:idx
                                     additionalAttributes:input->textView
                                                              .typingAttributes
                                                    input:input
                                            withSelection:NO];
                         } else {
                           [TextInsertionUtils replaceText:text
                                                        at:NSMakeRange(idx, 1)
                                      additionalAttributes:input->textView
                                                               .typingAttributes
                                                     input:input
                                             withSelection:NO];
                         }
                       }];

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
  if (range.length != 1 || ![text isEqualToString:@""]) {
    return NO;
  }
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)input;
  if (typedInput == nullptr) {
    return NO;
  }

  unichar character =
      [typedInput->textView.textStorage.string characterAtIndex:range.location];
  // zero-width space got backspaced
  if (character == 0x200B) {
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

    // and then remove associated styling

    UnorderedListStyle *ulStyle =
        typedInput->stylesDict[@([UnorderedListStyle getStyleType])];
    OrderedListStyle *olStyle =
        typedInput->stylesDict[@([OrderedListStyle getStyleType])];
    BlockQuoteStyle *bqStyle =
        (BlockQuoteStyle *)
            typedInput->stylesDict[@([BlockQuoteStyle getStyleType])];
    CodeBlockStyle *cbStyle =
        (CodeBlockStyle *)
            typedInput->stylesDict[@([CodeBlockStyle getStyleType])];
    CheckBoxStyle *checkBoxStyle =
        (CheckBoxStyle *)
            typedInput->stylesDict[@([CheckBoxStyle getStyleType])];

    if ([cbStyle detectStyle:removalRange]) {
      // code blocks are being handled differently; we want to remove previous
      // newline if there is a one
      if (range.location > 0) {
        removalRange =
            NSMakeRange(removalRange.location - 1, removalRange.length + 1);
      }
      [TextInsertionUtils replaceText:@""
                                   at:removalRange
                 additionalAttributes:nullptr
                                input:typedInput
                        withSelection:YES];
      return YES;
    }

    [TextInsertionUtils replaceText:@""
                                 at:removalRange
               additionalAttributes:typedInput->textView.typingAttributes
                              input:typedInput
                      withSelection:YES];

    if ([ulStyle detectStyle:styleRemovalRange]) {
      [ulStyle removeAttributes:styleRemovalRange];
    } else if ([olStyle detectStyle:styleRemovalRange]) {
      [olStyle removeAttributes:styleRemovalRange];
    } else if ([bqStyle detectStyle:styleRemovalRange]) {
      [bqStyle removeAttributes:styleRemovalRange];
    } else if ([checkBoxStyle detectStyle:styleRemovalRange]) {
      [checkBoxStyle removeAttributes:styleRemovalRange];
    }

    return YES;
  }
  return NO;
}

@end
