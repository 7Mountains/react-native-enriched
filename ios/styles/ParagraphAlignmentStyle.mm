#import "AlignmentConverter.h"
#import "EnrichedTextInputView.h"
#import "OccurenceUtils.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"

@implementation ParagraphAlignmentStyle {
  EnrichedTextInputView *_input;
}

- (instancetype)initWithInput:(id)input {
  self = [super init];
  _input = (EnrichedTextInputView *)input;
  return self;
}

+ (NSDictionary<NSString *, NSString *> *_Nullable)getParametersFromValue:
    (id)value {
  NSParagraphStyle *paragraphStyle = (NSParagraphStyle *)value;
  NSTextAlignment alignment = paragraphStyle.alignment;
  if (alignment == NSTextAlignmentNatural) {
    return nullptr;
  }

  return @{
    @"alignment" : [AlignmentConverter stringFromAlignment:alignment],
  };
}

+ (StyleType)getStyleType {
  return ParagraphAlignment;
}

+ (BOOL)isParagraphStyle {
  return YES;
}

+ (const char *)tagName {
  return nullptr;
}

+ (const char *)subTagName {
  return nullptr;
}

+ (NSAttributedStringKey)attributeKey {
  return nullptr;
}

+ (BOOL)isSelfClosing {
  return NO;
}

- (BOOL)styleCondition:(id _Nullable)value range:(NSRange)range {
  NSParagraphStyle *paragraphStyle = (NSParagraphStyle *)value;
  return value != nullptr && paragraphStyle.alignment != NSTextAlignmentNatural;
}

- (void)
    addAttributesInAttributedString:(NSMutableAttributedString *_Nonnull)string
                              range:(NSRange)range
                         attributes:
                             (NSDictionary<NSString *, NSString *> *_Nullable)
                                 attributes {
}

#pragma mark - Apply Style
- (void)applyStyle:(NSRange)range alignment:(NSTextAlignment)alignment {
  if (range.location == NSNotFound)
    return;

  NSRange paragraphRange =
      [_input->textView.textStorage.string paragraphRangeForRange:range];

  if (paragraphRange.length >= 1) {
    [_input->textView.textStorage beginEditing];

    [_input->textView.textStorage
        enumerateAttribute:NSParagraphStyleAttributeName
                   inRange:paragraphRange
                   options:0
                usingBlock:^(id _Nullable value, NSRange range, BOOL *stop) {
                  NSMutableParagraphStyle *style =
                      value ? [value mutableCopy]
                            : [[NSMutableParagraphStyle alloc] init];
                  style.alignment = alignment;

                  [_input->textView.textStorage
                      addAttribute:NSParagraphStyleAttributeName
                             value:style
                             range:range];
                }];

    [_input->textView.textStorage endEditing];
  }
  NSMutableDictionary *newTypingAttrs =
      [_input->textView.typingAttributes mutableCopy];
  NSMutableParagraphStyle *paragraphStyle =
      [_input->textView.typingAttributes[NSParagraphStyleAttributeName]
          mutableCopy];
  paragraphStyle.alignment = alignment;
  newTypingAttrs[NSParagraphStyleAttributeName] = paragraphStyle;
  _input->textView.typingAttributes = newTypingAttrs;
}

- (void)applyStyle:(NSRange)range {
  // no-op for alignment
}

- (BOOL)handleEnterPressInRange:(NSRange)range
                replacementText:(NSString *)text {
  if ([self detectStyle:_input->textView.selectedRange] && text.length > 0 &&
      [[NSCharacterSet newlineCharacterSet]
          characterIsMember:[text characterAtIndex:text.length - 1]]) {

    // Insert newline manually
    [TextInsertionUtils replaceText:text
                                 at:range
               additionalAttributes:nil
                              input:_input
                      withSelection:YES];

    // New empty paragraph begins at selectedRange.location
    NSRange newParagraphRange = [_input->textView.textStorage.string
        paragraphRangeForRange:_input->textView.selectedRange];

    // Clear alignment
    [_input->textView.textStorage beginEditing];
    [_input->textView.textStorage removeAttribute:NSParagraphStyleAttributeName
                                            range:newParagraphRange];
    [_input->textView.textStorage endEditing];

    return YES;
  }

  return NO;
}

#pragma mark - Typing Attributes (Empty)

- (void)addTypingAttributes {
}

- (void)removeTypingAttributes {
  // Alignment cannot be “removed” this way.
}

#pragma mark - Style Detection

- (BOOL)styleCondition:(id)value:(NSRange)range {
  if (!value)
    return NO;

  NSParagraphStyle *paragraphStyle = (NSParagraphStyle *)value;
  return paragraphStyle.alignment != NSTextAlignmentNatural;
}

- (BOOL)detectStyle:(NSRange)range {
  if (range.length >= 1) {
    return [OccurenceUtils detect:NSParagraphStyleAttributeName
                        withInput:_input
                          inRange:range
                    withCondition:^BOOL(id value, NSRange r) {
                      return [self styleCondition:value:r];
                    }];
  } else {
    return [OccurenceUtils detect:NSParagraphStyleAttributeName
                        withInput:_input
                          atIndex:range.location
                    checkPrevious:YES
                    withCondition:^BOOL(id value, NSRange r) {
                      return [self styleCondition:value:r];
                    }];
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:NSParagraphStyleAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id value, NSRange r) {
                 return [self styleCondition:value:r];
               }];
}

- (NSArray<StylePair *> *)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:NSParagraphStyleAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id value, NSRange r) {
                 return [self styleCondition:value:r];
               }];
}

- (void)addAttributes:(NSRange)range {
  // no-op
}

- (void)removeAttributes:(NSRange)range {
  // no-op
}

@end
