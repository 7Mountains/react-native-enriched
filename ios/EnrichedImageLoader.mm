#import "EnrichedImageLoader.h"
#import "EnrichedCookieManager.h"
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
  if (!url) {
    completion(nil);
    return;
  }

  if (RCTIsLocalAssetURL(url)) {
    completion(RCTImageFromLocalAssetURL(url));
    return;
  }

  SDWebImageDownloaderRequestModifier *modifier =
      [SDWebImageDownloaderRequestModifier
          requestModifierWithBlock:^NSURLRequest *_Nullable(
              NSURLRequest *_Nonnull request) {
            NSMutableURLRequest *r = [request mutableCopy];

            NSString *cookie =
                [[EnrichedCookieManager shared] cookieHeaderForURL:request.URL];

            if (cookie.length) {
              [r setValue:cookie forHTTPHeaderField:@"Cookie"];
            }

            return r;
          }];

  SDWebImageContext *context =
      @{SDWebImageContextDownloadRequestModifier : modifier};

  [self.sdManager
      loadImageWithURL:url
               options:SDWebImageHighPriority
               context:context
              progress:nil
             completed:^(UIImage *_Nullable image, NSData *_Nullable data,
                         NSError *_Nullable error, SDImageCacheType cacheType,
                         BOOL finished, NSURL *_Nullable imageURL) {
               completion(image);
             }];
}

@end
