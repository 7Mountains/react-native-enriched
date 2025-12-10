#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ImageResizeMode) {
  ImageResizeModeCover = 0,
  ImageResizeModeContain,
  ImageResizeModeFill,
  ImageResizeModeNone,
  ImageResizeModeScaleDown,
  ImageResizeModeInvalid
};

@interface ImageLayoutUtils : NSObject

+ (ImageResizeMode)resizeModeFromString:(NSString *)name;

+ (CGRect)rectForImage:(UIImage *)image
                inRect:(CGRect)slot
            resizeMode:(ImageResizeMode)mode;

@end
