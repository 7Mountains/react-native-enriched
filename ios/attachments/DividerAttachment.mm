#import "DividerAttachment.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@implementation DividerAttachment {
  UIColor *_color;
  CGFloat _height;
  CGFloat _thickness;
  CGFloat _paddingHorizontal;
}

- (instancetype)initWithStyles:(UIColor *)color
                        height:(CGFloat)height
                     thickness:(CGFloat)thickness {
  self = [super init];
  if (self) {
    _color = color ?: [UIColor grayColor];
    _height = height ?: 20.0;
    _thickness = thickness ?: 2.0;
  }

  return self;
};

- (instancetype)init {
  self = [super init];
  if (self) {
    _color = [UIColor grayColor];
    _height = 20.0;
    _thickness = 2.0;
  }
  return self;
}

- (UIImage *)imageForBounds:(CGRect)bounds
              textContainer:(NSTextContainer *)textContainer
             characterIndex:(NSUInteger)charIndex {
  CGFloat width = bounds.size.width;
  CGFloat height = bounds.size.height;

  UIImage *generated = [self drawDividerWithWidth:width height:height];

  return generated;
}

- (UIImage *)drawDividerWithWidth:(CGFloat)width height:(CGFloat)height {
  if (width <= 0 || height <= 0)
    return nil;

  UIGraphicsImageRenderer *renderer =
      [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(width, height)];

  return [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
    [_color setStroke];
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.lineWidth = _thickness;
    CGFloat centerY = height / 2.0;
    [path moveToPoint:CGPointMake(0, centerY)];
    [path addLineToPoint:CGPointMake(width, centerY)];
    [path stroke];
  }];
}

- (void)setDividerColor:(UIColor *)color {
  _color = color;
}

- (void)setDividerHeight:(CGFloat)height {
  _height = height;
}

- (void)setDividerThickness:(CGFloat)thickness {
  _thickness = thickness;
}

- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer
                      proposedLineFragment:(CGRect)lineFrag
                             glyphPosition:(CGPoint)position
                            characterIndex:(NSUInteger)charIndex {
  CGFloat padding = textContainer ? textContainer.lineFragmentPadding : 0.0;
  CGFloat width = lineFrag.size.width - padding * 2;

  return CGRectMake(0, 0, width, _height);
}

@end
