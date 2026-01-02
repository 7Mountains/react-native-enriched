#import <UIKit/UIKit.h>

@interface DividerAttachment : NSTextAttachment
- (instancetype)initWithStyles:(UIColor *)color
                        height:(CGFloat)height
                     thickness:(CGFloat)thickness;
@end
