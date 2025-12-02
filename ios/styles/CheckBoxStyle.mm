#import "StyleHeaders.h"
#import "EnrichedTextInputView.h"
#import "FontExtension.h"
#import "OccurenceUtils.h"
#import "ParagraphsUtils.h"
#import "TextInsertionUtils.h"
#import "ColorExtension.h"

@implementation CheckBoxStyle {
    EnrichedTextInputView *_input;
}

#pragma mark - Class Info

+ (StyleType)getStyleType { return Checkbox; }
+ (BOOL)isParagraphStyle { return YES; }

#pragma mark - Init

- (instancetype)initWithInput:(id)input {
    self = [super init];
    _input = (EnrichedTextInputView *)input;
    return self;
}

#pragma mark - Internal Helpers

- (CGFloat)getHeadIndent {
    // lists are drawn manually
    // margin before checkbox + gap + checkbox width
    return [_input->config checkboxListMarginLeft]
         + [_input->config checkboxListGapWidth]
         + [_input->config checkBoxWidth];
}

- (NSTextList *)listForChecked:(BOOL)checked {
    return [[NSTextList alloc] initWithMarkerFormat:(checked ? NSTextListMarkerCheck : NSTextListMarkerBox)
                                           options:0];
}

- (void)resetParagraphStyle:(NSMutableParagraphStyle *)pStyle {
    pStyle.textLists = @[];
    pStyle.headIndent = 0;
    pStyle.firstLineHeadIndent = 0;
    pStyle.minimumLineHeight = 0;
    pStyle.maximumLineHeight = 0;
    pStyle.lineHeightMultiple = 1;
}

- (NSMutableParagraphStyle *)currentTypingParagraphStyle {
    return [_input->textView.typingAttributes[NSParagraphStyleAttributeName] mutableCopy];
}

- (void)saveTypingParagraphStyle:(NSMutableParagraphStyle *)pStyle {
    NSMutableDictionary *attrs = [_input->textView.typingAttributes mutableCopy];
    attrs[NSParagraphStyleAttributeName] = pStyle;
    _input->textView.typingAttributes = attrs;
}

#pragma mark - Apply Style

- (void)applyStyle:(NSRange)range {
    BOOL present = [self detectStyle:range];

    if (range.length > 0) {
        present ? [self removeAttributes:range] : [self addAttributes:range];
    } else {
        present ? [self removeTypingAttributes] : [self addTypingAttributes];
    }
}

#pragma mark - Add Attributes

- (void)addAttributes:(NSRange)range {
    BOOL wasChecked = [self isCheckedAt: range.location];
    [self addCheckBoxAtRange:range isChecked:wasChecked];
}

- (void)addTypingAttributes {
    [self addAttributes:_input->textView.selectedRange];
}

#pragma mark - Remove Attributes

- (void)removeAttributes:(NSRange)range {
    NSArray *paragraphs =
        [ParagraphsUtils getSeparateParagraphsRangesIn:_input->textView range:range];

    [_input->textView.textStorage beginEditing];

    for (NSValue *val in paragraphs) {
        NSRange pRange = val.rangeValue;
        [_input->textView.textStorage enumerateAttribute:NSParagraphStyleAttributeName
                                                 inRange:pRange
                                                 options:0
                                              usingBlock:^(id value, NSRange sub, BOOL *stop) {

            // reset paragraph style
            NSMutableParagraphStyle *pStyle = [(NSParagraphStyle *)value mutableCopy];
            [self resetParagraphStyle:pStyle];

            [_input->textView.textStorage addAttribute:NSParagraphStyleAttributeName
                                                 value:pStyle
                                                 range:sub];
            [_input->textView.textStorage removeAttribute:NSBaselineOffsetAttributeName range:sub];
        }];
    }

    [_input->textView.textStorage endEditing];

    NSMutableParagraphStyle *pStyle = [self currentTypingParagraphStyle];
    [self resetParagraphStyle:pStyle];

    NSMutableDictionary *typing = [_input->textView.typingAttributes mutableCopy];
    typing[NSParagraphStyleAttributeName] = pStyle;
    [typing removeObjectForKey:NSBaselineOffsetAttributeName];
    _input->textView.typingAttributes = typing;
}

- (void)removeTypingAttributes {
    [self removeAttributes:_input->textView.selectedRange];
}

#pragma mark - Backspace Handling

- (BOOL)handleBackspaceInRange:(NSRange)range replacementText:(NSString *)text {

    if ([self detectStyle:_input->textView.selectedRange] && text.length == 0) {
        NSRange pRange =
            [_input->textView.textStorage.string paragraphRangeForRange:_input->textView.selectedRange];

        BOOL isFirst = NSEqualRanges(_input->textView.selectedRange, NSMakeRange(0, 0));
        BOOL isBeforeParagraph = (range.location == pRange.location - 1);

        if (isFirst || isBeforeParagraph) {
            [self removeAttributes:pRange];
            return YES;
        }
    }
    return NO;
}

#pragma mark - Newlines

- (BOOL)handleNewlinesInRange:(NSRange)range replacementText:(NSString *)text {

    if ([self detectStyle:_input->textView.selectedRange] &&
        text.length > 0 &&
        [[NSCharacterSet newlineCharacterSet]
         characterIsMember:[text characterAtIndex:text.length - 1]]) {

        [TextInsertionUtils replaceText:text
                                     at:range
                   additionalAttributes:nullptr
                                  input:_input
                           withSelection:YES];

        [self addAttributes:_input->textView.selectedRange];
        return YES;
    }

    return NO;
}

#pragma mark - Detection

- (BOOL)styleCondition:(id)value {
    NSParagraphStyle *paragraphStyle = (NSParagraphStyle *)value;
    if (!paragraphStyle || paragraphStyle.textLists.count != 1) return NO;

    NSString *marker = paragraphStyle.textLists.firstObject.markerFormat;
    return [marker isEqualToString:NSTextListMarkerBox] ||
           [marker isEqualToString:NSTextListMarkerCheck];
}

- (BOOL)detectStyle:(NSRange)range {

    if (range.length >= 1) {
        return [OccurenceUtils detect:NSParagraphStyleAttributeName
                            withInput:_input
                              inRange:range
                        withCondition:^BOOL(id value, NSRange r) {
            return [self styleCondition:value];
        }];
    }

    return [OccurenceUtils detect:NSParagraphStyleAttributeName
                        withInput:_input
                          atIndex:range.location
                    checkPrevious:YES
                    withCondition:^BOOL(id value, NSRange r) {
        return [self styleCondition:value];
    }];
}

- (BOOL)anyOccurence:(NSRange)range {
    return [OccurenceUtils any:NSParagraphStyleAttributeName
                     withInput:_input
                       inRange:range
                 withCondition:^BOOL(id value, NSRange r) {
        return [self styleCondition:value];
    }];
}

- (NSArray<StylePair *> *)findAllOccurences:(NSRange)range {
    return [OccurenceUtils all:NSParagraphStyleAttributeName
                     withInput:_input
                       inRange:range
                 withCondition:^BOOL(id value, NSRange r) {
        return [self styleCondition:value];
    }];
}

#pragma mark - Check State

- (BOOL)isCheckedAt:(NSUInteger)location {
    if (location >= _input->textView.textStorage.length) return NO;

    NSParagraphStyle *p =
        [_input->textView.textStorage attribute:NSParagraphStyleAttributeName
                                        atIndex:location
                                 effectiveRange:NULL];

    if (!p || p.textLists.count == 0) return NO;

    return [p.textLists.firstObject.markerFormat isEqualToString:NSTextListMarkerCheck];
}

- (void)toggleCheckedAt:(NSUInteger)location {

    NSRange pRange =
        [_input->textView.textStorage.string paragraphRangeForRange:NSMakeRange(location, 0)];

    if (pRange.location == NSNotFound || pRange.length == 0) return;
    if (![self detectStyle:pRange]) return;

    BOOL currentChecked = [self isCheckedAt:pRange.location];
    NSTextList *newList = [self listForChecked:!currentChecked];

    [_input->textView.textStorage beginEditing];

    [_input->textView.textStorage enumerateAttribute:NSParagraphStyleAttributeName
                                             inRange:pRange
                                             options:0
                                          usingBlock:^(id value, NSRange sub, BOOL *stop) {
        NSMutableParagraphStyle *pStyle = [(NSParagraphStyle *)value mutableCopy];
        pStyle.textLists = @[newList];
        [_input->textView.textStorage addAttribute:NSParagraphStyleAttributeName
                                             value:pStyle
                                             range:sub];
    }];

    [_input->textView.textStorage endEditing];

    // update typing attributes
    NSMutableParagraphStyle *pStyle = [self currentTypingParagraphStyle];
    [self saveTypingParagraphStyle:pStyle];
}

#pragma mark - Adding Checkboxes

- (void)addCheckBoxAtRange:(NSRange)range isChecked:(BOOL)isChecked {

    NSTextList *list = [self listForChecked:isChecked];
    CGFloat checBoxHeight = [_input->config checkBoxHeight];

    NSArray *paragraphs =
        [ParagraphsUtils getSeparateParagraphsRangesIn:_input->textView range:range];

    NSInteger offset = 0;
    NSRange preRange = _input->textView.selectedRange;

    _input->blockEmitting = YES;

    for (NSValue *paragraph in paragraphs) {
        NSRange fixed = NSMakeRange(paragraph.rangeValue.location + offset,
                                    paragraph.rangeValue.length);

        BOOL shouldInsert =
            (fixed.length == 0) ||
            (fixed.length == 1 &&
             [[NSCharacterSet newlineCharacterSet]
              characterIsMember:[_input->textView.textStorage.string characterAtIndex:fixed.location]]);

        if (shouldInsert) {
            [TextInsertionUtils insertText:@"\u200B"
                                        at:fixed.location
                      additionalAttributes:nullptr
                                     input:_input
                              withSelection:NO];

            fixed.length += 1;
            offset += 1;
        }

        [_input->textView.textStorage enumerateAttribute:NSParagraphStyleAttributeName
                                                 inRange:fixed
                                                 options:0
                                              usingBlock:^(id value, NSRange sub, BOOL *stop) {

            NSMutableParagraphStyle *paragraphStyle = [(NSParagraphStyle *)value mutableCopy];
            paragraphStyle.textLists = @[list];
            paragraphStyle.minimumLineHeight = checBoxHeight;
            paragraphStyle.maximumLineHeight = checBoxHeight;
            paragraphStyle.lineHeightMultiple = 1.0;

            paragraphStyle.headIndent = [self getHeadIndent];
            paragraphStyle.firstLineHeadIndent = [self getHeadIndent];
            UIFont *font = _input->textView.font ?: [UIFont systemFontOfSize:14];
            CGFloat baselineShift = (checBoxHeight - font.lineHeight) / 2.0;

            [_input->textView.textStorage addAttribute:NSParagraphStyleAttributeName
                                                 value:paragraphStyle
                                                 range:sub];
            [_input->textView.textStorage addAttribute:NSBaselineOffsetAttributeName
                                                 value:@(baselineShift)
                                                 range:sub];
        }];
    }

    _input->blockEmitting = NO;

    // adjust selection
    if (preRange.length == 0) {
        _input->textView.selectedRange = preRange;
    } else {
        _input->textView.selectedRange =
            NSMakeRange(preRange.location, preRange.length + offset);
    }
    NSMutableParagraphStyle *paragraphStyle = [self currentTypingParagraphStyle];
    paragraphStyle.textLists = @[list];
    paragraphStyle.minimumLineHeight = checBoxHeight;
    paragraphStyle.maximumLineHeight = checBoxHeight;
    paragraphStyle.lineHeightMultiple = 1.0;
    paragraphStyle.headIndent = [self getHeadIndent];
    paragraphStyle.firstLineHeadIndent = [self getHeadIndent];

    UIFont *font = _input->textView.font ?: [UIFont systemFontOfSize:14];
    CGFloat baselineShift = (checBoxHeight - font.lineHeight) / 2.0;

    NSMutableDictionary *typingAttrs = [_input->textView.typingAttributes mutableCopy];
    typingAttrs[NSParagraphStyleAttributeName] = paragraphStyle;
    typingAttrs[NSBaselineOffsetAttributeName] = @(baselineShift);
    _input->textView.typingAttributes = typingAttrs;
}

@end
