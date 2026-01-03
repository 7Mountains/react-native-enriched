#import "EnrichedParagraphStyle.h"

@implementation EnrichedParagraphStyle

#pragma mark - Copying (CRITICAL)

- (id)copyWithZone:(NSZone *)zone {
  EnrichedParagraphStyle *copy = [[[self class] allocWithZone:zone] init];
  [copy setParagraphStyle:self]; // copy all fields
  copy.headingLevel = self.headingLevel;
  return copy;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
  EnrichedParagraphStyle *copy = [[[self class] allocWithZone:zone] init];
  [copy setParagraphStyle:self];
  copy.headingLevel = self.headingLevel;
  return copy;
}

#pragma mark - Equality (CRITICAL)

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[EnrichedParagraphStyle class]]) {
    return NO;
  }

  EnrichedParagraphStyle *other = object;

  if ((self.headingLevel || other.headingLevel) &&
      ![self.headingLevel isEqual:other.headingLevel]) {
    return NO;
  }

  return [super isEqual:object];
}

- (NSUInteger)hash {
  return [super hash] ^ self.headingLevel.hash;
}

@end
