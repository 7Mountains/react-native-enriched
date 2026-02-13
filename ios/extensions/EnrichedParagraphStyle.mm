#import "EnrichedParagraphStyle.h"
#import <objc/runtime.h>

@interface NSParagraphStyle (EnrichedSwizzle)
- (BOOL)enriched_isEqual:(id)object;
@end

@implementation EnrichedParagraphStyle

+ (void)initialize {
  if (self == [EnrichedParagraphStyle class]) {
    [self swizzleSuperclass];
  }
}

+ (void)swizzleSuperclass {
  Method original =
      class_getInstanceMethod([NSParagraphStyle class], @selector(isEqual:));
  Method swizzled = class_getInstanceMethod([NSParagraphStyle class],
                                            @selector(enriched_isEqual:));

  if (original && swizzled) {
    method_exchangeImplementations(original, swizzled);
  }
}

- (instancetype)init {
  self = [super init];
  if (self) {
    self.headingLevel = EnrichedHeadingNone;
  }
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  EnrichedParagraphStyle *copy = [[[self class] allocWithZone:zone] init];

  [copy setParagraphStyle:self];
  copy.headingLevel = self.headingLevel;

  return copy;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
  EnrichedParagraphStyle *copy = [[[self class] allocWithZone:zone] init];

  [copy setParagraphStyle:self];
  copy.headingLevel = self.headingLevel;

  return copy;
}

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:[EnrichedParagraphStyle class]]) {
    return NO;
  }

  EnrichedParagraphStyle *other = object;

  if (self.headingLevel != other.headingLevel) {
    return NO;
  }

  return [super isEqual:object];
}

- (NSUInteger)hash {
  return [super hash] ^ (NSUInteger)self.headingLevel;
}

@end
