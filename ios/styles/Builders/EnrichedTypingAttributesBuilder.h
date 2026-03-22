#pragma once

@class InputConfig;

namespace facebook {
namespace react {
struct EnrichedTextInputViewProps;
}
} // namespace facebook

@interface EnrichedTypingAttributesBuilder : NSObject

+ (NSDictionary<NSAttributedStringKey, id> *)
    buildWithConfig:(InputConfig *)config
              props:(const facebook::react::EnrichedTextInputViewProps &)props;

@end
