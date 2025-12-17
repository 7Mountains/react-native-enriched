@protocol ParameterizedStyleProtocol <NSObject>

+ (NSDictionary<NSString *, NSString *> *_Nullable)getParametersFromValue:
    (id _Nonnull)value;

@end
