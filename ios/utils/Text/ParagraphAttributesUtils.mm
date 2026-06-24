#import "ParagraphAttributesUtils.h"
#import "EnrichedTextInputView.h"
#import "ParagraphsUtils.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"
#import "ZeroWidthSpaceUtils.h"

@implementation ParagraphAttributesUtils

+ (NSArray<id<BaseStyleProtocol>> *)paragraphStylesForInput:
    (EnrichedTextInputView *)input {
  NSMutableArray<id<BaseStyleProtocol>> *paragraphStyles =
      [NSMutableArray array];

  for (id<BaseStyleProtocol> style in input->stylesDict.allValues) {
    if ([[style class] isParagraphStyle]) {
      [paragraphStyles addObject:style];
    }
  }

  return paragraphStyles.copy;
}

+ (NSArray<id<BaseStyleProtocol>> *)paragraphStylesForInput:
                                        (EnrichedTextInputView *)input
                                                      range:(NSRange)range {
  return [self paragraphStylesForInput:input
                      attributedString:input->textView.textStorage
                                 range:range];
}

+ (NSArray<id<BaseStyleProtocol>> *)
    paragraphStylesForInput:(EnrichedTextInputView *)input
           attributedString:(NSAttributedString *)string
                   location:(NSUInteger)location {
  if (!string || string.length == 0 || location > string.length) {
    return @[];
  }

  NSRange paragraphRange =
      [string.string paragraphRangeForRange:NSMakeRange(location, 0)];

  return [self paragraphStylesForInput:input
                      attributedString:string
                                 range:paragraphRange];
}

+ (NSArray<id<BaseStyleProtocol>> *)
    paragraphStylesForInput:(EnrichedTextInputView *)input
           attributedString:(NSAttributedString *)string
                      range:(NSRange)range {
  if (!string || string.length == 0 || range.length == 0 ||
      range.location >= string.length) {
    return @[];
  }

  NSRange validRange =
      NSIntersectionRange(range, NSMakeRange(0, string.length));
  if (validRange.length == 0) {
    return @[];
  }

  NSUInteger index = validRange.location;
  NSMutableArray<id<BaseStyleProtocol>> *result = [NSMutableArray array];

  for (id<BaseStyleProtocol> style in [self paragraphStylesForInput:input]) {
    NSAttributedStringKey key = [style.class attributeKey];

    id attributes = [string attribute:key
                              atIndex:index
                longestEffectiveRange:nil
                              inRange:validRange];

    if ([style styleCondition:attributes range:validRange]) {
      [result addObject:style];
    }
  }

  return result.copy;
}

+ (NSDictionary *)attributesForStyle:(id<BaseStyleProtocol>)style
                         textStorage:(NSTextStorage *)textStorage
                               range:(NSRange)range {
  if (range.length == 0 || range.location >= textStorage.length) {
    return nil;
  }

  Class styleClass = [style class];
  NSAttributedStringKey key = [styleClass attributeKey];
  id value = [textStorage attribute:key
                            atIndex:range.location
              longestEffectiveRange:nil
                            inRange:range];

  if ([styleClass conformsToProtocol:@protocol(ParameterizedStyleProtocol)]) {
    return [(Class<ParameterizedStyleProtocol>)styleClass
        getParametersFromValue:value];
  }

  if ([styleClass conformsToProtocol:@protocol(ParagraphModifierStyle)]) {
    return [(Class<ParagraphModifierStyle>)styleClass
        containerAttributesFromValue:value];
  }

  return nil;
}

+ (void)resetParagraphAlignmentInAttributedString:
            (NSMutableAttributedString *)string
                                            range:(NSRange)range {
  [string enumerateAttribute:NSParagraphStyleAttributeName
                     inRange:range
                     options:0
                  usingBlock:^(id _Nullable value, NSRange effectiveRange,
                               BOOL *_Nonnull stop) {
                    if (![value isKindOfClass:[NSParagraphStyle class]]) {
                      return;
                    }

                    NSMutableParagraphStyle *paragraphStyle =
                        [value mutableCopy];
                    if (paragraphStyle.alignment == NSTextAlignmentNatural) {
                      return;
                    }

                    paragraphStyle.alignment = NSTextAlignmentNatural;
                    [string addAttribute:NSParagraphStyleAttributeName
                                   value:paragraphStyle
                                   range:effectiveRange];
                  }];
}

// if the user backspaces the last character in a line, the iOS applies typing
// attributes from the previous line in the case of some paragraph styles it
// works especially bad when a list point just appears this method handles that
// case differently with or without present paragraph styles
+ (BOOL)handleBackspaceInRange:(NSRange)range
               replacementText:(NSString *)text
                         input:(id)input {
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)input;

  if (typedInput == nullptr) {
    return NO;
  }

  // we make sure it was a backspace (text with 0 length) and it deleted
  // something (range longer than 0)
  if (text.length > 0 || range.length == 0) {
    return NO;
  }

  // find a non-newline range of the paragraph
  NSRange paragraphRange =
      [typedInput->textView.textStorage.string paragraphRangeForRange:range];

  NSArray *paragraphs =
      [ParagraphsUtils getNonNewlineRangesIn:typedInput->textView
                                       range:paragraphRange];
  if (paragraphs.count == 0) {
    return NO;
  }

  NSRange nonNewlineRange = [(NSValue *)paragraphs.firstObject rangeValue];

  // the backspace removes the whole content of a paragraph (possibly more but
  // has to start where the paragraph starts)
  if (range.location == nonNewlineRange.location &&
      range.length >= nonNewlineRange.length) {
    // for lists, quotes and codeblocks present we do the following:
    // - manually do the removing
    // - reset typing attribtues so that the previous line styles don't get
    // applied
    // - reapply the paragraph style that was present so that a zero width space
    // appears here
    NSArray<id<BaseStyleProtocol>> *handledStyles =
        [ZeroWidthSpaceUtils ZWSStylesForInput:typedInput];
    for (id<BaseStyleProtocol> style in handledStyles) {
      if ([style detectStyle:nonNewlineRange]) {
        [TextInsertionUtils replaceText:text
                                     at:range
                   additionalAttributes:nullptr
                                  input:typedInput
                          withSelection:YES];
        typedInput->textView.typingAttributes =
            typedInput->defaultTypingAttributes;
        [style addAttributes:NSMakeRange(range.location, 0)];
        return YES;
      }
    }

    // otherwise (no paragraph styles present), we just do the replacement
    // manually and reset typing attribtues
    [TextInsertionUtils replaceText:text
                                 at:range
               additionalAttributes:nullptr
                              input:typedInput
                      withSelection:YES];
    typedInput->textView.typingAttributes = typedInput->defaultTypingAttributes;
    return YES;
  }

  return NO;
}

/**
 * Handles the specific case of backspacing a newline character, which results
 * in merging two paragraphs.
 *
 * THE PROBLEM:
 * When merging a bottom paragraph (Source) into a top paragraph (Destination),
 * the bottom paragraph normally brings its paragraph attributes with it. If the
 * top paragraph already has paragraph styles, the merged paragraph should keep
 * those destination styles instead of preserving the source paragraph styles.
 *
 * THE SOLUTION:
 * 1. Finds the paragraph styles of the paragraph ABOVE the deleted newline.
 * 2. Removes paragraph styles from the paragraph BELOW the newline.
 * 3. Applies the left paragraph styles to the right paragraph.
 * 4. Performs the merge by deleting the newline.
 *
 * @return YES if the newline backspace was handled; NO otherwise.
 */
+ (BOOL)handleParagraphStylesMergeOnBackspace:(NSRange)range
                              replacementText:(NSString *)text
                                        input:(id)input {
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)input;
  if (typedInput == nullptr) {
    return NO;
  }

  // Must be a backspace.
  if (text.length > 0) {
    return NO;
  }

  // Backspace must have removed a newline character.
  NSString *removedString =
      [typedInput->textView.textStorage.string substringWithRange:range];
  if ([removedString
          rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]]
          .location == NSNotFound) {
    return NO;
  }

  NSRange leftRange = [typedInput->textView.textStorage.string
      paragraphRangeForRange:NSMakeRange(range.location, 0)];

  NSArray<id<BaseStyleProtocol>> *leftParagraphStyles =
      [self paragraphStylesForInput:typedInput range:leftRange];

  if (leftParagraphStyles.count == 0) {
    return NO;
  }

  // index out of bounds
  NSUInteger rightRangeStart = range.location + range.length;
  if (rightRangeStart >= typedInput->textView.textStorage.string.length) {
    return NO;
  }

  NSRange rightRange = [typedInput->textView.textStorage.string
      paragraphRangeForRange:NSMakeRange(rightRangeStart, 1)];

  NSMutableDictionary<NSNumber *, NSDictionary *> *leftStyleAttributes =
      [NSMutableDictionary dictionary];
  NSTextStorage *textStorage = typedInput->textView.textStorage;

  for (id<BaseStyleProtocol> style in leftParagraphStyles) {
    NSDictionary *attributes = [self attributesForStyle:style
                                            textStorage:textStorage
                                                  range:leftRange];
    if (attributes != nil) {
      leftStyleAttributes[@([[style class] getStyleType])] = attributes;
    }
  }

  [textStorage beginEditing];

  for (id<BaseStyleProtocol> style in
       [self paragraphStylesForInput:typedInput]) {
    [style removeAttributesFromAttributedString:textStorage range:rightRange];
  }
  [self resetParagraphAlignmentInAttributedString:textStorage range:rightRange];

  for (id<BaseStyleProtocol> style in leftParagraphStyles) {
    NSDictionary *attributes =
        leftStyleAttributes[@([[style class] getStyleType])];
    [style addAttributesInAttributedString:textStorage
                                     range:rightRange
                                attributes:attributes];
  }

  [textStorage endEditing];

  [TextInsertionUtils replaceText:text
                               at:range
             additionalAttributes:nullptr
                            input:typedInput
                    withSelection:YES];
  return YES;
}

/**
 * Resets typing attributes to defaults when the cursor lands on an empty line
 * after a deletion.
 *
 * This override is necessary because `UITextView` automatically inherits
 * attributes from the preceding newline. This prevents scenarios where a
 * restrictive style (like CodeBlock) "leaks" into the next empty paragraph.
 */
+ (BOOL)handleResetTypingAttributesOnBackspace:(NSRange)range
                               replacementText:(NSString *)text
                                         input:(id)input {
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)input;
  if (typedInput == nullptr) {
    return NO;
  }

  NSString *storageString = typedInput->textView.textStorage.string;

  if (text.length > 0 || range.location >= storageString.length) {
    return NO;
  }

  unichar firstCharToDelete = [storageString characterAtIndex:range.location];
  if (![[NSCharacterSet newlineCharacterSet]
          characterIsMember:firstCharToDelete]) {
    return NO;
  }

  NSRange leftParagraphRange =
      [storageString paragraphRangeForRange:NSMakeRange(range.location, 0)];
  BOOL isLeftLineEmpty = [self isParagraphEmpty:leftParagraphRange
                                       inString:storageString];

  BOOL isRightLineEmpty = YES;
  NSUInteger rightRangeStart = range.location + range.length;

  if (rightRangeStart < storageString.length) {
    NSRange rightParagraphRange =
        [storageString paragraphRangeForRange:NSMakeRange(rightRangeStart, 0)];
    isRightLineEmpty = [self isParagraphEmpty:rightParagraphRange
                                     inString:storageString];
  }

  if (isLeftLineEmpty && isRightLineEmpty) {
    [TextInsertionUtils replaceText:text
                                 at:range
               additionalAttributes:nullptr
                              input:typedInput
                      withSelection:YES];

    typedInput->textView.typingAttributes = typedInput->defaultTypingAttributes;
    return YES;
  }

  return NO;
}

+ (BOOL)isParagraphEmpty:(NSRange)range inString:(NSString *)string {
  if (range.length == 0)
    return YES;

  NSString *paragraphText = [string substringWithRange:range];
  NSString *trimmed = [paragraphText
      stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
  return trimmed.length == 0;
}

@end
