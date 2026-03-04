#import "BaseImageAttachment.h"
#import "EnrichedImageLoader.h"

@implementation BaseImageAttachment {
  UIImage *_cachedImage;
  CGSize _cachedSize;
}

#pragma mark - NSTextAttachment

- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer
                      proposedLineFragment:(CGRect)lineFrag
                             glyphPosition:(CGPoint)position
                            characterIndex:(NSUInteger)charIndex {

  CGFloat padding = textContainer ? textContainer.lineFragmentPadding : 0;
  CGFloat width = lineFrag.size.width - padding * 2;

  return CGRectMake(0, 0, width, self.height);
}

#pragma mark - Rendering

- (UIImage *)imageForBounds:(CGRect)bounds
              textContainer:(NSTextContainer *)textContainer
             characterIndex:(NSUInteger)charIndex {

  if (!self.needsRedraw && _cachedImage &&
      CGSizeEqualToSize(bounds.size, _cachedSize)) {
    return _cachedImage;
  }

  UIGraphicsImageRendererFormat *format =
      [UIGraphicsImageRendererFormat defaultFormat];
  format.opaque = NO;

  UIGraphicsImageRenderer *renderer =
      [[UIGraphicsImageRenderer alloc] initWithSize:bounds.size format:format];

  UIImage *image =
      [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [self drawContentInBounds:bounds context:ctx.CGContext];
      }];

  _cachedImage = image;
  _cachedSize = bounds.size;
  self.needsRedraw = NO;

  return image;
}

#pragma mark - Cache

- (void)invalidateCache {
  _cachedImage = nil;
  self.needsRedraw = YES;
}

- (void)updateImage:(UIImage *)image {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.image = image;
    [self invalidateCache];
    [self notifyUpdate];
  });
}

#pragma mark - Image Loading

- (void)loadImageAsyncWithURI:(NSString *)uri {
  __weak __typeof__(self) weakSelf = self;

  if (!uri.length)
    return;

  NSURL *url = [NSURL URLWithString:uri];
  [[EnrichedImageLoader shared]
       loadImage:url
      completion:^(UIImage *img) {
        if (!img)
          return;

        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (!strongSelf)
          return;

        img ? [strongSelf updateImage:img] : [self loadFallbackAsync];
      }];
}

- (void)loadFallbackAsync {
  __weak __typeof__(self) weakSelf = self;
  if (!_fallbackUri)
    return;

  NSURL *url = [NSURL URLWithString:_fallbackUri];

  [[EnrichedImageLoader shared] loadImage:url
                               completion:^(UIImage *img) {
                                 if (!img)
                                   return;
                                 __strong __typeof__(weakSelf) strongSelf =
                                     weakSelf;
                                 if (!strongSelf)
                                   return;
                                 [strongSelf updateImage:img];
                               }];
}

#pragma mark - Override

- (void)drawContentInBounds:(CGRect)bounds context:(CGContextRef)ctx {
  // subclasses override
}

@end
