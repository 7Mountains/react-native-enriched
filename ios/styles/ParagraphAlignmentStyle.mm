#import "AlignmentConverter.h"
#import "EnrichedTextInputView.h"
#import "OccurenceUtils.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"

@implementation ParagraphAlignmentStyle {
  EnrichedTextInputView *_input;
}

#pragma mark - Init

- (instancetype)initWithInput:(id)input {
  self = [super init];
  _input = (EnrichedTextInputView *)input;
  return self;
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
  return NSParagraphStyleAttributeName;
}

+ (BOOL)isSelfClosing {
  return NO;
}

#pragma mark - Serialization

+ (NSDictionary<NSString *, NSString *> *)containerAttributesFromValue:
    (id)value {
  if (![value isKindOfClass:[NSParagraphStyle class]])
    return nil;

  NSTextAlignment alignment = ((NSParagraphStyle *)value).alignment;
  if (alignment == NSTextAlignmentNatural)
    return nil;

  return @{@"alignment" : [AlignmentConverter stringFromAlignment:alignment]};
}

#pragma mark - List helpers

- (NSTextList *)primaryListFromStyle:(NSParagraphStyle *)style {
  if (!style || style.textLists.count == 0)
    return nil;
  return style.textLists.firstObject;
}

- (BOOL)isSameList:(NSParagraphStyle *)a other:(NSParagraphStyle *)b {
  NSTextList *la = [self primaryListFromStyle:a];
  NSTextList *lb = [self primaryListFromStyle:b];
  if (!la || !lb)
    return NO;
  return [la.markerFormat isEqualToString:lb.markerFormat];
}

#pragma mark - Range helpers

- (NSRange)paragraphRangeForRange:(NSRange)range {
  return [_input->textView.textStorage.string paragraphRangeForRange:range];
}

- (BOOL)rangeTouchesList:(NSRange)range {
  NSTextStorage *storage = _input->textView.textStorage;

  __block BOOL touches = NO;
  [storage enumerateAttribute:NSParagraphStyleAttributeName
                      inRange:range
                      options:0
                   usingBlock:^(id value, NSRange r, BOOL *stop) {
                     if ([self primaryListFromStyle:value]) {
                       touches = YES;
                       *stop = YES;
                     }
                   }];
  return touches;
}

#pragma mark - Expand list

- (NSRange)expandRangeToFullList:(NSRange)range {
  NSString *text = _input->textView.textStorage.string;
  NSTextStorage *storage = _input->textView.textStorage;

  if (text.length == 0)
    return range;

  NSRange baseParagraph = [text paragraphRangeForRange:range];

  NSUInteger safeIndex = baseParagraph.location >= text.length
                             ? text.length - 1
                             : baseParagraph.location;

  NSParagraphStyle *baseStyle = [storage attribute:NSParagraphStyleAttributeName
                                           atIndex:safeIndex
                                    effectiveRange:nil];

  NSTextList *baseList = [self primaryListFromStyle:baseStyle];
  if (!baseList)
    return baseParagraph;

  NSInteger start = baseParagraph.location;
  NSInteger end = NSMaxRange(baseParagraph);

  // expand upward
  while (start > 0) {
    NSRange prev = [text paragraphRangeForRange:NSMakeRange(start - 1, 0)];

    NSParagraphStyle *prevStyle =
        [storage attribute:NSParagraphStyleAttributeName
                   atIndex:prev.location
            effectiveRange:nil];

    if (![self isSameList:prevStyle other:baseStyle])
      break;

    start = prev.location;
  }

  // expand downward
  while (end < text.length) {
    NSRange next = [text paragraphRangeForRange:NSMakeRange(end, 0)];

    NSParagraphStyle *nextStyle =
        [storage attribute:NSParagraphStyleAttributeName
                   atIndex:next.location
            effectiveRange:nil];

    if (![self isSameList:nextStyle other:baseStyle])
      break;

    end = NSMaxRange(next);
  }

  return NSMakeRange(start, end - start);
}

#pragma mark - Apply alignment

- (void)applyAlignment:(NSTextAlignment)alignment inRange:(NSRange)range {

  NSTextStorage *storage = _input->textView.textStorage;
  NSString *text = storage.string;

  if (range.location == NSNotFound || text.length == 0)
    return;

  [storage beginEditing];

  NSUInteger location = range.location;

  while (location < NSMaxRange(range)) {

    if (location >= text.length)
      break;

    NSRange paragraph = [text paragraphRangeForRange:NSMakeRange(location, 0)];

    NSUInteger safeIndex = MIN(paragraph.location, text.length - 1);

    NSParagraphStyle *current = [storage attribute:NSParagraphStyleAttributeName
                                           atIndex:safeIndex
                                    effectiveRange:nil];

    NSMutableParagraphStyle *style =
        current ? [current mutableCopy]
                : [[NSMutableParagraphStyle alloc] init];

    style.alignment = alignment;

    [storage addAttribute:NSParagraphStyleAttributeName
                    value:style
                    range:paragraph];

    location = NSMaxRange(paragraph);
  }

  [storage endEditing];
}

#pragma mark - Main entry point

- (void)applyStyle:(NSRange)range alignment:(NSTextAlignment)alignment {

  NSString *text = _input->textView.textStorage.string;
  if (range.location == NSNotFound)
    return;

  NSRange targetRange;

  if (range.length == 0) {
    // caret
    NSRange paragraph = [self paragraphRangeForRange:range];

    NSUInteger safeIndex = paragraph.location >= text.length
                               ? text.length - 1
                               : paragraph.location;

    NSParagraphStyle *style =
        [_input->textView.textStorage attribute:NSParagraphStyleAttributeName
                                        atIndex:safeIndex
                                 effectiveRange:nil];

    if ([self primaryListFromStyle:style]) {
      targetRange = [self expandRangeToFullList:paragraph];
    } else {
      targetRange = paragraph;
    }
  } else {
    NSRange paragraphRange = [self paragraphRangeForRange:range];

    if ([self rangeTouchesList:paragraphRange]) {
      targetRange = [self expandRangeToFullList:paragraphRange];
    } else {
      targetRange = paragraphRange;
    }
  }

  [self applyAlignment:alignment inRange:targetRange];

  // update typing attributes
  NSMutableDictionary *typing = [_input->textView.typingAttributes mutableCopy];

  NSMutableParagraphStyle *typingStyle =
      [typing[NSParagraphStyleAttributeName] mutableCopy]
          ?: [[NSMutableParagraphStyle alloc] init];

  typingStyle.alignment = alignment;
  typing[NSParagraphStyleAttributeName] = typingStyle;

  _input->textView.typingAttributes = typing;
}

#pragma mark - Required overrides

- (void)applyStyle:(NSRange)range {
  // alignment uses applyStyle:alignment:
}

#pragma mark - Enter handling

- (BOOL)handleEnterPressInRange:(NSRange)range
                replacementText:(NSString *)text {

  if ([self detectStyle:_input->textView.selectedRange] && text.length > 0 &&
      [[NSCharacterSet newlineCharacterSet]
          characterIsMember:[text characterAtIndex:text.length - 1]]) {

    [TextInsertionUtils replaceText:text
                                 at:range
               additionalAttributes:nil
                              input:_input
                      withSelection:YES];

    NSRange newParagraph = [_input->textView.textStorage.string
        paragraphRangeForRange:_input->textView.selectedRange];

    [_input->textView.textStorage beginEditing];
    [_input->textView.textStorage removeAttribute:NSParagraphStyleAttributeName
                                            range:newParagraph];
    [_input->textView.textStorage endEditing];

    return YES;
  }

  return NO;
}

#pragma mark - Style detection

- (BOOL)styleCondition:(id)value range:(NSRange)range {
  NSParagraphStyle *style = (NSParagraphStyle *)value;
  return value != nil && style.alignment != NSTextAlignmentNatural;
}

- (BOOL)detectStyle:(NSRange)range {
  if (range.length >= 1) {
    return [OccurenceUtils detect:NSParagraphStyleAttributeName
                        withInput:_input
                          inRange:range
                    withCondition:^BOOL(id value, NSRange r) {
                      return [self styleCondition:value range:r];
                    }];
  } else {
    return [OccurenceUtils detect:NSParagraphStyleAttributeName
                        withInput:_input
                          atIndex:range.location
                    checkPrevious:YES
                    withCondition:^BOOL(id value, NSRange r) {
                      return [self styleCondition:value range:r];
                    }];
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:NSParagraphStyleAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id value, NSRange r) {
                 return [self styleCondition:value range:r];
               }];
}

- (NSArray<StylePair *> *)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:NSParagraphStyleAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id value, NSRange r) {
                 return [self styleCondition:value range:r];
               }];
}

- (void)addAttributes:(NSRange)range {
}
- (void)removeAttributes:(NSRange)range {
}

- (void)
    addAttributesInAttributedString:(NSMutableAttributedString *_Nonnull)string
                              range:(NSRange)range
                         attributes:
                             (NSDictionary<NSString *, NSString *> *_Nullable)
                                 attributes {
  // no-op
}

- (void)addTypingAttributes {
  // no-op
}

- (void)removeTypingAttributes {
  // no-op
}

@end
