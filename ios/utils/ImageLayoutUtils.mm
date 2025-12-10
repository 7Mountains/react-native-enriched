#import "ImageLayoutUtils.h"

@implementation ImageLayoutUtils

+ (ImageResizeMode)resizeModeFromString:(NSString *)name {
  NSString *m = name.lowercaseString;

  if ([m isEqualToString:@"cover"])
    return ImageResizeModeCover;
  if ([m isEqualToString:@"contain"])
    return ImageResizeModeContain;
  if ([m isEqualToString:@"fill"])
    return ImageResizeModeFill;
  if ([m isEqualToString:@"stretch"])
    return ImageResizeModeFill;
  if ([m isEqualToString:@"none"])
    return ImageResizeModeNone;
  if ([m isEqualToString:@"center"])
    return ImageResizeModeNone;
  if ([m isEqualToString:@"scale-down"])
    return ImageResizeModeScaleDown;

  return ImageResizeModeInvalid;
}

+ (CGRect)rectForImage:(UIImage *)image
                inRect:(CGRect)slot
            resizeMode:(ImageResizeMode)mode {
  CGSize img = image.size;
  CGFloat slotW = slot.size.width;
  CGFloat slotH = slot.size.height;

  CGFloat scaleW = slotW / img.width;
  CGFloat scaleH = slotH / img.height;

  switch (mode) {

  case ImageResizeModeContain: {
    CGFloat scale = MIN(scaleW, scaleH);
    CGFloat w = img.width * scale;
    CGFloat h = img.height * scale;
    return CGRectMake(slot.origin.x + (slotW - w) / 2,
                      slot.origin.y + (slotH - h) / 2, w, h);
  }

  case ImageResizeModeCover: {
    CGFloat scale = MAX(scaleW, scaleH);
    CGFloat w = img.width * scale;
    CGFloat h = img.height * scale;
    return CGRectMake(slot.origin.x + (slotW - w) / 2,
                      slot.origin.y + (slotH - h) / 2, w, h);
  }

  case ImageResizeModeFill:
    return slot;

  case ImageResizeModeNone:
    return CGRectMake(slot.origin.x + (slotW - img.width) / 2,
                      slot.origin.y + (slotH - img.height) / 2, img.width,
                      img.height);

  case ImageResizeModeScaleDown: {
    CGFloat scale = MIN(1.0, MIN(scaleW, scaleH));
    CGFloat w = img.width * scale;
    CGFloat h = img.height * scale;
    return CGRectMake(slot.origin.x + (slotW - w) / 2,
                      slot.origin.y + (slotH - h) / 2, w, h);
  }

  default:
    return slot;
  }
}

@end
