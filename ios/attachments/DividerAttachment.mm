#import "DividerAttachment.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@implementation DividerAttachment

- (instancetype)init {
  self = [super init];
  if (self) {
    _color = [UIColor grayColor];
    _height = 20.0;
    _thickness = 2.0;
    _imageCache = [NSMutableDictionary new];
  }
  return self;
}

- (UIImage *)imageForBounds:(CGRect)bounds
              textContainer:(NSTextContainer *)textContainer
             characterIndex:(NSUInteger)charIndex {
  CGFloat width = bounds.size.width;
  CGFloat height = bounds.size.height;

  NSNumber *cacheKey = @(width);

  UIImage *cached = self.imageCache[cacheKey];
  if (cached) {
    return cached;
  }

  UIImage *generated = [self drawDividerWithWidth:width height:height];
  self.imageCache[cacheKey] = generated;

  return generated;
}

- (UIImage *)drawDividerWithWidth:(CGFloat)width height:(CGFloat)height {
  if (width <= 0 || height <= 0)
    return nil;

  UIGraphicsImageRenderer *renderer =
      [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(width, height)];

  return [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
    [self.color setStroke];
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.lineWidth = self.thickness;
    CGFloat centerY = height / 2.0;
    [path moveToPoint:CGPointMake(0, centerY)];
    [path addLineToPoint:CGPointMake(width, centerY)];
    [path stroke];
  }];
}

#pragma mark - Cache invalidation when style changes

- (void)setDividerColor:(UIColor *)color {
  _color = color;
  [self.imageCache removeAllObjects];
}

- (void)setDividerHeight:(CGFloat)height {
  _height = height;
  [self.imageCache removeAllObjects];
}

- (void)setDividerThickness:(CGFloat)thickness {
  _thickness = thickness;
  [self.imageCache removeAllObjects];
}

#pragma mark - Attachment size

- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer
                      proposedLineFragment:(CGRect)lineFrag
                             glyphPosition:(CGPoint)position
                            characterIndex:(NSUInteger)charIndex {
  CGFloat padding = textContainer ? textContainer.lineFragmentPadding : 0.0;
  CGFloat width = lineFrag.size.width - padding * 2;

  return CGRectMake(0, 0, width, _height);
}

@end
