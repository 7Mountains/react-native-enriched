#import "EnrichedTextStyleFactory.h"
#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

@implementation EnrichedTextStyleFactory

#pragma mark - Styles (per input)

+ (NSDictionary<NSNumber *, id> *)makeStylesWithInput:
    (EnrichedTextInputView *)input {
  return @{
    @([BoldStyle getStyleType]) : [[BoldStyle alloc] initWithInput:input],
    @([ItalicStyle getStyleType]) : [[ItalicStyle alloc] initWithInput:input],
    @([UnderlineStyle getStyleType]) :
        [[UnderlineStyle alloc] initWithInput:input],
    @([StrikethroughStyle getStyleType]) :
        [[StrikethroughStyle alloc] initWithInput:input],
    @([ColorStyle getStyleType]) : [[ColorStyle alloc] initWithInput:input],
    @([InlineCodeStyle getStyleType]) :
        [[InlineCodeStyle alloc] initWithInput:input],
    @([LinkStyle getStyleType]) : [[LinkStyle alloc] initWithInput:input],
    @([MentionStyle getStyleType]) : [[MentionStyle alloc] initWithInput:input],
    @([H1Style getStyleType]) : [[H1Style alloc] initWithInput:input],
    @([H2Style getStyleType]) : [[H2Style alloc] initWithInput:input],
    @([H3Style getStyleType]) : [[H3Style alloc] initWithInput:input],
    @([H4Style getStyleType]) : [[H4Style alloc] initWithInput:input],
    @([H5Style getStyleType]) : [[H5Style alloc] initWithInput:input],
    @([H6Style getStyleType]) : [[H6Style alloc] initWithInput:input],
    @([UnorderedListStyle getStyleType]) :
        [[UnorderedListStyle alloc] initWithInput:input],
    @([OrderedListStyle getStyleType]) :
        [[OrderedListStyle alloc] initWithInput:input],
    @([BlockQuoteStyle getStyleType]) :
        [[BlockQuoteStyle alloc] initWithInput:input],
    @([CodeBlockStyle getStyleType]) :
        [[CodeBlockStyle alloc] initWithInput:input],
    @([ImageStyle getStyleType]) : [[ImageStyle alloc] initWithInput:input],
    @([CheckBoxStyle getStyleType]) :
        [[CheckBoxStyle alloc] initWithInput:input],
    @([DividerStyle getStyleType]) : [[DividerStyle alloc] initWithInput:input],
    @([ContentStyle getStyleType]) : [[ContentStyle alloc] initWithInput:input],
    @([ParagraphAlignmentStyle getStyleType]) :
        [[ParagraphAlignmentStyle alloc] initWithInput:input]
  };
}

#pragma mark - Conflicts (static)

+ (NSDictionary<NSNumber *, NSArray<NSNumber *> *> *)makeConflictingStyles {
  static NSDictionary *conflicts = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    conflicts = @{
      @([BoldStyle getStyleType]) : @[ @([MentionStyle getStyleType]) ],
      @([ItalicStyle getStyleType]) : @[ @([MentionStyle getStyleType]) ],
      @([UnderlineStyle getStyleType]) : @[ @([MentionStyle getStyleType]) ],
      @([StrikethroughStyle getStyleType]) :
          @[ @([MentionStyle getStyleType]) ],
      @([ColorStyle getStyleType]) : @[ @([MentionStyle getStyleType]) ],
      @([InlineCodeStyle getStyleType]) :
          @[ @([LinkStyle getStyleType]), @([MentionStyle getStyleType]) ],
      @([LinkStyle getStyleType]) : @[
        @([InlineCodeStyle getStyleType]), @([LinkStyle getStyleType]),
        @([MentionStyle getStyleType])
      ],
      @([MentionStyle getStyleType]) : @[
        @([InlineCodeStyle getStyleType]), @([LinkStyle getStyleType]),
        @([BoldStyle getStyleType]), @([ItalicStyle getStyleType]),
        @([UnderlineStyle getStyleType]), @([StrikethroughStyle getStyleType])
      ],
      @([H1Style getStyleType]) : @[
        @([H2Style getStyleType]), @([H3Style getStyleType]),
        @([H4Style getStyleType]), @([H5Style getStyleType]),
        @([H6Style getStyleType]), @([UnorderedListStyle getStyleType]),
        @([OrderedListStyle getStyleType]), @([BlockQuoteStyle getStyleType]),
        @([CodeBlockStyle getStyleType]), @([CheckBoxStyle getStyleType]),
        @([DividerStyle getStyleType])
      ],
      @([H2Style getStyleType]) : @[
        @([H1Style getStyleType]), @([H3Style getStyleType]),
        @([H4Style getStyleType]), @([H5Style getStyleType]),
        @([H6Style getStyleType]), @([UnorderedListStyle getStyleType]),
        @([OrderedListStyle getStyleType]), @([BlockQuoteStyle getStyleType]),
        @([CodeBlockStyle getStyleType]), @([CheckBoxStyle getStyleType]),
        @([DividerStyle getStyleType])
      ],
      @([H3Style getStyleType]) : @[
        @([H1Style getStyleType]), @([H2Style getStyleType]),
        @([H4Style getStyleType]), @([H5Style getStyleType]),
        @([H6Style getStyleType]), @([UnorderedListStyle getStyleType]),
        @([OrderedListStyle getStyleType]), @([BlockQuoteStyle getStyleType]),
        @([CodeBlockStyle getStyleType]), @([CheckBoxStyle getStyleType]),
        @([DividerStyle getStyleType])
      ],
      @([H4Style getStyleType]) : @[
        @([H1Style getStyleType]), @([H2Style getStyleType]),
        @([H3Style getStyleType]), @([H5Style getStyleType]),
        @([H6Style getStyleType]), @([UnorderedListStyle getStyleType]),
        @([OrderedListStyle getStyleType]), @([BlockQuoteStyle getStyleType]),
        @([CodeBlockStyle getStyleType]), @([CheckBoxStyle getStyleType]),
        @([DividerStyle getStyleType])
      ],
      @([H5Style getStyleType]) : @[
        @([H1Style getStyleType]), @([H2Style getStyleType]),
        @([H3Style getStyleType]), @([H4Style getStyleType]),
        @([H6Style getStyleType]), @([UnorderedListStyle getStyleType]),
        @([OrderedListStyle getStyleType]), @([BlockQuoteStyle getStyleType]),
        @([CodeBlockStyle getStyleType]), @([CheckBoxStyle getStyleType]),
        @([DividerStyle getStyleType])
      ],
      @([H6Style getStyleType]) : @[
        @([H1Style getStyleType]), @([H2Style getStyleType]),
        @([H3Style getStyleType]), @([H4Style getStyleType]),
        @([H5Style getStyleType]), @([UnorderedListStyle getStyleType]),
        @([OrderedListStyle getStyleType]), @([BlockQuoteStyle getStyleType]),
        @([CodeBlockStyle getStyleType]), @([CheckBoxStyle getStyleType]),
        @([DividerStyle getStyleType])
      ],
      @([UnorderedListStyle getStyleType]) : @[
        @([H1Style getStyleType]), @([H2Style getStyleType]),
        @([H3Style getStyleType]), @([H4Style getStyleType]),
        @([H5Style getStyleType]), @([H6Style getStyleType]),
        @([OrderedListStyle getStyleType]), @([BlockQuoteStyle getStyleType]),
        @([CodeBlockStyle getStyleType]), @([CheckBoxStyle getStyleType]),
        @([DividerStyle getStyleType])
      ],
      @([OrderedListStyle getStyleType]) : @[
        @([H1Style getStyleType]), @([H2Style getStyleType]),
        @([H3Style getStyleType]), @([H4Style getStyleType]),
        @([H5Style getStyleType]), @([H6Style getStyleType]),
        @([UnorderedListStyle getStyleType]), @([BlockQuoteStyle getStyleType]),
        @([CodeBlockStyle getStyleType]), @([CheckBoxStyle getStyleType]),
        @([DividerStyle getStyleType])
      ],
      @([BlockQuoteStyle getStyleType]) : @[
        @([H1Style getStyleType]), @([H2Style getStyleType]),
        @([H3Style getStyleType]), @([H4Style getStyleType]),
        @([H5Style getStyleType]), @([H6Style getStyleType]),
        @([UnorderedListStyle getStyleType]),
        @([OrderedListStyle getStyleType]), @([CodeBlockStyle getStyleType]),
        @([CheckBoxStyle getStyleType]), @([DividerStyle getStyleType])
      ],
      @([CodeBlockStyle getStyleType]) : @[
        @([H1Style getStyleType]), @([H2Style getStyleType]),
        @([H3Style getStyleType]), @([H4Style getStyleType]),
        @([H5Style getStyleType]), @([H6Style getStyleType]),
        @([BoldStyle getStyleType]), @([ItalicStyle getStyleType]),
        @([UnderlineStyle getStyleType]), @([StrikethroughStyle getStyleType]),
        @([UnorderedListStyle getStyleType]),
        @([OrderedListStyle getStyleType]), @([BlockQuoteStyle getStyleType]),
        @([InlineCodeStyle getStyleType]), @([MentionStyle getStyleType]),
        @([LinkStyle getStyleType]), @([DividerStyle getStyleType])
      ],
      @([ImageStyle getStyleType]) :
          @[ @([LinkStyle getStyleType]), @([MentionStyle getStyleType]) ],
      @([CheckBoxStyle getStyleType]) : @[
        @([H1Style getStyleType]), @([H2Style getStyleType]),
        @([H3Style getStyleType]), @([H4Style getStyleType]),
        @([H5Style getStyleType]), @([H6Style getStyleType]),
        @([UnorderedListStyle getStyleType]),
        @([OrderedListStyle getStyleType]), @([BlockQuoteStyle getStyleType]),
        @([CodeBlockStyle getStyleType]), @([DividerStyle getStyleType])
      ],
      @([DividerStyle getStyleType]) : @[
        @([H1Style getStyleType]),
        @([H2Style getStyleType]),
        @([H3Style getStyleType]),
        @([H4Style getStyleType]),
        @([H5Style getStyleType]),
        @([H6Style getStyleType]),
        @([UnorderedListStyle getStyleType]),
        @([OrderedListStyle getStyleType]),
        @([CheckBoxStyle getStyleType]),
        @([BlockQuoteStyle getStyleType]),
        @([CodeBlockStyle getStyleType]),
      ],
      @([ContentStyle getStyleType]) : @[],
    };
  });
  return conflicts;
}

#pragma mark - Blocking (static)

+ (NSDictionary<NSNumber *, NSArray<NSNumber *> *> *)makeBlockingStyles {
  static NSDictionary *blocking = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    blocking = @{
      @([BoldStyle getStyleType]) : @[
        @([CodeBlockStyle getStyleType]), @([DividerStyle getStyleType]),
        @([ContentStyle getStyleType])
      ],
      @([ItalicStyle getStyleType]) : @[
        @([CodeBlockStyle getStyleType]), @([DividerStyle getStyleType]),
        @([ContentStyle getStyleType])
      ],
      @([UnderlineStyle getStyleType]) : @[
        @([CodeBlockStyle getStyleType]), @([DividerStyle getStyleType]),
        @([ContentStyle getStyleType])
      ],
      @([StrikethroughStyle getStyleType]) : @[
        @([CodeBlockStyle getStyleType]), @([DividerStyle getStyleType]),
        @([ContentStyle getStyleType])
      ],
      @([ColorStyle getStyleType]) : @[
        @([CodeBlockStyle getStyleType]), @([DividerStyle getStyleType]),
        @([ContentStyle getStyleType])
      ],
      @([InlineCodeStyle getStyleType]) : @[
        @([CodeBlockStyle getStyleType]), @([DividerStyle getStyleType]),
        @([ContentStyle getStyleType])
      ],
      @([LinkStyle getStyleType]) : @[
        @([CodeBlockStyle getStyleType]), @([DividerStyle getStyleType]),
        @([ContentStyle getStyleType])
      ],
      @([MentionStyle getStyleType]) : @[
        @([CodeBlockStyle getStyleType]), @([DividerStyle getStyleType]),
        @([ContentStyle getStyleType])
      ],
      @([H1Style getStyleType]) : @[
        @([CodeBlockStyle getStyleType]), @([DividerStyle getStyleType]),
        @([ContentStyle getStyleType])
      ],
      @([H2Style getStyleType]) : @[
        @([CodeBlockStyle getStyleType]), @([DividerStyle getStyleType]),
        @([ContentStyle getStyleType])
      ],
      @([H3Style getStyleType]) : @[
        @([CodeBlockStyle getStyleType]), @([DividerStyle getStyleType]),
        @([ContentStyle getStyleType])
      ],
      @([H4Style getStyleType]) : @[
        @([CodeBlockStyle getStyleType]), @([DividerStyle getStyleType]),
        @([ContentStyle getStyleType])
      ],
      @([H5Style getStyleType]) : @[
        @([CodeBlockStyle getStyleType]), @([DividerStyle getStyleType]),
        @([ContentStyle getStyleType])
      ],
      @([H6Style getStyleType]) : @[
        @([CodeBlockStyle getStyleType]), @([DividerStyle getStyleType]),
        @([ContentStyle getStyleType])
      ],
      @([UnorderedListStyle getStyleType]) : @[
        @([DividerStyle getStyleType]), @([CodeBlockStyle getStyleType]),
        @([ContentStyle getStyleType])
      ],
      @([OrderedListStyle getStyleType]) :
          @[ @([DividerStyle getStyleType]), @([ContentStyle getStyleType]) ],
      @([BlockQuoteStyle getStyleType]) :
          @[ @([DividerStyle getStyleType]), @([ContentStyle getStyleType]) ],
      @([CodeBlockStyle getStyleType]) :
          @[ @([DividerStyle getStyleType]), @([ContentStyle getStyleType]) ],
      @([ImageStyle getStyleType]) : @[
        @([InlineCodeStyle getStyleType]), @([DividerStyle getStyleType]),
        @([ContentStyle getStyleType])
      ],
      @([CheckBoxStyle getStyleType]) :
          @[ @([CodeBlockStyle getStyleType]), @([ContentStyle getStyleType]) ],
      @([DividerStyle getStyleType]) : @[
        @([CheckBoxStyle getStyleType]), @([H1Style getStyleType]),
        @([H2Style getStyleType]), @([H3Style getStyleType]),
        @([H4Style getStyleType]), @([H5Style getStyleType]),
        @([H6Style getStyleType]), @([UnorderedListStyle getStyleType]),
        @([OrderedListStyle getStyleType]), @([BlockQuoteStyle getStyleType]),
        @([CodeBlockStyle getStyleType]), @([InlineCodeStyle getStyleType]),
        @([LinkStyle getStyleType]), @([MentionStyle getStyleType]),
        @([ContentStyle getStyleType])
      ],
      @([ContentStyle getStyleType]) : @[
        @([CheckBoxStyle getStyleType]), @([H1Style getStyleType]),
        @([H2Style getStyleType]), @([H3Style getStyleType]),
        @([H4Style getStyleType]), @([H5Style getStyleType]),
        @([H6Style getStyleType]), @([UnorderedListStyle getStyleType]),
        @([OrderedListStyle getStyleType]), @([BlockQuoteStyle getStyleType]),
        @([CodeBlockStyle getStyleType]), @([InlineCodeStyle getStyleType]),
        @([LinkStyle getStyleType]), @([MentionStyle getStyleType]),
        @([DividerStyle getStyleType])
      ]
    };
  });
  return blocking;
}

@end
