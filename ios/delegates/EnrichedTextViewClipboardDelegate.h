@protocol EnrichedTextViewClipboardDelegate <NSObject>

- (void)handleCopyFromTextView:(UITextView *)textView sender:(id)sender;
- (void)handlePasteIntoTextView:(UITextView *)textView sender:(id)sender;
- (void)handleCutFromTextView:(UITextView *)textView sender:(id)sender;

@end
