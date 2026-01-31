#import "EnrichedCommandHandler.h"
#import "ColorExtension.h"
#import "EnrichedTextInputView+Commands.h"
#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

static inline void RunOnMainThread(void (^block)(void)) {
  if ([NSThread isMainThread]) {
    block();
  } else {
    dispatch_sync(dispatch_get_main_queue(), block);
  }
}

@implementation EnrichedCommandHandler {
  __weak EnrichedTextInputView *_input;
}

- (instancetype)initWithInput:(EnrichedTextInputView *)input {
  if (self = [super init]) {
    _input = input;
  }
  return self;
}

- (void)handleCommand:(NSString *)commandName args:(NSArray *)args {
  if (!_input)
    return;

  if ([commandName isEqualToString:@"focus"]) {
    [_input focus];

  } else if ([commandName isEqualToString:@"blur"]) {
    [_input blur];

  } else if ([commandName isEqualToString:@"setValue"]) {
    NSString *value = args[0];
    [_input setValue:value];

  } else if ([commandName isEqualToString:@"toggleBold"]) {
    [_input toggleRegularStyle:[BoldStyle getStyleType]];

  } else if ([commandName isEqualToString:@"toggleItalic"]) {
    [_input toggleRegularStyle:[ItalicStyle getStyleType]];

  } else if ([commandName isEqualToString:@"toggleUnderline"]) {
    [_input toggleRegularStyle:[UnderlineStyle getStyleType]];

  } else if ([commandName isEqualToString:@"toggleStrikeThrough"]) {
    [_input toggleRegularStyle:[StrikethroughStyle getStyleType]];

  } else if ([commandName isEqualToString:@"setColor"]) {
    NSString *colorText = args[0];
    [_input setColor:colorText];

  } else if ([commandName isEqualToString:@"removeColor"]) {
    [_input removeColor];

  } else if ([commandName isEqualToString:@"toggleInlineCode"]) {
    [_input toggleRegularStyle:[InlineCodeStyle getStyleType]];

  } else if ([commandName isEqualToString:@"addLink"]) {
    NSInteger start = [args[0] integerValue];
    NSInteger end = [args[1] integerValue];
    NSString *text = args[2];
    NSString *url = args[3];
    [_input addLinkAt:start end:end text:text url:url];

  } else if ([commandName isEqualToString:@"addMention"]) {
    [_input addMention:args[0] text:args[1] attributes:args[2]];

  } else if ([commandName isEqualToString:@"startMention"]) {
    [_input startMentionWithIndicator:args[0]];

  } else if ([commandName isEqualToString:@"toggleH1"]) {
    [_input toggleParagraphStyle:[H1Style getStyleType]];

  } else if ([commandName isEqualToString:@"toggleH2"]) {
    [_input toggleParagraphStyle:[H2Style getStyleType]];

  } else if ([commandName isEqualToString:@"toggleH3"]) {
    [_input toggleParagraphStyle:[H3Style getStyleType]];

  } else if ([commandName isEqualToString:@"toggleH4"]) {
    [_input toggleParagraphStyle:[H4Style getStyleType]];

  } else if ([commandName isEqualToString:@"toggleH5"]) {
    [_input toggleParagraphStyle:[H5Style getStyleType]];

  } else if ([commandName isEqualToString:@"toggleH6"]) {
    [_input toggleParagraphStyle:[H6Style getStyleType]];

  } else if ([commandName isEqualToString:@"toggleUnorderedList"]) {
    [_input toggleParagraphStyle:[UnorderedListStyle getStyleType]];

  } else if ([commandName isEqualToString:@"toggleOrderedList"]) {
    [_input toggleParagraphStyle:[OrderedListStyle getStyleType]];

  } else if ([commandName isEqualToString:@"toggleBlockQuote"]) {
    [_input toggleParagraphStyle:[BlockQuoteStyle getStyleType]];

  } else if ([commandName isEqualToString:@"toggleCodeBlock"]) {
    [_input toggleParagraphStyle:[CodeBlockStyle getStyleType]];

  } else if ([commandName isEqualToString:@"addImage"]) {
    [_input addImage:args[0]
               width:[args[1] floatValue]
              height:[args[2] floatValue]];

  } else if ([commandName isEqualToString:@"setSelection"]) {
    [_input setCustomSelection:[args[0] integerValue]
                           end:[args[1] integerValue]];

  } else if ([commandName isEqualToString:@"requestHTML"]) {
    [_input requestHTML:[args[0] integerValue] prettify:[args[1] boolValue]];

  } else if ([commandName isEqualToString:@"toggleCheckList"]) {
    [_input toggleParagraphStyle:[CheckBoxStyle getStyleType]];

  } else if ([commandName isEqualToString:@"addDividerAtNewLine"]) {
    [_input addDividerAtNewLine];

  } else if ([commandName isEqualToString:@"setParagraphAlignment"]) {
    [_input setParagraphAlignment:args[0]];
    [_input anyTextMayHaveBeenModified];
  } else if ([commandName isEqualToString:@"addContent"]) {
    ContentParams *params = [ContentParams paramsFromArgs:args];
    if (params) {
      [_input addContent:params];
    }
  } else if ([commandName isEqualToString:@"scrollTo"]) {
    CGFloat x = [args[0] floatValue];
    CGFloat y = [args[1] floatValue];
    BOOL animated = [args[2] boolValue];

    RunOnMainThread(^{
      UIScrollView *scrollView = self->_input->textView;

      UIEdgeInsets inset = scrollView.contentInset;
      CGSize contentSize = scrollView.contentSize;
      CGSize boundsSize = scrollView.bounds.size;

      CGFloat minX = -inset.left;
      CGFloat minY = -inset.top;

      CGFloat maxX = contentSize.width - boundsSize.width + inset.right;
      CGFloat maxY = contentSize.height - boundsSize.height + inset.bottom;

      maxX = MAX(minX, maxX);
      maxY = MAX(minY, maxY);

      CGFloat clampedX = MIN(MAX(x, minX), maxX);
      CGFloat clampedY = MIN(MAX(y, minY), maxY);

      [scrollView setContentOffset:CGPointMake(clampedX, clampedY)
                          animated:animated];
    });
  }
}

@end
