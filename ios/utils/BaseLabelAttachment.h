#import <UIKit/UIKit.h>

@interface BaseLabelAttachment : NSTextAttachment

@property(nonatomic, copy) NSString *labelText;
@property(nonatomic, strong) UIFont *font;
@property(nonatomic, strong) UIColor *textColor;

// container paddings
@property(nonatomic) UIEdgeInsets inset;
@property(nonatomic) UIEdgeInsets margin;

// background & border
@property(nonatomic, strong) UIColor *bgColor;
@property(nonatomic, strong) UIColor *borderColor;
@property(nonatomic) CGFloat borderWidth;
@property(nonatomic, copy) NSString *borderStyle;
@property(nonatomic) CGFloat cornerRadius;

// core
- (void)refreshAttachmentImage;
- (CGSize)textSize;
- (CGRect)contentRectForContainer:(CGSize)containerSize;
- (void)drawBackgroundInRect:(CGRect)rect context:(CGContextRef)ctx;
- (void)drawBorderInRect:(CGRect)rect context:(CGContextRef)ctx;

@end
