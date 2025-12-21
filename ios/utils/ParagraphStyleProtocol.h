#import "BaseStyleProtocol.h"

@protocol ParagraphStyleProtocol <BaseStyleProtocol>
@optional
+ (NSDictionary<NSString *, NSString *> *)getParametersFromValue:
    (id _Nullable)value;
@end
