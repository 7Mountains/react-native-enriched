typedef NS_ENUM(NSInteger, TextBlockTapKind) {
  TextBlockTapKindNone = 0,
  TextBlockTapKindCheckbox,
  TextBlockTapKindAttachment,
};

@class EnrichedTextInputView;

@interface TextBlockTapGestureRecognizer : UITapGestureRecognizer

@property(nonatomic, weak) UITextView *textView;
@property(nonatomic, weak) EnrichedTextInputView *input;

@property(nonatomic, assign, readonly) TextBlockTapKind tapKind;
@property(nonatomic, assign, readonly) NSInteger characterIndex;
@property(nonatomic, strong, readonly) NSTextAttachment *attachment;

- (instancetype)initWithTarget:(id)target
                        action:(SEL)action
                      textView:(UITextView *)textView
                         input:(EnrichedTextInputView *)input
    NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithTarget:(id)target action:(SEL)action NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end
