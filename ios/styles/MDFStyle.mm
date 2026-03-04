#import "ColorExtension.h"
#import "EnrichedTextInputView.h"
#import "HtmlAttributeNames.h"
#import "MdfAttachment.h"
#import "OccurenceUtils.h"
#import "Strings.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"
#import "UIView+React.h"
#import "WordsUtils.h"
#import <React/RCTFont.h>

static NSString *const MdfAttributeName = @"MdfAttributeName";

@implementation MDFStyle {
  EnrichedTextInputView *_input;
}

#pragma mark - Init

- (instancetype)initWithInput:(id)input {
  self = [super init];
  _input = (EnrichedTextInputView *)input;
  return self;
}

+ (StyleType)getStyleType {
  return MDF;
}

+ (BOOL)isParagraphStyle {
  return YES;
}

+ (BOOL)isSelfClosing {
  return YES;
}

+ (const char *)tagName {
  return "mdf";
}

+ (const char *)subTagName {
  return nil;
}

+ (NSAttributedStringKey)attributeKey {
  return MdfAttributeName;
}

+ (NSDictionary<NSString *, id> *_Nullable)getParametersFromValue:(id)value {
  MDFParams *mdfParams = value;
  if (![mdfParams isKindOfClass:[MDFParams class]]) {
    return nil;
  }

  return [mdfParams toDictionary];
}

- (void)addAttributesInAttributedString:
            (NSMutableAttributedString *)attributedString
                                  range:(NSRange)range
                             attributes:
                                 (NSDictionary<NSString *, id> *)attributes {
  if (range.length == 0)
    return;

  MDFParams *params = [MDFParams fromdDictionary:attributes];

  [attributedString addAttributes:[self prepareAttributes:params] range:range];
}

#pragma mark - NO-OP STYLE METHODS

- (void)applyStyle:(NSRange)range {
}
- (void)addAttributes:(NSRange)range {
}
- (void)addTypingAttributes {
}
- (void)removeTypingAttributes {
}

- (void)removeAttributesFromAttributedString:(NSMutableAttributedString *)string
                                       range:(NSRange)range {
  [string removeAttribute:NSAttachmentAttributeName range:range];
}

- (void)removeAttributes:(NSRange)range {
  NSTextStorage *textStorage = _input->textView.textStorage;
  [textStorage beginEditing];
  [self removeAttributesFromAttributedString:textStorage range:range];
  [textStorage endEditing];
}

#pragma mark - Style Detection Helpers

- (BOOL (^)(id _Nullable, NSRange))contentCondition {
  return ^BOOL(id _Nullable value, NSRange range) {
    return [self styleCondition:value range:range];
  };
}

- (BOOL)styleCondition:(id)value range:(NSRange)range {
  return value != nullptr;
}

- (BOOL)detectStyle:(NSRange)range {
  auto condition = [self contentCondition];

  if (range.length >= 1) {
    return [OccurenceUtils detect:MdfAttributeName
                        withInput:_input
                          inRange:range
                    withCondition:condition];
  } else {
    UITextView *textView = _input->textView;
    NSRange paragraphRange =
        [textView.textStorage.string paragraphRangeForRange:range];
    return [self anyOccurence:paragraphRange];
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:MdfAttributeName
                   withInput:_input
                     inRange:range
               withCondition:[self contentCondition]];
}

- (NSArray<StylePair *> *)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:MdfAttributeName
                   withInput:_input
                     inRange:range
               withCondition:[self contentCondition]];
}

#pragma mark - Attachment Params Lookup

- (MDFParams *)getParmsAt:(NSUInteger)location {
  if (location >= _input->textView.textStorage.length)
    return nil;

  unichar c = [_input->textView.textStorage.string characterAtIndex:location];
  if (c != ORCChar)
    return nil;

  NSDictionary *attrs = [_input->textView.textStorage attributesAtIndex:location
                                                         effectiveRange:NULL];

  id value = attrs[MdfAttributeName];
  return [value isKindOfClass:[ContentParams class]] ? value : nil;
}

- (MediaAttachment *)prepareAttachment:(MDFParams *)params {
  MDFAttachment *attachment =
      [[MDFAttachment alloc] initWithParams:params
                                     styles:_input->config.mdfStyle];

  attachment.delegate = _input;

  return attachment;
}

- (NSDictionary *)prepareAttributes:(MDFParams *)params {
  NSMutableDictionary *attributes = _input->defaultTypingAttributes.mutableCopy;
  attributes[NSAttachmentAttributeName] = [self prepareAttachment:params];
  attributes[MdfAttributeName] = params;
  attributes[ReadOnlyParagraphKey] = @YES;
  return attributes;
}

- (void)addMdf:(MDFParams *)params {
  if (!_input || !params)
    return;

  UITextView *textView = _input->textView;
  NSString *string = textView.textStorage.string;

  NSRange selection = textView.selectedRange;
  NSRange lineRange = [string lineRangeForRange:selection];
  NSUInteger index = lineRange.location + lineRange.length;

  NSDictionary *attrs = [self prepareAttributes:params];

  [TextInsertionUtils insertEscapingParagraphsAtIndex:index
                                                 text:ORC
                                           attributes:attrs
                                                input:_input
                                        withSelection:YES];
}

@end
