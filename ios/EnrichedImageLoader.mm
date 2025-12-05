#import "EnrichedImageLoader.h"
#import <React/RCTUtils.h>

@implementation EnrichedImageLoader
+ (instancetype)shared {
    static EnrichedImageLoader *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [self new];
        shared.sdManager = [SDWebImageManager sharedManager];
    });
    return shared;
}

- (void)loadImage:(NSURL *)url completion:(void (^)(UIImage *))completion {
    if (!url) { completion(nil); return; }
  
    if (RCTIsLocalAssetURL(url)) {
        completion(RCTImageFromLocalAssetURL(url));
        return;
    }

    [self.sdManager loadImageWithURL:url
                              options:SDWebImageHighPriority
                             progress:nil
                            completed:^(UIImage * _Nullable image,
                                        NSData * _Nullable data,
                                        NSError * _Nullable error,
                                        SDImageCacheType cacheType,
                                        BOOL finished,
                                        NSURL * _Nullable imageURL) {
        completion(image);
    }];
}
// Since we use claudfron urls we have to make a request with claudfront headers
- (void)loadImage:(NSURL *)url
          headers:(NSDictionary<NSString *, NSString *> *)headers
       completion:(void (^)(UIImage *image))completion
{
    if (!url) { completion(nil); return; }

    SDWebImageDownloaderRequestModifier *requestModifier =
      [SDWebImageDownloaderRequestModifier requestModifierWithBlock:^NSURLRequest * _Nullable(NSURLRequest * _Nonnull request) {

        NSMutableURLRequest *modifiedRequest = [request mutableCopy];
        for (NSString *key in headers) {
            [modifiedRequest setValue:headers[key] forHTTPHeaderField:key];
        }
        return modifiedRequest;
    }];

    SDWebImageContext *context = @{
      SDWebImageContextDownloadRequestModifier : requestModifier
    };

    [self.sdManager loadImageWithURL:url
                              options:SDWebImageHighPriority
                              context:context
                             progress:nil
                            completed:^(UIImage * _Nullable image,
                                        NSData * _Nullable data,
                                        NSError * _Nullable error,
                                        SDImageCacheType cacheType,
                                        BOOL finished,
                                        NSURL * _Nullable imageURL)
    {
        completion(image);
    }];
}

@end
