
@class HeadingStyleBase, EnrichedTextInputView;

@interface HeadingsParagraphInvariantUtils : NSObject

+ (void)handleImproperHeadingStyles:(NSArray<HeadingStyleBase *> *)styles
                              input:(EnrichedTextInputView *)input;

@end
