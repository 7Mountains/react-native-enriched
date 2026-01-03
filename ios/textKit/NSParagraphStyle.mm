#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@implementation NSParagraphStyle (AppSwizzle)

+ (void)load {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    Method original = class_getInstanceMethod(self, @selector(isEqual:));
    Method swizzled = class_getInstanceMethod(self, @selector(app_isEqual:));
    method_exchangeImplementations(original, swizzled);
  });
}

- (BOOL)app_isEqual:(id)object {
  BOOL selfIsBase = object_getClass(self) == NSParagraphStyle.class ||
                    object_getClass(self) == NSMutableParagraphStyle.class;

  BOOL objectIsBase = object_getClass(object) == NSParagraphStyle.class ||
                      object_getClass(object) == NSMutableParagraphStyle.class;

  if (selfIsBase && !objectIsBase) {
    return [object isEqual:self];
  }

  return [self app_isEqual:object];
}

@end
