#import <UIKit/UIKit.h>
#import <SDWebImage/SDWebImage.h>

@interface EnrichedImageLoader : NSObject
@property (nonatomic, strong) SDWebImageManager *sdManager;
+ (instancetype)shared;
- (void)loadImage:(NSURL *)url completion:(void (^)(UIImage *))completion;
- (void)loadImage:(NSURL *)url
          headers:(NSDictionary<NSString *, NSString *> *)headers
       completion:(void (^)(UIImage *image))completion;
@end
