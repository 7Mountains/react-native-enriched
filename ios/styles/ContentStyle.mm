#import "ColorExtension.h"
#import "EnrichedImageLoader.h"
#import "EnrichedTextInputView.h"
#import "HtmlAttributeNames.h"
#import "ImageLabelAttachment.h"
#import "OccurenceUtils.h"
#import "Strings.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"
#import "UIView+React.h"
#import "WordsUtils.h"
#import <React/RCTFont.h>

static NSString *const ContentAttributeName = @"ContentAttributeName";

@implementation ContentStyle {
  EnrichedTextInputView *_input;
}

#pragma mark - Init

- (instancetype)initWithInput:(id)input {
  self = [super init];
  _input = (EnrichedTextInputView *)input;
  return self;
}

+ (StyleType)getStyleType {
  return Content;
}

+ (BOOL)isParagraphStyle {
  return YES;
}

+ (BOOL)isSelfClosing {
  return YES;
}

+ (const char *)tagName {
  return "content";
}

+ (const char *)subTagName {
  return nil;
}

+ (NSAttributedStringKey)attributeKey {
  return ContentAttributeName;
}

+ (NSDictionary<NSString *, id> *_Nullable)getParametersFromValue:(id)value {
  ContentParams *contentParams = value;
  if (![contentParams isKindOfClass:[ContentParams class]]) {
    return nil;
  }

  NSUInteger capacity = contentParams.attributes.count + 3;

  NSMutableDictionary *params =
      [NSMutableDictionary dictionaryWithCapacity:capacity];

  if (contentParams.type) {
    params[ContentTypeAttributeName] = contentParams.type;
  }

  if (contentParams.url) {
    params[ContentSrcAttributeName] = contentParams.url;
  }

  if (contentParams.text) {
    params[ContentTextAttributeName] = contentParams.text;
  }

  if (contentParams.attributes.count > 0) {
    [params addEntriesFromDictionary:contentParams.attributes];
  }

  return params.count ? params : nil;
}

- (void)addAttributesInAttributedString:
            (NSMutableAttributedString *)attributedString
                                  range:(NSRange)range
                             attributes:
                                 (NSDictionary<NSString *, id> *)attributes {
  if (range.length == 0 || attributes.count == 0)
    return;

  ContentParams *params = [ContentParams new];

  id text = attributes[ContentTextAttributeName];
  if ([text isKindOfClass:NSString.class]) {
    params.text = text;
  }

  id type = attributes[ContentTypeAttributeName];
  if ([type isKindOfClass:NSString.class]) {
    params.type = type;
  }

  id url = attributes[ContentSrcAttributeName];
  if ([url isKindOfClass:NSString.class]) {
    params.url = url;
  }

  NSMutableDictionary *extra = [attributes mutableCopy];
  [extra removeObjectsForKeys:@[
    ContentSrcAttributeName, ContentTypeAttributeName, ContentTextAttributeName
  ]];
  if ([extra isKindOfClass:NSDictionary.class]) {
    params.attributes = extra;
  }

  [attributedString addAttributes:[self prepareAttributes:params] range:range];
}

#pragma mark - NO-OP STYLE METHODS

/// Centralized NO-OP macro so all "do nothing" methods call the same code
#define CONTENTSTYLE_NOOP()                                                    \
  do {                                                                         \
  } while (0)

- (void)applyStyle:(NSRange)range {
  CONTENTSTYLE_NOOP();
}
- (void)addAttributes:(NSRange)range {
  CONTENTSTYLE_NOOP();
}
- (void)addTypingAttributes {
  CONTENTSTYLE_NOOP();
}
- (void)removeTypingAttributes {
  CONTENTSTYLE_NOOP();
}

- (void)removeAttributes:(NSRange)range {
  NSTextStorage *textStorage = _input->textView.textStorage;
  [textStorage beginEditing];
  [textStorage removeAttribute:NSAttachmentAttributeName range:range];
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
    return [OccurenceUtils detect:ContentAttributeName
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
  return [OccurenceUtils any:ContentAttributeName
                   withInput:_input
                     inRange:range
               withCondition:[self contentCondition]];
}

- (NSArray<StylePair *> *)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:ContentAttributeName
                   withInput:_input
                     inRange:range
               withCondition:[self contentCondition]];
}

#pragma mark - Attachment Params Lookup

- (ContentParams *)getContentParams:(NSUInteger)location {
  if (location >= _input->textView.textStorage.length)
    return nil;

  unichar c = [_input->textView.textStorage.string characterAtIndex:location];
  if (c != ORCChar)
    return nil;

  NSDictionary *attrs = [_input->textView.textStorage attributesAtIndex:location
                                                         effectiveRange:NULL];

  id value = attrs[ContentAttributeName];
  return [value isKindOfClass:[ContentParams class]] ? value : nil;
}

#pragma mark - Internal: Props & Attachments

- (ContentStyleProps *)stylePropsWithParams:(ContentParams *)params {
  return [_input->config contentStylePropsForType:params.type];
}

- (MediaAttachment *)prepareAttachment:(ContentParams *)params {
  ContentStyleProps *styles = [self stylePropsWithParams:params];

  MediaAttachment *attachment;

  BOOL hasImageURL = params.url != nil && params.url.length > 0;

  if (hasImageURL) {
    attachment = [[ImageLabelAttachment alloc] initWithParams:params
                                                       styles:styles];
    attachment.delegate = _input;
  } else {
    attachment = [[BaseLabelAttachment alloc] initWithParams:params
                                                      styles:styles];
    attachment.delegate = _input;
  }

  return attachment;
}

- (NSDictionary *)prepareAttributes:(ContentParams *)params {
  NSMutableDictionary *attributes =
      [_input->defaultTypingAttributes mutableCopy];
  attributes[NSAttachmentAttributeName] = [self prepareAttachment:params];
  attributes[ContentAttributeName] = params;
  attributes[ReadOnlyParagraphKey] = @YES;
  return attributes;
}

- (void)addContent:(ContentParams *)params {
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
