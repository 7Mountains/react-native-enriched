#import "StyleHeaders.h"
#import "EnrichedTextInputView.h"
#import "OccurenceUtils.h"
#import "TextInsertionUtils.h"

@implementation ParagraphAlignmentStyle {
    EnrichedTextInputView *_input;
}

+ (StyleType)getStyleType { return ParagraphAlignment; }

+ (BOOL)isParagraphStyle { return NO; }

- (instancetype)initWithInput:(id)input {
    self = [super init];
    _input = (EnrichedTextInputView *)input;
    return self;
}

#pragma mark - Apply Style

/// New alignment-based API
- (void)applyStyle:(NSRange)range alignment:(NSTextAlignment)alignment {
  if (range.location == NSNotFound) return;

    NSRange paragraphRange = [_input->textView.textStorage.string paragraphRangeForRange:range];

    [_input->textView.textStorage beginEditing];

    [_input->textView.textStorage enumerateAttribute:NSParagraphStyleAttributeName
                                             inRange:paragraphRange
                                             options:0
                                          usingBlock:^(id _Nullable value, NSRange range, BOOL *stop) {

        NSMutableParagraphStyle *style = value
            ? [value mutableCopy]
            : [[NSMutableParagraphStyle alloc] init];
        style.alignment = alignment;
      
      [_input->textView.textStorage addAttribute:NSParagraphStyleAttributeName
                                           value:style
                                           range:range];

        [_input->textView.textStorage addAttribute:NSParagraphStyleAttributeName
                                             value:style
                                             range:range];
    }];

    [_input->textView.textStorage endEditing];
}

/// Old API required by protocol – does nothing but keeps signature
- (void)applyStyle:(NSRange)range {
    // NO-OP – alignment requires explicit alignment parameter
}

- (BOOL)handleEnterPressInRange:(NSRange)range replacementText:(NSString *)text {
    if ([self detectStyle:_input->textView.selectedRange] &&
        text.length > 0 &&
        [[NSCharacterSet newlineCharacterSet] characterIsMember:[text characterAtIndex:text.length - 1]]) {

        // Insert newline manually
        [TextInsertionUtils replaceText:text at:range additionalAttributes:nil input:_input withSelection:YES];

        // New empty paragraph begins at selectedRange.location
        NSRange newParagraphRange =
            [_input->textView.textStorage.string paragraphRangeForRange:_input->textView.selectedRange];

        // Clear alignment
        [_input->textView.textStorage beginEditing];
        [_input->textView.textStorage removeAttribute:NSParagraphStyleAttributeName range:newParagraphRange];
        [_input->textView.textStorage endEditing];

        return YES;
    }

    return NO;
}


#pragma mark - Typing Attributes (Empty)

- (void)addTypingAttributes {
    // Paragraph alignment is NOT applied via typingAttributes.
}

- (void)removeTypingAttributes {
    // Alignment cannot be “removed” this way.
}

#pragma mark - Style Detection

- (BOOL)styleCondition:(id)value :(NSRange)range {
    if (!value) return NO;

    NSParagraphStyle *style = (NSParagraphStyle *)value;
    return (style.alignment != NSTextAlignmentNatural);
}

- (BOOL)detectStyle:(NSRange)range {
    if (range.length >= 1) {
        return [OccurenceUtils detect:NSParagraphStyleAttributeName
                             withInput:_input
                               inRange:range
                        withCondition:^BOOL(id value, NSRange r) {
            return [self styleCondition:value :r];
        }];
    } else {
        return [OccurenceUtils detect:NSParagraphStyleAttributeName
                             withInput:_input
                               atIndex:range.location
                         checkPrevious:YES
                        withCondition:^BOOL(id value, NSRange r) {
            return [self styleCondition:value :r];
        }];
    }
}

- (BOOL)anyOccurence:(NSRange)range {
    return [OccurenceUtils any:NSParagraphStyleAttributeName
                      withInput:_input
                        inRange:range
                 withCondition:^BOOL(id value, NSRange r) {
        return [self styleCondition:value :r];
    }];
}

- (NSArray<StylePair *> *)findAllOccurences:(NSRange)range {
    return [OccurenceUtils all:NSParagraphStyleAttributeName
                      withInput:_input
                        inRange:range
                 withCondition:^BOOL(id value, NSRange r) {
        return [self styleCondition:value :r];
    }];
}

- (void)addAttributes:(NSRange)range { 
  // no-op
}


- (void)removeAttributes:(NSRange)range { 
  // no-op
}


@end
