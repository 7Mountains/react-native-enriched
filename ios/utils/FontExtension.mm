#import "FontExtension.h"
#import <React/RCTLog.h>

#pragma mark - FontVariants

@interface FontVariants : NSObject
@property(nonatomic, strong) UIFont *regular;
@property(nonatomic, strong) UIFont *bold;
@property(nonatomic, strong) UIFont *italic;
@property(nonatomic, strong) UIFont *boldItalic;
@end

@implementation FontVariants
@end

#pragma mark - Font cache helpers

static NSCache<NSString *, FontVariants *> *FontVariantsCache(void) {
  static NSCache *cache;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    cache = [NSCache new];
    cache.countLimit = 32;
  });
  return cache;
}

static NSString *FontKey(UIFont *font) {
  return [NSString stringWithFormat:@"%@-%.2f", font.fontName, font.pointSize];
}

static UIFont *MakeFont(UIFont *base, UIFontDescriptorSymbolicTraits traits) {
  UIFontDescriptor *d =
      [base.fontDescriptor fontDescriptorWithSymbolicTraits:traits];
  if (!d) {
    return nil;
  }
  return [UIFont fontWithDescriptor:d size:base.pointSize];
}

static UIFontDescriptorSymbolicTraits
RegularTraits(UIFontDescriptorSymbolicTraits traits) {
  return traits & ~(UIFontDescriptorTraitBold | UIFontDescriptorTraitItalic);
}

static FontVariants *BuildVariants(UIFont *font) {
  FontVariants *v = [FontVariants new];

  UIFontDescriptorSymbolicTraits baseTraits =
      RegularTraits(font.fontDescriptor.symbolicTraits);

  UIFontDescriptor *regularDescriptor =
      [font.fontDescriptor fontDescriptorWithSymbolicTraits:baseTraits];

  UIFont *regular = regularDescriptor
                        ? [UIFont fontWithDescriptor:regularDescriptor
                                                size:font.pointSize]
                        : font;

  v.regular = regular;

  v.bold = MakeFont(regular, baseTraits | UIFontDescriptorTraitBold);

  v.italic = MakeFont(regular, baseTraits | UIFontDescriptorTraitItalic);

  v.boldItalic = MakeFont(regular, baseTraits | UIFontDescriptorTraitBold |
                                       UIFontDescriptorTraitItalic);

  return v;
}

static FontVariants *VariantsForFont(UIFont *font) {
  if (!font)
    return nil;

  NSString *key = FontKey(font);
  FontVariants *v = [FontVariantsCache() objectForKey:key];
  if (!v) {
    v = BuildVariants(font);
    [FontVariantsCache() setObject:v forKey:key];
  }
  return v;
}

#pragma mark - UIFont(FontExtension)

@implementation UIFont (FontExtension)

- (BOOL)isBold {
  return (self.fontDescriptor.symbolicTraits & UIFontDescriptorTraitBold) ==
         UIFontDescriptorTraitBold;
}

- (BOOL)isItalic {
  return (self.fontDescriptor.symbolicTraits & UIFontDescriptorTraitItalic) ==
         UIFontDescriptorTraitItalic;
}

- (UIFont *)setBold {
  if ([self isBold]) {
    return self;
  }

  FontVariants *v = VariantsForFont(self);
  BOOL italic = [self isItalic];

  if (italic) {
    return v.boldItalic ?: self;
  }
  return v.bold ?: self;
}

- (UIFont *)removeBold {
  if (![self isBold]) {
    return self;
  }

  FontVariants *v = VariantsForFont(self);
  BOOL italic = [self isItalic];

  if (italic) {
    return v.italic ?: self;
  }
  return v.regular ?: self;
}

- (UIFont *)setItalic {
  if ([self isItalic]) {
    return self;
  }

  FontVariants *v = VariantsForFont(self);
  BOOL bold = [self isBold];

  if (bold) {
    return v.boldItalic ?: self;
  }
  return v.italic ?: self;
}

- (UIFont *)removeItalic {
  if (![self isItalic]) {
    return self;
  }

  FontVariants *v = VariantsForFont(self);
  BOOL bold = [self isBold];

  if (bold) {
    return v.bold ?: self;
  }
  return v.regular ?: self;
}

- (UIFont *)withFontTraits:(UIFont *)from {
  if (!from) {
    return self;
  }

  FontVariants *v = VariantsForFont(self);
  BOOL bold = [from isBold];
  BOOL italic = [from isItalic];

  if (bold && italic) {
    return v.boldItalic ?: self;
  }
  if (bold) {
    return v.bold ?: self;
  }
  if (italic) {
    return v.italic ?: self;
  }
  return v.regular ?: self;
}

- (UIFont *)setSize:(CGFloat)size {
  if (fabs(self.pointSize - size) < 0.01) {
    return self;
  }

  UIFont *resized = [UIFont fontWithDescriptor:self.fontDescriptor size:size];

  if (!resized) {
    RCTLogWarn(@"[EnrichedTextInput]: Couldn't apply font size %.2f", size);
    return self;
  }

  FontVariants *v = VariantsForFont(resized);
  return v.regular ?: resized;
}

@end
