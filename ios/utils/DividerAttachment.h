#import <UIKit/UIKit.h>

@interface DividerAttachment : NSTextAttachment
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) CGFloat thickness;
@property (nonatomic, assign) CGFloat paddingHorizontal;
@property (nonatomic, strong) NSMutableDictionary *imageCache;
@end
