#import "ColorExtension.h"
#import "EnrichedTextInputView.h"
#import "FontExtension.h"
#import "OccurenceUtils.h"
#import "StyleHeaders.h"
#import "StyleTypeEnum.h"

@implementation ColorStyle {
  EnrichedTextInputView *_input;
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
    @"color" : [color hexString],
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

- (void)removeAttributes:(NSRange)range {
  NSTextStorage *ts = _input->textView.textStorage;
  if (range.length == 0)
    return;

  NSUInteger len = ts.length;
  if (range.location >= len)
    return;

  NSUInteger max = MIN(NSMaxRange(range), len);

  [ts beginEditing];

  for (NSUInteger i = range.location; i < max; i++) {
    UIColor *restoreColor = [self originalColorAtIndex:i];

    [ts addAttribute:NSForegroundColorAttributeName
               value:restoreColor
               range:NSMakeRange(i, 1)];

    [ts addAttribute:NSUnderlineColorAttributeName
               value:restoreColor
               range:NSMakeRange(i, 1)];

    [ts addAttribute:NSStrikethroughColorAttributeName
               value:restoreColor
               range:NSMakeRange(i, 1)];
  }

  [ts endEditing];
}

#pragma mark - Add Attributes (HTML → AttributedString)

- (void)addAttributesInAttributedString:
            (NSMutableAttributedString *)attributedString
                                  range:(NSRange)range
                             attributes:(NSDictionary<NSString *, NSString *>
                                             *_Nullable)attributes {
  if (range.length == 0)
    return;

  NSString *colorAttribute = attributes[@"color"] ?: @"";

  UIColor *color = nil;
  if ([colorAttribute isKindOfClass:[NSString class]]) {
    color = [UIColor colorFromString:(NSString *)colorAttribute];
  }

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

#pragma mark - Detection

+ (BOOL)isInLink:(NSDictionary *)attrs
       sameColor:(UIColor *)color
           input:(EnrichedTextInputView *)input {
  id<BaseStyleProtocol> link = input->stylesDict[@(Link)];
  NSAttributedStringKey key = [[link class] attributeKey];
  return attrs[key] && [color isEqual:input->config.linkColor];
}

+ (BOOL)isInInlineCode:(NSDictionary *)attrs
             sameColor:(UIColor *)color
                 input:(EnrichedTextInputView *)input {
  id<BaseStyleProtocol> inlineCode = input->stylesDict[@(InlineCode)];
  NSAttributedStringKey key = [[inlineCode class] attributeKey];
  return attrs[key] && [color isEqual:input->config.inlineCodeFgColor];
}

+ (BOOL)isInBlockQuote:(NSDictionary *)attrs
             sameColor:(UIColor *)color
                 input:(EnrichedTextInputView *)input {
  id<BaseStyleProtocol> bq = input->stylesDict[@(BlockQuote)];
  NSAttributedStringKey key = [[bq class] attributeKey];
  return attrs[key] && [color isEqual:input->config.blockquoteColor];
}

+ (BOOL)isInMention:(NSDictionary *)attrs
           location:(NSUInteger)loc
          sameColor:(UIColor *)color
              input:(EnrichedTextInputView *)input {
  id<BaseStyleProtocol> mention = input->stylesDict[@(Mention)];
  NSAttributedStringKey key = [[mention class] attributeKey];
  if (!attrs[key])
    return NO;

  MentionStyle *mentionStyle = (MentionStyle *)mention;
  MentionParams *params = [mentionStyle getMentionParamsAt:loc];
  if (!params)
    return NO;

  MentionStyleProps *props =
      [input->config mentionStylePropsForIndicator:params.indicator];

  return [color isEqual:props.color];
}

+ (BOOL)isInCodeBlock:(NSDictionary *)attrs
            sameColor:(UIColor *)color
                input:(EnrichedTextInputView *)input {
  id<BaseStyleProtocol> code = input->stylesDict[@(CodeBlock)];
  NSAttributedStringKey key = [[code class] attributeKey];
  return attrs[key] && [color isEqual:input->config.codeBlockFgColor];
}

#pragma mark - Main detection entry

- (BOOL)styleCondition:(id _Nullable)value range:(NSRange)range {
  if (!value)
    return NO;

  UIColor *color = (UIColor *)value;

  if ([color isEqual:_input->config.primaryColor])
    return NO;

  NSTextStorage *ts = _input->textView.textStorage;
  NSUInteger len = ts.length;

  BOOL useTypingAttributes =
      (range.length == 0) || (range.location == 0) || (range.location >= len);

  NSDictionary *attrs = nil;

  NSUInteger loc = range.location;
  if (loc >= len && len > 0)
    loc = len - 1;

  if (useTypingAttributes) {
    attrs = _input->textView.typingAttributes;
  } else {
    attrs = [ts attributesAtIndex:loc effectiveRange:nil];
  }

  if ([ColorStyle isInLink:attrs sameColor:color input:_input])
    return NO;
  if ([ColorStyle isInInlineCode:attrs sameColor:color input:_input])
    return NO;
  if ([ColorStyle isInBlockQuote:attrs sameColor:color input:_input])
    return NO;

  if ([ColorStyle isInMention:attrs location:loc sameColor:color input:_input])
    return NO;

  if ([ColorStyle isInCodeBlock:attrs sameColor:color input:_input])
    return NO;

  return YES;
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

- (BOOL)detectExcludingColor:(UIColor *)excludedColor inRange:(NSRange)range {
  if (![self detectStyle:range]) {
    return NO;
  }
  UIColor *currentColor = [self getColorInRange:range];
  return currentColor != nil && ![currentColor isEqualToColor:excludedColor];
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

- (UIColor *)originalColorAtIndex:(NSUInteger)index {
  NSTextStorage *ts = _input->textView.textStorage;
  NSUInteger len = ts.length;

  if (len == 0)
    return _input->config.primaryColor;

  if (index >= len)
    index = len - 1;

  NSDictionary *attrs = [ts attributesAtIndex:index effectiveRange:nil];

  UIColor *color = attrs[NSForegroundColorAttributeName];

  if (!color)
    return _input->config.primaryColor;

  if ([ColorStyle isInLink:attrs sameColor:color input:_input])
    return _input->config.linkColor;

  if ([ColorStyle isInInlineCode:attrs sameColor:color input:_input])
    return _input->config.inlineCodeFgColor;

  if ([ColorStyle isInBlockQuote:attrs sameColor:color input:_input])
    return _input->config.blockquoteColor;

  if ([ColorStyle isInMention:attrs
                     location:index
                    sameColor:color
                        input:_input]) {
    MentionStyle *mention = (MentionStyle *)_input->stylesDict[@(Mention)];
    MentionParams *p = [mention getMentionParamsAt:index];
    if (p) {
      MentionStyleProps *props =
          [_input->config mentionStylePropsForIndicator:p.indicator];
      return props.color;
    }
  }

  return _input->config.primaryColor;
}

- (void)removeColorInSelectedRange {
  NSRange selectedRange = _input->textView.selectedRange;

  if (selectedRange.length > 0) {
    [self removeAttributes:selectedRange];
  } else {
    [self removeTypingAttributes];
  }
}

@end
