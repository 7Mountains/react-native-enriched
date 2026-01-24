#import <Foundation/Foundation.h>

@class EnrichedTextInputView;

@interface EnrichedTextStyleFactory : NSObject

+ (NSDictionary<NSNumber *, id> *)makeStylesWithInput:
    (EnrichedTextInputView *)input;
+ (NSDictionary<NSNumber *, NSArray<NSNumber *> *> *)makeConflictingStyles;
+ (NSDictionary<NSNumber *, NSArray<NSNumber *> *> *)makeBlockingStyles;

@end
