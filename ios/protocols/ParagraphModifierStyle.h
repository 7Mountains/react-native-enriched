@protocol ParagraphModifierStyle <NSObject>

@required
+ (NSDictionary<NSString *, NSString *> *_Nullable)containerAttributesFromValue:
    (id _Nullable)value;

@end
