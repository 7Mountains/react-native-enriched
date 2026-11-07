#pragma once
#import "EnrichedStyleHost.h"
#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Shows the HTML of the input, read-only: the text is built and measured by
// the shadow node, off the main thread, and comes with the state
@interface EnrichedTextView : RCTViewComponentView <EnrichedStyleHost>
@end

NS_ASSUME_NONNULL_END
