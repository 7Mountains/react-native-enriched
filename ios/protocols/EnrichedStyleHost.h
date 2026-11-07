#pragma once
#import "MediaAttachment.h"
#import <UIKit/UIKit.h>

@class InputConfig;

// What the styles read from their host while they build an attributed string
// from HTML or draw it (see LayoutManagerExtension): the input, or a
// read-only text (EnrichedTextView, and the host of its parsing off the main
// thread, without a text view)
@protocol EnrichedStyleHost <MediaAttachmentDelegate>
@property(nonatomic, readonly, nullable) UITextView *textView;
@property(nonatomic, readonly, nullable) InputConfig *config;
@property(nonatomic, readonly, nullable)
    NSDictionary<NSAttributedStringKey, id> *defaultTypingAttributes;
@property(nonatomic, readonly, nullable)
    NSDictionary<NSNumber *, id> *stylesDict;
@end
