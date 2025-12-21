#import <UIKit/UIKit.h>

@interface AlignmentConverter : NSObject
+ (NSTextAlignment)alignmentFromString:(NSString *)string;
+ (NSString *)stringFromAlignment:(NSTextAlignment)alignment;
@end
