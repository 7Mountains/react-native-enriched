#import "EnrichedPreparedText.h"
#import "InputConfig.h"

@implementation EnrichedPreparedText

- (instancetype)initWithText:(NSAttributedString *)text
                      config:(InputConfig *)config {
  if (self = [super init]) {
    _text = text;
    _config = config;
  }
  return self;
}

@end
