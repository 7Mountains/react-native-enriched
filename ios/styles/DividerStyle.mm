#import "DividerAttachment.h"
#import "EnrichedTextInputView.h"
#import "OccurenceUtils.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"

static NSString *const placeholder = @"\uFFFC";

@implementation DividerStyle {
  EnrichedTextInputView *_input;
  NSDictionary *_cachedAttributes;
  InputConfig *_cachedConfig;
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
    _cachedConfig = nil;
    _cachedAttributes = nil;
  }
  return self;
}

- (void)addAttributesInAttributedString:
            (NSMutableAttributedString *)attributedString
                                  range:(NSRange)range
                             attributes:(NSDictionary<NSString *, NSString *>
                                             *_Nullable)attributes {
  if (range.length == 0)
    return;

  NSDictionary *attrs = [self prepareAttributes];

  [attributedString addAttributes:attrs range:range];
}

#pragma mark - Style Application

- (void)applyStyle:(NSRange)range {
  // no-op for dividers
}

- (void)addAttributes:(NSRange)range {
  // no-op for dividers
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
  return [value isKindOfClass:[DividerAttachment class]];
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

- (NSDictionary *)prepareAttributes {
  InputConfig *config = _input->config;

  if (_cachedConfig == config && _cachedAttributes != nil) {
    return _cachedAttributes;
  }
  _cachedConfig = config;

  NSMutableParagraphStyle *pStyle = [NSMutableParagraphStyle new];

  DividerAttachment *attachment =
      [[DividerAttachment alloc] initWithStyles:config.dividerColor
                                         height:config.dividerHeight
                                      thickness:config.dividerThickness];

  _cachedAttributes = @{
    NSParagraphStyleAttributeName : pStyle,
    NSAttachmentAttributeName : attachment,
    NSFontAttributeName : config.primaryFont,
    NSForegroundColorAttributeName : config.primaryColor,
    NSFontAttributeName : config.primaryFont,
    ReadOnlyParagraphKey : @(YES),
  };

  return _cachedAttributes;
}

- (BOOL)isParagraphEmpty:(NSRange)paragraphRange
             textStorage:(NSTextStorage *)textStorage {
  if (paragraphRange.length == 0)
    return YES;

  NSString *text = [[textStorage string] substringWithRange:paragraphRange];

  // Trim whitespace & newlines
  NSString *trimmed = [text
      stringByTrimmingCharactersInSet:NSCharacterSet
                                          .whitespaceAndNewlineCharacterSet];

  if (trimmed.length > 0)
    return NO;

  // Check attachments inside paragraph
  __block BOOL hasAttachment = NO;
  [textStorage enumerateAttribute:NSAttachmentAttributeName
                          inRange:paragraphRange
                          options:0
                       usingBlock:^(id value, NSRange range, BOOL *stop) {
                         if (value) {
                           hasAttachment = YES;
                           *stop = YES;
                         }
                       }];

  return !hasAttachment;
}

#pragma mark - Divider Insertion
- (void)insertDividerAt:(NSUInteger)index setSelection:(BOOL)setSelection {

  EnrichedTextInputView *input = _input;
  UITextView *textView = input->textView;
  NSTextStorage *textStorage = textView.textStorage;
  NSString *string = textStorage.string;

  NSDictionary *dividerAttrs = [self prepareAttributes];
  input->blockEmitting = YES;

  NSRange paragraphRange =
      [string paragraphRangeForRange:NSMakeRange(index, 0)];

  if (![self isParagraphEmpty:paragraphRange textStorage:textStorage]) {
    input->blockEmitting = NO;
    return;
  }

  [textStorage beginEditing];

  // Remove paragraph contents (only whitespace/newlines)
  if (paragraphRange.length > 0) {
    [textStorage replaceCharactersInRange:paragraphRange withString:@""];
  }

  NSUInteger dividerIndex = paragraphRange.location;

  // Insert divider placeholder
  [TextInsertionUtils insertText:placeholder
                              at:dividerIndex
            additionalAttributes:input->defaultTypingAttributes
                           input:input
                   withSelection:NO];

  NSRange dividerRange = NSMakeRange(dividerIndex, 1);
  [TextInsertionUtils replaceText:placeholder
                               at:dividerRange
             additionalAttributes:dividerAttrs
                            input:input
                    withSelection:NO];

  [TextInsertionUtils insertText:@"\n"
                              at:dividerIndex + 1
            additionalAttributes:input->defaultTypingAttributes
                           input:input
                   withSelection:NO];

  [textStorage endEditing];

  if (setSelection) {
    textView.selectedRange = NSMakeRange(dividerIndex + 2, 0);
  }

  input->blockEmitting = NO;
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
