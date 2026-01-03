#import "EnrichedParagraphStyle.h"
#import "EnrichedTextInputView.h"
#import "FontExtension.h"
#import "OccurenceUtils.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"

@implementation HeadingStyleBase

// mock values since H1/2/3/4/5/6Style classes anyway are used
+ (StyleType)getStyleType {
  return None;
}
- (CGFloat)getHeadingFontSize {
  return 0;
}

- (NSNumber *_Nullable)headingLevel {
  return nil;
}

- (BOOL)isHeadingBold {
  return false;
}

+ (const char *)subTagName {
  return nil;
}

+ (NSAttributedStringKey)attributeKey {
  return NSParagraphStyleAttributeName;
}

+ (BOOL)isSelfClosing {
  return NO;
}

- (EnrichedTextInputView *)typedInput {
  return (EnrichedTextInputView *)input;
}

- (instancetype)initWithInput:(id)input {
  self = [super init];
  self->input = input;
  return self;
}

// the range will already be the full paragraph/s range
// but if the paragraph is empty it still is of length 0
- (void)applyStyle:(NSRange)range {
  BOOL isStylePresent = [self detectStyle:range];
  if (range.length >= 1) {
    isStylePresent ? [self removeAttributes:range] : [self addAttributes:range];
  } else {
    isStylePresent ? [self removeTypingAttributes] : [self addTypingAttributes];
  }
}

// the range will already be the proper full paragraph/s range
- (void)addAttributes:(NSRange)range {
  [self addAttributes:range withTypingAttributes:YES];
}

- (void)addAttributes:(NSRange)range
    withTypingAttributes:(BOOL)withTypingAttributes {
  [[self typedInput]->textView.textStorage beginEditing];
  [self addAttributesInAttributedString:[self typedInput]->textView.textStorage
                                  range:range
                             attributes:nullptr];
  [[self typedInput]->textView.textStorage endEditing];
  if (withTypingAttributes) {
    // also toggle typing attributes
    [self addTypingAttributes];
  }
}

- (void)addAttributesInAttributedString:
            (NSMutableAttributedString *)attributedString
                                  range:(NSRange)range
                             attributes:(NSDictionary<NSString *, NSString *>
                                             *_Nullable)attributes {
  auto fontSize = [self getHeadingFontSize];
  BOOL isHeadingBold = [self isHeadingBold];
  auto paragraphStyle = [[EnrichedParagraphStyle alloc] init];
  paragraphStyle.headingLevel = [self headingLevel];
  [attributedString addAttribute:NSParagraphStyleAttributeName
                           value:paragraphStyle
                           range:range];
  [attributedString enumerateAttribute:NSFontAttributeName
                               inRange:range
                               options:0
                            usingBlock:^(id _Nullable value, NSRange range,
                                         BOOL *_Nonnull stop) {
                              UIFont *font = (UIFont *)value;
                              if (font != nullptr) {
                                UIFont *newFont = [font setSize:fontSize];
                                if (isHeadingBold) {
                                  newFont = [newFont setBold];
                                }
                                [attributedString
                                    addAttribute:NSFontAttributeName
                                           value:newFont
                                           range:range];
                              }
                            }];
}

// will always be called on empty paragraphs so only typing attributes can be
// changed
- (void)addTypingAttributes {
  UIFont *currentFontAttr =
      (UIFont *)[self typedInput]
          ->textView.typingAttributes[NSFontAttributeName];
  if (currentFontAttr != nullptr) {
    NSMutableDictionary *newTypingAttrs =
        [[self typedInput]->textView.typingAttributes mutableCopy];
    UIFont *newFont = [currentFontAttr setSize:[self getHeadingFontSize]];
    if ([self isHeadingBold]) {
      newFont = [newFont setBold];
    }
    EnrichedParagraphStyle *newParagraphStyle =
        [newTypingAttrs[NSParagraphStyleAttributeName] mutableCopy];
    newParagraphStyle.headingLevel = [self headingLevel];
    newTypingAttrs[NSFontAttributeName] = newFont;
    newTypingAttrs[NSParagraphStyleAttributeName] = newParagraphStyle;
    [self typedInput]->textView.typingAttributes = newTypingAttrs;
  }
}

- (EnrichedParagraphStyle *)paragraphStyleForRange:(NSRange)range {
  NSTextStorage *ts = [self typedInput]->textView.textStorage;

  NSRange paragraphRange = [ts.string paragraphRangeForRange:range];

  NSParagraphStyle *current = [ts attribute:NSParagraphStyleAttributeName
                                    atIndex:paragraphRange.location
                             effectiveRange:nil];

  EnrichedParagraphStyle *style;

  if ([current isKindOfClass:[EnrichedParagraphStyle class]]) {
    style = [(EnrichedParagraphStyle *)current mutableCopy];
  } else {
    style = [[EnrichedParagraphStyle alloc] init];
    if (current) {
      [style setParagraphStyle:current];
    }
  }

  return style;
}

// we need to remove the style from the whole paragraph
- (void)removeAttributes:(NSRange)range {

  UITextView *textView = self.typedInput->textView;
  NSTextStorage *textStorage = textView.textStorage;

  NSRange paragraphRange = [textStorage.string paragraphRangeForRange:range];

  EnrichedParagraphStyle *paragraphStyle =
      [textStorage attribute:NSParagraphStyleAttributeName
                     atIndex:paragraphRange.location
              effectiveRange:nil];

  EnrichedParagraphStyle *newParagraphStyle = [paragraphStyle mutableCopy];
  newParagraphStyle.headingLevel = 0;

  [textStorage beginEditing];

  [textStorage addAttribute:NSParagraphStyleAttributeName
                      value:newParagraphStyle
                      range:range];

  [textStorage
      enumerateAttribute:NSFontAttributeName
                 inRange:paragraphRange
                 options:0
              usingBlock:^(id value, NSRange attributeRange, BOOL *stop) {
                if (!value) {
                  return;
                }

                UIFont *newFont = [(UIFont *)value
                    setSize:self.typedInput->config.primaryFontSize.floatValue];

                if ([self isHeadingBold]) {
                  newFont = [newFont removeBold];
                }

                [textStorage addAttribute:NSFontAttributeName
                                    value:newFont
                                    range:attributeRange];
              }];

  [textStorage endEditing];
  NSMutableDictionary *typingAttributes =
      [textView.typingAttributes mutableCopy];

  UIFont *currentFont = typingAttributes[NSFontAttributeName];
  UIFont *newFont =
      [currentFont setSize:self.typedInput->config.primaryFontSize.floatValue];

  if ([self isHeadingBold]) {
    newFont = [newFont removeBold];
  }
  typingAttributes[NSFontAttributeName] = newFont;
  typingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle;

  textView.typingAttributes = typingAttributes;
}

- (void)removeTypingAttributes {
  UITextView *textView = [self typedInput]->textView;
  NSMutableDictionary *typingAttributes =
      [textView.typingAttributes mutableCopy];
  EnrichedParagraphStyle *newParagraphStyle =
      [typingAttributes[NSParagraphStyleAttributeName] mutableCopy];

  newParagraphStyle.headingLevel = @(0);
  UIFont *currentFont = typingAttributes[NSFontAttributeName];
  UIFont *newFont =
      [currentFont setSize:self.typedInput->config.primaryFontSize.floatValue];

  if ([self isHeadingBold]) {
    newFont = [newFont removeBold];
  }
  typingAttributes[NSFontAttributeName] = newFont;
  typingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle;

  textView.typingAttributes = typingAttributes;
}

- (BOOL)styleCondition:(id _Nullable)value range:(NSRange)range {
  EnrichedParagraphStyle *paragprahStyle = (EnrichedParagraphStyle *)value;
  return paragprahStyle != nullptr &&
         paragprahStyle.headingLevel == [self headingLevel];
}

- (BOOL)detectStyle:(NSRange)range {
  if (range.length >= 1) {
    return [OccurenceUtils detect:NSParagraphStyleAttributeName
                        withInput:input
                          inRange:range
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value range:range];
                    }];
  } else {
    return [OccurenceUtils detect:NSParagraphStyleAttributeName
                        withInput:[self typedInput]
                          atIndex:range.location
                    checkPrevious:YES
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value range:range];
                    }];
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:NSParagraphStyleAttributeName
                   withInput:[self typedInput]
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value range:range];
               }];
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:NSParagraphStyleAttributeName
                   withInput:[self typedInput]
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value range:range];
               }];
}

// used to make sure headings dont persist after a newline is placed
- (BOOL)handleNewlinesInRange:(NSRange)range replacementText:(NSString *)text {
  EnrichedTextInputView *input = [self typedInput];
  UITextView *textView = input->textView;
  // in a heading and a new text ends with a newline
  if ([self detectStyle:textView.selectedRange] && text.length > 0 &&
      [[NSCharacterSet newlineCharacterSet]
          characterIsMember:[text characterAtIndex:text.length - 1]]) {
    // do the replacement manually
    [TextInsertionUtils replaceText:text
                                 at:range
               additionalAttributes:input->defaultTypingAttributes
                              input:[self typedInput]
                      withSelection:YES];
    // remove the attribtues at the new selection
    [self removeTypingAttributes];
    return YES;
  }
  return NO;
}

// backspacing a line after a heading "into" a heading will not result in the
// text attaining heading attributes so, we do it manually
- (void)handleImproperHeadings {

  UITextView *textView = [self typedInput]->textView;
  NSTextStorage *textStorage = textView.textStorage;
  NSString *string = textStorage.string;

  NSRange fullRange = NSMakeRange(0, string.length);

  [string
      enumerateSubstringsInRange:fullRange
                         options:NSStringEnumerationByParagraphs |
                                 NSStringEnumerationSubstringNotRequired
                      usingBlock:^(__unused NSString *substr,
                                   NSRange paragraphRange,
                                   __unused NSRange enclosingRange,
                                   __unused BOOL *stop) {
                        if (paragraphRange.length == 0)
                          return;

                        NSParagraphStyle *paragraphStyle =
                            [textStorage attribute:NSParagraphStyleAttributeName
                                           atIndex:paragraphRange.location
                                    effectiveRange:nil];

                        if (![paragraphStyle
                                isKindOfClass:[EnrichedParagraphStyle class]])
                          return;

                        NSNumber *current =
                            ((EnrichedParagraphStyle *)paragraphStyle)
                                .headingLevel;
                        NSNumber *target = [self headingLevel];
                        if (current == nil || target == nil ||
                            ![current isEqual:target])
                          return;

                        [self addAttributes:paragraphRange
                            withTypingAttributes:NO];
                      }];
}

@end
