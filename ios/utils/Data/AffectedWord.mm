#import "AffectedWord.h"

@implementation AffectedWord

- (instancetype)initWithText:(NSString *)text range:(NSRange)range {
  self = [super init];
  if (!self)
    return nil;

  _text = text;
  _range = range;

  return self;
}

@end
