#pragma once
#import "EnrichedStyleHost.h"

NS_ASSUME_NONNULL_BEGIN

@interface EnrichedTextParseHost : NSObject <EnrichedStyleHost>

- (instancetype)initWithConfig:(InputConfig *)config
       defaultTypingAttributes:
           (NSDictionary<NSAttributedStringKey, id> *)defaultTypingAttributes;

// The host of the style on this thread, reused for its next texts: its styles
// cache what they build (e.g. the fonts of the headings), and aren't shared
// between threads
+ (instancetype)hostForCurrentThreadWithConfig:(InputConfig *)config
                       defaultTypingAttributes:
                           (NSDictionary<NSAttributedStringKey, id> *)
                               defaultTypingAttributes;

@end

NS_ASSUME_NONNULL_END
