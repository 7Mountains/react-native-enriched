#pragma once
#import <UIKit/UIKit.h>

@interface AttachmentInvalidationBatcher : NSObject
- (instancetype)initWithTextView:(UITextView *)textView;
- (void)enqueueAttachment:(NSTextAttachment *)attachment;
@end
