#import "AlignmentConverter.h"
#import "ParagraphStyleBase.h"

@implementation ParagraphStyleBase

+ (NSDictionary<NSString *, NSString *> *)getParametersFromValue:(id)value {
  if (value) {
    NSParagraphStyle *paragraphStyle = value;

    NSTextAlignment alignment = paragraphStyle.alignment;

    return alignment != NSTextAlignmentNatural ? @{
      @"aligment" : [AlignmentConverter stringFromAlignment:alignment]
    }
                                               : nullptr;
  }

  return nullptr;
}

- (void)addAttributes:(NSRange)range {
}

- (void)
    addAttributesInAttributedString:(NSMutableAttributedString *_Nonnull)string
                              range:(NSRange)range
                         attributes:
                             (NSDictionary<NSString *, NSString *> *_Nullable)
                                 attributes {
}

- (void)addTypingAttributes {
}

- (BOOL)anyOccurence:(NSRange)range {
  return NO;
}

- (void)applyStyle:(NSRange)range {
}

+ (NSAttributedStringKey _Nonnull)attributeKey {
  return nil;
}

- (BOOL)detectStyle:(NSRange)range {
  return NO;
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  return @[];
}

+ (StyleType)getStyleType {
  return None;
}

@end
