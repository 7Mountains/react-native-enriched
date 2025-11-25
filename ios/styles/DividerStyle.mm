#import "DividerAttachment.h"
#import "StyleHeaders.h"
#import "EnrichedTextInputView.h"
#import "OccurenceUtils.h"
#import "TextInsertionUtils.h"

static NSString *const placeholder = @"\uFFFC";

@implementation DividerStyle {
    EnrichedTextInputView *_input;
}

+ (StyleType)getStyleType { return Divider; }

+ (BOOL)isParagraphStyle { return YES; }

- (instancetype)initWithInput:(id)input {
    if (self = [super init]) {
        _input = (EnrichedTextInputView *)input;
    }
    return self;
}

#pragma mark - Style Application

- (void)applyStyle:(NSRange)range {
    // no-op for dividers
}

- (void)addAttributes:(NSRange)range {
    NSTextStorage *textStorage = _input->textView.textStorage;
    NSDictionary *attrs = [self prepareAttributes];

    [textStorage beginEditing];
    [textStorage addAttributes:attrs range:range];
    [textStorage endEditing];
}

- (void)addTypingAttributes {
    // no-op for dividers
}

- (void)removeAttributes:(NSRange)range {
    NSTextStorage *textStorage = _input->textView.textStorage;
    [textStorage beginEditing];
    [textStorage removeAttribute:NSAttachmentAttributeName range:range];
    [textStorage endEditing];
}

- (void)removeTypingAttributes {
    NSMutableDictionary *attrs = [_input->textView.typingAttributes mutableCopy];
    [attrs removeObjectForKey:NSAttachmentAttributeName];
    _input->textView.typingAttributes = attrs;
}

#pragma mark - Style Detection Helpers

- (BOOL)styleCondition:(id)value range:(NSRange)range {
    NSString *charStr = [_input->textView.textStorage.string substringWithRange:range];
    return [value isKindOfClass:[DividerAttachment class]] && [charStr isEqualToString:placeholder];
}

- (BOOL)detectStyle:(NSRange)range {
  if (range.length >= 1) {
    return [OccurenceUtils detect:NSAttachmentAttributeName withInput:_input inRange:range
        withCondition:^BOOL(id _Nullable value, NSRange range) {
            return [self styleCondition:value range:range];
        }
    ];
  } else {  
    return [OccurenceUtils detect:NSAttachmentAttributeName withInput:_input atIndex:range.location checkPrevious:NO
        withCondition:^BOOL(id _Nullable value, NSRange range) {
            return [self styleCondition:value range:range];
        }
    ];
  }
}

- (BOOL)anyOccurence:(NSRange)range {
    return [OccurenceUtils any:NSAttachmentAttributeName
                     withInput:_input
                       inRange:range
                 withCondition:^BOOL(id value, NSRange r) {
                         return [self styleCondition:value range:r];
                     }];
}

- (NSArray<StylePair *> *)findAllOccurences:(NSRange)range {
    return [OccurenceUtils all:NSAttachmentAttributeName
                     withInput:_input
                       inRange:range
                 withCondition:^BOOL(id value, NSRange r) {
                         return [self styleCondition:value range:r];
                     }];
}

#pragma mark - Attachment & Attributes

- (DividerAttachment *)prepareAttachment {
    DividerAttachment *attachment = [[DividerAttachment alloc] init];
    attachment.color = _input->config.dividerColor;
    attachment.height = _input->config.dividerHeight;
    attachment.thickness = _input->config.dividerThickness;
    return attachment;
}

- (NSDictionary *)prepareAttributes {
    InputConfig *config = _input->config;

    return @{
        NSAttachmentAttributeName: [self prepareAttachment],
        NSFontAttributeName: config.primaryFont,
        NSForegroundColorAttributeName: config.primaryColor,
        NSFontAttributeName: config.primaryFont,
    };
}

#pragma mark - Divider Insertion

- (void)insertDividerAt:(NSUInteger)index setSelection:(BOOL)setSelection {
    EnrichedTextInputView *input = _input;
    NSTextStorage *textStorage = input->textView.textStorage;
    NSString *string = textStorage.string;

    NSDictionary *dividerAttrs = [self prepareAttributes];

    BOOL needsNewlineBefore = (index > 0 && [string characterAtIndex:index - 1] != '\n');
    BOOL needsNewlineAfter  = (index < string.length && [string characterAtIndex:index] != '\n');

    NSInteger insertIndex = index;
    input->textView.typingAttributes = input->defaultTypingAttributes;
    if(needsNewlineBefore) {
      [TextInsertionUtils insertText:@"\n"
                                at:insertIndex
              additionalAttributes:input->defaultTypingAttributes
                             input:input
                     withSelection:NO];
      insertIndex += 1;
    }

    [TextInsertionUtils insertText:placeholder
                               at:insertIndex
             additionalAttributes:input->defaultTypingAttributes
                             input:input
                     withSelection:setSelection];

    NSRange placeholderRange = NSMakeRange(insertIndex, 1);

    [textStorage beginEditing];
    [textStorage addAttributes:dividerAttrs range:placeholderRange];
    [textStorage endEditing];
    if (needsNewlineAfter) {
        [TextInsertionUtils insertText:@"\n"
                                   at:insertIndex
                 additionalAttributes:input->defaultTypingAttributes
                                 input:input
                         withSelection:NO];
        insertIndex += 1;
    }

  if (setSelection) {
    _input->textView.selectedRange = NSMakeRange(insertIndex + 1, 0);
  }

}

- (void)insertDividerAtline:(NSRange *)at withSelection:(BOOL)withSelection {
    UITextView *tv = _input->textView;
    NSString *string = tv.textStorage.string;

    NSRange selection = tv.selectedRange;
    NSRange lineRange = [string lineRangeForRange:selection];
    NSUInteger index = lineRange.location + lineRange.length;

    [self insertDividerAt:index setSelection:withSelection];
}

- (void)insertDividerAtNewLine {
    UITextView *tv = _input->textView;
    NSString *string = tv.textStorage.string;

    NSRange selection = tv.selectedRange;
    NSRange lineRange = [string lineRangeForRange:selection];
    NSUInteger index = lineRange.location + lineRange.length;

    [self insertDividerAt:index setSelection:YES];
}

@end
