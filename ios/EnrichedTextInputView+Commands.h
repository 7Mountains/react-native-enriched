#import "EnrichedTextInputView.h"

@class ContentParams;

@interface EnrichedTextInputView (Commands)

- (void)focus;
- (void)blur;
- (void)setValue:(NSString *)value;

- (void)toggleRegularStyle:(StyleType)type;
- (void)toggleParagraphStyle:(StyleType)type;

- (void)setColor:(NSString *)colorText;
- (void)removeColor;

- (void)addLinkAt:(NSInteger)start
              end:(NSInteger)end
             text:(NSString *)text
              url:(NSString *)url;

- (void)addMention:(NSString *)indicator
              text:(NSString *)text
              type:(NSString *)type
        attributes:(NSString *)attributes;

- (void)startMentionWithIndicator:(NSString *)indicator;

- (void)addImage:(NSString *)uri width:(float)width height:(float)height;

- (void)setCustomSelection:(NSInteger)visibleStart end:(NSInteger)visibleEnd;

- (void)requestHTML:(NSInteger)requestId prettify:(BOOL)prettify;

- (void)addDividerAtNewLine;
- (void)setParagraphAlignment:(NSString *)alignment;

- (void)anyTextMayHaveBeenModified;

- (void)addContent:(ContentParams *)params;

@end
