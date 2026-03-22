#pragma once
#import <UIKit/UIKit.h>
#import <react/renderer/components/RNEnrichedTextInputViewSpec/EventEmitters.h>

@interface EnrichedSelectionEventPayloadBuilder : NSObject

+ (const facebook::react::EnrichedTextInputViewEventEmitter::OnChangeSelection)
    buildFromTextView:(UITextView *)textView;

@end
