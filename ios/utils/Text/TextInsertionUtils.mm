#import "TextInsertionUtils.h"
#import "EnrichedTextInputView.h"
#import "ParagraphsUtils.h"
#import "Strings.h"
#import "StyleHeaders.h"
#import "UIView+React.h"

@implementation TextInsertionUtils
+ (void)insertText:(NSString *)text
                      at:(NSInteger)index
    additionalAttributes:
        (NSDictionary<NSAttributedStringKey, id> *)additionalAttrs
                   input:(id)input
           withSelection:(BOOL)withSelection {
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)input;
  if (typedInput == nullptr) {
    return;
  }

  UITextView *textView = typedInput->textView;

  NSMutableDictionary<NSAttributedStringKey, id> *copiedAttrs =
      [textView.typingAttributes mutableCopy];
  if (additionalAttrs != nullptr) {
    [copiedAttrs addEntriesFromDictionary:additionalAttrs];
  }

  NSAttributedString *newAttrStr =
      [[NSAttributedString alloc] initWithString:text attributes:copiedAttrs];
  [textView.textStorage insertAttributedString:newAttrStr atIndex:index];

  if (withSelection) {
    if (![textView isFirstResponder]) {
      [textView reactFocus];
    }
    textView.selectedRange = NSMakeRange(index + text.length, 0);
  }
  [typedInput setRecentlyChangedRange:NSMakeRange(index, text.length)];
}

+ (void)replaceText:(NSString *)text
                      at:(NSRange)range
    additionalAttributes:
        (NSDictionary<NSAttributedStringKey, id> *)additionalAttrs
                   input:(id)input
           withSelection:(BOOL)withSelection {
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)input;
  if (typedInput == nullptr) {
    return;
  }

  UITextView *textView = typedInput->textView;

  [textView.textStorage replaceCharactersInRange:range withString:text];
  if (additionalAttrs != nullptr) {
    [textView.textStorage
        addAttributes:additionalAttrs
                range:NSMakeRange(range.location, [text length])];
  }

  if (withSelection) {
    if (![textView isFirstResponder]) {
      [textView reactFocus];
    }
    textView.selectedRange = NSMakeRange(range.location + text.length, 0);
  }
  [typedInput setRecentlyChangedRange:NSMakeRange(range.location, text.length)];
}

+ (BOOL)tryInsertText:(NSString *)text
    afterReadOnlyParagraphInRange:(NSRange)range
                            input:(id)input
                  paragraphsLimit:(NSInteger)paragraphsLimit {
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)input;
  if (typedInput == nullptr || text.length == 0 || range.length != 0) {
    return NO;
  }

  UITextView *textView = typedInput->textView;
  NSTextStorage *storage = textView.textStorage;
  if (![ParagraphsUtils isAtEndOfReadOnlyParagraph:storage
                                          location:range.location]) {
    return NO;
  }

  NSString *replacementText = [NewLine stringByAppendingString:text];
  if (paragraphsLimit > 0) {
    NSInteger existing = [ParagraphsUtils paragraphsCountInTextView:textView];
    NSInteger incoming =
        [ParagraphsUtils incomingParagraphsCountFromString:replacementText];

    if (existing + incoming - 1 > paragraphsLimit) {
      return NO;
    }
  }

  NSAttributedString *replacement = [[NSAttributedString alloc]
      initWithString:replacementText
          attributes:typedInput->defaultTypingAttributes];
  NSRange replacementRange = NSMakeRange(range.location, replacement.length);

  [storage beginEditing];
  [storage replaceCharactersInRange:range withAttributedString:replacement];
  [storage removeAttribute:ReadOnlyParagraphKey range:replacementRange];
  [storage endEditing];

  textView.selectedRange = NSMakeRange(NSMaxRange(replacementRange), 0);
  [typedInput setRecentlyChangedRange:replacementRange];

  return YES;
}

+ (BOOL)tryDeleteReadOnlyParagraphBeforeRange:(NSRange)range input:(id)input {
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)input;
  if (typedInput == nullptr || range.length != 1 || range.location == 0) {
    return NO;
  }

  UITextView *textView = typedInput->textView;
  NSTextStorage *storage = textView.textStorage;
  NSRange readOnlyRange = NSMakeRange(0, 0);
  id readOnly = [storage attribute:ReadOnlyParagraphKey
                           atIndex:range.location - 1
                    effectiveRange:&readOnlyRange];

  if (readOnly == nil || NSMaxRange(readOnlyRange) < range.location) {
    return NO;
  }

  NSRange deletionRange =
      NSMakeRange(readOnlyRange.location,
                  MAX(NSMaxRange(readOnlyRange), NSMaxRange(range)) -
                      readOnlyRange.location);

  [storage beginEditing];
  [storage deleteCharactersInRange:deletionRange];
  [storage endEditing];

  textView.selectedRange = NSMakeRange(deletionRange.location, 0);
  [typedInput setRecentlyChangedRange:deletionRange];

  return YES;
}

+ (void)insertEscapingParagraphsAtIndex:(NSUInteger)index
                                   text:(NSString *)text
                             attributes:
                                 (NSDictionary<NSAttributedStringKey, id> *)
                                     attributes
                                  input:(EnrichedTextInputView *)typedInput
                          withSelection:(BOOL)withSelection {
  if (!typedInput)
    return;

  UITextView *textView = typedInput->textView;
  NSTextStorage *storage = textView.textStorage;
  NSString *fullText = storage.string;

  BOOL hasNewlineBefore = (index > 0 && [fullText characterAtIndex:index - 1] ==
                                            NewLineUnsinedChar);
  BOOL hasNewlineAfter = (index < fullText.length &&
                          [fullText
                              characterAtIndex:index] == NewLineUnsinedChar);

  BOOL isParagraphEmpty = (index == 0 || hasNewlineBefore) &&
                          (index == fullText.length || hasNewlineAfter);

  NSDictionary *baseAttrs = typedInput->defaultTypingAttributes;
  NSAttributedString *newline =
      [[NSAttributedString alloc] initWithString:NewLine attributes:baseAttrs];

  [storage beginEditing];

  if (!isParagraphEmpty && !hasNewlineBefore) {
    [storage insertAttributedString:newline atIndex:index++];
  }

  NSMutableAttributedString *insert =
      [[NSMutableAttributedString alloc] initWithString:text
                                             attributes:baseAttrs];
  if (attributes) {
    [insert addAttributes:attributes range:NSMakeRange(0, insert.length)];
  }

  [storage insertAttributedString:insert atIndex:index];
  index += insert.length;

  if (!hasNewlineAfter) {
    [storage insertAttributedString:newline atIndex:index++];
  }

  [storage endEditing];

  if (withSelection) {
    if (![textView isFirstResponder]) {
      [textView reactFocus];
    }
    textView.selectedRange = NSMakeRange(index, 0);
  }
}

@end
