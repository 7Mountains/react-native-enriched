#import "MediaAttachment.h"
#import <UIKit/UIKit.h>

@class ContentParams, ContentStyleProps;

@interface BaseLabelAttachment : MediaAttachment
- (instancetype)initWithParams:(ContentParams *)params
                        styles:(ContentStyleProps *)styles;
@end
