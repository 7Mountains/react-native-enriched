#pragma once
#import <UIKit/UIKit.h>

static UIImage *MakeLoaderImage(void) {
  static UIImage *image;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    CGSize size = CGSizeMake(40, 40);

    UIGraphicsImageRenderer *renderer =
        [[UIGraphicsImageRenderer alloc] initWithSize:size];

    image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
      [[UIColor colorWithWhite:0.7 alpha:1.0] setFill];
      UIRectFill(CGRectMake(0, 0, size.width, size.height));
    }];
  });

  return image;
}
