#import "ImageLayoutUtils.h"
#import <UIKit/UIKit.h>

#pragma mark - Enums

typedef NS_ENUM(uint8_t, BorderStyle) {
  BorderStyleSolid = 0,
  BorderStyleDashed,
  BorderStyleDotted,
};

#pragma mark - Parsers

static inline BorderStyle ParseBorderStyle(NSString *styleString) {
  if (!styleString)
    return BorderStyleSolid;
  if ([styleString isEqualToString:@"dashed"])
    return BorderStyleDashed;
  if ([styleString isEqualToString:@"dotted"])
    return BorderStyleDotted;
  return BorderStyleSolid;
}

static inline ImageResizeMode ParseResizeMode(NSString *s) {
  return [ImageLayoutUtils resizeModeFromString:s];
}

#pragma mark - Geometry helpers

static inline CGFloat ResolveSize(CGFloat value, CGFloat fallback) {
  return value > 0 ? value : fallback;
}

static inline CGFloat PixelAlign(CGFloat v) {
  CGFloat scale = UIScreen.mainScreen.scale;
  return round(v * scale) / scale;
}

static inline CGRect ContentRect(CGRect bounds, UIEdgeInsets margin) {
  return CGRectMake(margin.left, margin.top,
                    bounds.size.width - margin.left - margin.right,
                    bounds.size.height - margin.top - margin.bottom);
}

#pragma mark - Text

static inline NSDictionary *MakeTextAttributes(UIFont *font, UIColor *color) {
  return @{NSFontAttributeName : font, NSForegroundColorAttributeName : color};
}

static inline CGFloat TextHeight(NSString *text, UIFont *font) {
  return [text sizeWithAttributes:@{NSFontAttributeName : font}].height;
}

#pragma mark - Clip path

static inline UIBezierPath *
MakeImageClipPath(CGRect rect, CGFloat topLeftRadius, CGFloat topRightRadius,
                  CGFloat bottomLeftRadius, CGFloat bottomRightRadius) {
  UIBezierPath *path = [UIBezierPath bezierPath];

  CGFloat minX = CGRectGetMinX(rect);
  CGFloat minY = CGRectGetMinY(rect);
  CGFloat maxX = CGRectGetMaxX(rect);
  CGFloat maxY = CGRectGetMaxY(rect);

  [path moveToPoint:CGPointMake(minX + topLeftRadius, minY)];

  [path addLineToPoint:CGPointMake(maxX - topRightRadius, minY)];
  if (topRightRadius > 0)
    [path addArcWithCenter:CGPointMake(maxX - topRightRadius,
                                       minY + topRightRadius)
                    radius:topRightRadius
                startAngle:-M_PI_2
                  endAngle:0
                 clockwise:YES];

  [path addLineToPoint:CGPointMake(maxX, maxY - bottomRightRadius)];
  if (bottomRightRadius > 0)
    [path addArcWithCenter:CGPointMake(maxX - bottomRightRadius,
                                       maxY - bottomRightRadius)
                    radius:bottomRightRadius
                startAngle:0
                  endAngle:M_PI_2
                 clockwise:YES];

  [path addLineToPoint:CGPointMake(minX + bottomLeftRadius, maxY)];
  if (bottomLeftRadius > 0)
    [path addArcWithCenter:CGPointMake(minX + bottomLeftRadius,
                                       maxY - bottomLeftRadius)
                    radius:bottomLeftRadius
                startAngle:M_PI_2
                  endAngle:M_PI
                 clockwise:YES];

  [path addLineToPoint:CGPointMake(minX, minY + topLeftRadius)];
  if (topLeftRadius > 0)
    [path
        addArcWithCenter:CGPointMake(minX + topLeftRadius, minY + topLeftRadius)
                  radius:topLeftRadius
              startAngle:M_PI
                endAngle:3 * M_PI_2
               clockwise:YES];

  [path closePath];
  return path;
}

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

static inline CGRect ImageRect(CGRect contentRect, CGFloat imageWidth,
                               CGFloat imageHeight) {
  CGFloat w = imageWidth > 0 ? imageWidth : contentRect.size.width * 0.3;
  CGFloat h = imageHeight > 0 ? imageHeight : contentRect.size.height;

  CGFloat y = contentRect.origin.y + (contentRect.size.height - h) * 0.5;

  return CGRectMake(contentRect.origin.x, y, w, h);
}

static inline void ApplyBorderStyle(UIBezierPath *path, BorderStyle style) {
  switch (style) {
  case BorderStyleDashed: {
    CGFloat dash[] = {6, 3};
    [path setLineDash:dash count:2 phase:0];
    break;
  }
  case BorderStyleDotted: {
    CGFloat dot[] = {2, 2};
    [path setLineDash:dot count:2 phase:0];
    break;
  }
  default:
    break;
  }
}

static inline void ApplyBorderStyleCG(CGContextRef ctx, BorderStyle style) {
  switch (style) {
  case BorderStyleDashed: {
    CGFloat dashes[] = {6.0, 3.0};
    CGContextSetLineDash(ctx, 0, dashes, 2);
    break;
  }
  case BorderStyleDotted: {
    CGFloat dashes[] = {2.0, 2.0};
    CGContextSetLineDash(ctx, 0, dashes, 2);
    break;
  }
  default:
    // solid
    CGContextSetLineDash(ctx, 0, NULL, 0);
    break;
  }
}
