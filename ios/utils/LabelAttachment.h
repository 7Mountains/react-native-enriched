@interface LabelAttachment : NSTextAttachment

@property (nonatomic, strong) NSString *labelText;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic) UIEdgeInsets inset;
@property (nonatomic) UIEdgeInsets margin;
@property (nonatomic, strong) UIColor *bgColor;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic) CGFloat borderWidth;
@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic) CGFloat cornerRadius;
@property (nonatomic, strong) NSString *borderStyle;
@end
