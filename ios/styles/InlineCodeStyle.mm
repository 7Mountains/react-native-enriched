#import "ColorExtension.h"
#import "EnrichedTextInputView.h"
#import "FontExtension.h"
#import "OccurenceUtils.h"
#import "ParagraphsUtils.h"
#import "StyleHeaders.h"

@implementation InlineCodeStyle {
  EnrichedTextInputView *_input;
}

+ (StyleType)getStyleType {
  return InlineCode;
}

+ (BOOL)isParagraphStyle {
  return NO;
}

+ (const char *)tagName {
  return "code";
}

+ (const char *)subTagName {
  return nil;
}

+ (NSAttributedStringKey)attributeKey {
  return NSBackgroundColorAttributeName;
}

+ (BOOL)isSelfClosing {
  return NO;
}

- (instancetype)initWithInput:(id)input {
  self = [super init];
  _input = (EnrichedTextInputView *)input;
  return self;
}

- (void)applyStyle:(NSRange)range {
  BOOL isStylePresent = [self detectStyle:range];
  if (range.length >= 1) {
    isStylePresent ? [self removeAttributes:range] : [self addAttributes:range];
  } else {
    isStylePresent ? [self removeTypingAttributes] : [self addTypingAttributes];
  }
}

- (void)addAttributesInAttributedString:
            (NSMutableAttributedString *)attributedString
                                  range:(NSRange)range
                             attributes:(NSDictionary<NSString *, NSString *>
                                             *_Nullable)attributes {
  [attributedString addAttribute:NSBackgroundColorAttributeName
                           value:[[_input->config inlineCodeBgColor]
                                     colorWithAlphaIfNotTransparent:0.4]
                           range:range];
  [attributedString addAttribute:NSForegroundColorAttributeName
                           value:[_input->config inlineCodeFgColor]
                           range:range];
  [attributedString addAttribute:NSUnderlineColorAttributeName
                           value:[_input->config inlineCodeFgColor]
                           range:range];
  [attributedString addAttribute:NSStrikethroughColorAttributeName
                           value:[_input->config inlineCodeFgColor]
                           range:range];
  UIFont *font = [_input->config monospacedFont];
  [attributedString addAttribute:NSFontAttributeName value:font range:range];
}

- (void)addAttributes:(NSRange)range {
  // we don't want to apply inline code to newline characters, it looks bad
  NSArray *nonNewlineRanges =
      [ParagraphsUtils getNonNewlineRangesIn:_input->textView range:range];

  for (NSValue *value in nonNewlineRanges) {
    NSRange currentRange = [value rangeValue];
    [_input->textView.textStorage beginEditing];
    [self addAttributesInAttributedString:_input->textView.textStorage
                                    range:currentRange
                               attributes:nullptr];
    [_input->textView.textStorage endEditing];
  }
}

- (void)addTypingAttributes {
  NSMutableDictionary *newTypingAttrs =
      [_input->textView.typingAttributes mutableCopy];
  newTypingAttrs[NSBackgroundColorAttributeName] =
      [[_input->config inlineCodeBgColor] colorWithAlphaIfNotTransparent:0.4];
  newTypingAttrs[NSForegroundColorAttributeName] =
      [_input->config inlineCodeFgColor];
  newTypingAttrs[NSUnderlineColorAttributeName] =
      [_input->config inlineCodeFgColor];
  newTypingAttrs[NSStrikethroughColorAttributeName] =
      [_input->config inlineCodeFgColor];
  UIFont *currentFont = (UIFont *)newTypingAttrs[NSFontAttributeName];
  if (currentFont != nullptr) {
    newTypingAttrs[NSFontAttributeName] = [[[_input->config monospacedFont]
        withFontTraits:currentFont] setSize:currentFont.pointSize];
  }
  _input->textView.typingAttributes = newTypingAttrs;
}

- (void)removeAttributes:(NSRange)range {
  [_input->textView.textStorage beginEditing];

  [_input->textView.textStorage removeAttribute:NSBackgroundColorAttributeName
                                          range:range];
  [_input->textView.textStorage addAttribute:NSForegroundColorAttributeName
                                       value:[_input->config primaryColor]
                                       range:range];
  [_input->textView.textStorage addAttribute:NSUnderlineColorAttributeName
                                       value:[_input->config primaryColor]
                                       range:range];
  [_input->textView.textStorage addAttribute:NSStrikethroughColorAttributeName
                                       value:[_input->config primaryColor]
                                       range:range];
  [_input->textView.textStorage
      enumerateAttribute:NSFontAttributeName
                 inRange:range
                 options:0
              usingBlock:^(id _Nullable value, NSRange range,
                           BOOL *_Nonnull stop) {
                UIFont *font = (UIFont *)value;
                if (font != nullptr) {
                  UIFont *newFont = [[[_input->config primaryFont]
                      withFontTraits:font] setSize:font.pointSize];
                  [_input->textView.textStorage addAttribute:NSFontAttributeName
                                                       value:newFont
                                                       range:range];
                }
              }];

  [_input->textView.textStorage endEditing];
}

- (void)removeTypingAttributes {
  NSMutableDictionary *newTypingAttrs =
      [_input->textView.typingAttributes mutableCopy];
  [newTypingAttrs removeObjectForKey:NSBackgroundColorAttributeName];
  newTypingAttrs[NSForegroundColorAttributeName] =
      [_input->config primaryColor];
  newTypingAttrs[NSUnderlineColorAttributeName] = [_input->config primaryColor];
  newTypingAttrs[NSStrikethroughColorAttributeName] =
      [_input->config primaryColor];
  UIFont *currentFont = (UIFont *)newTypingAttrs[NSFontAttributeName];
  if (currentFont != nullptr) {
    newTypingAttrs[NSFontAttributeName] = [[[_input->config primaryFont]
        withFontTraits:currentFont] setSize:currentFont.pointSize];
  }
  _input->textView.typingAttributes = newTypingAttrs;
}

// making sure no newlines get inline code style, it looks bad
- (void)handleNewlines {
  NSTextStorage *storage = _input->textView.textStorage;
  NSString *string = storage.string;

  [string
      enumerateSubstringsInRange:NSMakeRange(0, string.length)
                         options:NSStringEnumerationByLines
                      usingBlock:^(
                          NSString *_Nullable substring, NSRange substringRange,
                          NSRange enclosingRange, BOOL *_Nonnull stop) {
                        NSRange newlineRange =
                            NSMakeRange(NSMaxRange(enclosingRange) - 1, 1);

                        if (newlineRange.location >= string.length)
                          return;

                        unichar ch =
                            [string characterAtIndex:newlineRange.location];
                        if (![[NSCharacterSet newlineCharacterSet]
                                characterIsMember:ch])
                          return;

                        UIColor *bgColor =
                            [storage attribute:NSBackgroundColorAttributeName
                                       atIndex:newlineRange.location
                                effectiveRange:nil];

                        if ([self styleCondition:bgColor range:newlineRange]) {
                          [self removeAttributes:newlineRange];
                        }
                      }];
}

- (BOOL)styleConditionWithAttributes:(NSDictionary *)attrs
                               range:(NSRange)range {
  UIColor *bgColor = attrs[NSBackgroundColorAttributeName];
  if (!bgColor) {
    return NO;
  }

  MentionStyle *mStyle =
      (MentionStyle *)_input->stylesDict[@([MentionStyle getStyleType])];
  id mentionAttribute = attrs [[mStyle.class attributeKey]];
  return ![mStyle styleCondition:mentionAttribute range:range];
}

// emojis don't retain monospace font attribute so we check for the background
// color if there is no mention
- (BOOL)styleCondition:(id _Nullable)value range:(NSRange)range {
  UIColor *bgColor = (UIColor *)value;
  MentionStyle *mStyle =
      (MentionStyle *)_input->stylesDict[@([MentionStyle getStyleType])];
  return bgColor != nullptr && mStyle != nullptr && ![mStyle detectStyle:range];
}

- (BOOL)detectStyle:(NSRange)range {
  if (range.length >= 1) {
    NSArray *nonNewlineRanges =
        [ParagraphsUtils getNonNewlineRangesIn:_input->textView range:range];
    if (nonNewlineRanges.count == 0) {
      return NO;
    }

    BOOL detected = YES;
    for (NSValue *value in nonNewlineRanges) {
      NSRange currentRange = [value rangeValue];
      BOOL currentDetected =
          [OccurenceUtils detect:NSBackgroundColorAttributeName
                       withInput:_input
                         inRange:currentRange
                   withCondition:^BOOL(id _Nullable value, NSRange range) {
                     return [self styleCondition:value range:range];
                   }];
      detected = detected && currentDetected;
    }

    return detected;
  } else {
    return [OccurenceUtils detect:NSBackgroundColorAttributeName
                        withInput:_input
                          atIndex:range.location
                    checkPrevious:NO
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value range:range];
                    }];
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:NSBackgroundColorAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value range:range];
               }];
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:NSBackgroundColorAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value range:range];
               }];
}

@end
