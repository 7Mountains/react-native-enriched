//
//  ListStyleBase.m
//  Pods
//
//  Created by Ivan Ignathuk on 14/05/2026.
//

#import "OccurenceUtils.h"
#import "ParagraphsUtils.h"
#import "Strings.h"
#import "StyleConstants.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"

@implementation ListStyleBase

+ (StyleType)getStyleType {
  NSAssert(NO, @"Subclasses must override getStyleType");
  return None;
}

+ (BOOL)isParagraphStyle {
  return YES;
}

+ (const char *)tagName {
  NSAssert(NO, @"Subclasses must override tagName");
  return "";
}

+ (const char *)subTagName {
  return "li";
}

+ (BOOL)isSelfClosing {
  return NO;
}

+ (NSAttributedStringKey)attributeKey {
  return NSParagraphStyleAttributeName;
}

+ (NSArray<NSTextList *> *)textLists {
  NSAssert(NO, @"Subclasses must override textLists");
  return @[];
}

+ (NSString *)shortcut {
  NSAssert(NO, @"Subclasses must override shortcut");
  return @"";
}

+ (unichar)shortcutPrefix {
  NSAssert(NO, @"Subclasses must override shortcutPrefix");
  return 0;
}

- (instancetype)initWithInput:(id)input {
  self = [super init];
  if (self) {
    _input = (EnrichedTextInputView *)input;
  }
  return self;
}

- (CGFloat)getHeadIndent {
  NSAssert(NO, @"Subclasses must override getHeadIndent");
  return 0;
}

- (NSParagraphStyle *)prepareAttributes {
  CGFloat headIntent = [self getHeadIndent];

  if (_cachedHeadIntent == headIntent && _cachedAttributes) {
    return _cachedAttributes;
  }

  _cachedHeadIntent = headIntent;

  NSMutableParagraphStyle *pStyle =
      [_input->defaultTypingAttributes[NSParagraphStyleAttributeName]
          mutableCopy];

  pStyle.textLists = [[self class] textLists];
  pStyle.headIndent = headIntent;
  pStyle.firstLineHeadIndent = headIntent;
  pStyle.minimumLineHeight = 0;
  pStyle.tailIndent = DefaultListTailIndent;
  pStyle.paragraphSpacing = 0;
  pStyle.paragraphSpacingBefore = 0;

  _cachedAttributes = pStyle;
  return _cachedAttributes;
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
  [attributedString addAttribute:NSParagraphStyleAttributeName
                           value:[self prepareAttributes]
                           range:range];
}

- (void)addAttributes:(NSRange)range {
  UITextView *textView = _input->textView;

  NSArray *paragraphs = [ParagraphsUtils getSeparateParagraphsRangesIn:textView
                                                                 range:range];

  NSInteger offset = 0;
  NSRange preModificationRange = textView.selectedRange;

  _input->blockEmitting = YES;

  for (NSValue *value in paragraphs) {
    NSRange rangeValue = value.rangeValue;
    NSRange fixedRange =
        NSMakeRange(rangeValue.location + offset, rangeValue.length);

    BOOL isEmptyParagraph =
        fixedRange.length == 0 ||
        (fixedRange.length == 1 &&
         [[NSCharacterSet newlineCharacterSet]
             characterIsMember:[textView.textStorage.string
                                   characterAtIndex:fixedRange.location]]);

    if (isEmptyParagraph) {
      [TextInsertionUtils insertText:ZWS
                                  at:fixedRange.location
                additionalAttributes:nullptr
                               input:_input
                       withSelection:NO];

      fixedRange = NSMakeRange(fixedRange.location, fixedRange.length + 1);
      offset += 1;
    }

    [textView.textStorage
        enumerateAttribute:NSParagraphStyleAttributeName
                   inRange:fixedRange
                   options:0
                usingBlock:^(id _Nullable value, NSRange range,
                             BOOL *_Nonnull stop) {
                  NSMutableParagraphStyle *pStyle =
                      [[self prepareAttributes] mutableCopy];

                  pStyle.alignment = value != nil
                                         ? ((NSParagraphStyle *)value).alignment
                                         : NSTextAlignmentNatural;

                  [textView.textStorage
                      addAttribute:NSParagraphStyleAttributeName
                             value:pStyle
                             range:range];
                }];
  }

  _input->blockEmitting = NO;

  if (preModificationRange.length == 0) {
    textView.selectedRange = preModificationRange;
  } else {
    textView.selectedRange = NSMakeRange(preModificationRange.location,
                                         preModificationRange.length + offset);
  }

  NSMutableDictionary *typingAttrs = [textView.typingAttributes mutableCopy];
  NSMutableParagraphStyle *pStyle =
      [typingAttrs[NSParagraphStyleAttributeName] mutableCopy];

  CGFloat headIntent = [self getHeadIndent];

  pStyle.textLists = [[self class] textLists];
  pStyle.headIndent = headIntent;
  pStyle.firstLineHeadIndent = headIntent;
  pStyle.paragraphSpacing = 0;
  pStyle.paragraphSpacingBefore = 0;
  pStyle.minimumLineHeight = 0;

  typingAttrs[NSParagraphStyleAttributeName] = pStyle;
  textView.typingAttributes = typingAttrs;
}

- (void)addTypingAttributes {
  [self addAttributes:_input->textView.selectedRange];
}

- (void)removeAttributesFromAttributedString:(NSMutableAttributedString *)string
                                       range:(NSRange)range {
  NSArray *paragraphs =
      [ParagraphsUtils getSeparateParagraphsRangesInAttributedString:string
                                                               range:range];

  NSParagraphStyle *defaultParagraphStyle =
      _input->defaultTypingAttributes[NSParagraphStyleAttributeName];

  for (NSValue *val in paragraphs) {
    NSRange pRange = val.rangeValue;

    [string enumerateAttribute:NSParagraphStyleAttributeName
                       inRange:pRange
                       options:0
                    usingBlock:^(id _Nullable value, NSRange range,
                                 BOOL *_Nonnull stop) {
                      NSMutableParagraphStyle *pStyle =
                          [(NSParagraphStyle *)value mutableCopy];

                      pStyle.textLists = @[];
                      pStyle.headIndent = defaultParagraphStyle.headIndent;
                      pStyle.firstLineHeadIndent =
                          defaultParagraphStyle.firstLineHeadIndent;
                      pStyle.tailIndent = defaultParagraphStyle.tailIndent;
                      pStyle.paragraphSpacing =
                          defaultParagraphStyle.paragraphSpacing;
                      pStyle.paragraphSpacingBefore =
                          defaultParagraphStyle.paragraphSpacingBefore;

                      [string addAttribute:NSParagraphStyleAttributeName
                                     value:pStyle
                                     range:range];
                    }];
  }
}

- (void)removeAttributes:(NSRange)range {
  UITextView *textView = _input->textView;
  NSTextStorage *storage = textView.textStorage;

  NSParagraphStyle *defaultParagraphStyle =
      _input->defaultTypingAttributes[NSParagraphStyleAttributeName];

  [storage beginEditing];
  [self removeAttributesFromAttributedString:storage range:range];
  [storage endEditing];

  NSMutableDictionary *typingAttrs = [textView.typingAttributes mutableCopy];
  NSMutableParagraphStyle *pStyle =
      [typingAttrs[NSParagraphStyleAttributeName] mutableCopy];

  pStyle.textLists = @[];
  pStyle.headIndent = defaultParagraphStyle.headIndent;
  pStyle.firstLineHeadIndent = defaultParagraphStyle.firstLineHeadIndent;
  pStyle.tailIndent = defaultParagraphStyle.tailIndent;
  pStyle.paragraphSpacing = defaultParagraphStyle.paragraphSpacing;
  pStyle.paragraphSpacingBefore = defaultParagraphStyle.paragraphSpacingBefore;

  typingAttrs[NSParagraphStyleAttributeName] = pStyle;
  textView.typingAttributes = typingAttrs;
}

- (void)removeTypingAttributes {
  [self removeAttributes:_input->textView.selectedRange];
}

- (BOOL)handleBackspaceInRange:(NSRange)range replacementText:(NSString *)text {
  UITextView *textView = _input->textView;

  if ([self detectStyle:textView.selectedRange] && text.length == 0) {
    NSRange paragraphRange = [textView.textStorage.string
        paragraphRangeForRange:textView.selectedRange];

    if (NSEqualRanges(textView.selectedRange, NSMakeRange(0, 0))) {
      [self removeAttributes:paragraphRange];
      return YES;
    }

    if (range.location == paragraphRange.location - 1) {
      [self removeAttributes:paragraphRange];
      return YES;
    }
  }

  return NO;
}

- (BOOL)tryHandlingListShorcutInRange:(NSRange)range
                      replacementText:(NSString *)text {
  UITextView *textView = _input->textView;
  NSRange paragraphRange =
      [textView.textStorage.string paragraphRangeForRange:range];

  if (![text isEqualToString:[[self class] shortcut]] ||
      range.location - 1 != paragraphRange.location) {
    return NO;
  }

  unichar charBefore =
      [textView.textStorage.string characterAtIndex:range.location - 1];

  if (charBefore != [[self class] shortcutPrefix]) {
    return NO;
  }

  if (![_input handleStyleBlocksAndConflicts:[[self class] getStyleType]
                                       range:paragraphRange]) {
    return NO;
  }

  _input->blockEmitting = YES;

  [TextInsertionUtils replaceText:@""
                               at:NSMakeRange(paragraphRange.location, 1)
             additionalAttributes:nullptr
                            input:_input
                    withSelection:YES];

  _input->blockEmitting = NO;

  [self addAttributes:NSMakeRange(paragraphRange.location,
                                  paragraphRange.length - 1)];

  return YES;
}

- (BOOL)styleCondition:(id _Nullable)value range:(NSRange)range {
  NSParagraphStyle *paragraph = (NSParagraphStyle *)value;
  return paragraph != nullptr &&
         paragraph.textLists == [[self class] textLists];
}

- (BOOL)detectStyle:(NSRange)range {
  if (range.length >= 1) {
    return [OccurenceUtils detect:NSParagraphStyleAttributeName
                        withInput:_input
                          inRange:range
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value range:range];
                    }];
  }

  return [OccurenceUtils detect:NSParagraphStyleAttributeName
                      withInput:_input
                        atIndex:range.location
                  checkPrevious:YES
                  withCondition:^BOOL(id _Nullable value, NSRange range) {
                    return [self styleCondition:value range:range];
                  }];
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:NSParagraphStyleAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value range:range];
               }];
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:NSParagraphStyleAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value range:range];
               }];
}

@end
