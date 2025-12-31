#import "BaseLabelAttachment.h"

@interface BaseLabelAttachment ()
@property(nonatomic) CGSize lastRenderedSize;
@property(nonatomic) CGSize cachedTextSize;
@end

@implementation BaseLabelAttachment

- (instancetype)init {
  self = [super init];
  if (!self)
    return nil;

  _labelText = @"";
  _font = [UIFont systemFontOfSize:14];
  _textColor = UIColor.whiteColor;

  _inset = UIEdgeInsetsMake(10, 12, 10, 12);
  _margin = UIEdgeInsetsMake(6, 0, 6, 0);

  _bgColor = UIColor.clearColor;
  _cornerRadius = 8.0;

  _borderColor = UIColor.separatorColor;
  _borderWidth = 0.0;
  _borderStyle = @"solid";

  _lastRenderedSize = CGSizeZero;

  return self;
}

#pragma mark - Shared helpers

- (CGSize)textSize {
  NSDictionary *attrs = @{NSFontAttributeName : self.font};
  return [self.labelText sizeWithAttributes:attrs];
}

- (CGRect)contentRectForContainer:(CGSize)containerSize {
  return CGRectMake(self.margin.left, self.margin.top,
                    containerSize.width - self.margin.left - self.margin.right,
                    containerSize.height - self.margin.top -
                        self.margin.bottom);
}

- (void)drawBackgroundInRect:(CGRect)rect context:(CGContextRef)ctx {
  UIBezierPath *path =
      [UIBezierPath bezierPathWithRoundedRect:rect
                                 cornerRadius:self.cornerRadius];
  [self.bgColor setFill];
  [path fill];
}

- (void)drawBorderInRect:(CGRect)rect context:(CGContextRef)ctx {
  if (self.borderWidth <= 0 || !self.borderColor)
    return;

  CGContextSaveGState(ctx);

  CGRect borderRect =
      CGRectInset(rect, self.borderWidth / 2, self.borderWidth / 2);

  UIBezierPath *path =
      [UIBezierPath bezierPathWithRoundedRect:borderRect
                                 cornerRadius:self.cornerRadius];
  path.lineWidth = self.borderWidth;

  if ([self.borderStyle isEqualToString:@"dashed"]) {
    CGFloat dash[] = {6, 3};
    [path setLineDash:dash count:2 phase:0];
  } else if ([self.borderStyle isEqualToString:@"dotted"]) {
    CGFloat dot[] = {2, 2};
    [path setLineDash:dot count:2 phase:0];
  }

  [self.borderColor setStroke];
  [path stroke];

  CGContextRestoreGState(ctx);
}

#pragma mark - NSTextAttachment overrides
- (UIImage *)imageForBounds:(CGRect)bounds
              textContainer:(NSTextContainer *)textContainer
             characterIndex:(NSUInteger)charIndex {

  if (!textContainer)
    return self.image;

  CGSize size = CGSizeMake(round(bounds.size.width), round(bounds.size.height));

  if (!CGSizeEqualToSize(size, self.lastRenderedSize)) {
    self.lastRenderedSize = size;
    self.image = [self renderAttachmentInSize:size];
  }

  return self.image;
}

- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer
                      proposedLineFragment:(CGRect)lineFrag
                             glyphPosition:(CGPoint)position
                            characterIndex:(NSUInteger)charIndex {

  return (CGRect){.origin = CGPointZero,
                  .size = [self requiredSizeForLineFragment:lineFrag.size]};
}

#pragma mark - Overridable API

- (CGSize)requiredSizeForLineFragment:(CGSize)lineSize {
  return CGSizeZero;
}

- (UIImage *)renderAttachmentInSize:(CGSize)containerSize {
  return nil;
}

#pragma mark - Async entry

- (void)loadAsync {
  self.lastRenderedSize = CGSizeZero;
  [self notifyUpdate];
}

@end
