#import "EnrichedHtmlStyles.h"
#import "EnrichedHtmlStyleRegistry.h"

#import <react/utils/FollyConvert.h>

using namespace facebook::react;

@implementation EnrichedHtmlStyles

RCT_EXPORT_MODULE()

- (NSNumber *)registerHtmlStyle:(NSDictionary *)style {
  return @(
      EnrichedHtmlStyleRegistry::registerStyle(convertIdToFollyDynamic(style)));
}

- (std::shared_ptr<TurboModule>)getTurboModule:
    (const ObjCTurboModule::InitParams &)params {
  return std::make_shared<NativeEnrichedHtmlStylesSpecJSI>(params);
}

@end
