#pragma once
#import <UIKit/UIKit.h>
#import <react/renderer/components/RNEnrichedTextInputViewSpec/EventEmitters.h>

NS_ASSUME_NONNULL_BEGIN

@interface EnrichedKeyPressEventPayloadBuilder : NSObject

+ (const facebook::react::EnrichedTextInputViewEventEmitter::OnInputKeyPress)
    buildFromTextView:(UITextView *)textView
                  key:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
