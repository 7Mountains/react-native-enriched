#pragma once
#import <UIKit/UIKit.h>
#import <react/renderer/components/RNEnrichedTextInputViewSpec/EventEmitters.h>

NS_ASSUME_NONNULL_BEGIN

@interface EnrichedScrollEventPayloadBuilder : NSObject

+ (const facebook::react::EnrichedTextInputViewEventEmitter::OnInputScroll)
    buildFromScrollView:(UIScrollView *)scrollView
                 target:(NSNumber *)reactTag;

@end

NS_ASSUME_NONNULL_END
