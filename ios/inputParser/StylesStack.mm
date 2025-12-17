#import "StylesStack.h"

@interface StylesStack ()
@property(nonatomic, strong) NSMutableArray<StyleContext *> *stack;
@end

@implementation StylesStack

- (instancetype)init {
  if (!(self = [super init]))
    return nil;

  _stack = [NSMutableArray new];
  return self;
}

- (void)pushStyle:(id<BaseStyleProtocol>)style
       attributes:(NSDictionary *)attributes {
  StyleContext *ctx = [StyleContext new];
  ctx.style = style;
  ctx.attributes = attributes ?: @{};
  [_stack addObject:ctx];
}

- (void)popStyle:(id<BaseStyleProtocol>)style {
  for (NSInteger i = _stack.count - 1; i >= 0; i--) {
    if (_stack[i].style == style) {
      [_stack removeObjectAtIndex:i];
      return;
    }
  }
}

- (void)applyStylesToAttributedString:(NSMutableAttributedString *)string
                                range:(NSRange)range {
  for (StyleContext *ctx in _stack) {
    [ctx.style addAttributesInAttributedString:string
                                         range:range
                                    attributes:ctx.attributes];
  }
}

@end
