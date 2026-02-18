#import "ColorExtension.h"
#import "EnrichedTextInputView.h"
#import "FontExtension.h"
#import "HtmlAttributeNames.h"
#import "OccurenceUtils.h"
#import "StyleHeaders.h"
#import "StyleTypeEnum.h"

@implementation ColorStyle {
  EnrichedTextInputView *_input;
}

- (NSArray<NSNumber *> *)coloredStyleTypes {
  static NSArray<NSNumber *> *types = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    types = @[
      @(Link),
      @(InlineCode),
      @(BlockQuote),
      @(CodeBlock),
      @(Mention),
    ];
  });
  return types;
}

+ (StyleType)getStyleType {
  return Colored;
}

- (instancetype)initWithInput:(id)input {
  self = [super init];
  _input = (EnrichedTextInputView *)input;
  return self;
}

- (void)applyStyle:(NSRange)range {
}

+ (BOOL)isParagraphStyle {
  return NO;
}

+ (BOOL)isSelfClosing {
  return NO;
}

+ (const char *)tagName {
  return "font";
}

+ (const char *_Nullable)subTagName {
  return nil;
}

+ (NSAttributedStringKey)attributeKey {
  return NSForegroundColorAttributeName;
}

+ (NSDictionary *)getParametersFromValue:(id)value {
  UIColor *color = value;

  return @{
    ColorAttributeName : [color hexString],
  };
}

- (void)applyStyle:(NSRange)range color:(UIColor *)color {
  BOOL isStylePresent = [self detectStyle:range color:color];

  if (range.length >= 1) {
    isStylePresent ? [self removeAttributes:range]
                   : [self addAttributes:range color:color];
  } else {
    isStylePresent ? [self removeTypingAttributes]
                   : [self addTypingAttributes:color];
  }
}

#pragma mark - Add attributes

- (void)addAttributes:(NSRange)range color:(UIColor *)color {
  if (color == nil)
    return;
  [_input->textView.textStorage beginEditing];
  [_input->textView.textStorage addAttributes:@{
    NSForegroundColorAttributeName : color,
    NSUnderlineColorAttributeName : color,
    NSStrikethroughColorAttributeName : color
  }
                                        range:range];
  [_input->textView.textStorage endEditing];
  _color = color;
}

- (void)addTypingAttributes {
}

- (void)addTypingAttributes:(UIColor *)color {
  NSMutableDictionary *newTypingAttrs =
      [_input->textView.typingAttributes mutableCopy];
  newTypingAttrs[NSForegroundColorAttributeName] = color;
  newTypingAttrs[NSUnderlineColorAttributeName] = color;
  newTypingAttrs[NSStrikethroughColorAttributeName] = color;
  _input->textView.typingAttributes = newTypingAttrs;
}

#pragma mark - Remove attributes

- (void)removeAttributesFromAttributedString:(NSMutableAttributedString *)string
                                       range:(NSRange)range {
  NSUInteger max = MIN(NSMaxRange(range), string.length);
  for (NSUInteger i = range.location; i < max; i++) {
    UIColor *restoreColor = [self originalColorAtIndex:i];
    NSDictionary *newAttributes = @{
      NSForegroundColorAttributeName : restoreColor,
      NSUnderlineColorAttributeName : restoreColor,
      NSStrikethroughColorAttributeName : restoreColor,
    };
    [string addAttributes:newAttributes range:NSMakeRange(i, 1)];
  }
}

- (void)removeAttributes:(NSRange)range {
  NSTextStorage *textStorage = _input->textView.textStorage;
  if (range.length == 0)
    return;

  NSUInteger len = textStorage.length;
  if (range.location >= len)
    return;

  NSUInteger max = MIN(NSMaxRange(range), len);

  [textStorage beginEditing];

  [self removeAttributesFromAttributedString:textStorage range:range];

  [textStorage endEditing];
}

- (void)addAttributesInAttributedString:
            (NSMutableAttributedString *)attributedString
                                  range:(NSRange)range
                             attributes:(NSDictionary<NSString *, NSString *>
                                             *_Nullable)attributes {
  if (range.length == 0)
    return;

  NSString *colorAttribute =
      attributes.count > 0 ? attributes[ColorAttributeName] : nil;

  UIColor *color = nil;
  if (!colorAttribute) {
    return;
  }

  color = [UIColor colorFromString:(NSString *)colorAttribute];

  if (!color)
    return;

  [attributedString addAttributes:@{
    NSForegroundColorAttributeName : color,
    NSUnderlineColorAttributeName : color,
    NSStrikethroughColorAttributeName : color
  }
                            range:range];
}

- (void)removeTypingAttributes {
  NSMutableDictionary *newTypingAttrs =
      [_input->textView.typingAttributes mutableCopy];
  NSRange selectedRange = _input->textView.selectedRange;
  NSUInteger location = selectedRange.location;

  UIColor *baseColor = [self originalColorAtIndex:location];

  newTypingAttrs[NSForegroundColorAttributeName] = baseColor;
  newTypingAttrs[NSUnderlineColorAttributeName] = baseColor;
  newTypingAttrs[NSStrikethroughColorAttributeName] = baseColor;
  _input->textView.typingAttributes = newTypingAttrs;
}

#pragma mark - Main detection entry
- (BOOL)styleConditionWithAttributes:(NSDictionary *)attrs
                               range:(NSRange)range {
  UIColor *color = attrs[NSForegroundColorAttributeName];
  if (!color)
    return NO;

  if ([color isEqualToColor:_input->config.primaryColor])
    return NO;

  return ![self isColorOwnedByOtherStyle:color attributes:attrs range:range];
}

- (BOOL)styleCondition:(id)value range:(NSRange)range {
  if (!value)
    return NO;

  NSTextStorage *ts = _input->textView.textStorage;
  NSUInteger len = ts.length;

  NSDictionary *attrs;
  if (range.length == 0 || range.location >= len) {
    attrs = _input->textView.typingAttributes;
  } else {
    NSUInteger loc = MIN(range.location, len - 1);
    attrs = [ts attributesAtIndex:loc effectiveRange:nil];
  }

  return [self styleConditionWithAttributes:attrs range:range];
}

- (BOOL)detectStyle:(NSRange)range {
  if (range.length >= 1) {
    return [OccurenceUtils detect:NSForegroundColorAttributeName
                        withInput:_input
                          inRange:range
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value range:range];
                    }];
  } else {
    id value =
        _input->textView.typingAttributes[NSForegroundColorAttributeName];
    return [self styleCondition:value range:range];
  }
}

- (BOOL)detectStyle:(NSRange)range color:(UIColor *)color {
  if (range.length >= 1) {
    return [OccurenceUtils detect:NSForegroundColorAttributeName
                        withInput:_input
                          inRange:range
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [(UIColor *)value isEqualToColor:color] &&
                             [self styleCondition:value range:range];
                    }];
  } else {
    return [OccurenceUtils detect:NSForegroundColorAttributeName
                        withInput:_input
                          atIndex:range.location
                    checkPrevious:NO
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [(UIColor *)value isEqualToColor:color] &&
                             [self styleCondition:value range:range];
                    }];
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:NSForegroundColorAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value range:range];
               }];
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:NSForegroundColorAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value range:range];
               }];
}

- (void)addAttributes:(NSRange)range {
  // no-op
}

- (UIColor *)getColorAt:(NSUInteger)location {
  NSRange effectiveRange = NSMakeRange(0, 0);
  NSRange inputRange = NSMakeRange(0, _input->textView.textStorage.length);

  if (location == _input->textView.textStorage.length) {
    UIColor *typingColor =
        _input->textView.typingAttributes[NSForegroundColorAttributeName];
    return typingColor ?: [_input->config primaryColor];
  }

  return [_input->textView.textStorage attribute:NSForegroundColorAttributeName
                                         atIndex:location
                           longestEffectiveRange:&effectiveRange
                                         inRange:inputRange];
}

- (UIColor *)getColorInRange:(NSRange)range {
  NSUInteger location = range.location;
  NSUInteger length = range.length;

  NSRange effectiveRange = NSMakeRange(0, 0);
  NSRange inputRange = NSMakeRange(0, _input->textView.textStorage.length);

  if (location == _input->textView.textStorage.length) {
    UIColor *typingColor =
        _input->textView.typingAttributes[NSForegroundColorAttributeName];
    return typingColor ?: [_input->config primaryColor];
  }

  NSUInteger queryLocation = location;
  if (length == 0 && location > 0) {
    queryLocation = location - 1;
  }

  UIColor *color =
      [_input->textView.textStorage attribute:NSForegroundColorAttributeName
                                      atIndex:queryLocation
                        longestEffectiveRange:&effectiveRange
                                      inRange:inputRange];

  return color;
}

- (UIColor *)naturalColorForAttributes:(NSDictionary *)attrs
                                 index:(NSUInteger)index {
  for (NSNumber *num in self.coloredStyleTypes) {
    UIColor *color = [self colorForStyle:(StyleType)num.integerValue
                              attributes:attrs
                                   index:index];
    if (color) {
      return color;
    }
  }

  return _input->config.primaryColor;
}

- (UIColor *)originalColorAtIndex:(NSUInteger)index {
  NSTextStorage *ts = _input->textView.textStorage;
  NSUInteger len = ts.length;

  if (len == 0)
    return _input->config.primaryColor;

  if (index >= len)
    index = len - 1;

  NSDictionary *attrs = [ts attributesAtIndex:index effectiveRange:nil];

  return [self naturalColorForAttributes:attrs index:index];
}

- (void)removeColorInSelectedRange {
  NSRange selectedRange = _input->textView.selectedRange;

  if (selectedRange.length > 0) {
    [self removeAttributes:selectedRange];
  } else {
    [self removeTypingAttributes];
  }
}

- (BOOL)isColorOwnedByOtherStyle:(UIColor *)color
                      attributes:(NSDictionary *)attrs
                           range:(NSRange)range {
  NSUInteger index = range.location;

  for (NSNumber *num in self.coloredStyleTypes) {
    StyleType type = (StyleType)num.integerValue;
    UIColor *styleColor = [self colorForStyle:type
                                   attributes:attrs
                                        index:index];

    if (styleColor && [styleColor isEqual:color]) {
      return YES;
    }
  }

  return NO;
}

- (UIColor *)colorForStyle:(StyleType)type
                attributes:(NSDictionary *)attrs
                     index:(NSUInteger)index {
  id<BaseStyleProtocol> style = _input->stylesDict[@(type)];
  if (!style)
    return nil;

  NSAttributedStringKey key = [style.class attributeKey];
  id attr = attrs[key];
  if (!attr || ![style styleCondition:attr range:NSRange(index, 0)])
    return nil;

  InputConfig *config = _input->config;

  switch (type) {
  case Link:
    return config.linkColor;

  case InlineCode:
    return config.inlineCodeFgColor;

  case BlockQuote:
    return config.blockquoteColor;

  case CodeBlock:
    return config.codeBlockFgColor;

  case Mention: {
    MentionParams *params = (MentionParams *)attr;
    if (!params)
      return nil;

    MentionStyleProps *props = [config mentionStylePropsForType:params.type];
    return props.color;
  }

  default:
    return nil;
  }
}

@end
