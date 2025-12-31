#import "ImageAttachment.h"
#import "EnrichedImageLoader.h"

@implementation ImageAttachment

- (instancetype)initWithImageData:(ImageData *)data {
  self = [super initWithURI:data.uri width:data.width height:data.height];
  if (!self)
    return nil;

  _imageData = data;
  self.image = [UIImage new];

  [self loadAsync];
  return self;
}

- (void)loadAsync {
  NSURL *url = [NSURL URLWithString:self.uri];
  if (!url) {
    self.image = [UIImage systemImageNamed:@"file"];
    return;
  }

  [[EnrichedImageLoader shared] loadImage:url
                               completion:^(UIImage *img) {
                                 if (img) {
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                     self.image = img;
                                     [self notifyUpdate];
                                   });
                                 }
                               }];
}

@end
