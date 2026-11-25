#import "EnrichedTextSizeCache.h"

#import <CoreText/CoreText.h>
#import <Foundation/Foundation.h>

namespace facebook::react {

EnrichedTextMeasureCache<Size> &EnrichedTextSizeCache() {
  // Never destroyed: read by the shadow nodes until the app exits
  static auto *cache = new EnrichedTextMeasureCache<Size>();
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    [NSNotificationCenter.defaultCenter
        addObserverForName:(NSNotificationName)
                               kCTFontManagerRegisteredFontsChangedNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *notification) {
                  cache->clear();
                }];
  });
  return *cache;
}

} // namespace facebook::react
