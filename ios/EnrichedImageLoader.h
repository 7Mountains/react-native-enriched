#import <SDWebImage/SDWebImage.h>
#import <UIKit/UIKit.h>

@interface EnrichedImageLoader : NSObject
@property(nonatomic, strong) SDWebImageManager *sdManager;
+ (instancetype)shared;
- (void)loadImage:(NSURL *)url completion:(void (^)(UIImage *))completion;
@end
