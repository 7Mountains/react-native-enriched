#pragma once
#import "EnrichedStyleHost.h"

NS_ASSUME_NONNULL_BEGIN

@interface EnrichedTextParseHost : NSObject <EnrichedStyleHost>

- (instancetype)initWithConfig:(InputConfig *)config
       defaultTypingAttributes:
           (NSDictionary<NSAttributedStringKey, id> *)defaultTypingAttributes;

@end

NS_ASSUME_NONNULL_END
