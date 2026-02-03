#import "ImageLayoutUtils.h"

@implementation ImageLayoutUtils

+ (ImageResizeMode)resizeModeFromString:(NSString *)name {
  NSString *mode = name.lowercaseString;

  if ([mode isEqualToString:@"cover"])
    return ImageResizeModeCover;
  if ([mode isEqualToString:@"contain"])
    return ImageResizeModeContain;
  if ([mode isEqualToString:@"fill"])
    return ImageResizeModeFill;
  if ([mode isEqualToString:@"stretch"])
    return ImageResizeModeFill;
  if ([mode isEqualToString:@"none"])
    return ImageResizeModeNone;
  if ([mode isEqualToString:@"center"])
    return ImageResizeModeNone;
  if ([mode isEqualToString:@"scale-down"])
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
