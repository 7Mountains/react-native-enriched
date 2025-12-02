#import "LabelAttachment.h"

@implementation LabelAttachment

- (instancetype)init {
    self = [super init];
    if (self) {
        _labelText = @"";
        _font = [UIFont systemFontOfSize:14];
        _inset = UIEdgeInsetsMake(10, 12, 10, 12);
        _margin = UIEdgeInsetsMake(6, 0, 6, 0);
        _bgColor = [UIColor clearColor];
        _textColor = [UIColor whiteColor];
        _cornerRadius = 8.0;
        _borderColor = [UIColor separatorColor];
        _borderWidth = 1.0;
        _borderStyle = @"solid";
    }
    return self;
}

- (UIImage *)imageForBounds:(CGRect)imageBounds
               textContainer:(NSTextContainer *)textContainer
              characterIndex:(NSUInteger)charIndex
{
    if (!textContainer) return nil;

    NSDictionary *attrs = @{ NSFontAttributeName : self.font };
    CGSize textSize = [self.labelText sizeWithAttributes:attrs];

    CGFloat contentWidth = textContainer.size.width;
    CGFloat contentHeight = textSize.height + self.inset.top + self.inset.bottom;
    CGSize size = CGSizeMake(
        contentWidth + self.margin.left + self.margin.right,
        contentHeight + self.margin.top + self.margin.bottom
    );

    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect rect = CGRectMake(
        self.margin.left,
        self.margin.top,
        contentWidth,
        contentHeight
    );

    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect
                                                     cornerRadius:self.cornerRadius];
    [self.bgColor setFill];
    [path fill];

    if (self.borderWidth > 0 && self.borderColor) {
        CGContextSaveGState(ctx);

        CGRect borderRect = CGRectInset(rect, self.borderWidth / 2.0, self.borderWidth / 2.0);

        UIBezierPath *borderPath =
            [UIBezierPath bezierPathWithRoundedRect:borderRect
                                        cornerRadius:self.cornerRadius - (self.borderWidth / 2.0)];

        [self.borderColor setStroke];
        borderPath.lineWidth = self.borderWidth;

        if ([self.borderStyle isEqualToString:@"dashed"]) {
            CGFloat dash[] = {6, 3};
            [borderPath setLineDash:dash count:2 phase:0];
        } else if ([self.borderStyle isEqualToString:@"dotted"]) {
            CGFloat dot[] = {2, 2};
            [borderPath setLineDash:dot count:2 phase:0];
        }

        [borderPath stroke];
        CGContextRestoreGState(ctx);
    }

    // Draw text centered inside rect
    CGRect textRect = CGRectMake(
        rect.origin.x + (rect.size.width - textSize.width) / 2,
        rect.origin.y + (rect.size.height - textSize.height) / 2,
        textSize.width,
        textSize.height
    );

    [self.labelText drawInRect:textRect
                 withAttributes:@{
                     NSFontAttributeName : self.font,
                     NSForegroundColorAttributeName : self.textColor
                 }];

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return img;
}

- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer
                      proposedLineFragment:(CGRect)lineFrag
                             glyphPosition:(CGPoint)position
                            characterIndex:(NSUInteger)charIndex
{
    NSDictionary *attrs = @{ NSFontAttributeName : self.font };
    CGSize textSize = [self.labelText sizeWithAttributes:attrs];

    CGFloat contentWidth = lineFrag.size.width;
    CGFloat contentHeight = textSize.height + self.inset.top + self.inset.bottom;

    // NEW: include margins
    return CGRectMake(0,
                      0,
                      contentWidth + self.margin.left + self.margin.right,
                      contentHeight + self.margin.top + self.margin.bottom);
}

@end
