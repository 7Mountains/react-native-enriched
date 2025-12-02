#import "StyleHeaders.h"
#import "EnrichedTextInputView.h"
#import "OccurenceUtils.h"
#import "TextInsertionUtils.h"
#import "WordsUtils.h"
#import "UIView+React.h"
#import "ColorExtension.h"
#import "LabelAttachment.h"

static NSString *const ContentAttributeName = @"ContentAttributeName";
static NSString *const placeholder = @"\uFFFC";

@implementation ContentStyle {
    EnrichedTextInputView *_input;
}

+ (StyleType)getStyleType { return Content; }

+ (BOOL)isParagraphStyle { return YES; }

#pragma mark - Init

- (instancetype)initWithInput:(id)input {
    self = [super init];
    _input = (EnrichedTextInputView *)input;
    return self;
}

#pragma mark - NO-OP STYLE METHODS

/// Centralized NO-OP macro so all "do nothing" methods call the same code
#define CONTENTSTYLE_NOOP() do {} while(0)

- (void)applyStyle:(NSRange)range           { CONTENTSTYLE_NOOP(); }
- (void)addAttributes:(NSRange)range        { CONTENTSTYLE_NOOP(); }
- (void)addTypingAttributes                 { CONTENTSTYLE_NOOP(); }
- (void)removeTypingAttributes              { CONTENTSTYLE_NOOP(); }

#pragma mark - Public API

- (void)addContentAtRange:(NSRange)range params:(ContentParams *)params {
    if (range.location == NSNotFound) return;

    NSTextStorage *textStorage = _input->textView.textStorage;
    NSString *string = textStorage.string;

    _input->blockEmitting = YES;

    BOOL needsLeadingNewline =
        (range.location > 0 &&
         ![[string substringWithRange:NSMakeRange(range.location - 1, 1)]
           isEqualToString:@"\n"]);

    if (needsLeadingNewline) {
        [TextInsertionUtils replaceText:@"\n"
                                     at:NSMakeRange(range.location, 0)
                     additionalAttributes:nil
                                   input:_input
                           withSelection:NO];

        range.location += 1;
    }
    NSMutableDictionary *attrs = [_input->defaultTypingAttributes mutableCopy];
    attrs[NSAttachmentAttributeName] = [self prepareAttachment:params];
    attrs[ContentAttributeName] = params;

    [TextInsertionUtils replaceText:placeholder
                                 at:range
                 additionalAttributes:attrs
                               input:_input
                       withSelection:NO];
 
    NSUInteger afterLocation = range.location + 1; // FFFC takes 1 char
    string = textStorage.string; // refresh after insertion

    BOOL isLastChar = (afterLocation >= string.length);
    BOOL needsTrailingNewline =
        isLastChar ||
        ![[string substringWithRange:NSMakeRange(afterLocation, 1)]
          isEqualToString:@"\n"];

    if (needsTrailingNewline) {
      [TextInsertionUtils insertText:@"\n"
                          at:afterLocation
                          additionalAttributes:nil
                          input:_input
                          withSelection:NO
      ];
    }

    _input->blockEmitting = NO;
}

- (void)removeAttributes:(NSRange)range     {
  NSTextStorage *textStorage = _input->textView.textStorage;
  [textStorage beginEditing];
  [textStorage removeAttribute:NSAttachmentAttributeName range:range];
  [textStorage endEditing];
}


#pragma mark - Style Detection Helpers

- (BOOL (^)(id _Nullable, NSRange))contentCondition {
    return ^BOOL(id _Nullable value, NSRange range) {
        NSString *substr =
        [self->_input->textView.textStorage.string substringWithRange:range];
        return ([value isKindOfClass:LabelAttachment.class] && [substr isEqualToString:placeholder]);
    };
}

- (BOOL)styleCondition:(id)value range:(NSRange)range {
    return self.contentCondition(value, range);
}

- (BOOL)detectStyle:(NSRange)range {
    auto condition = [self contentCondition];

    if (range.length >= 1) {
        return [OccurenceUtils detect:NSAttachmentAttributeName
                             withInput:_input
                               inRange:range
                         withCondition:condition];
    } else {
        return [OccurenceUtils detect:NSAttachmentAttributeName
                             withInput:_input
                              atIndex:range.location
                        checkPrevious:NO
                         withCondition:condition];
    }
}

- (BOOL)anyOccurence:(NSRange)range {
    return [OccurenceUtils any:NSAttachmentAttributeName
                      withInput:_input
                        inRange:range
                  withCondition:[self contentCondition]];
}

- (NSArray<StylePair *> *)findAllOccurences:(NSRange)range {
    return [OccurenceUtils all:NSAttachmentAttributeName
                      withInput:_input
                        inRange:range
                  withCondition:[self contentCondition]];
}

#pragma mark - Attachment Params Lookup

- (ContentParams *)getContentParams:(NSUInteger)location {
    if (location >= _input->textView.textStorage.length) return nil;

    unichar c = [_input->textView.textStorage.string characterAtIndex:location];
    if (c != 0xFFFC) return nil;

    NSRange effective;
    NSDictionary *attrs =
        [_input->textView.textStorage attributesAtIndex:location
                                        effectiveRange:&effective];

    id value = attrs[ContentAttributeName];
    return [value isKindOfClass:[ContentParams class]] ? value : nil;
}

#pragma mark - Internal: Props & Attachments

- (ContentStyleProps *)stylePropsWithParams:(ContentParams *)params {
    return [_input->config contentStylePropsForType:params.type];
}

- (LabelAttachment *)prepareAttachment:(ContentParams *)params {
    ContentStyleProps *styles = [self stylePropsWithParams:params];

    LabelAttachment *attachment = [[LabelAttachment alloc] init];
    attachment.labelText    = params.text;
    attachment.font         = _input->config.primaryFont;
    attachment.bgColor      = styles.backgroundColor;
    attachment.textColor    = styles.textColor;
    attachment.inset        = UIEdgeInsetsMake(styles.paddingTop, styles.paddingLeft,
                                               styles.paddingBottom, styles.paddingRight);
    attachment.margin       = UIEdgeInsetsMake(styles.marginTop, styles.marginLeft,
                                               styles.marginBottom, styles.marginRight);
    attachment.cornerRadius = styles.borderRadius;
    attachment.borderWidth  = styles.borderWidth;
    attachment.borderColor  = styles.borderColor;
    attachment.borderStyle  = styles.borderStyle;

    return attachment;
}

- (NSDictionary *)prepareAttributes:(ContentParams *)params {
    InputConfig *config = _input->config;

    return @{
        NSAttachmentAttributeName     : [self prepareAttachment:params],
        NSFontAttributeName           : config.primaryFont,
        NSForegroundColorAttributeName: config.primaryColor
    };
}

@end
