#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@implementation NSParagraphStyle (EnrichedSwizzle)

- (BOOL)enriched_isEqual:(id)object {
  BOOL selfIsStandard =
      object_getClass(self) == [NSParagraphStyle class] ||
      object_getClass(self) == [NSMutableParagraphStyle class];

  BOOL objectIsStandard =
      object_getClass(object) == [NSParagraphStyle class] ||
      object_getClass(object) == [NSMutableParagraphStyle class];

  if (selfIsStandard && !objectIsStandard) {
    return [object isEqual:self];
  }

  return [self enriched_isEqual:object];
}

@end
