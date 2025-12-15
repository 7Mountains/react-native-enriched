#import "DividerAttachment.h"
#import "EnrichedTextInputView.h"
#import "OccurenceUtils.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"

static NSString *const placeholder = @"\uFFFC";

@implementation DividerStyle {
  EnrichedTextInputView *_input;
}

+ (StyleType)getStyleType {
  return Divider;
}

+ (BOOL)isParagraphStyle {
  return YES;
}

+ (const char *)tagName {
  return "hr";
}

+ (const char *)subTagName {
  return nil;
}

+ (BOOL)isSelfClosing {
  return YES;
}

+ (NSAttributedStringKey)attributeKey {
  return NSAttachmentAttributeName;
}

- (instancetype)initWithInput:(id)input {
  if (self = [super init]) {
    _input = (EnrichedTextInputView *)input;
  }
  return self;
}

#pragma mark - Style Application

- (void)applyStyle:(NSRange)range {
  // no-op for dividers
}

- (void)addAttributes:(NSRange)range withTypingAttr:(BOOL)withTypingAttr {
  NSTextStorage *textStorage = _input->textView.textStorage;
  NSDictionary *attrs = [self prepareAttributes];
  _input->blockEmitting = YES;
  [textStorage beginEditing];
  [TextInsertionUtils replaceText:placeholder
                               at:range
             additionalAttributes:attrs
                            input:_input
                    withSelection:NO];
  [textStorage endEditing];
  _input->blockEmitting = NO;
}

- (void)addTypingAttributes {
  // no-op for dividers
}

- (void)removeAttributes:(NSRange)range {
  NSTextStorage *textStorage = _input->textView.textStorage;
  [textStorage beginEditing];
  [textStorage removeAttribute:NSAttachmentAttributeName range:range];
  [textStorage endEditing];
}

- (void)removeTypingAttributes {
  NSMutableDictionary *attrs = [_input->textView.typingAttributes mutableCopy];
  [attrs removeObjectForKey:NSAttachmentAttributeName];
  _input->textView.typingAttributes = attrs;
}

#pragma mark - Style Detection Helpers

- (BOOL)styleCondition:(id)value range:(NSRange)range {
  NSString *charStr =
      [_input->textView.textStorage.string substringWithRange:range];
  return [value isKindOfClass:[DividerAttachment class]] &&
         [charStr isEqualToString:placeholder];
}

- (BOOL)detectStyle:(NSRange)range {
  if (range.length >= 1) {
    return [OccurenceUtils detect:NSAttachmentAttributeName
                        withInput:_input
                          inRange:range
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value range:range];
                    }];
  } else {
    return [OccurenceUtils detect:NSAttachmentAttributeName
                        withInput:_input
                          atIndex:range.location
                    checkPrevious:NO
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value range:range];
                    }];
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:NSAttachmentAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id value, NSRange r) {
                 return [self styleCondition:value range:r];
               }];
}

- (NSArray<StylePair *> *)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:NSAttachmentAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id value, NSRange r) {
                 return [self styleCondition:value range:r];
               }];
}

#pragma mark - Attachment & Attributes

- (DividerAttachment *)prepareAttachment {
  DividerAttachment *attachment = [[DividerAttachment alloc] init];
  attachment.color = _input->config.dividerColor;
  attachment.height = _input->config.dividerHeight;
  attachment.thickness = _input->config.dividerThickness;
  return attachment;
}

- (NSDictionary *)prepareAttributes {
  InputConfig *config = _input->config;

  return @{
    NSAttachmentAttributeName : [self prepareAttachment],
    NSFontAttributeName : config.primaryFont,
    NSForegroundColorAttributeName : config.primaryColor,
    NSFontAttributeName : config.primaryFont,
    ReadOnlyParagraphKey : @(YES),
  };
}

#pragma mark - Divider Insertion

- (void)insertDividerAt:(NSUInteger)index setSelection:(BOOL)setSelection {
  EnrichedTextInputView *input = _input;
  NSTextStorage *textStorage = input->textView.textStorage;
  NSString *string = textStorage.string;

  NSDictionary *dividerAttrs = [self prepareAttributes];
  _input->blockEmitting = YES;

  // empty paragraph
  NSRange paragraphRange =
      [string paragraphRangeForRange:NSMakeRange(index, 0)];

  NSString *paragraphText = [string substringWithRange:paragraphRange];
  BOOL isEmptyParagraph =
      (paragraphRange.length <= 1 || [paragraphText isEqualToString:@"\n"]);

  if (isEmptyParagraph) {
    [textStorage beginEditing];

    if (paragraphRange.length > 0) {
      [textStorage replaceCharactersInRange:paragraphRange withString:@""];
    }
    NSUInteger insertPos = paragraphRange.location;
    [TextInsertionUtils insertText:placeholder
                                at:insertPos
              additionalAttributes:input->defaultTypingAttributes
                             input:input
                     withSelection:NO];

    NSRange phRange = NSMakeRange(insertPos, 1);
    [TextInsertionUtils replaceText:placeholder
                                 at:phRange
               additionalAttributes:dividerAttrs
                              input:_input
                      withSelection:setSelection];

    [TextInsertionUtils insertText:@"\n"
                                at:insertPos + 1
              additionalAttributes:input->defaultTypingAttributes
                             input:input
                     withSelection:NO];

    [textStorage endEditing];

    if (setSelection) {
      _input->textView.selectedRange = NSMakeRange(insertPos + 2, 0);
    }

    _input->blockEmitting = NO;
    return;
  }

  BOOL beforeIsNewline =
      (index > 0 && [string characterAtIndex:index - 1] == '\n');

  BOOL afterIsNewline =
      (index < string.length && [string characterAtIndex:index] == '\n');

  BOOL isPrevDivider = NO;
  if (index > 0) {
    id prevAttr = [textStorage attribute:NSAttachmentAttributeName
                                 atIndex:index - 1
                          effectiveRange:nil];
    if ([prevAttr isKindOfClass:[DividerAttachment class]]) {
      isPrevDivider = YES;
    }
  }

  BOOL isNextDivider = NO;
  if (index < string.length) {
    id nextAttr = [textStorage attribute:NSAttachmentAttributeName
                                 atIndex:index
                          effectiveRange:nil];
    if ([nextAttr isKindOfClass:[DividerAttachment class]]) {
      isNextDivider = YES;
    }
  }

  BOOL needsNewlineBefore = !beforeIsNewline && !isPrevDivider;
  BOOL needsNewlineAfter = !afterIsNewline && !isNextDivider;

  NSInteger insertIndex = index;
  input->textView.typingAttributes = input->defaultTypingAttributes;

  [textStorage beginEditing];

  if (needsNewlineBefore) {
    [TextInsertionUtils insertText:@"\n"
                                at:insertIndex
              additionalAttributes:input->defaultTypingAttributes
                             input:input
                     withSelection:NO];
    insertIndex += 1;
  }

  [TextInsertionUtils insertText:placeholder
                              at:insertIndex
            additionalAttributes:input->defaultTypingAttributes
                           input:input
                   withSelection:NO];

  NSRange phRange = NSMakeRange(insertIndex, 1);

  [TextInsertionUtils replaceText:placeholder
                               at:phRange
             additionalAttributes:dividerAttrs
                            input:_input
                    withSelection:setSelection];

  if (needsNewlineAfter) {
    [TextInsertionUtils insertText:@"\n"
                                at:insertIndex
              additionalAttributes:input->defaultTypingAttributes
                             input:input
                     withSelection:NO];
    insertIndex += 1;
  }

  [textStorage endEditing];

  if (setSelection) {
    _input->textView.selectedRange = NSMakeRange(insertIndex + 1, 0);
  }

  _input->blockEmitting = NO;
}

- (void)insertDividerAtline:(NSRange *)at withSelection:(BOOL)withSelection {
  UITextView *tv = _input->textView;
  NSString *string = tv.textStorage.string;

  NSRange selection = tv.selectedRange;
  NSRange lineRange = [string lineRangeForRange:selection];
  NSUInteger index = lineRange.location + lineRange.length;

  [self insertDividerAt:index setSelection:withSelection];
}

- (void)insertDividerAtNewLine {
  UITextView *tv = _input->textView;
  NSString *string = tv.textStorage.string;

  NSRange selection = tv.selectedRange;
  NSRange lineRange = [string lineRangeForRange:selection];
  NSUInteger index = lineRange.location + lineRange.length;

  [self insertDividerAt:index setSelection:YES];
}

@end
