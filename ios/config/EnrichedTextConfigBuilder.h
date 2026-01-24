#import <Foundation/Foundation.h>

@class InputConfig;

namespace facebook {
namespace react {
struct EnrichedTextInputViewProps;
}
} // namespace facebook

@interface EnrichedTextConfigBuilder : NSObject

+ (InputConfig *)
    makeConfigFromProps:
        (const facebook::react::EnrichedTextInputViewProps &)newViewProps
           oldViewProps:
               (const facebook::react::EnrichedTextInputViewProps &)oldViewProps
         previousConfig:(InputConfig *)previousConfig;

@end
