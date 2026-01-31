#import "TextInsertionUtils.h"
#import "EnrichedTextInputView.h"
#import "Strings.h"
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
  typedInput->recentlyChangedRange = NSMakeRange(index, text.length);
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
  typedInput->recentlyChangedRange = NSMakeRange(range.location, text.length);
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
