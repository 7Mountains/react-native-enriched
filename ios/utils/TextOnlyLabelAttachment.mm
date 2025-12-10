#import "TextOnlyLabelAttachment.h"

@implementation TextOnlyLabelAttachment

- (instancetype)init {
  self = [super init];
  if (!self)
    return nil;

  _centerText = YES;
  return self;
}

#pragma mark - RENDER

- (UIImage *)renderAttachmentInSize:(CGSize)containerSize {

  CGSize textSize = [self textSize];

  CGSize totalSize =
      CGSizeMake(containerSize.width + self.margin.left + self.margin.right,
                 textSize.height + self.inset.top + self.inset.bottom +
                     self.margin.top + self.margin.bottom);

  UIGraphicsBeginImageContextWithOptions(totalSize, NO, 0.0);
  CGContextRef ctx = UIGraphicsGetCurrentContext();

  CGRect contentRect = [self contentRectForContainer:totalSize];

  // background
  [self drawBackgroundInRect:contentRect context:ctx];

  // border
  [self drawBorderInRect:contentRect context:ctx];

  // text
  CGFloat textX = contentRect.origin.x + self.inset.left;
  CGFloat textW = contentRect.size.width - self.inset.left - self.inset.right;

  if (self.centerText) {
    // center horizontally
    NSDictionary *attrs = @{NSFontAttributeName : self.font};
    CGFloat textActualWidth = [self.labelText sizeWithAttributes:attrs].width;

    textX =
        contentRect.origin.x + (contentRect.size.width - textActualWidth) / 2.0;
    textW = textActualWidth;
  }

  CGRect textRect = CGRectMake(textX, contentRect.origin.y + self.inset.top,
                               textW, textSize.height);

  [self.labelText drawInRect:textRect
              withAttributes:@{
                NSFontAttributeName : self.font,
                NSForegroundColorAttributeName : self.textColor
              }];

  UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return img;
}

#pragma mark - SIZE

- (CGSize)requiredSizeForLineFragment:(CGSize)lineSize {
  CGSize textSize = [self textSize];

  return CGSizeMake(lineSize.width, textSize.height + self.inset.top +
                                        self.inset.bottom + self.margin.top +
                                        self.margin.bottom);
}

@end
