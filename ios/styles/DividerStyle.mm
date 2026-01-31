#import "DividerAttachment.h"
#import "EnrichedTextInputView.h"
#import "OccurenceUtils.h"
#import "Strings.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"

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
    NSRange paragraphRange =
        [_input->textView.textStorage.string paragraphRangeForRange:range];
    return [self anyOccurence:paragraphRange];
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

#pragma mark - Divider Insertion

- (void)insertDividerAtNewLine {
  UITextView *textView = _input->textView;
  NSString *string = textView.textStorage.string;

  NSRange selection = textView.selectedRange;
  NSRange lineRange = [string lineRangeForRange:selection];
  NSUInteger index = lineRange.location + lineRange.length;
  NSDictionary *dividerAttrs = [self prepareAttributes];
  _input->blockEmitting = YES;
  [TextInsertionUtils insertEscapingParagraphsAtIndex:index
                                                 text:ORC
                                           attributes:dividerAttrs
                                                input:_input
                                        withSelection:YES];
  _input->blockEmitting = NO;
}

@end
